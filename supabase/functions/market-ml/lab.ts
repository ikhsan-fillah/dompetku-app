// Edge Function market-ml-lab: eksperimen perbaikan model (GBM, fitur pasar,
// universe lebih luas) tanpa menyentuh fungsi produksi market-ml.
// Hanya membaca price_history; tidak menulis apa pun. Auth sama: header x-cron-secret.
//   {mode:'eval', fold:0..4, model:'logit'|'gbm', market?:bool, universe?:'base'|'all', gbm?:Partial<GbmParams>, detail?:bool, testBase?:bool, stride?:number, target?:'tb'|'rel', rule?:{feature:string, sign:1|-1}}
import { createClient } from 'npm:@supabase/supabase-js@2';
import { buildRows, FEATURES, fitLogistic, predict, walkForward, type Row, type Series } from './lib.ts';
import { buildMarketRows, MACRO, MARKET_FEATURES } from './market.ts';
import { fitGbm, gbmImportance, GBM_DEFAULT, predictGbm } from './gbm.ts';

const BASE_UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
const PARAMS = { horizon: 10, k: 1 };
const MP = { horizon: 5, k: 1 };
const FOLDS = 5;
const LAMBDA = 5;
const MKT_PICK = [
  'ihsg_ret5', 'ihsg_ret20', 'ihsg_vol20', 'ihsg_distSma50', 'ihsg_rsi',
  'eido_ret5', 'spx_ret5', 'vix_level', 'usdidr_ret20', 'brent_ret20',
];

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false },
});
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

async function loadAll(sinceDays: number): Promise<Series[]> {
  const since = new Date(Date.now() - sinceDays * 86400000).toISOString().slice(0, 10);
  const { data, error } = await db.rpc('ml_price_json', { since });
  if (error) throw new Error(`ml_price_json: ${error.message}`);
  type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };
  return (data as Raw[]).map((s) => ({
    ticker: s.ticker,
    bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
  }));
}

function withMarket(rows: Row[], all: Series[]): { rows: Row[]; names: string[] } {
  const macro = new Set(MACRO);
  const { up } = buildMarketRows(all.filter((s) => macro.has(s.ticker)), MP);
  const idx = MKT_PICK.map((n) => (MARKET_FEATURES as readonly string[]).indexOf(n));
  const map = new Map(up.map((r) => [r.date, idx.map((j) => r.x[j])]));
  const out = rows.filter((r) => map.has(r.date)).map((r) => ({ ...r, x: [...r.x, ...map.get(r.date)!] }));
  return { rows: out, names: [...FEATURES, ...MKT_PICK] };
}

const COST = 0.004; // asumsi biaya pulang-pergi (beli ~0,15% + jual ~0,25%), belum termasuk slippage
const r4 = (v: number) => Math.round(v * 1e4) / 1e4;
const avg = (a: number[]) => (a.length ? a.reduce((s, v) => s + v, 0) / a.length : NaN);

/** Kalibrasi, sinyal selektif (ambang dari data latih), dan backtest top-k.
 *  Return sederhana, beli di harga buka besok. hold = jual penutupan hari ke-H;
 *  barrier = jual saat batas atas/bawah tersentuh (sesuai label), selain itu penutupan hari ke-H. */
