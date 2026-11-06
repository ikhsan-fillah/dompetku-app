// Uji kelayakan siklus 5 hari + 10 hari dengan revisi di hari ke-5 (lab, read-only).
// Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.
//
// Dua pertanyaan, dijawab pada riwayat harga tanpa menyentuh produksi:
//  1. Apakah model TA 5 hari lolos gate yang sama dengan model 10 hari?
//  2. Setelah 5 hari nyata, apakah peluang 10 hari yang direvisi lebih baik daripada
//     (a) prediksi hari ke-0 yang tidak diubah, (b) base rate saja, dan (c) fungsi
//     mekanis dari jalur harga 5 hari saja tanpa indikator? Selisih (c) vs gabungan
//     menunjukkan apakah indikator hari ke-5 menambah informasi di luar jalur harga.
import { auc, buildRows, fitLogistic, predict, projectX, round, TA_FEATURES, walkForward } from './lib.ts';
import type { FoldResult, Row, Series } from './lib.ts';

export const LAMBDA = 5;
export const FOLDS = 5;
/** Hari ke berapa prediksi 10 hari direvisi, dan panjang jendela penuh. */
export const REVISE_AT = 5;
export const FULL = 10;

export const PATH_FEATURES = ['z5', 'maxUp5', 'minDn5'] as const;

/** Gate yang sama dengan produksi: AUC rata-rata >= 0,53 dan logloss lebih baik dari base di >= 80% lipatan. */
export function gate(folds: { auc: number; logloss: number; logloss_base: number }[]) {
  const meanAuc = folds.reduce((a, f) => a + f.auc, 0) / folds.length;
  const beat = folds.filter((f) => f.logloss < f.logloss_base).length;
  return { ok: meanAuc >= 0.53 && beat >= Math.ceil(folds.length * 0.8), meanAuc: round(meanAuc), foldsBeatBase: beat, folds: folds.length };
}

/** Model TA 5 hari: label triple-barrier horizon 5, batas 1 sigma * akar(5), fitur TA sama dengan model 10 hari. */
export function evalFiveDay(series: Series[], fold?: number): FoldResult[] {
  const rows = buildRows(series, { horizon: 5, k: 1 }).map((r) => ({ ...r, x: projectX(r.x, TA_FEATURES) }));
  return walkForward(rows, 5, FOLDS, LAMBDA, fold, TA_FEATURES, 'distSma50');
}

export type RevisionSample = {
  ticker: string;
  date: string; // hari sinyal (hari ke-0)
  y: number;
  x0: number[]; // fitur TA hari ke-0
  path: number[]; // z5, maxUp5, minDn5 (satuan lebar batas 10 hari)
  ta5: number[]; // fitur TA hari ke-5
};

export type Determined = { date: string; y: number };

/**
 * Sampel revisi: baris hari ke-0 yang labelnya 10 hari sudah diketahui, batas belum tersentuh
 * dalam 5 hari pertama (kalau sudah, label ditentukan dan tidak perlu model: dicatat di `determined`).
 */
export function buildRevisionSamples(series: Series[]) {
  const rows = buildRows(series, { horizon: FULL, k: 1 });
  const byKey = new Map(rows.map((r) => [`${r.ticker}|${r.date}`, r]));
  const bars = new Map(series.map((s) => [s.ticker, s.bars]));
  const index = new Map(series.map((s) => [s.ticker, new Map(s.bars.map((b, i) => [b.date, i]))]));
  const day0: Row[] = [];
  const samples: RevisionSample[] = [];
  const determined: Determined[] = [];
  for (const r of rows) {
    if (r.y === null) continue;
    day0.push({ ...r, x: projectX(r.x, TA_FEATURES) });
    const b = bars.get(r.ticker)!;
    const i = index.get(r.ticker)!.get(r.date)!;
    const upper = r.close * (1 + r.upperPct);
    const lower = r.close * (1 + r.lowerPct);
    const width = Math.log(1 + r.upperPct);
    let touched = 0;
    let maxUp = -Infinity;
    let minDn = Infinity;
    for (let j = i + 1; j <= i + REVISE_AT; j++) {
      // Aturan label produksi: batas bawah diperiksa lebih dulu pada hari yang sama.
      if (b[j].low <= lower) {
        touched = -1;
        break;
      }
      if (b[j].high >= upper) {
        touched = 1;
        break;
      }
      maxUp = Math.max(maxUp, Math.log(b[j].high / r.close) / width);
      minDn = Math.min(minDn, Math.log(b[j].low / r.close) / width);
    }
    if (touched !== 0) {
      determined.push({ date: r.date, y: touched === 1 ? 1 : 0 });
      continue;
    }
    const r5 = byKey.get(`${r.ticker}|${b[i + REVISE_AT].date}`);
    if (!r5) continue;
    samples.push({
      ticker: r.ticker,
      date: r.date,
      y: r.y,
      x0: projectX(r.x, TA_FEATURES),
      path: [Math.log(b[i + REVISE_AT].close / r.close) / width, maxUp, minDn],
      ta5: projectX(r5.x, TA_FEATURES),
    });
  }
  return { day0, samples, determined };
}

