// Edge Function market-ml: ambil harga harian (Yahoo Finance), latih dan uji
// model, screening, dan analisis harian otomatis untuk saham aktif.
// Dipanggil pg_cron lewat public.ml_invoke (header x-cron-secret dari Vault). Mode lewat body JSON:
//   {mode:'ingest', range:'5y'|'3mo', tickers?:string[]}
//   {mode:'evaluate', fold:0..4}
//   {mode:'fit', folds:FoldResult[]}
//   {mode:'screen', top?:number}
//   {mode:'daily'}
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  buildRows,
  drivers,
  FEATURES,
  fitLogistic,
  indicators,
  predict,
  round,
  signalOf,
  walkForward,
  type Bar,
  type FoldResult,
  type Model,
  type Row,
  type Series,
} from './lib.ts';
import {
  buildMarketRows,
  CNBC_MARKET_RSS,
  googleNewsUrl,
  MACRO,
  MARKET_FEATURES,
  NEWS_QUERIES,
  parseRss,
  scoreTitle,
  summarize,
  type NewsItem,
} from './market.ts';

const UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
const HORIZON = 10;
const BARRIER_K = 1;
const LAMBDA = 5;
const FOLDS = 5;
// Model IHSG: horizon 5 hari bursa, batas 1 sigma.
const MP = { horizon: 5, k: 1 };
const SELF_URL = `${Deno.env.get('SUPABASE_URL')}/functions/v1/market-ml`;

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false },
});

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

// ---------------------------------------------------------------- Yahoo