function selective({ tr, te, p, pf }: { tr: Row[]; te: Row[]; p: number[]; pf: (x: number[]) => number }) {
  const step = Math.max(1, Math.floor(tr.length / 20000));
  const ptr: number[] = [];
  for (let i = 0; i < tr.length; i += step) ptr.push(pf(tr[i].x));
  ptr.sort((a, b) => a - b);
  const q = (x: number) => ptr[Math.min(ptr.length - 1, Math.floor(x * ptr.length))];
  const ok = te.map((r) => r.holdRet != null && r.tradeRet != null);
  const H = (i: number) => te[i].holdRet as number;
  const T = (i: number) => te[i].tradeRet as number;
  const stat = (idx: number[]) => ({
    n: idx.length,
    hitLabel: r4(avg(idx.map((i) => te[i].y as number))),
    holdWin: r4(avg(idx.map((i) => (H(i) > COST ? 1 : 0)))),
    holdNet: r4(avg(idx.map(H)) - COST),
    barWin: r4(avg(idx.map((i) => (T(i) > COST ? 1 : 0)))),
    barNet: r4(avg(idx.map(T)) - COST),
  });
  const all = te.map((_, i) => i).filter((i) => ok[i]);
  const thresholds: Record<string, unknown> = { all: stat(all) };
  // penyaring: baris dengan prediksi di bawah kuantil data latih (sinyal "hindari")
  const avoid: Record<string, unknown> = {};
  for (const lv of [0.1, 0.2, 0.3]) {
    const t = q(lv);
    const lo = all.filter((i) => p[i] < t);
    const hi = all.filter((i) => p[i] >= t);
    const big = (idx: number[]) => r4(avg(idx.map((i) => (H(i) < -0.1 ? 1 : 0))));
    avoid[`q${lv * 100}`] = {
      thr: r4(t),
      low: { ...stat(lo), bigLoss: big(lo) },
      rest: { ...stat(hi), bigLoss: big(hi) },
    };
  }
  for (const lv of [0.9, 0.95, 0.99]) {
    const t = q(lv);
    thresholds[`p${lv * 100}`] = { thr: r4(t), ...stat(all.filter((i) => p[i] >= t)) };
  }
  const ord = [...all].sort((a, b) => p[a] - p[b]);
  const calib = [];
  for (let d = 0; d < 10; d++) {
    const s = ord.slice(Math.floor((d * ord.length) / 10), Math.floor(((d + 1) * ord.length) / 10));
    calib.push([r4(avg(s.map((i) => p[i]))), r4(avg(s.map((i) => te[i].y as number)))]);
  }
  const byDate = new Map<string, number[]>();
  for (const i of all) (byDate.get(te[i].date) ?? byDate.set(te[i].date, []).get(te[i].date)!).push(i);
  const dates = [...byDate.keys()].sort();
  const bt: Record<string, unknown> = {};
  for (const k of [3, 5, 10]) {
    let eqH = 1, eqB = 1, eqAll = 1, beatH = 0, periods = 0;
    const tH: number[] = [];
    const tB: number[] = [];
    for (let j = 0; j < dates.length; j += PARAMS.horizon) {
      const ids = byDate.get(dates[j])!;
      if (ids.length < k * 2) continue;
      const pick = [...ids].sort((a, b) => p[b] - p[a]).slice(0, k);
      const rAll = avg(ids.map(H));
      const rh = pick.map((i) => H(i) - COST);
      const rb = pick.map((i) => T(i) - COST);
      tH.push(...rh);
      tB.push(...rb);
      eqAll *= 1 + rAll;
      eqH *= 1 + avg(rh);
      eqB *= 1 + avg(rb);
      if (avg(rh) > rAll) beatH++;
      periods++;
    }
    bt[`top${k}`] = {
      periods, beatEW: beatH,
      holdWin: r4(avg(tH.map((v) => (v > 0 ? 1 : 0)))), holdEq: r4(eqH),
      barWin: r4(avg(tB.map((v) => (v > 0 ? 1 : 0)))), barEq: r4(eqB),
      ewEq: r4(eqAll),
    };
  }
  // per periode: beli rata semua vs beli rata tanpa 20%/30% terbawah (peringkat pada hari itu)
  const filt: Record<string, unknown> = {};
  for (const cut of [0.2, 0.3]) {
    let eqAll = 1, eqKeep = 1, eqDrop = 1, beat = 0, periods = 0;
    for (let j = 0; j < dates.length; j += PARAMS.horizon) {
      const ids = byDate.get(dates[j])!;
      if (ids.length < 10) continue;
      const srt = [...ids].sort((a, b) => p[a] - p[b]);
      const nd = Math.floor(srt.length * cut);
      const rAll = avg(ids.map(H)) - COST;
      const rKeep = avg(srt.slice(nd).map(H)) - COST;
      const rDrop = avg(srt.slice(0, nd).map(H)) - COST;
      eqAll *= 1 + rAll;
      eqKeep *= 1 + rKeep;
      eqDrop *= 1 + rDrop;
      if (rKeep > rAll) beat++;
      periods++;
    }
    filt[`drop${cut * 100}`] = { periods, beat, eqAll: r4(eqAll), eqKeep: r4(eqKeep), eqDropped: r4(eqDrop) };
  }
  return { cost: COST, thresholds, avoid, filter: filt, calib, backtest: bt };
}

