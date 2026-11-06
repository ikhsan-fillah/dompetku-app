// Edge Function market-ml-cycle-run: siklus prediksi 10 hari bursa (5 hari + 10 hari + revisi di hari ke-5).
// Terpisah dari market-ml: tidak mengubah ml_prediction, model ml-logit-%, atau cron yang sudah ada.
// Menulis ke ml_cycle dan ml_model (hanya versi ml-ta5-% dan ml-rev10-%). Auth: header x-cron-secret.
//
//   {mode:'daily', dry?}            isi hasil nyata, revisi hari ke-5, dan mulai siklus pertama saham yang belum punya
//   {mode:'retrain'}                latih model 5 hari + revisi (uji walk-forward dulu), lalu mulai siklus untuk
//                                   saham yang siklusnya sudah selesai
//   {mode:'eval', fold}             (dipanggil retrain) hasil satu lipatan: model 5 hari dan revisi
//   {mode:'fit', foldsFive, foldsRev, dry?}   (dipanggil retrain) latih dan simpan; dry = hanya hitung
//   {mode:'start', fresh?, dry?}    mulai siklus; fresh=true hanya untuk saham tanpa siklus
import { createClient } from 'npm:@supabase/supabase-js@2';
import { buildRows, predict, projectX, round, signalOf, TA_FEATURES } from './lib.ts';
import type { FoldResult, Model, Series } from './lib.ts';
import {
  evalFiveDay,
  evalRevision,
  fitFiveDay,
  fitRevision,
  gate,
  gateRevision,
  latestRows,
  outcomeFor,
  pathAfter,
  PATH_FEATURES,
  revise,
} from './cycle.ts';
import type { RevisionFold } from './cycle.ts';

const UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
const LAMBDA = 5;
const SELF_URL = `${Deno.env.get('SUPABASE_URL')}/functions/v1/market-ml-cycle-run`;
/** Sinyal lebih tua dari ini (hari kalender) dianggap data harga basi, siklus tidak dimulai. */
const MAX_STALE_DAYS = 5;

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { 'Content-Type': 'application/json' } });

type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };

async function loadSeries(sinceDays: number, tickers: string[]): Promise<Series[]> {
  const since = new Date(Date.now() - sinceDays * 86400000).toISOString().slice(0, 10);
  const { data, error } = await db.rpc('ml_price_json', { since });
  if (error) throw new Error(`ml_price_json: ${error.message}`);
  const allowed = new Set([...UNIVERSE, ...tickers]);
  return (data as Raw[]).filter((s) => allowed.has(s.ticker)).map((s) => ({
    ticker: s.ticker,
    bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
  }));
}

type ActiveModel = { version: string; trainedAt: Date; model: Model; baseRate: number };

/** Model aktif terbaru dengan awalan versi `prefix`, atau null. */
async function activeModel(prefix: string): Promise<ActiveModel | null> {
  const { data } = await db
    .from('ml_model')
    .select('version,trained_at,params')
    .eq('is_active', true)
    .like('version', `${prefix}%`)
    .order('trained_at', { ascending: false })
    .limit(1);
  const m = data?.[0];
  if (!m) return null;
  return { version: m.version, trainedAt: new Date(m.trained_at), model: m.params.model as Model, baseRate: m.params.baseRate as number };
}

// ---------------------------------------------------------------- latih

/** Panggilan pertama ke isolate dingin kadang gagal WORKER_RESOURCE_LIMIT (546); ulangi, percobaan berikutnya jalan. */
async function callSelf(secret: string, body: Record<string, unknown>) {
  let last = '';
  for (let attempt = 0; attempt < 3; attempt++) {
    const res = await fetch(SELF_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-cron-secret': secret },
      body: JSON.stringify(body),
    });
    const j = await res.json().catch(() => ({}));
    if (res.ok) return j;
    last = JSON.stringify(j).slice(0, 200);
    if (res.status !== 546 && res.status !== 503) break;
  }
  throw new Error(`${body.mode}: ${last}`);
}

async function retrain(secret: string) {
  const five: FoldResult[] = [];
  const rev: RevisionFold[] = [];
  // Dua lipatan sekaligus: lebih dari itu membuat ml_price_json kena statement timeout.
  for (const pair of [[0, 1], [2, 3], [4]]) {
    const out = await Promise.all(pair.map((fold) => callSelf(secret, { mode: 'eval', fold })));
    for (const o of out) {
      five.push(o.five);
      rev.push(o.rev);
    }
  }
  const fit = await callSelf(secret, { mode: 'fit', foldsFive: five, foldsRev: rev });
  const start = await callSelf(secret, { mode: 'start', fresh: false });
  return { fit, start };
}