const mean = (a: number[]) => a.reduce((s, v) => s + v, 0) / a.length;
const logloss = (p: number[], y: number[]) =>
  -mean(p.map((v, i) => (y[i] ? Math.log(Math.max(v, 1e-9)) : Math.log(Math.max(1 - v, 1e-9)))));

export type Score = { auc: number; logloss: number };
const score = (p: number[], y: number[]): Score => ({ auc: round(auc(p, y)), logloss: round(logloss(p, y)) });

export type RevisionFold = {
  fold: number;
  testStart: string;
  testEnd: string;
  nTrain: number;
  nTest: number;
  /** Porsi baris uji yang batasnya sudah tersentuh dalam 5 hari (label sudah ditentukan). */
  determinedShare: number;
  baseRate: number;
  day0: Score; // prediksi hari ke-0, tidak direvisi
  base: Score; // base rate sampel yang bertahan, tanpa fitur
  path: Score; // logistik pada jalur harga 5 hari saja
  full: Score; // logistik pada jalur harga + fitur TA hari ke-5
};

/** Walk-forward dengan purge FULL hari, lipatan sama seperti produksi (berdasar tanggal baris hari ke-0). */
export function evalRevision(series: Series[], only?: number): RevisionFold[] {
  const { day0, samples, determined } = buildRevisionSamples(series);
  const dates = [...new Set(day0.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / FOLDS);
  const out: RevisionFold[] = [];
  for (let f = 0; f < FOLDS; f++) {
    if (only !== undefined && f !== only) continue;
    const startIdx = minTrain + f * block;
    const endIdx = f === FOLDS - 1 ? dates.length - 1 : startIdx + block - 1;
    const trainEnd = dates[startIdx - FULL - 1];
    const testStart = dates[startIdx];
    const testEnd = dates[endIdx];
    const tr0 = day0.filter((r) => r.date <= trainEnd);
    const trS = samples.filter((s) => s.date <= trainEnd);
    const teS = samples.filter((s) => s.date >= testStart && s.date <= testEnd);
    const teD = determined.filter((d) => d.date >= testStart && d.date <= testEnd);
    const m0 = fitLogistic(tr0.map((r) => r.x), tr0.map((r) => r.y as number), LAMBDA, 4, 25, TA_FEATURES);
    const mp = fitLogistic(trS.map((s) => s.path), trS.map((s) => s.y), LAMBDA, 4, 25, PATH_FEATURES);
    const names = [...PATH_FEATURES, ...TA_FEATURES];
    const mf = fitLogistic(trS.map((s) => [...s.path, ...s.ta5]), trS.map((s) => s.y), LAMBDA, 4, 25, names);
    const y = teS.map((s) => s.y);
    const base = mean(trS.map((s) => s.y));
    out.push({
      fold: f,
      testStart,
      testEnd,
      nTrain: trS.length,
      nTest: teS.length,
      determinedShare: round(teD.length / Math.max(1, teD.length + teS.length)),
      baseRate: round(base),
      day0: score(teS.map((s) => predict(m0, s.x0)), y),
      base: score(teS.map(() => base), y),
      path: score(teS.map((s) => predict(mp, s.path)), y),
      full: score(teS.map((s) => predict(mf, [...s.path, ...s.ta5])), y),
    });
  }
  return out;
}

/** Ringkasan lintas lipatan: siapa yang menang atas siapa, dengan logloss (lebih kecil lebih baik). */
export function summarizeRevision(folds: RevisionFold[]) {
  const wins = (a: keyof Pick<RevisionFold, 'day0' | 'base' | 'path' | 'full'>, b: keyof Pick<RevisionFold, 'day0' | 'base' | 'path' | 'full'>) =>
    folds.filter((f) => f[a].logloss < f[b].logloss).length;
  const m = (k: 'day0' | 'base' | 'path' | 'full', s: keyof Score) => round(mean(folds.map((f) => f[k][s])));
  return {
    folds: folds.length,
    meanDeterminedShare: round(mean(folds.map((f) => f.determinedShare))),
    meanAuc: { day0: m('day0', 'auc'), path: m('path', 'auc'), full: m('full', 'auc') },
    meanLogloss: { day0: m('day0', 'logloss'), base: m('base', 'logloss'), path: m('path', 'logloss'), full: m('full', 'logloss') },
    // Revisi (full) lebih baik dari prediksi hari ke-0 yang tidak diubah?
    fullBeatsDay0: wins('full', 'day0'),
    // Revisi lebih baik dari base rate polos?
    fullBeatsBase: wins('full', 'base'),
    // Indikator hari ke-5 menambah sesuatu di luar jalur harga?
    fullBeatsPath: wins('full', 'path'),
    pathBeatsBase: wins('path', 'base'),
  };
}
