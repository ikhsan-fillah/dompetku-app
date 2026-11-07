// Uji lab "rencana level": apakah model bisa memilih harga beli, CL, dan TP yang lebih baik
// daripada aturan tetap? Read-only, hanya memakai price_history. Tanpa data broker.
// Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.
//
// Satu rencana = limit beli di C - a*ATR (a=0: beli harga buka besok), berlaku WAIT hari bursa;
// setelah terisi: CL = harga beli - c*ATR, TP = harga beli + r*ATR, keluar paling lambat HOLD hari
// bursa sesudah hari terisi. Hasil dihitung setelah biaya COST. Konservatif:
//  - hari CL dan TP tersentuh bersamaan: dianggap CL dulu;
//  - hari terisi oleh limit di tengah hari: hanya CL yang dicek (urutan high/low tidak diketahui);
//  - gap melewati CL atau TP: keluar di harga buka hari itu.
// Belum dimodelkan: fraksi harga BEI, batas auto rejection, slippage, antrean order.
import { FEATURES, buildRows, projectX, round, TA_FEATURES } from './lib.ts';
import type { Bar, Series } from './lib.ts';

export const COST = 0.004;
export const HOLD = 10;
export const WAIT = 3;
export const FOLDS = 5;
export const LAMBDA = 50;
/** Hari bursa terakhir yang dibutuhkan sesudah hari sinyal supaya semua rencana punya hasil penuh. */
export const NEED = WAIT + HOLD;

export const ENTRY_A = [0, 0.5, 1];
export const CL_C = [1, 1.5, 2];
export const TP_R = [1.5, 2, 3];
export type Config = { a: number; c: number; r: number };
export const CONFIGS: Config[] = ENTRY_A.flatMap((a) => CL_C.flatMap((c) => TP_R.map((r) => ({ a, c, r }))));
export const configName = (k: Config) => `a${k.a}_cl${k.c}_tp${k.r}`;

/** 0 = limit tidak terisi, 1 = TP, 2 = CL, 3 = keluar karena waktu habis. */
export type Code = 0 | 1 | 2 | 3;
export type Sim = { code: Code; ret: number };

/**
 * Simulasikan satu rencana. `limit` null = beli harga buka besok. `levels(entry)` memberi CL dan TP mutlak.
 * Null bila data sesudah hari sinyal belum cukup (i + NEED harus ada).
 */
export function simulate(
  bars: Bar[],
  i: number,
  limit: number | null,
  levels: (entry: number) => { cl: number; tp: number },
): Sim | null {
  if (i + NEED >= bars.length) return null;
  let fillDay = -1;
  let entry = 0;
  let atOpen = true;
  if (limit === null) {
    fillDay = i + 1;
    entry = bars[i + 1].open;
  } else {
    for (let j = i + 1; j <= i + WAIT; j++) {
      if (bars[j].open <= limit) {
        fillDay = j;
        entry = bars[j].open;
        break;
      }
      if (bars[j].low <= limit) {
        fillDay = j;
        entry = limit;
        atOpen = false;
        break;
      }
    }
  }
  if (fillDay < 0 || entry <= 0) return { code: 0, ret: 0 };
  const { cl, tp } = levels(entry);
  const net = (exit: number) => exit / entry - 1 - COST;
  for (let d = fillDay; d <= fillDay + HOLD; d++) {
    const b = bars[d];
    const first = d === fillDay;
    if (!first && b.open <= cl) return { code: 2, ret: net(b.open) };
    if (b.low <= cl) return { code: 2, ret: net(cl) };
    if (first && !atOpen) continue; // urutan high/low di hari terisi tidak diketahui
    if (b.high >= tp) return { code: 1, ret: net(!first && b.open >= tp ? b.open : tp) };
  }
  return { code: 3, ret: net(bars[fillDay + HOLD].close) };
}

// ---------------------------------------------------------------- support / resistance

const PIV = 3;
const SR_LOOKBACK = 60;

export type Pivots = { low: boolean[]; high: boolean[] };

/** Pivot: titik terendah/tertinggi dibanding PIV bar di kiri dan kanan. Baru terkonfirmasi PIV bar kemudian. */
export function pivots(bars: Bar[]): Pivots {
  const low = new Array(bars.length).fill(false);
  const high = new Array(bars.length).fill(false);
  for (let p = PIV; p < bars.length - PIV; p++) {
    let isLow = true;
    let isHigh = true;
    for (let k = p - PIV; k <= p + PIV; k++) {
      if (k === p) continue;
      if (bars[k].low < bars[p].low) isLow = false;
      if (bars[k].high > bars[p].high) isHigh = false;
    }
    low[p] = isLow;
    high[p] = isHigh;
  }
  return { low, high };
}

