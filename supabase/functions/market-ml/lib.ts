// Inti ML saham: indikator, fitur, label triple-barrier, regresi logistik
// (IRLS + L2), validasi walk-forward dengan purge, dan prediksi + pendorong.
// Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.

export type Bar = {
  date: string; // YYYY-MM-DD (WIB)
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number; // lembar saham
};

export type Series = { ticker: string; bars: Bar[] };

type Num = number | null;

// ---------------------------------------------------------------- indikator
// Sama dengan /mnt/project-files/saham/hitung_indikator.py (cocok Stockbit).

export function rma(vals: Num[], len: number): Num[] {
  const out: Num[] = new Array(vals.length).fill(null);
  let s: number | null = null;
  const buf: number[] = [];
  vals.forEach((v, i) => {
    if (v === null) return;
    if (s === null) {
      buf.push(v);
      if (buf.length === len) {
        s = buf.reduce((a, b) => a + b, 0) / len;
        out[i] = s;
      }
    } else {
      s = (s * (len - 1) + v) / len;
      out[i] = s;
    }
  });
  return out;
}

export function ema(vals: Num[], len: number): Num[] {
  const out: Num[] = new Array(vals.length).fill(null);
  const a = 2 / (len + 1);
  let s: number | null = null;
  const buf: number[] = [];
  vals.forEach((v, i) => {
    if (v === null) return;
    if (s === null) {
      buf.push(v);
      if (buf.length === len) {
        s = buf.reduce((x, y) => x + y, 0) / len;
        out[i] = s;
      }
    } else {
      s = a * v + (1 - a) * s;
      out[i] = s;
    }
  });
  return out;
}

export function sma(vals: Num[], len: number): Num[] {
  const out: Num[] = new Array(vals.length).fill(null);
  for (let i = len - 1; i < vals.length; i++) {
    let sum = 0;
    let ok = true;
    for (let j = i - len + 1; j <= i; j++) {
      const v = vals[j];
      if (v === null) {
        ok = false;
        break;
      }
      sum += v;
    }
    if (ok) out[i] = sum / len;
  }
  return out;
}

function rollStd(vals: Num[], len: number): Num[] {
  const out: Num[] = new Array(vals.length).fill(null);
  for (let i = len - 1; i < vals.length; i++) {
    let s = 0;
    let s2 = 0;
    let ok = true;
    for (let j = i - len + 1; j <= i; j++) {
      const v = vals[j];
      if (v === null) {
        ok = false;
        break;
      }
      s += v;
      s2 += v * v;
    }
    if (!ok) continue;
    const m = s / len;
    out[i] = Math.sqrt(Math.max(0, (s2 - len * m * m) / (len - 1)));
  }
  return out;
}

function rollExt(vals: number[], len: number, max: boolean): Num[] {
  const out: Num[] = new Array(vals.length).fill(null);
  for (let i = len - 1; i < vals.length; i++) {
    let e = vals[i];
    for (let j = i - len + 1; j < i; j++) e = max ? Math.max(e, vals[j]) : Math.min(e, vals[j]);
    out[i] = e;
  }
  return out;
}

const rollMax = (v: number[], len: number) => rollExt(v, len, true);
const rollMin = (v: number[], len: number) => rollExt(v, len, false);

export type Indicators = {
  rsi: Num[];
  stochK: Num[];
  stochD: Num[];
  macd: Num[];
  signal: Num[];
  hist: Num[];
  volMa20Lot: Num[];
  sma20: Num[];
  sma50: Num[];
  atr14: Num[];
  vol20: Num[]; // simpangan baku log return harian 20 hari
};