async function fit(body: { foldsFive: FoldResult[]; foldsRev: RevisionFold[]; dry?: boolean }) {
  const today = new Date().toISOString().slice(0, 10);
  const series = await loadSeries(365 * 6, []);
  const g5 = gate(body.foldsFive);
  const gr = gateRevision(body.foldsRev);
  const f5 = fitFiveDay(series);
  const fr = fitRevision(series);
  const out = {
    five: { gate: g5, nTrain: f5.nTrain, baseRate: round(f5.baseRate), coef: Object.fromEntries(TA_FEATURES.map((f, j) => [f, round(f5.model.coef[j], 3)])) },
    revision: { gate: gr, nTrain: fr.nTrain, baseRate: round(fr.baseRate), coef: Object.fromEntries(PATH_FEATURES.map((f, j) => [f, round(fr.model.coef[j], 3)])) },
  };
  if (body.dry) return { dry: true, ...out };
  const errors: string[] = [];
  const save = async (prefix: string, row: Record<string, unknown>, activate: boolean) => {
    if (activate) {
      const { error } = await db.from('ml_model').update({ is_active: false }).eq('is_active', true).like('version', `${prefix}%`);
      if (error) errors.push(`${prefix} nonaktifkan: ${error.message}`);
    }
    const { error } = await db.from('ml_model').upsert({ ...row, is_active: activate });
    if (error) errors.push(`${prefix} simpan: ${error.message}`);
  };
  await save('ml-ta5-', {
    version: `ml-ta5-${today}${g5.ok ? '' : '-cand'}`,
    horizon_days: 5,
    barrier_k: 1,
    features: [...TA_FEATURES],
    params: { model: f5.model, baseRate: f5.baseRate, lambda: LAMBDA, nTrain: f5.nTrain, firstDate: f5.firstDate, lastLabeledDate: f5.lastLabeledDate },
    metrics: { folds: body.foldsFive, gate: g5 },
    universe: f5.tickers,
  }, g5.ok);
  await save('ml-rev10-', {
    version: `ml-rev10-${today}${gr.ok ? '' : '-cand'}`,
    horizon_days: 10,
    barrier_k: 1,
    features: [...PATH_FEATURES],
    params: { model: fr.model, baseRate: fr.baseRate, lambda: LAMBDA, nTrain: fr.nTrain, firstDate: fr.firstDate, lastLabeledDate: fr.lastLabeledDate },
    metrics: { folds: body.foldsRev, gate: gr },
    universe: UNIVERSE,
  }, gr.ok);
  return { ...out, errors };
}

// ---------------------------------------------------------------- mulai siklus

/** Mulai siklus. fresh=true: hanya saham yang belum pernah punya siklus. fresh=false: juga saham yang siklusnya sudah selesai. */
async function startCycles(opts: { fresh: boolean; dry?: boolean }) {
  const m10 = await activeModel('ml-logit-');
  if (!m10) return { note: 'tidak ada model 10 hari aktif, siklus tidak dimulai' };
  const m5 = await activeModel('ml-ta5-');
  const { data: wl } = await db.from('watchlist').select('user_id,ticker').eq('is_active', true);
  const list = (wl ?? []) as { user_id: string; ticker: string }[];
  if (list.length === 0) return { note: 'watchlist kosong' };
  const tickers = [...new Set(list.map((w) => w.ticker))];
  const series = await loadSeries(420, tickers);
  const rows10 = buildRows(series, { horizon: 10, k: 1 });
  const rows5 = buildRows(series, { horizon: 5, k: 1 });
  const latest10 = new Map(latestRows(rows10).map((r) => [r.ticker, r]));
  const latest5 = new Map(latestRows(rows5).map((r) => [r.ticker, r]));
  const { data: prevRows } = await db.from('ml_cycle').select('user_id,ticker,cycle_start,out10_date').in('ticker', tickers).order('cycle_start', { ascending: false });
  const prev = new Map<string, { cycle_start: string; out10_date: string | null }>();
  for (const p of prevRows ?? []) if (!prev.has(`${p.user_id}|${p.ticker}`)) prev.set(`${p.user_id}|${p.ticker}`, p);
  const started: unknown[] = [];
  const skipped: unknown[] = [];
  const errors: string[] = [];
  for (const w of list) {
    const p = prev.get(`${w.user_id}|${w.ticker}`);
    const eligible = !p || (!opts.fresh && p.out10_date !== null);
    if (!eligible) {
      skipped.push({ ticker: w.ticker, why: p!.out10_date === null ? 'siklus berjalan' : 'menunggu pelatihan Sabtu' });
      continue;
    }
    const r10 = latest10.get(w.ticker);
    if (!r10) {
      skipped.push({ ticker: w.ticker, why: 'tidak ada data terbaru' });
      continue;
    }
    if ((Date.now() - Date.parse(r10.date)) / 86400000 > MAX_STALE_DAYS) {
      skipped.push({ ticker: w.ticker, why: `data harga basi (${r10.date})` });
      continue;
    }
    if (p && r10.date <= p.cycle_start) {
      skipped.push({ ticker: w.ticker, why: 'belum ada hari bursa baru sejak siklus terakhir' });
      continue;
    }
    const prob10 = predict(m10.model, projectX(r10.x, m10.model.features));
    const r5 = latest5.get(w.ticker);
    const prob5 = m5 && r5 ? predict(m5.model, projectX(r5.x, m5.model.features)) : null;
    const row = {
      user_id: w.user_id,
      ticker: w.ticker,
      cycle_start: r10.date,
      close0: r10.close,
      model10: m10.version,
      prob10: round(prob10),
      base10: round(m10.baseRate),
      signal10: signalOf(prob10, m10.baseRate),
      upper10: round(r10.upperPct),
      lower10: round(r10.lowerPct),
      ...(m5 && r5 && prob5 !== null
        ? { model5: m5.version, prob5: round(prob5), base5: round(m5.baseRate), signal5: signalOf(prob5, m5.baseRate), upper5: round(r5.upperPct), lower5: round(r5.lowerPct) }
        : {}),
    };
    started.push({ ticker: w.ticker, cycleStart: r10.date, prob10: row.prob10, prob5: 'prob5' in row ? row.prob5 : null });
    if (opts.dry) continue;
    // ignoreDuplicates: prediksi yang sudah dikunci tidak pernah ditimpa.
    const { error } = await db.from('ml_cycle').upsert(row, { onConflict: 'user_id,ticker,cycle_start', ignoreDuplicates: true });
    if (error) errors.push(`${w.ticker}: ${error.message}`);
  }
  return { model10: m10.version, model5: m5?.version ?? null, started, skipped, errors };
}