/** Support terdekat di bawah dan resistance terdekat di atas penutupan hari i, dari pivot yang sudah terkonfirmasi. */
export function nearestSR(bars: Bar[], pv: Pivots, i: number): { sup: number | null; res: number | null } {
  const close = bars[i].close;
  let sup: number | null = null;
  let res: number | null = null;
  for (let p = i - PIV; p >= Math.max(PIV, i - SR_LOOKBACK); p--) {
    if (pv.low[p] && bars[p].low < close && (sup === null || bars[p].low > sup)) sup = bars[p].low;
    if (pv.high[p] && bars[p].high > close && (res === null || bars[p].high < res)) res = bars[p].high;
  }
  return { sup, res };
}

// ---------------------------------------------------------------- baris data

export const LEVEL_FEATURES = [...TA_FEATURES, 'atrPct', 'dSup', 'dRes'] as const;
const ATR_IDX = (FEATURES as readonly string[]).indexOf('atrPct');
const SR_CAP = 6;

export type LevelRow = {
  ticker: string;
  date: string;
  i: number;
  bars: Bar[];
  close: number;
  atr: number;
  sup: number | null;
  res: number | null;
  x: number[]; // LEVEL_FEATURES
  /** Hasil 27 rencana ATR, disimpan sebagai array bertipe supaya hemat memori. */
  simRet?: Float64Array;
  simCode?: Uint8Array;
};

export function buildLevelRows(series: Series[]): LevelRow[] {
  const base = buildRows(series, { horizon: HOLD, k: 1 });
  const byTicker = new Map(series.map((s) => [s.ticker, { s, idx: new Map(s.bars.map((b, i) => [b.date, i])), pv: pivots(s.bars) }]));
  const out: LevelRow[] = [];
  for (const r of base) {
    const t = byTicker.get(r.ticker)!;
    const i = t.idx.get(r.date)!;
    if (i + NEED >= t.s.bars.length) continue;
    const atr = r.x[ATR_IDX] * r.close;
    if (!(atr > 0)) continue;
    const { sup, res } = nearestSR(t.s.bars, t.pv, i);
    const dSup = sup === null ? SR_CAP : Math.min(SR_CAP, (r.close - sup) / atr);
    const dRes = res === null ? SR_CAP : Math.min(SR_CAP, (res - r.close) / atr);
    out.push({
      ticker: r.ticker,
      date: r.date,
      i,
      bars: t.s.bars,
      close: r.close,
      atr,
      sup,
      res,
      x: [...projectX(r.x, TA_FEATURES), r.x[ATR_IDX], dSup, dRes],
    });
  }
  return out;
}

/** Hitung sekali hasil 27 rencana ATR untuk satu baris. */
function ensureSims(row: LevelRow): void {
  if (row.simRet) return;
  row.simRet = new Float64Array(CONFIGS.length);
  row.simCode = new Uint8Array(CONFIGS.length);
  CONFIGS.forEach((k, j) => {
    const limit = k.a === 0 ? null : row.close - k.a * row.atr;
    if (limit !== null && limit <= 0) return;
    const s = simulate(row.bars, row.i, limit, (e) => ({ cl: e - k.c * row.atr, tp: e + k.r * row.atr })) as Sim;
    row.simRet![j] = s.ret;
    row.simCode![j] = s.code;
  });
}

/** Hasil rencana ke-k (indeks CONFIGS) untuk satu baris. */
export function simAt(row: LevelRow, k: number): Sim {
  ensureSims(row);
  return { code: row.simCode![k] as Code, ret: row.simRet![k] };
}

/** Pembanding tanpa level: beli harga buka besok, jual penutupan hari ke-HOLD (sama dengan uji maju produksi). */
export function holdSim(row: LevelRow): Sim {
  const entry = row.bars[row.i + 1].open;
  return { code: 3, ret: row.bars[row.i + HOLD].close / entry - 1 - COST };
}

/**
 * Aturan support/resistance: limit beli di support terdekat (bila dalam 3 ATR di bawah penutupan),
 * CL 0,5 ATR di bawah support, TP di resistance terdekat (bila minimal 1 ATR di atas support).
 * Null bila rencana tidak bisa dibuat.
 */
export function srSim(row: LevelRow): Sim | null {
  const { sup, res, close, atr } = row;
  if (sup === null || res === null) return null;
  if (close - sup > 3 * atr || res - sup < atr) return null;
  return simulate(row.bars, row.i, sup, (e) => ({ cl: e - 0.5 * atr, tp: res }));
}

// ---------------------------------------------------------------- ringkasan

const mean = (a: number[]) => (a.length ? a.reduce((s, v) => s + v, 0) / a.length : NaN);

