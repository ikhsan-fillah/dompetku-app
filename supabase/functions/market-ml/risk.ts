// Uji lab: apakah perkiraan PELUANG kena CL dari model lebih akurat daripada frekuensi historis biasa?
// Read-only, hanya memakai price_history. Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.
//
// Peristiwa: dalam 10 hari bursa setelah sinyal (malam hari i), harga terendah (low) menyentuh
// penutupan hari i dikurangi CL persen. CL diuji pada 2%, 3%, 4%, 5% (batas wajar Ikhsan 1-4%, 5% = CL).
// Ini sama dengan definisi "sentuh" yang dipakai papan Risiko (drawdown dari penutupan hari sinyal).
//
// Lima peramal peluang, semua hanya memakai data yang sudah diketahui pada tanggal sinyal (walk-forward, purge):
//  P0 frekuensi gabungan semua saham di data latih (tanpa informasi saham)
//  S  frekuensi historis per saham di data latih, dihaluskan ke P0 (20 pengamatan semu). INI yang dipakai papan Risiko sekarang.
//  R  frekuensi per saham pada 250 pengamatan terakhir yang hasilnya sudah diketahui (menyesuaikan diri dengan keadaan terbaru)
//  H  regresi ridge pada volatilitas 5/20/60 hari -> perkiraan drawdown (skala log) -> peluang dari sebaran sisa data latih
//  M  regresi ridge pada 16 fitur volatilitas -> perkiraan drawdown -> peluang dari sebaran sisa data latih
// Sebaran sisa diambil per tiga kelompok perkiraan (rendah/sedang/tinggi) supaya lebar sebaran ikut volatilitas.
//
// SYARAT LOLOS (ditetapkan sebelum melihat hasil). Ukuran = skor Brier (makin kecil makin baik), per periode uji:
//  K1  M lebih baik dari S di minimal 4 dari 5 periode, untuk SETIAP CL (2%, 3%, 4%, 5%)
//  K2  M lebih baik dari R di minimal 4 dari 5 periode, untuk CL 3% dan 5%
//  K3  Kalibrasi: |rata-rata peluang M - frekuensi nyata| <= 0,05 di minimal 4 dari 5 periode, untuk CL 3% dan 5%
//  Lolos hanya bila K1, K2, dan K3 semuanya terpenuhi.
// Bila K1 lolos tetapi K2 atau K3 tidak: model hanya menang atas frekuensi statis, tidak atas frekuensi terbaru,
// dan peluang dari model tidak boleh ditampilkan sebagai angka tepat.
import { round } from './lib.ts';
import type { Series } from './lib.ts';
import { AHEAD, FOLDS, LAMBDA, buildVolRows, fitRidge, predictRidge } from './vol.ts';
import type { VolRow } from './vol.ts';

export const CLS = [0.02, 0.03, 0.04, 0.05] as const;
export const ROLL = 250;
export const MIN_ROLL = 60;
export const SHRINK = 20;
const HAR_IDX = [0, 1, 2];
const METHODS = ['P0', 'S', 'R', 'H', 'M'] as const;
type Method = (typeof METHODS)[number];

const mean = (a: number[]) => a.reduce((s, v) => s + v, 0) / (a.length || 1);
const thrOf = (c: number) => Math.log(c + 0.01) - 1e-9;
const hit = (r: VolRow, c: number) => (r.yDd >= thrOf(c) ? 1 : 0);

/** Banyak elemen terurut yang >= v. */
function countGe(sorted: number[], v: number): number {
  let lo = 0;
  let hi = sorted.length;
  while (lo < hi) {
    const m = (lo + hi) >> 1;
    if (sorted[m] < v) lo = m + 1;
    else hi = m;
  }
  return sorted.length - lo;
}

/** Peluang sisa >= batas, dihaluskan sedikit supaya tidak pernah tepat 0 atau 1. */
function tailProb(resid: number[], gap: number): number {
  return (countGe(resid, gap) + 0.5) / (resid.length + 1);
}

type Quantizer = { c1: number; c2: number; groups: number[][] };

function makeResidualModel(pred: number[], y: number[]): (p: number, thr: number) => number {
  const s = [...pred].sort((a, b) => a - b);
  const c1 = s[Math.floor(s.length / 3)];
  const c2 = s[Math.floor((2 * s.length) / 3)];
  const q: Quantizer = { c1, c2, groups: [[], [], []] };
  pred.forEach((p, i) => q.groups[p < c1 ? 0 : p < c2 ? 1 : 2].push(y[i] - p));
  q.groups.forEach((g) => g.sort((a, b) => a - b));
  return (p, thr) => tailProb(q.groups[p < c1 ? 0 : p < c2 ? 1 : 2], thr - p);
}

export type Bin = { pred: number; obs: number; n: number };

export type CellScore = {
  /** frekuensi nyata peristiwa di periode uji */
  obs: number;
  brier: Record<Method, number>;
  /** rata-rata peluang yang diramalkan */
  meanPred: Record<Method, number>;
  mBeatsS: boolean;
  mBeatsR: boolean;
  /** 1 - Brier(M) / Brier(S) */
  skillMvsS: number;
  /** lima kelompok menurut peluang M: rata-rata peluang vs frekuensi nyata */
  bins?: Bin[];
};

export type RiskFold = { fold: number; testStart: string; testEnd: string; nTrain: number; nTest: number; cl: Record<string, CellScore> };