export function indicators(bars: Bar[]): Indicators {
  const c = bars.map((b) => b.close);
  const n = c.length;
  const ch: Num[] = c.map((v, i) => (i === 0 ? null : v - c[i - 1]));
  const g = rma(ch.map((x) => (x === null ? null : Math.max(x, 0))), 14);
  const l = rma(ch.map((x) => (x === null ? null : Math.max(-x, 0))), 14);
  const rsi: Num[] = c.map((_, i) => {
    const gi = g[i];
    const li = l[i];
    if (gi === null || li === null) return null;
    return li === 0 ? 100 : 100 - 100 / (1 + gi / li);
  });
  const st: Num[] = new Array(n).fill(null);
  for (let i = 13; i < n; i++) {
    const w = rsi.slice(i - 13, i + 1);
    if (w.some((x) => x === null)) continue;
    const lo = Math.min(...(w as number[]));
    const hi = Math.max(...(w as number[]));
    st[i] = hi === lo ? 0 : (((rsi[i] as number) - lo) / (hi - lo)) * 100;
  }
  const stochK = sma(st, 3);
  const stochD = sma(stochK, 3);
  const e12 = ema(c, 12);
  const e26 = ema(c, 26);
  const macd: Num[] = c.map((_, i) => (e26[i] === null ? null : (e12[i] as number) - (e26[i] as number)));
  const signal = ema(macd, 9);
  const hist: Num[] = macd.map((m, i) => (m === null || signal[i] === null ? null : m - (signal[i] as number)));
  const volMa20Lot = sma(bars.map((b) => b.volume / 100), 20);
  const tr: Num[] = bars.map((b, i) =>
    i === 0
      ? null
      : Math.max(b.high - b.low, Math.abs(b.high - bars[i - 1].close), Math.abs(b.low - bars[i - 1].close)),
  );
  const atr14 = rma(tr, 14);
  const lr: Num[] = c.map((v, i) => (i === 0 ? null : Math.log(v / c[i - 1])));
  return {
    rsi,
    stochK,
    stochD,
    macd,
    signal,
    hist,
    volMa20Lot,
    sma20: sma(c, 20),
    sma50: sma(c, 50),
    atr14,
    vol20: rollStd(lr, 20),
  };
}

// ---------------------------------------------------------------- fitur

export const FEATURES = [
  'ret1',
  'ret5',
  'ret10',
  'ret20',
  'ret60',
  'vol20',
  'volRatio5_20',
  'volumeRatio',
  'rsi',
  'stochK',
  'stochKminusD',
  'macdHistPct',
  'macdPct',
  'distSma20',
  'distSma50',
  'sma20vs50',
  'atrPct',
  'rangePos20',
  'gap',
  'dayRange',
  // relatif terhadap pasar (lintas saham pada hari yang sama)
  'xsRankRet5',
  'xsRankRet20',
  'xsRankVolumeRatio',
  'excessRet5',
] as const;

export type Row = {
  ticker: string;
  date: string;
  x: number[]; // urutan sesuai FEATURES
  y: number | null; // 1 = target naik tersentuh lebih dulu, 0 = tidak
  fwdRet: number | null; // return close ke close H hari ke depan
  upperPct: number;
  lowerPct: number;
  close: number;
  valueIdr20: number; // rata-rata nilai transaksi 20 hari (likuiditas)
};

export type LabelParams = { horizon: number; k: number };