/** Target relatif: 1 jika return H hari mengalahkan median semua saham pada tanggal yang sama. */
function relabelRelative(rows: Row[]): Row[] {
  const byDate = new Map<string, number[]>();
  rows.forEach((r, i) => {
    if (r.fwdRet == null) return;
    (byDate.get(r.date) ?? byDate.set(r.date, []).get(r.date)!).push(i);
  });
  const y: (number | null)[] = rows.map(() => null);
  for (const ids of byDate.values()) {
    const v = ids.map((i) => rows[i].fwdRet as number).sort((a, b) => a - b);
    const med = v.length % 2 ? v[(v.length - 1) / 2] : (v[v.length / 2 - 1] + v[v.length / 2]) / 2;
    for (const i of ids) y[i] = (rows[i].fwdRet as number) > med ? 1 : 0;
  }
  return rows.map((r, i) => ({ ...r, y: y[i] }));
}

// deno-lint-ignore no-explicit-any
async function evaluate(body: Record<string, any>) {
  const t0 = Date.now();
  const all = await loadAll(365 * 6);
  const macro = new Set<string>(MACRO);
  const base = new Set(BASE_UNIVERSE);
  const stocks = all.filter((s) => !macro.has(s.ticker) && (body.universe === 'all' || base.has(s.ticker)));
  let rows = buildRows(stocks, PARAMS);
  if (body.target === 'rel') rows = relabelRelative(rows);
  let names: string[] = [...FEATURES];
  if (body.market) ({ rows, names } = withMarket(rows, all));
  const gp = { ...GBM_DEFAULT, ...(body.gbm ?? {}) };
  let importance: unknown = null;
  const fitter = body.model === 'gbm'
    ? (X: number[][], y: number[]) => {
      const m = fitGbm(X, y, names, gp);
      importance = gbmImportance(m);
      return (x: number[]) => predictGbm(m, x);
    }
    : body.rule
    ? () => {
      // aturan sederhana satu fitur (pembanding tanpa ML): skor = tanda * nilai fitur
      const j = names.indexOf(body.rule.feature);
      if (j < 0) throw new Error(`fitur tidak dikenal: ${body.rule.feature}`);
      const sg = body.rule.sign === -1 ? -1 : 1;
      return (x: number[]) => sg * x[j];
    }
    : body.stride
    ? (X: number[][], y: number[]) => {
      // latih pada sebagian baris (label 10 hari saling tumpang tindih, jadi informasinya sebagian besar tetap)
      const k = body.stride as number;
      const m = fitLogistic(X.filter((_, i) => i % k === 0), y.filter((_, i) => i % k === 0), LAMBDA, 4, 25, names);
      return (x: number[]) => predict(m, x);
    }
    : undefined;
  const res = walkForward(rows, PARAMS.horizon, FOLDS, LAMBDA, body.fold ?? 0, names, 'ret20', fitter, body.detail ? selective : undefined,
    body.testBase ? (r: Row) => base.has(r.ticker) : undefined);
  return {
    model: body.rule ? `rule:${body.rule.sign === -1 ? '-' : '+'}${body.rule.feature}` : body.model ?? 'logit',
    market: !!body.market,
    universe: body.universe ?? 'base',
    testBase: !!body.testBase,
    target: body.target ?? 'tb',
    tickers: stocks.length,
    nFeatures: names.length,
    ms: Date.now() - t0,
    importance,
    fold: res[0],
  };
}

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    if (body.mode === 'eval') return json(await evaluate(body));
    return json({ error: 'mode tidak dikenal' }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
