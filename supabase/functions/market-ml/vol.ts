// Uji lab: bisakah model memprediksi BESAR gerak harga 10 hari ke depan (bukan arahnya)
// lebih baik daripada tebakan sederhana? Read-only, hanya memakai price_history.
// Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.
//
// Dua target (keduanya dihitung dari bar i+1 .. i+10, sinyal malam hari i):
//  rv = log(akar rata-rata kuadrat return harian + 0,0001)   -> besar gerak harian
//  dd = log(drawdown terdalam dari penutupan hari i + 0,01)  -> seberapa dalam harga bisa turun (dasar lebar CL)
// Tiga peramal, semua dilatih pada data sebelum periode uji (walk-forward, purge):
//  A  persistensi: volatilitas 20 hari terakhir + koreksi bias dari data latih ("sama seperti kemarin")
//  H  regresi pada vol 5/20/60 hari saja (pembanding standar yang kuat, gaya HAR)
//  M  regresi ridge pada semua fitur (termasuk ATR, rentang harian, volume, RSI, tren, volatilitas pasar)
//
// SYARAT LOLOS (ditetapkan sebelum melihat hasil), per target:
//  M lebih baik dari A (MSE lebih kecil) di 5 dari 5 periode, DAN
//  M lebih baik dari H di minimal 4 dari 5 periode.
// Kalau tidak lolos, kesimpulannya: tidak ada nilai tambah di atas volatilitas yang sudah diketahui.
import { FEATURES, buildRows, round } from './lib.ts';
import type { Bar, Series } from './lib.ts';

export const FOLDS = 5;
export const AHEAD = 10;
export const LAMBDA = 50;

export const VOL_FEATURES = [
  'lv5', 'lv20', 'lv60', 'latr', 'lrange5', 'absRet1', 'ret5', 'ret20', 'distSma50', 'distSma20',
  'rsi', 'volumeRatio', 'absGap', 'mktLv20', 'lv20MinusMkt', 'lv5MinusLv20',
] as const;
const HAR_IDX = [0, 1, 2];

const fx = (n: string) => (FEATURES as readonly string[]).indexOf(n);

export type VolRow = { ticker: string; date: string; x: number[]; lv20: number; yRv: number; yDd: number };

function rollStd(a: number[], i: number, len: number): number {
  let s = 0;
  let s2 = 0;
  for (let j = i - len + 1; j <= i; j++) {
    s += a[j];
    s2 += a[j] * a[j];
  }
  const m = s / len;
  return Math.sqrt(Math.max(0, (s2 - len * m * m) / (len - 1)));
}

/** Nilai target untuk sinyal di bar i. Null bila 10 bar ke depan belum ada. */
export function targetsAt(bars: Bar[], i: number): { yRv: number; yDd: number } | null {
  if (i + AHEAD >= bars.length) return null;
  let ss = 0;
  let minLow = Infinity;
  for (let j = i + 1; j <= i + AHEAD; j++) {
    const r = Math.log(bars[j].close / bars[j - 1].close);
    ss += r * r;
    minLow = Math.min(minLow, bars[j].low);
  }
  const dd = Math.max(0, 1 - minLow / bars[i].close);
  return { yRv: Math.log(Math.sqrt(ss / AHEAD) + 1e-4), yDd: Math.log(dd + 0.01) };
}

export type BuildOpts = {
  /** Sertakan baris terbaru yang hasil 10 harinya belum ada (target NaN), untuk peramalan. */
  keepOpen?: boolean;
  /** Volatilitas pasar hanya dirata-ratakan dari saham-saham ini (bukan semua seri yang dimuat). */
  mktUniverse?: Set<string>;
};