export type Stats = {
  signals: number;
  fillRate: number;
  tpShare: number;
  clShare: number;
  timeoutShare: number;
  meanPerSignal: number;
  meanPerFilled: number;
  winRate: number;
  avgWin: number;
  avgLoss: number;
  profitFactor: number;
  /** t-statistik rata-rata per sinyal setelah dirata-ratakan per tanggal (kasar: abaikan autokorelasi). */
  t: number;
};

export function stats(sims: Sim[], dates: string[]): Stats {
  const filled = sims.filter((s) => s.code !== 0);
  const wins = filled.filter((s) => s.ret > 0);
  const losses = filled.filter((s) => s.ret <= 0);
  const gw = wins.reduce((a, s) => a + s.ret, 0);
  const gl = -losses.reduce((a, s) => a + s.ret, 0);
  const byDate = new Map<string, number[]>();
  sims.forEach((s, i) => {
    const l = byDate.get(dates[i]) ?? [];
    l.push(s.ret);
    byDate.set(dates[i], l);
  });
  const dm = [...byDate.values()].map(mean);
  const m = mean(dm);
  const sd = Math.sqrt(mean(dm.map((v) => (v - m) ** 2)));
  const share = (c: Code) => (filled.length ? filled.filter((s) => s.code === c).length / filled.length : NaN);
  return {
    signals: sims.length,
    fillRate: round(filled.length / Math.max(1, sims.length)),
    tpShare: round(share(1)),
    clShare: round(share(2)),
    timeoutShare: round(share(3)),
    meanPerSignal: round(mean(sims.map((s) => s.ret)), 5),
    meanPerFilled: round(mean(filled.map((s) => s.ret)), 5),
    winRate: round(filled.length ? wins.length / filled.length : NaN),
    avgWin: round(mean(wins.map((s) => s.ret)), 4),
    avgLoss: round(mean(losses.map((s) => s.ret)), 4),
    profitFactor: round(gl > 0 ? gw / gl : NaN, 3),
    t: round(sd > 0 ? m / (sd / Math.sqrt(dm.length)) : NaN, 2),
  };
}

// ---------------------------------------------------------------- regresi ridge (satu X, banyak y)

function solve(A: number[][], b: number[]): number[] {
  const n = b.length;
  const M = A.map((row, i) => [...row, b[i]]);
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let r = c + 1; r < n; r++) if (Math.abs(M[r][c]) > Math.abs(M[p][c])) p = r;
    [M[c], M[p]] = [M[p], M[c]];
    const piv = M[c][c] || 1e-12;
    for (let r = 0; r < n; r++) {
      if (r === c) continue;
      const f = M[r][c] / piv;
      if (f === 0) continue;
      for (let k = c; k <= n; k++) M[r][k] -= f * M[c][k];
    }
  }
  return M.map((row, i) => row[n] / (row[i] || 1e-12));
}

export type RidgeSet = { mean: number[]; std: number[]; W: number[][] }; // W[k] = [intercept, ...koef]

/** Latih satu regresi ridge untuk tiap kolom target Y[k] dengan matriks fitur yang sama. */
export function fitRidgeMany(X: number[][], Y: number[][], lambda: number, clip = 4): RidgeSet {
  const d = X[0].length;
  const mu = new Array(d).fill(0);
  const sd = new Array(d).fill(0);
  for (const x of X) for (let j = 0; j < d; j++) mu[j] += x[j];
  for (let j = 0; j < d; j++) mu[j] /= X.length;
  for (const x of X) for (let j = 0; j < d; j++) sd[j] += (x[j] - mu[j]) ** 2;
  for (let j = 0; j < d; j++) sd[j] = Math.sqrt(sd[j] / X.length) || 1;
  const Z = X.map((x) => [1, ...x.map((v, j) => Math.max(-clip, Math.min(clip, (v - mu[j]) / sd[j])))]);
  const D = d + 1;
  const A = Array.from({ length: D }, () => new Array(D).fill(0));
  for (const z of Z) for (let j = 0; j < D; j++) for (let k = j; k < D; k++) A[j][k] += z[j] * z[k];
  for (let j = 0; j < D; j++) for (let k = 0; k < j; k++) A[j][k] = A[k][j];
  for (let j = 1; j < D; j++) A[j][j] += lambda;
  const W = Y.map((y) => {
    const g = new Array(D).fill(0);
    for (let i = 0; i < Z.length; i++) for (let j = 0; j < D; j++) g[j] += Z[i][j] * y[i];
    return solve(A, g);
  });
  return { mean: mu, std: sd, W };
}

export function predictMany(m: RidgeSet, x: number[], clip = 4): number[] {
  const z = x.map((v, j) => Math.max(-clip, Math.min(clip, (v - m.mean[j]) / m.std[j])));
  return m.W.map((w) => w[0] + z.reduce((a, v, j) => a + v * w[j + 1], 0));
}

// ---------------------------------------------------------------- evaluasi walk-forward