/** Fitur per saham (tanpa fitur lintas saham), label triple-barrier. */
function rowsForSeries(s: Series, p: LabelParams): (Row & { raw: Record<string, number> })[] {
  const b = s.bars;
  const ind = indicators(b);
  const c = b.map((x) => x.close);
  const vol = b.map((x) => x.volume);
  const volSma5 = sma(vol, 5);
  const volSma20 = sma(vol, 20);
  const hi20 = rollMax(b.map((x) => x.high), 20);
  const lo20 = rollMin(b.map((x) => x.low), 20);
  const vol5 = rollStd(c.map((v, i) => (i === 0 ? null : Math.log(v / c[i - 1]))), 5);
  const value20 = sma(b.map((x) => x.close * x.volume), 20);
  const out: (Row & { raw: Record<string, number> })[] = [];
  const H = p.horizon;
  for (let i = 60; i < b.length; i++) {
    const need = [ind.stochD[i], ind.hist[i], ind.sma50[i], ind.atr14[i], ind.vol20[i], volSma20[i], vol5[i], hi20[i], lo20[i], value20[i]];
    if (need.some((v) => v === null || !Number.isFinite(v as number))) continue;
    const sigma = ind.vol20[i] as number;
    if (sigma <= 0 || volSma20[i] === 0) continue;
    const r = (k: number) => Math.log(c[i] / c[i - k]);
    const range = (hi20[i] as number) - (lo20[i] as number);
    const raw: Record<string, number> = {
      ret1: r(1),
      ret5: r(5),
      ret10: r(10),
      ret20: r(20),
      ret60: r(60),
      vol20: sigma,
      volRatio5_20: (vol5[i] as number) / sigma,
      volumeRatio: Math.log((vol[i] + 1) / ((volSma20[i] as number) + 1)),
      rsi: (ind.rsi[i] as number) / 100,
      stochK: (ind.stochK[i] as number) / 100,
      stochKminusD: ((ind.stochK[i] as number) - (ind.stochD[i] as number)) / 100,
      macdHistPct: (ind.hist[i] as number) / c[i],
      macdPct: (ind.macd[i] as number) / c[i],
      distSma20: c[i] / (ind.sma20[i] as number) - 1,
      distSma50: c[i] / (ind.sma50[i] as number) - 1,
      sma20vs50: (ind.sma20[i] as number) / (ind.sma50[i] as number) - 1,
      atrPct: (ind.atr14[i] as number) / c[i],
      rangePos20: range > 0 ? (c[i] - (lo20[i] as number)) / range : 0.5,
      gap: b[i].open / c[i - 1] - 1,
      dayRange: (b[i].high - b[i].low) / c[i],
    };
    // Batas mengikuti volatilitas: k * sigma harian * akar(H).
    const width = p.k * sigma * Math.sqrt(H);
    const upper = c[i] * Math.exp(width);
    const lower = c[i] * Math.exp(-width);
    let y: number | null = null;
    let fwd: number | null = null;
    if (i + H < b.length) {
      y = 0;
      for (let j = i + 1; j <= i + H; j++) {
        const hitUp = b[j].high >= upper;
        const hitDown = b[j].low <= lower;
        if (hitDown) break; // turun dulu, atau keduanya di hari yang sama: konservatif
        if (hitUp) {
          y = 1;
          break;
        }
      }
      fwd = Math.log(c[i + H] / c[i]);
    }
    out.push({
      ticker: s.ticker,
      date: b[i].date,
      x: [],
      y,
      fwdRet: fwd,
      upperPct: Math.exp(width) - 1,
      lowerPct: Math.exp(-width) - 1,
      close: c[i],
      valueIdr20: value20[i] as number,
      raw,
    });
  }
  return out;
}

function pctRank(values: number[]): number[] {
  const idx = values.map((v, i) => [v, i] as const).sort((a, b) => a[0] - b[0]);
  const out = new Array(values.length).fill(0.5);
  if (values.length < 2) return out;
  idx.forEach(([, i], r) => (out[i] = r / (values.length - 1)));
  return out;
}

/** Dataset lengkap: fitur per saham + fitur lintas saham per tanggal. */
export function buildRows(all: Series[], p: LabelParams): Row[] {
  const rows = all.flatMap((s) => rowsForSeries(s, p));
  const byDate = new Map<string, typeof rows>();
  for (const r of rows) {
    const list = byDate.get(r.date) ?? [];
    list.push(r);
    byDate.set(r.date, list);
  }
  for (const list of byDate.values()) {
    const r5 = pctRank(list.map((r) => r.raw.ret5));
    const r20 = pctRank(list.map((r) => r.raw.ret20));
    const rv = pctRank(list.map((r) => r.raw.volumeRatio));
    const med5 = median(list.map((r) => r.raw.ret5));
    list.forEach((r, i) => {
      r.raw.xsRankRet5 = r5[i];
      r.raw.xsRankRet20 = r20[i];
      r.raw.xsRankVolumeRatio = rv[i];
      r.raw.excessRet5 = r.raw.ret5 - med5;
    });
  }
  // Tanggal dengan terlalu sedikit saham membuat peringkat tidak bermakna.
  const usable = rows.filter((r) => (byDate.get(r.date)?.length ?? 0) >= 5);
  for (const r of usable) r.x = FEATURES.map((f) => r.raw[f]);
  return usable.map(({ raw: _raw, ...rest }) => rest).sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0));
}