/** raw = simbol Yahoo apa adanya (indeks, ETF, kurs, komoditas); selain itu saham IDX (.JK). */
async function fetchYahoo(ticker: string, range: string, raw = false): Promise<Bar[]> {
  const sym = raw ? encodeURIComponent(ticker) : `${ticker}.JK`;
  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${sym}?range=${range}&interval=1d`;
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  if (!res.ok) throw new Error(`${ticker}: HTTP ${res.status}`);
  const body = await res.json();
  const r = body?.chart?.result?.[0];
  if (!r?.timestamp) throw new Error(`${ticker}: tanpa data`);
  const q = r.indicators.quote[0];
  const offset = (r.meta?.gmtoffset ?? 25200) * 1000;
  const bars: Bar[] = [];
  r.timestamp.forEach((t: number, i: number) => {
    const o = q.open[i], h = q.high[i], l = q.low[i], c = q.close[i];
    const v = raw ? (q.volume?.[i] ?? 0) : q.volume[i];
    if ([o, h, l, c, v].some((x) => x === null || x === undefined)) return;
    if (!raw && v === 0) return; // kurs dan indeks boleh tanpa volume
    const date = new Date(t * 1000 + offset).toISOString().slice(0, 10);
    bars.push({ date, open: o, high: h, low: l, close: c, volume: v });
  });
  // Yahoo kadang mengulang tanggal terakhir; ambil yang terakhir.
  const byDate = new Map(bars.map((b) => [b.date, b]));
  return [...byDate.values()].sort((a, b) => (a.date < b.date ? -1 : 1));
}

async function ingest(tickers: string[], range: string, raw = false) {
  const ok: string[] = [];
  const failed: string[] = [];
  let rows = 0;
  for (let i = 0; i < tickers.length; i += 6) {
    const batch = tickers.slice(i, i + 6);
    const results = await Promise.allSettled(batch.map((t) => fetchYahoo(t, range, raw)));
    for (let j = 0; j < batch.length; j++) {
      const r = results[j];
      if (r.status === 'rejected') {
        failed.push(`${batch[j]} (${String(r.reason).slice(0, 80)})`);
        continue;
      }
      const payload = r.value.map((b) => ({
        ticker: batch[j],
        trade_date: b.date,
        open_price: b.open,
        high_price: b.high,
        low_price: b.low,
        close_price: b.close,
        volume: Math.round(b.volume),
        source: 'yahoo',
        fetched_at: new Date().toISOString(),
      }));
      for (let k = 0; k < payload.length; k += 1000) {
        const { error } = await db.from('price_history').upsert(payload.slice(k, k + 1000));
        if (error) throw new Error(`upsert ${batch[j]}: ${error.message}`);
      }
      rows += payload.length;
      ok.push(batch[j]);
    }
  }
  return { ok, failed, rows };
}

/** Harga dari price_history: universe model, ditambah `extra` bila diminta. */
function loadSeries(sinceDays: number, extra: string[] = []): Promise<Series[]> {
  return loadRaw(sinceDays, [...UNIVERSE, ...extra]);
}

async function loadRaw(sinceDays: number, symbols: string[]): Promise<Series[]> {
  const since = new Date(Date.now() - sinceDays * 86400000).toISOString().slice(0, 10);
  const { data, error } = await db.rpc('ml_price_json', { since });
  if (error) throw new Error(`ml_price_json: ${error.message}`);
  const allowed = new Set(symbols);
  type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };
  return (data as Raw[]).filter((s) => allowed.has(s.ticker)).map((s) => ({
    ticker: s.ticker,
    bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
  }));
}

const PARAMS = { horizon: HORIZON, k: BARRIER_K };

// ---------------------------------------------------------------- model

async function activeModel(): Promise<{ version: string; model: Model; baseRate: number } | null> {
  const { data } = await db
    .from('ml_model')
    .select('*')
    .eq('is_active', true)
    .like('version', 'ml-logit-%')
    .order('trained_at', { ascending: false })
    .limit(1);
  const m = data?.[0];
  if (!m) return null;
  return { version: m.version, model: m.params.model as Model, baseRate: m.params.baseRate as number };
}

type Side = { model: Model; baseRate: number };
async function activeMarket(): Promise<{ version: string; up: Side; down: Side } | null> {
  const { data } = await db
    .from('ml_model')
    .select('version,params')
    .eq('is_active', true)
    .like('version', 'ml-ihsg-%')
    .order('trained_at', { ascending: false })
    .limit(1);
  const m = data?.[0];
  return m ? { version: m.version, up: m.params.up as Side, down: m.params.down as Side } : null;
}

/** Syarat model baru boleh dipakai: AUC rata-rata >= 0,53 dan logloss lebih baik dari base rate di >= 80% fold. */
function gate(folds: FoldResult[]) {
  const meanAuc = folds.reduce((a, f) => a + f.auc, 0) / folds.length;
  const beat = folds.filter((f) => f.logloss < f.logloss_base).length;
  return { ok: meanAuc >= 0.53 && beat >= Math.ceil(folds.length * 0.8), meanAuc: round(meanAuc), foldsBeatBase: beat, folds: folds.length };
}

function latestRows(rows: Row[]): Row[] {
  const last = new Map<string, Row>();
  for (const r of rows) last.set(r.ticker, r); // rows urut tanggal
  const maxDate = [...last.values()].reduce((a, r) => (r.date > a ? r.date : a), '');
  // Hanya saham yang punya data di tanggal terakhir bursa.
  return [...last.values()].filter((r) => r.date === maxDate);
}

function describe(p: { prob: number; base: number; signal: string; upper: number; lower: number }) {
  const pct = (v: number) => `${(v * 100).toFixed(1)}%`;
  const head = {
    peluang: 'Peluang naik di atas rata-rata',
    netral: 'Tidak ada keunggulan yang jelas',
    risiko: 'Peluang naik di bawah rata-rata',
  }[p.signal];
  return `${head}: peluang menyentuh +${pct(p.upper)} sebelum ${pct(p.lower)} dalam ${HORIZON} hari bursa = ${pct(p.prob)} (rata-rata ${pct(p.base)}). Model statistik, bukan saran.`;
}

// ---------------------------------------------------------------- daily

async function daily() {
  const started = new Date().toISOString();
  const { data: wl, error } = await db.from('watchlist').select('user_id,ticker').eq('is_active', true);
  if (error) throw new Error(error.message);
  // Saham aktif di luar universe tetap diambil harganya supaya grafik di app terisi.
  const extra = [...new Set((wl ?? []).map((w) => w.ticker))].filter((t) => !UNIVERSE.includes(t));
  const ing = await ingest([...UNIVERSE, ...extra], '1mo');
  const am = await activeModel();
  if (!am) throw new Error('belum ada model aktif');
  const series = await loadSeries(420, extra);
  const rows = buildRows(series, PARAMS);
  const latest = new Map(latestRows(rows).map((r) => [r.ticker, r]));
  const out: unknown[] = [];
  const errors: string[] = [];
  const check = (label: string, res: { error: { message: string } | null }) => {
    if (res.error) errors.push(`${label}: ${res.error.message}`);
  };
  for (const w of wl ?? []) {
    const s = series.find((x) => x.ticker === w.ticker);
    if (s) await writeSnapshots(w.user_id, s);
    const r = latest.get(w.ticker);
    if (!r) {
      out.push({ ticker: w.ticker, note: 'tidak ada data terbaru (di luar universe atau tidak diperdagangkan)' });
      continue;
    }
    const prob = predict(am.model, r.x);
    const signal = signalOf(prob, am.baseRate);
    const drv = drivers(am.model, r.x);
    const outside = !UNIVERSE.includes(w.ticker);
    check(`ml_prediction ${w.ticker}`, await db.from('ml_prediction').upsert(
      {
        user_id: w.user_id,
        ticker: w.ticker,
        trade_date: r.date,
        model_version: am.version,
        horizon_days: HORIZON,
        prob_up: round(prob),
        base_rate: round(am.baseRate),
        signal,
        upper_pct: round(r.upperPct),
        lower_pct: round(r.lowerPct),
        close_price: r.close,
        drivers: drv,
      },
      { onConflict: 'user_id,ticker,trade_date,model_version' },
    ));
    check(`analysis_result del ${w.ticker}`, await db.from('analysis_result').delete().match({ user_id: w.user_id, ticker: w.ticker, trade_date: r.date, rule_version: am.version }));
    // range_label dibatasi CHECK (Latest/7D/1M/3M); hasil ML dibedakan lewat rule_version.
    check(`analysis_result ${w.ticker}`, await db.from('analysis_result').insert({
      user_id: w.user_id,
      ticker: w.ticker,
      trade_date: r.date,
      range_label: 'Latest',
      kondisi: signal,
      technical_note:
        describe({ prob, base: am.baseRate, signal, upper: r.upperPct, lower: r.lowerPct }) +
        (outside ? ' Catatan: saham ini di luar data latih model, jadi hasilnya kurang bisa dipercaya.' : ''),
      broker_note: null,
      rule_version: am.version,
    }));
    out.push({ ticker: w.ticker, date: r.date, prob: round(prob, 3), signal });
  }
  let market: unknown = null;
  try {
    market = await marketDaily(errors);
  } catch (e) {
    errors.push(`market: ${String(e).slice(0, 200)}`);
  }
  const users = [...new Set((wl ?? []).map((w) => w.user_id))];
  for (const u of users) {
    check('run_log', await db.from('run_log').insert({
      user_id: u,
      started_at: started,
      finished_at: new Date().toISOString(),
      tickers: (wl ?? []).filter((w) => w.user_id === u).map((w) => w.ticker),
      status: ing.failed.length || errors.length ? 'sebagian' : 'selesai',
      rereads: 0,
      note: `market-ml daily ${am.version}; gagal: ${ing.failed.join(', ') || '-'}; error tulis: ${errors.length}`,
    }));
  }
  return { ingest: ing, predictions: out, market, errors };
}

/** Isi daily_snapshot 70 hari terakhir: tanggal baru, atau ganti baris berjalan. */
async function writeSnapshots(userId: string, s: Series) {
  const bars = s.bars;
  const ind = indicators(bars);
  const from = Math.max(1, bars.length - 70);
  const { data: existing } = await db
    .from('daily_snapshot')
    .select('trade_date,is_intraday')
    .eq('user_id', userId)
    .eq('ticker', s.ticker)
    .gte('trade_date', bars[from].date);
  const keep = new Set((existing ?? []).filter((e) => !e.is_intraday).map((e) => e.trade_date));
  const n = (v: number | null, d = 2) => (v === null ? null : round(v, d));
  const payload = [];
  for (let i = from; i < bars.length; i++) {
    const b = bars[i];
    if (keep.has(b.date)) continue; // data Stockbit yang sudah final tidak ditimpa
    payload.push({
      user_id: userId,
      ticker: s.ticker,
      trade_date: b.date,
      open_price: Math.round(b.open),
      high_price: Math.round(b.high),
      low_price: Math.round(b.low),
      close_price: Math.round(b.close),
      prev_close: Math.round(bars[i - 1].close),
      volume_lot: Math.round(b.volume / 100),
      value_idr: null,
      volume_ma20: ind.volMa20Lot[i] === null ? null : Math.round(ind.volMa20Lot[i] as number),
      stoch_rsi_a: n(ind.stochK[i]),
      stoch_rsi_b: n(ind.stochD[i]),
      macd_a: n(ind.macd[i]),
      macd_b: n(ind.signal[i]),
      macd_hist: n(ind.hist[i]),
      is_intraday: false,
      quality: 'ok',
      quality_note: 'otomatis dari Yahoo Finance; indikator dari riwayat panjang',
      captured_at: new Date().toISOString(),
    });
  }
  if (payload.length) {
    const { error } = await db.from('daily_snapshot').upsert(payload, { onConflict: 'user_id,ticker,trade_date' });
    if (error) throw new Error(`daily_snapshot ${s.ticker}: ${error.message}`);
  }
}

// ---------------------------------------------------------------- pasar (IHSG) dan berita

async function fetchNews(): Promise<NewsItem[]> {
  const feeds = [
    ...NEWS_QUERIES.map((q) => ({ url: googleNewsUrl(q), q, google: true })),
    { url: CNBC_MARKET_RSS, q: 'CNBC market', google: false },
  ];
  const res = await Promise.allSettled(
    feeds.map(async (f) => {
      const r = await fetch(f.url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (!r.ok) throw new Error(`${f.q}: HTTP ${r.status}`);
      return parseRss(await r.text(), f.q, f.google);
    }),
  );
  const cutoff = Date.now() - 48 * 3600 * 1000;
  const seen = new Set<string>();
  const items: NewsItem[] = [];
  for (const r of res) {
    if (r.status !== 'fulfilled') continue;
    for (const it of r.value) {
      const key = it.title.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
      if (seen.has(key) || Date.parse(it.published_at) < cutoff) continue;
      seen.add(key);
      items.push(it);
    }
  }
  return items;
}

async function storeNews(items: NewsItem[], errors: string[]) {
  const rows = items.map((it) => {
    const s = scoreTitle(it.title);
    return {
      url: it.url,
      title: it.title,
      source: it.source,
      published_at: it.published_at,
      query: it.query,
      sentiment: s.score === null ? null : round(s.score, 3),
      pos_hits: s.pos,
      neg_hits: s.neg,
      topics: s.topics,
    };
  });
  for (let k = 0; k < rows.length; k += 500) {
    const { error } = await db.from('market_news').upsert(rows.slice(k, k + 500), { onConflict: 'url', ignoreDuplicates: true });
    if (error) errors.push(`market_news: ${error.message}`);
  }
}

function topHeadlines(items: NewsItem[], n = 8) {
  return items
    .map((it) => ({ it, s: scoreTitle(it.title) }))
    .filter((x) => x.s.topics.length > 0)
    .sort((a, b) => b.s.topics.length - a.s.topics.length || Math.abs(b.s.score ?? 0) - Math.abs(a.s.score ?? 0) || (a.it.published_at < b.it.published_at ? 1 : -1))
    .slice(0, n)
    .map(({ it, s }) => ({ title: it.title, source: it.source, url: it.url, published_at: it.published_at, sentiment: s.score, topics: s.topics }));
}

async function marketDaily(errors: string[]) {
  const ing = await ingest(MACRO, '1mo', true);
  if (ing.failed.length) errors.push(`makro gagal: ${ing.failed.join(', ')}`);
  const news = await fetchNews();
  await storeNews(news, errors);
  const sum = summarize(news);
  const mm = await activeMarket();
  if (!mm) return { note: 'belum ada model IHSG aktif', news: sum };
  const { up, down } = buildMarketRows(await loadRaw(500, MACRO), MP);
  const lu = up[up.length - 1];
  const ld = down[down.length - 1];
  if (!lu || !ld) return { note: 'data IHSG atau data global belum lengkap', news: sum };
  const pUp = predict(mm.up.model, lu.x);
  const pDown = predict(mm.down.model, ld.x);
  const dUp = pUp - mm.up.baseRate;
  const dDown = pDown - mm.down.baseRate;
  const kondisi = dUp >= 0.05 && dDown < 0.05 ? 'peluang' : dDown >= 0.05 && dUp < 0.05 ? 'risiko' : 'netral';
  const pct = (v: number) => `${(v * 100).toFixed(1)}%`;
  const topics = sum.topics.slice(0, 4).map((t) => `${t.topic} (${t.n})`).join(', ') || '-';
  const note =
    `IHSG ${lu.date}: peluang menyentuh +${pct(lu.upperPct)} lebih dulu dalam ${MP.horizon} hari bursa = ${pct(pUp)} (rata-rata ${pct(mm.up.baseRate)}); ` +
    `risiko menyentuh ${pct(lu.lowerPct)} lebih dulu = ${pct(pDown)} (rata-rata ${pct(mm.down.baseRate)}). ` +
    `Berita 48 jam: ${sum.count} judul, skor ${sum.score === null ? '-' : sum.score.toFixed(2)} (${sum.positive} positif, ${sum.negative} negatif); topik: ${topics}. ` +
    'Skor berita belum dipakai model. Model statistik, bukan saran.';
  const { error } = await db.from('market_signal').upsert(
    {
      trade_date: lu.date,
      model_version: mm.version,
      horizon_days: MP.horizon,
      prob_up: round(pUp),
      base_up: round(mm.up.baseRate),
      prob_down: round(pDown),
      base_down: round(mm.down.baseRate),
      kondisi,
      upper_pct: round(lu.upperPct),
      lower_pct: round(lu.lowerPct),
      close_price: lu.close,
      drivers: { up: drivers(mm.up.model, lu.x, 5), down: drivers(mm.down.model, ld.x, 5) },
      news_score: sum.score === null ? null : round(sum.score, 3),
      news_count: sum.count,
      news_topics: sum.topics,
      news_top: topHeadlines(news),
      note,
    },
    { onConflict: 'trade_date' },
  );
  if (error) errors.push(`market_signal: ${error.message}`);
  return { date: lu.date, pUp: round(pUp, 3), pDown: round(pDown, 3), kondisi, news: sum, note };
}

async function callSelf(secret: string, body: Record<string, unknown>) {
  const res = await fetch(SELF_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-cron-secret': secret },
    body: JSON.stringify(body),
  });
  const j = await res.json();
  if (!res.ok) throw new Error(`${body.mode}: ${JSON.stringify(j).slice(0, 200)}`);
  return j;
}

/** Latih ulang mingguan: uji walk-forward dulu, model baru hanya dipakai bila lulus gate. */
async function retrain(secret: string) {
  const sFolds = (await Promise.all([0, 1, 2, 3, 4].map((f) => callSelf(secret, { mode: 'evaluate', fold: f })))).flat() as FoldResult[];
  const sg = gate(sFolds);
  const stock = { gate: sg, fit: await callSelf(secret, { mode: 'fit', folds: sFolds, activate: sg.ok }) };
  const [mu, md] = await Promise.all([
    callSelf(secret, { mode: 'market_evaluate', label: 'up' }),
    callSelf(secret, { mode: 'market_evaluate', label: 'down' }),
  ]);
  const gu = gate(mu.folds);
  const gd = gate(md.folds);
  const market = {
    gateUp: gu,
    gateDown: gd,
    fit: await callSelf(secret, { mode: 'market_fit', folds: { up: mu.folds, down: md.folds }, activate: gu.ok && gd.ok }),
  };
  return { stock, market };
}

// ---------------------------------------------------------------- handler

Deno.serve(async (req) => {
  // Rahasia disimpan di Vault (dibaca lewat RPC khusus service role).
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    switch (body.mode) {
      case 'ingest':
        return json(await ingest(body.tickers ?? UNIVERSE, body.range ?? '5y'));
      case 'evaluate': {
        const rows = buildRows(await loadSeries(365 * 6), PARAMS);
        return json(walkForward(rows, HORIZON, FOLDS, LAMBDA, body.fold ?? 0));
      }
      case 'fit': {
        const rows = buildRows(await loadSeries(365 * 6), PARAMS);
        const lab = rows.filter((r) => r.y !== null);
        const model = fitLogistic(lab.map((r) => r.x), lab.map((r) => r.y as number), LAMBDA);
        const baseRate = lab.reduce((a, r) => a + (r.y as number), 0) / lab.length;
        const activate = body.activate !== false;
        const version = `ml-logit-tb${HORIZON}-${new Date().toISOString().slice(0, 10)}${activate ? '' : '-cand'}`;
        const tickers = [...new Set(rows.map((r) => r.ticker))].sort();
        if (activate) await db.from('ml_model').update({ is_active: false }).eq('is_active', true).like('version', 'ml-logit-%');
        const { error } = await db.from('ml_model').upsert({
          version,
          horizon_days: HORIZON,
          barrier_k: BARRIER_K,
          features: [...FEATURES],
          params: { model, baseRate, lambda: LAMBDA, nTrain: lab.length, firstDate: lab[0].date, lastLabeledDate: lab[lab.length - 1].date },
          metrics: { folds: body.folds ?? [] },
          universe: tickers,
          is_active: activate,
        });
        if (error) throw new Error(error.message);
        return json({ version, activate, nTrain: lab.length, baseRate: round(baseRate), coef: Object.fromEntries(FEATURES.map((f, j) => [f, round(model.coef[j], 3)])) });
      }
      case 'screen': {
        const am = await activeModel();
        if (!am) throw new Error('belum ada model aktif');
        const rows = buildRows(await loadSeries(420), PARAMS);
        const list = latestRows(rows).map((r) => {
          const prob = predict(am.model, r.x);
          return {
            ticker: r.ticker,
            date: r.date,
            prob: round(prob, 3),
            signal: signalOf(prob, am.baseRate),
            valueIdr20B: round(r.valueIdr20 / 1e9, 1),
            upperPct: round(r.upperPct, 3),
            lowerPct: round(r.lowerPct, 3),
            drivers: drivers(am.model, r.x, 3),
          };
        });
        list.sort((a, b) => b.prob - a.prob);
        return json({ model: am.version, baseRate: round(am.baseRate, 3), list });
      }
      case 'daily':
        return json(await daily());
      case 'ingest_macro':
        return json(await ingest(MACRO, body.range ?? '10y', true));
      case 'market_evaluate': {
        const rows = buildMarketRows(await loadRaw(365 * 11, MACRO), MP);
        const r = body.label === 'down' ? rows.down : rows.up;
        const lab = r.filter((x) => x.y !== null);
        return json({
          label: body.label ?? 'up',
          n: lab.length,
          first: lab[0]?.date,
          last: lab[lab.length - 1]?.date,
          folds: walkForward(r, MP.horizon, FOLDS, LAMBDA, undefined, MARKET_FEATURES, 'ihsg_ret20'),
        });
      }
      case 'market_fit': {
        const { up, down } = buildMarketRows(await loadRaw(365 * 11, MACRO), MP);
        const fitOne = (rows: Row[]) => {
          const lab = rows.filter((r) => r.y !== null);
          const model = fitLogistic(lab.map((r) => r.x), lab.map((r) => r.y as number), LAMBDA, 4, 25, MARKET_FEATURES);
          return { model, baseRate: lab.reduce((a, r) => a + (r.y as number), 0) / lab.length, n: lab.length, first: lab[0].date, last: lab[lab.length - 1].date };
        };
        const u = fitOne(up);
        const d = fitOne(down);
        const activate = body.activate !== false;
        const version = `ml-ihsg-tb${MP.horizon}-${new Date().toISOString().slice(0, 10)}${activate ? '' : '-cand'}`;
        if (activate) await db.from('ml_model').update({ is_active: false }).eq('is_active', true).like('version', 'ml-ihsg-%');
        const { error } = await db.from('ml_model').upsert({
          version,
          horizon_days: MP.horizon,
          barrier_k: MP.k,
          features: [...MARKET_FEATURES],
          params: { up: { model: u.model, baseRate: u.baseRate }, down: { model: d.model, baseRate: d.baseRate }, lambda: LAMBDA, nTrain: u.n, firstDate: u.first, lastLabeledDate: u.last },
          metrics: { folds: body.folds ?? null },
          universe: [...MACRO],
          is_active: activate,
        });
        if (error) throw new Error(error.message);
        const coef = (m: Model) => Object.fromEntries(MARKET_FEATURES.map((f, j) => [f, round(m.coef[j], 3)]));
        return json({ version, activate, nTrain: u.n, baseUp: round(u.baseRate), baseDown: round(d.baseRate), coefUp: coef(u.model), coefDown: coef(d.model) });
      }
      case 'news': {
        const errors: string[] = [];
        const items = await fetchNews();
        await storeNews(items, errors);
        return json({ summary: summarize(items), top: topHeadlines(items), errors });
      }
      case 'market_daily': {
        const errors: string[] = [];
        return json({ market: await marketDaily(errors), errors });
      }
      case 'retrain':
        return json(await retrain(secret as string));
      default:
        return json({ error: 'mode tidak dikenal' }, 400);
    }
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