export function buildVolRows(series: Series[], opts: BuildOpts = {}): VolRow[] {
  const base = buildRows(series, { horizon: AHEAD, k: 1 });
  const info = new Map(
    series.map((s) => {
      const lr = s.bars.map((b, i) => (i === 0 ? 0 : Math.log(b.close / s.bars[i - 1].close)));
      const range = s.bars.map((b) => (b.high - b.low) / b.close);
      return [s.ticker, { s, lr, range, idx: new Map(s.bars.map((b, i) => [b.date, i])) }] as const;
    }),
  );
  const iVol20 = fx('vol20');
  const iR5 = fx('volRatio5_20');
  const rows: (VolRow & { raw: number[] })[] = [];
  for (const r of base) {
    const t = info.get(r.ticker)!;
    const i = t.idx.get(r.date)!;
    if (i < 61) continue;
    const y = targetsAt(t.s.bars, i);
    if (!y && !opts.keepOpen) continue;
    const v20 = r.x[iVol20];
    const v5 = r.x[iR5] * v20;
    const v60 = rollStd(t.lr, i, 60);
    const range5 = (t.range[i] + t.range[i - 1] + t.range[i - 2] + t.range[i - 3] + t.range[i - 4]) / 5;
    const lv5 = Math.log(v5 + 1e-4);
    const lv20 = Math.log(v20 + 1e-4);
    const lv60 = Math.log(v60 + 1e-4);
    rows.push({
      ticker: r.ticker,
      date: r.date,
      lv20,
      yRv: y ? y.yRv : NaN,
      yDd: y ? y.yDd : NaN,
      x: [],
      raw: [
        lv5, lv20, lv60, Math.log(r.x[fx('atrPct')] + 1e-4), Math.log(range5 + 1e-4), Math.abs(r.x[fx('ret1')]),
        r.x[fx('ret5')], r.x[fx('ret20')], r.x[fx('distSma50')], r.x[fx('distSma20')], r.x[fx('rsi')],
        r.x[fx('volumeRatio')], Math.abs(r.x[fx('gap')]), 0, 0, lv5 - lv20,
      ],
    });
  }
  // Volatilitas pasar = rata-rata lv20 seluruh saham pada tanggal yang sama (tanpa IHSG).
  const byDate = new Map<string, number[]>();
  for (const r of rows) if (!opts.mktUniverse || opts.mktUniverse.has(r.ticker)) byDate.set(r.date, [...(byDate.get(r.date) ?? []), r.lv20]);
  const mkt = new Map([...byDate].map(([d, v]) => [d, v.reduce((a, b) => a + b, 0) / v.length]));
  return rows.map(({ raw, ...r }) => {
    const m = mkt.get(r.date)!;
    raw[13] = m;
    raw[14] = r.lv20 - m;
    return { ...r, x: raw };
  });
}

// ---------------------------------------------------------------- ridge

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

export type Ridge = { mean: number[]; std: number[]; w: number[] };

export function fitRidge(X: number[][], y: number[], lambda: number, clip = 5): Ridge {
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
  const g = new Array(D).fill(0);
  for (let i = 0; i < Z.length; i++) {
    for (let j = 0; j < D; j++) {
      g[j] += Z[i][j] * y[i];
      for (let k = j; k < D; k++) A[j][k] += Z[i][j] * Z[i][k];
    }
  }
  for (let j = 0; j < D; j++) for (let k = 0; k < j; k++) A[j][k] = A[k][j];
  for (let j = 1; j < D; j++) A[j][j] += lambda;
  return { mean: mu, std: sd, w: solve(A, g) };
}

export function predictRidge(m: Ridge, x: number[], clip = 5): number {
  let s = m.w[0];
  for (let j = 0; j < x.length; j++) s += m.w[j + 1] * Math.max(-clip, Math.min(clip, (x[j] - m.mean[j]) / m.std[j]));
  return s;
}

// ---------------------------------------------------------------- evaluasi

const mean = (a: number[]) => a.reduce((s, v) => s + v, 0) / (a.length || 1);
const mse = (p: number[], y: number[]) => mean(p.map((v, i) => (v - y[i]) ** 2));
function corr(a: number[], b: number[]): number {
  const ma = mean(a);
  const mb = mean(b);
  let sab = 0;
  let saa = 0;
  let sbb = 0;
  for (let i = 0; i < a.length; i++) {
    sab += (a[i] - ma) * (b[i] - mb);
    saa += (a[i] - ma) ** 2;
    sbb += (b[i] - mb) ** 2;
  }
  return sab / Math.sqrt(saa * sbb);
}
const quantile = (a: number[], q: number) => [...a].sort((x, y) => x - y)[Math.min(a.length - 1, Math.floor(a.length * q))];

export type MethodScore = {
  mse: number;
  /** 1 - MSE / MSE(A): positif berarti lebih baik daripada persistensi. */
  skillVsA: number;
  corr: number;
};

export type TargetFold = {
  A: MethodScore;
  H: MethodScore;
  M: MethodScore;
  mBeatsA: boolean;
  mBeatsH: boolean;
  /**
   * Kalibrasi lebar CL (hanya target dd): batas = prediksi + kuantil 80% sisa dari data latih. Idealnya drawdown
   * melewati batas di sekitar 20% kasus di semua kelompok volatilitas. Urutan: [rendah, sedang, tinggi, semua].
   */
  hitRate?: Record<'A' | 'H' | 'M', number[]>;
};