function median(v: number[]): number {
  const s = [...v].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

// ---------------------------------------------------------------- model

export type Model = {
  features: string[];
  mean: number[];
  std: number[];
  coef: number[]; // terstandardisasi
  intercept: number;
  lambda: number;
  clip: number;
};

const sigmoid = (z: number) => 1 / (1 + Math.exp(-Math.max(-30, Math.min(30, z))));

function standardize(X: number[][], clip: number) {
  const d = X[0].length;
  const mean = new Array(d).fill(0);
  const std = new Array(d).fill(0);
  for (const x of X) for (let j = 0; j < d; j++) mean[j] += x[j];
  for (let j = 0; j < d; j++) mean[j] /= X.length;
  for (const x of X) for (let j = 0; j < d; j++) std[j] += (x[j] - mean[j]) ** 2;
  for (let j = 0; j < d; j++) std[j] = Math.sqrt(std[j] / X.length) || 1;
  return { mean, std, clip };
}

function z(x: number[], m: { mean: number[]; std: number[]; clip: number }): number[] {
  return x.map((v, j) => Math.max(-m.clip, Math.min(m.clip, (v - m.mean[j]) / m.std[j])));
}

/** Selesaikan A w = b (eliminasi Gauss dengan pivot). */
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

/** Regresi logistik L2 dengan IRLS (Newton). Intercept tidak dipenalti. */
export function fitLogistic(
  X: number[][],
  y: number[],
  lambda = 1,
  clip = 4,
  iters = 25,
  names: readonly string[] = FEATURES,
): Model {
  const st = standardize(X, clip);
  const Z = X.map((x) => [1, ...z(x, st)]);
  const d = Z[0].length;
  let w = new Array(d).fill(0);
  const prior = y.reduce((a, b) => a + b, 0) / y.length;
  w[0] = Math.log(prior / (1 - prior));
  for (let it = 0; it < iters; it++) {
    const H = Array.from({ length: d }, () => new Array(d).fill(0));
    const g = new Array(d).fill(0);
    for (let i = 0; i < Z.length; i++) {
      const zi = Z[i];
      let s = 0;
      for (let j = 0; j < d; j++) s += w[j] * zi[j];
      const p = sigmoid(s);
      const r = y[i] - p;
      const wt = Math.max(p * (1 - p), 1e-6);
      for (let j = 0; j < d; j++) {
        g[j] += r * zi[j];
        const a = wt * zi[j];
        for (let k = j; k < d; k++) H[j][k] += a * zi[k];
      }
    }
    for (let j = 0; j < d; j++) for (let k = 0; k < j; k++) H[j][k] = H[k][j];
    for (let j = 1; j < d; j++) {
      H[j][j] += lambda;
      g[j] -= lambda * w[j];
    }
    const step = solve(H, g);
    w = w.map((v, j) => v + step[j]);
    if (Math.max(...step.map(Math.abs)) < 1e-6) break;
  }
  return { features: [...names], mean: st.mean, std: st.std, coef: w.slice(1), intercept: w[0], lambda, clip };
}

export function predict(m: Model, x: number[]): number {
  const zz = z(x, m);
  let s = m.intercept;
  for (let j = 0; j < zz.length; j++) s += m.coef[j] * zz[j];
  return sigmoid(s);
}

/** Kontribusi tiap fitur terhadap log-odds, terbesar dulu. */
export function drivers(m: Model, x: number[], top = 4) {
  const zz = z(x, m);
  return m.features
    .map((f, j) => ({ feature: f, value: x[j], contribution: m.coef[j] * zz[j] }))
    .sort((a, b) => Math.abs(b.contribution) - Math.abs(a.contribution))
    .slice(0, top)
    .map((d) => ({ ...d, value: round(d.value, 4), contribution: round(d.contribution, 3) }));
}

export const round = (v: number, d = 4) => Math.round(v * 10 ** d) / 10 ** d;

// ---------------------------------------------------------------- evaluasi

export function auc(p: number[], y: number[]): number {
  const pairs = p.map((v, i) => [v, y[i]] as const).sort((a, b) => a[0] - b[0]);
  let rankSum = 0;
  let pos = 0;
  let i = 0;
  while (i < pairs.length) {
    let j = i;
    while (j + 1 < pairs.length && pairs[j + 1][0] === pairs[i][0]) j++;
    const avg = (i + j) / 2 + 1;
    for (let k = i; k <= j; k++) if (pairs[k][1] === 1) {
      rankSum += avg;
      pos++;
    }
    i = j + 1;
  }
  const neg = pairs.length - pos;
  if (pos === 0 || neg === 0) return NaN;
  return (rankSum - (pos * (pos + 1)) / 2) / (pos * neg);
}

const logloss = (p: number[], y: number[]) =>
  -p.reduce((a, v, i) => a + (y[i] ? Math.log(Math.max(v, 1e-9)) : Math.log(Math.max(1 - v, 1e-9))), 0) / p.length;

const brier = (p: number[], y: number[]) => p.reduce((a, v, i) => a + (v - y[i]) ** 2, 0) / p.length;

export type FoldResult = {
  trainEnd: string;
  testStart: string;
  testEnd: string;
  nTrain: number;
  nTest: number;
  baseRate: number;
  auc: number;
  auc_momentum: number;
  logloss: number;
  logloss_base: number;
  brier: number;
  brier_base: number;
  hitTop20: number;
  hitAll: number;
  fwdRetTop20: number;
  fwdRetAll: number;
};

/**
 * Walk-forward: latih pada data sebelum `testStart` dikurangi purge
 * (H hari bursa), uji pada blok berikutnya. Tidak ada data masa depan bocor.
 */
export function walkForward(
  rows: Row[],
  horizon: number,
  folds = 5,
  lambda = 1,
  only?: number,
  names: readonly string[] = FEATURES,
  momName = 'ret20',
): FoldResult[] {
  const labeled = rows.filter((r) => r.y !== null);
  const dates = [...new Set(labeled.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / folds);
  const res: FoldResult[] = [];
  for (let f = 0; f < folds; f++) {
    if (only !== undefined && f !== only) continue;
    const testStartIdx = minTrain + f * block;
    const testEndIdx = f === folds - 1 ? dates.length - 1 : testStartIdx + block - 1;
    const trainEndIdx = testStartIdx - horizon - 1; // purge
    const trainEnd = dates[trainEndIdx];
    const testStart = dates[testStartIdx];
    const testEnd = dates[testEndIdx];
    const tr = labeled.filter((r) => r.date <= trainEnd);
    const te = labeled.filter((r) => r.date >= testStart && r.date <= testEnd);
    const m = fitLogistic(tr.map((r) => r.x), tr.map((r) => r.y as number), lambda, 4, 25, names);
    const p = te.map((r) => predict(m, r.x));
    const y = te.map((r) => r.y as number);
    const base = tr.reduce((a, r) => a + (r.y as number), 0) / tr.length;
    const mom = te.map((r) => r.x[names.indexOf(momName)]);
    const order = p.map((v, i) => [v, i] as const).sort((a, b) => b[0] - a[0]);
    const top = order.slice(0, Math.max(1, Math.floor(order.length * 0.2))).map(([, i]) => i);
    const mean = (a: number[]) => a.reduce((s, v) => s + v, 0) / a.length;
    res.push({
      trainEnd,
      testStart,
      testEnd,
      nTrain: tr.length,
      nTest: te.length,
      baseRate: round(base),
      auc: round(auc(p, y)),
      auc_momentum: round(auc(mom, y)),
      logloss: round(logloss(p, y)),
      logloss_base: round(logloss(p.map(() => base), y)),
      brier: round(brier(p, y)),
      brier_base: round(brier(p.map(() => base), y)),
      hitTop20: round(mean(top.map((i) => y[i]))),
      hitAll: round(mean(y)),
      fwdRetTop20: round(mean(top.map((i) => te[i].fwdRet as number))),
      fwdRetAll: round(mean(te.map((r) => r.fwdRet as number))),
    });
  }
  return res;
}

/** Label sinyal dengan zona tidak yakin di sekitar base rate. */
export function signalOf(prob: number, base: number, band = 0.05): 'peluang' | 'netral' | 'risiko' {
  if (prob >= base + band) return 'peluang';
  if (prob <= base - band) return 'risiko';
  return 'netral';
}