export type LevelFold = {
  fold: number;
  testStart: string;
  testEnd: string;
  nTrain: number;
  nTest: number;
  strategies: Record<string, Stats>;
  /** Porsi hari uji di mana aturan support/resistance bisa membuat rencana (ada support dekat dan resistance cukup jauh). */
  srPlanRate: number;
  /** Rata-rata hasil per sinyal tiap rencana tetap pada data uji, urutan CONFIGS. */
  fixedMean: number[];
  fixedFill: number[];
  bestFixedTrain: string;
  /** Rencana yang paling sering dipilih model pada data uji. */
  topChoices: { plan: string; share: number }[];
  /** Koefisien model (terstandardisasi) untuk rencana terbaik hasil pilihan paling sering. */
  coefTop: Record<string, number>;
};

export function evalLevels(series: Series[], only?: number): LevelFold[] {
  const rows = buildLevelRows(series);
  const dates = [...new Set(rows.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / FOLDS);
  const out: LevelFold[] = [];
  for (let f = 0; f < FOLDS; f++) {
    if (only !== undefined && f !== only) continue;
    const startIdx = minTrain + f * block;
    const endIdx = f === FOLDS - 1 ? dates.length - 1 : startIdx + block - 1;
    const trainEnd = dates[startIdx - NEED - 1];
    const testStart = dates[startIdx];
    const testEnd = dates[endIdx];
    const tr = rows.filter((r) => r.date <= trainEnd);
    const te = rows.filter((r) => r.date >= testStart && r.date <= testEnd);
    const Ytr = CONFIGS.map((_, k) => tr.map((r) => simAt(r, k).ret));
    const model = fitRidgeMany(tr.map((r) => r.x), Ytr, LAMBDA);
    const trMean = Ytr.map(mean);
    const bestK = trMean.indexOf(Math.max(...trMean));
    const trBestEv = tr.map((r) => Math.max(...predictMany(model, r.x)));
    const sorted = [...trBestEv].sort((a, b) => a - b);
    const thr20 = sorted[Math.floor(sorted.length * 0.8)];
    const teDates = te.map((r) => r.date);
    const chosen = te.map((r) => {
      const ev = predictMany(model, r.x);
      const k = ev.indexOf(Math.max(...ev));
      return { k, ev: ev[k] };
    });
    const strat: Record<string, Stats> = {};
    strat.beliBukaBesokJual10Hari = stats(te.map(holdSim), teDates);
    strat.rencanaTetapTerbaikDiLatih = stats(te.map((r) => simAt(r, bestK)), teDates);
    strat.rataRata27Rencana = stats(te.flatMap((r) => CONFIGS.map((_, k) => simAt(r, k))), te.flatMap((r) => CONFIGS.map(() => r.date)));
    strat.modelPilihRencana = stats(te.map((r, i) => simAt(r, chosen[i].k)), teDates);
    const pos = te.map((r, i) => ({ r, i })).filter(({ i }) => chosen[i].ev > 0);
    strat.modelHanyaBilaEvPositif = stats(pos.map(({ r, i }) => simAt(r, chosen[i].k)), pos.map(({ r }) => r.date));
    const top = te.map((r, i) => ({ r, i })).filter(({ i }) => chosen[i].ev >= thr20);
    strat.modelEvTeratas20persen = stats(top.map(({ r, i }) => simAt(r, chosen[i].k)), top.map(({ r }) => r.date));
    const srRows = te.map((r) => ({ r, s: srSim(r) })).filter((v): v is { r: LevelRow; s: Sim } => v.s !== null);
    strat.aturanSupportResistance = stats(srRows.map((v) => v.s), srRows.map((v) => v.r.date));
    const planRate = srRows.length / Math.max(1, te.length);
    const counts = new Map<number, number>();
    chosen.forEach((c) => counts.set(c.k, (counts.get(c.k) ?? 0) + 1));
    const topChoices = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([k, n]) => ({ plan: configName(CONFIGS[k]), share: round(n / te.length, 3) }));
    const kTop = [...counts.entries()].sort((a, b) => b[1] - a[1])[0][0];
    const coefTop: Record<string, number> = {};
    LEVEL_FEATURES.forEach((name, j) => (coefTop[name] = round(model.W[kTop][j + 1], 5)));
    out.push({
      fold: f,
      testStart,
      testEnd,
      nTrain: tr.length,
      nTest: te.length,
      strategies: strat,
      srPlanRate: round(planRate),
      fixedMean: CONFIGS.map((_, k) => round(mean(te.map((r) => simAt(r, k).ret)), 5)),
      fixedFill: CONFIGS.map((_, k) => round(mean(te.map((r) => (simAt(r, k).code === 0 ? 0 : 1))), 3)),
      bestFixedTrain: configName(CONFIGS[bestK]),
      topChoices,
      coefTop,
    });
  }
  return out;
}