export type VolFold = { fold: number; testStart: string; testEnd: string; nTrain: number; nTest: number; rv: TargetFold; dd: TargetFold };

function evalTarget(tr: VolRow[], te: VolRow[], pick: (r: VolRow) => number, withHit: boolean): TargetFold {
  const ytr = tr.map(pick);
  const yte = te.map(pick);
  const bias = mean(tr.map((r, i) => ytr[i] - r.lv20));
  const predA = (r: VolRow) => r.lv20 + bias;
  const harX = (r: VolRow) => HAR_IDX.map((j) => r.x[j]);
  const mH = fitRidge(tr.map(harX), ytr, 1);
  const mM = fitRidge(tr.map((r) => r.x), ytr, LAMBDA);
  const predH = (r: VolRow) => predictRidge(mH, harX(r));
  const predM = (r: VolRow) => predictRidge(mM, r.x);
  const pA = te.map(predA);
  const mseA = mse(pA, yte);
  const score = (p: number[]): MethodScore => ({ mse: round(mse(p, yte), 5), skillVsA: round(1 - mse(p, yte) / mseA, 4), corr: round(corr(p, yte), 4) });
  const pH = te.map(predH);
  const pM = te.map(predM);
  const out: TargetFold = { A: score(pA), H: score(pH), M: score(pM), mBeatsA: mse(pM, yte) < mseA, mBeatsH: mse(pM, yte) < mse(pH, yte) };
  if (withHit) {
    const hit = (pred: (r: VolRow) => number): number[] => {
      const ptr = tr.map(pred);
      const q80 = quantile(ptr.map((p, i) => ytr[i] - p), 0.8);
      const c1 = quantile(ptr, 1 / 3);
      const c2 = quantile(ptr, 2 / 3);
      const pt = te.map(pred);
      const over = pt.map((p, i) => (yte[i] > p + q80 ? 1 : 0));
      const grp = (lo: number, hi: number) => {
        const sel = over.filter((_, i) => pt[i] >= lo && pt[i] < hi);
        return round(sel.length ? mean(sel) : NaN, 3);
      };
      return [grp(-Infinity, c1), grp(c1, c2), grp(c2, Infinity), round(mean(over), 3)];
    };
    out.hitRate = { A: hit(predA), H: hit(predH), M: hit(predM) };
  }
  return out;
}

export function evalVol(series: Series[], only?: number): VolFold[] {
  const rows = buildVolRows(series);
  const dates = [...new Set(rows.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / FOLDS);
  const out: VolFold[] = [];
  for (let f = 0; f < FOLDS; f++) {
    if (only !== undefined && f !== only) continue;
    const startIdx = minTrain + f * block;
    const endIdx = f === FOLDS - 1 ? dates.length - 1 : startIdx + block - 1;
    const trainEnd = dates[startIdx - AHEAD - 1];
    const testStart = dates[startIdx];
    const testEnd = dates[endIdx];
    const tr = rows.filter((r) => r.date <= trainEnd);
    const te = rows.filter((r) => r.date >= testStart && r.date <= testEnd);
    out.push({
      fold: f,
      testStart,
      testEnd,
      nTrain: tr.length,
      nTest: te.length,
      rv: evalTarget(tr, te, (r) => r.yRv, false),
      dd: evalTarget(tr, te, (r) => r.yDd, true),
    });
  }
  return out;
}

/** Ringkasan syarat lolos lintas periode. */
export function verdict(folds: VolFold[]) {
  const sum = (t: 'rv' | 'dd') => {
    const beatsA = folds.filter((f) => f[t].mBeatsA).length;
    const beatsH = folds.filter((f) => f[t].mBeatsH).length;
    return {
      folds: folds.length,
      mBeatsA: beatsA,
      mBeatsH: beatsH,
      pass: beatsA === folds.length && beatsH >= Math.ceil(folds.length * 0.8),
      meanSkillVsA: { H: round(mean(folds.map((f) => f[t].H.skillVsA)), 4), M: round(mean(folds.map((f) => f[t].M.skillVsA)), 4) },
      meanCorr: { A: round(mean(folds.map((f) => f[t].A.corr)), 4), H: round(mean(folds.map((f) => f[t].H.corr)), 4), M: round(mean(folds.map((f) => f[t].M.corr)), 4) },
    };
  };
  return { rv: sum('rv'), dd: sum('dd') };
}