// ---------------------------------------------------------------- harian

/** Isi hasil nyata 5 hari, revisi hari ke-5, dan hasil nyata 10 hari untuk siklus yang berjalan. */
async function updateCycles(dry?: boolean) {
  const { data: open, error } = await db.from('ml_cycle').select('*').is('out10_date', null);
  if (error) throw new Error(error.message);
  // deno-lint-ignore no-explicit-any
  const cycles = (open ?? []) as Record<string, any>[];
  if (cycles.length === 0) return { open: 0, updated: [], errors: [] as string[] };
  const series = await loadSeries(420, [...new Set(cycles.map((c) => c.ticker as string))]);
  const byTicker = new Map(series.map((s) => [s.ticker, s.bars]));
  const rev = await activeModel('ml-rev10-');
  const updated: unknown[] = [];
  const errors: string[] = [];
  for (const c of cycles) {
    const bars = byTicker.get(c.ticker);
    const i = bars?.findIndex((b) => b.date === c.cycle_start) ?? -1;
    if (!bars || i < 0) {
      errors.push(`${c.ticker} ${c.cycle_start}: tanggal siklus tidak ada di price_history`);
      continue;
    }
    const patch: Record<string, unknown> = {};
    if (c.out5_date === null && c.model5) {
      const o = outcomeFor(bars, i, 5, Number(c.upper5), Number(c.lower5));
      if (o) Object.assign(patch, { out5_date: o.date, out5_entry: o.entry, out5_exit: o.exit, out5_ret_net: round(o.retNet), out5_win: o.win, out5_hit_upper: o.hitUpper });
    }
    if (c.rev_date === null) {
      const ps = pathAfter(bars, i, Number(c.upper10), Number(c.lower10));
      const rv = ps ? revise(rev?.model ?? null, ps) : null;
      if (ps && rv) {
        Object.assign(patch, {
          rev_date: bars[i + 5].date,
          rev_state: rv.state,
          rev_prob: round(rv.prob),
          rev_model: rv.state === 'diperbarui' ? rev!.version : null,
          rev_base: rv.state === 'diperbarui' ? round(rev!.baseRate) : null,
          rev_z5: round(rv.z5),
          rev_max_up: round(rv.maxUp5),
          rev_min_dn: round(rv.minDn5),
        });
      }
    }
    const o10 = outcomeFor(bars, i, 10, Number(c.upper10), Number(c.lower10));
    if (o10) Object.assign(patch, { out10_date: o10.date, out10_entry: o10.entry, out10_exit: o10.exit, out10_ret_net: round(o10.retNet), out10_win: o10.win, out10_hit_upper: o10.hitUpper });
    if (Object.keys(patch).length === 0) continue;
    updated.push({ ticker: c.ticker, cycleStart: c.cycle_start, set: Object.keys(patch) });
    if (dry) continue;
    const { error: e } = await db.from('ml_cycle').update(patch).eq('id', c.id);
    if (e) errors.push(`${c.ticker} ${c.cycle_start}: ${e.message}`);
  }
  return { open: cycles.length, updated, errors };
}

// ---------------------------------------------------------------- handler

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    const t0 = Date.now();
    switch (body.mode) {
      case 'eval': {
        const series = await loadSeries(365 * 6, []);
        const fold = Number(body.fold);
        return json({ ms: Date.now() - t0, five: evalFiveDay(series, fold)[0], rev: evalRevision(series, fold)[0] });
      }
      case 'fit':
        return json({ ms: Date.now() - t0, ...(await fit(body)) });
      case 'start':
        return json({ ms: Date.now() - t0, ...(await startCycles({ fresh: body.fresh !== false, dry: !!body.dry })) });
      case 'daily': {
        const update = await updateCycles(!!body.dry);
        const start = await startCycles({ fresh: true, dry: !!body.dry });
        return json({ ms: Date.now() - t0, update, start });
      }
      case 'retrain':
        return json({ ms: Date.now() - t0, ...(await retrain(secret)) });
      default:
        return json({ error: 'mode tidak dikenal' }, 400);
    }
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