export function evalRisk(series: Series[], only?: number): RiskFold[] {
  const rows = buildVolRows(series);
  const dates = [...new Set(rows.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / FOLDS);

  // Urutan per saham + jumlah kumulatif peristiwa, untuk frekuensi bergulir R tanpa mengintip masa depan.
  const pos = new Map<VolRow, { t: string; p: number }>();
  const cum = new Map<string, number[][]>();
  const byTicker = new Map<string, VolRow[]>();
  for (const r of rows) byTicker.set(r.ticker, [...(byTicker.get(r.ticker) ?? []), r]);
  for (const [t, list] of byTicker) {
    list.forEach((r, p) => pos.set(r, { t, p }));
    cum.set(
      t,
      CLS.map((c) => {
        const a = [0];
        for (const r of list) a.push(a[a.length - 1] + hit(r, c));
        return a;
      }),
    );
  }

  const out: RiskFold[] = [];
  for (let f = 0; f < FOLDS; f++) {
    if (only !== undefined && f !== only) continue;
    const startIdx = minTrain + f * block;
    const endIdx = f === FOLDS - 1 ? dates.length - 1 : startIdx + block - 1;
    const trainEnd = dates[startIdx - AHEAD - 1];
    const testStart = dates[startIdx];
    const testEnd = dates[endIdx];
    const tr = rows.filter((r) => r.date <= trainEnd);
    const te = rows.filter((r) => r.date >= testStart && r.date <= testEnd);
    const ytr = tr.map((r) => r.yDd);
    const harX = (r: VolRow) => HAR_IDX.map((j) => r.x[j]);
    const mH = fitRidge(tr.map(harX), ytr, 1);
    const mM = fitRidge(tr.map((r) => r.x), ytr, LAMBDA);
    const predH = (r: VolRow) => predictRidge(mH, harX(r));
    const predM = (r: VolRow) => predictRidge(mM, r.x);
    const resH = makeResidualModel(tr.map(predH), ytr);
    const resM = makeResidualModel(tr.map(predM), ytr);
    const pHte = te.map(predH);
    const pMte = te.map(predM);

    const cl: Record<string, CellScore> = {};
    CLS.forEach((c, ci) => {
      const thr = thrOf(c);
      const pooled = mean(tr.map((r) => hit(r, c)));
      const tickerStat = new Map<string, { n: number; k: number }>();
      for (const r of tr) {
        const s = tickerStat.get(r.ticker) ?? { n: 0, k: 0 };
        s.n++;
        s.k += hit(r, c);
        tickerStat.set(r.ticker, s);
      }
      const probS = (r: VolRow) => {
        const s = tickerStat.get(r.ticker) ?? { n: 0, k: 0 };
        return (s.k + SHRINK * pooled) / (s.n + SHRINK);
      };
      const probR = (r: VolRow) => {
        const { t, p } = pos.get(r)!;
        const hi = p - 11; // indeks terakhir yang hasilnya sudah diketahui
        const lo = Math.max(0, hi - ROLL + 1);
        const n = hi - lo + 1;
        if (n < MIN_ROLL) return probS(r);
        const a = cum.get(t)![ci];
        return (a[hi + 1] - a[lo] + 0.5) / (n + 1);
      };
      const y = te.map((r) => hit(r, c));
      const P: Record<Method, number[]> = {
        P0: te.map(() => pooled),
        S: te.map(probS),
        R: te.map(probR),
        H: te.map((_, i) => resH(pHte[i], thr)),
        M: te.map((_, i) => resM(pMte[i], thr)),
      };
      const brier = (p: number[]) => mean(p.map((v, i) => (v - y[i]) ** 2));
      const b = Object.fromEntries(METHODS.map((m) => [m, round(brier(P[m]), 5)])) as Record<Method, number>;
      const mp = Object.fromEntries(METHODS.map((m) => [m, round(mean(P[m]), 4)])) as Record<Method, number>;
      const cell: CellScore = {
        obs: round(mean(y), 4),
        brier: b,
        meanPred: mp,
        mBeatsS: brier(P.M) < brier(P.S),
        mBeatsR: brier(P.M) < brier(P.R),
        skillMvsS: round(1 - brier(P.M) / brier(P.S), 4),
      };
      if (c === 0.03 || c === 0.05) {
        const order = P.M.map((v, i) => [v, i] as const).sort((a, b2) => a[0] - b2[0]);
        const size = Math.ceil(order.length / 5);
        cell.bins = Array.from({ length: 5 }, (_, k) => {
          const sel = order.slice(k * size, (k + 1) * size).map(([, i]) => i);
          return { pred: round(mean(sel.map((i) => P.M[i])), 3), obs: round(mean(sel.map((i) => y[i])), 3), n: sel.length };
        });
      }
      cl[String(Math.round(c * 100))] = cell;
    });
    out.push({ fold: f, testStart, testEnd, nTrain: tr.length, nTest: te.length, cl });
  }
  return out;
}

/** Ringkasan syarat lolos lintas periode. */
export function verdict(folds: RiskFold[]) {
  const need = Math.ceil(folds.length * 0.8);
  const cnt = (cl: string, fn: (c: CellScore) => boolean) => folds.filter((f) => fn(f.cl[cl])).length;
  const k1 = Object.fromEntries(['2', '3', '4', '5'].map((c) => [c, cnt(c, (x) => x.mBeatsS)]));
  const k2 = Object.fromEntries(['3', '5'].map((c) => [c, cnt(c, (x) => x.mBeatsR)]));
  const k3 = Object.fromEntries(['3', '5'].map((c) => [c, cnt(c, (x) => Math.abs(x.meanPred.M - x.obs) <= 0.05)]));
  const ok = (o: Record<string, number>) => Object.values(o).every((v) => v >= need);
  return {
    folds: folds.length,
    K1_MbeatsS: { counts: k1, pass: ok(k1) },
    K2_MbeatsR: { counts: k2, pass: ok(k2) },
    K3_calibration: { counts: k3, pass: ok(k3) },
    pass: ok(k1) && ok(k2) && ok(k3),
  };
}
