// Model produksi perkiraan gerak harian 10 hari ke depan (rv), dari uji lab vol.ts (lolos 5 dari 5 periode vs
// persistensi, 7 Nov 2026). Dilatih ulang tiap kali dipanggil dari seluruh riwayat 44 saham (ridge 16 fitur
// volatilitas, cepat), jadi tidak ada koefisien yang disimpan dan tidak ada model yang bisa basi.
// Murni TypeScript tanpa API Deno, supaya bisa diuji dengan Node.
//
// Mode periksa (checkForecast): sebelum angka perkiraan ditampilkan, prosedur produksi yang sama diuji pada empat
// kuartal terakhir (dilatih hanya dengan data sebelum tiap kuartal). SYARAT LOLOS (ditetapkan sebelum melihat hasil):
//  P1  rata-rata galat log (prediksi - kenyataan) berada dalam +-0,15 (kira-kira +-16%) di minimal 3 dari 4 kuartal
//  P2  perkiraan lebih baik dari persistensi (MSE lebih kecil) di minimal 3 dari 4 kuartal
// Bila gagal, perkiraan tidak ditampilkan sebagai angka di app.
import { round } from './lib.ts';
import type { Series } from './lib.ts';
import { AHEAD, LAMBDA, buildVolRows, fitRidge, predictRidge } from './vol.ts';
import type { VolRow } from './vol.ts';

export const VOL_MODEL_VERSION = 'vol-ridge-rv-v1';
export const QUARTER = 63;

const mean = (a: number[]) => a.reduce((s, v) => s + v, 0) / (a.length || 1);

/** Gerak harian dalam persen dari nilai target log(rms + 1e-4). */
export const moveFromLog = (v: number) => (Math.exp(v) - 1e-4) * 100;

export type VolForecast = { ticker: string; asOf: string; move: number };

/** Perkiraan gerak harian 10 hari ke depan untuk hari terakhir tiap saham. */
export function forecastLatest(series: Series[], universe: Set<string>): { forecasts: VolForecast[]; nTrain: number } {
  const rows = buildVolRows(series, { keepOpen: true, mktUniverse: universe });
  const train = rows.filter((r) => universe.has(r.ticker) && Number.isFinite(r.yRv));
  if (train.length < 1000) throw new Error(`data latih terlalu sedikit: ${train.length}`);
  const model = fitRidge(train.map((r) => r.x), train.map((r) => r.yRv), LAMBDA);
  const last = new Map<string, VolRow>();
  for (const r of rows) {
    const cur = last.get(r.ticker);
    if (!cur || r.date > cur.date) last.set(r.ticker, r);
  }
  const forecasts = [...last.values()].map((r) => ({
    ticker: r.ticker,
    asOf: r.date,
    move: round(moveFromLog(predictRidge(model, r.x)), 3),
  }));
  return { forecasts, nTrain: train.length };
}

export type QuarterCheck = {
  quarter: number;
  testStart: string;
  testEnd: string;
  nTrain: number;
  nTest: number;
  /** rata-rata (prediksi - kenyataan) pada skala log; 0,10 berarti prediksi rata-rata 10% terlalu tinggi */
  meanLogErr: number;
  mse: number;
  mseA: number;
  skillVsA: number;
  /** rata-rata gerak yang diperkirakan / rata-rata gerak nyata (persen) */
  meanPredMove: number;
  meanRealMove: number;
  biasOk: boolean;
  beatsA: boolean;
};

export function checkForecast(series: Series[], universe: Set<string>): { quarters: QuarterCheck[]; verdict: { P1: number; P2: number; pass: boolean } } {
  const all = buildVolRows(series, { mktUniverse: universe }).filter((r) => universe.has(r.ticker));
  const dates = [...new Set(all.map((r) => r.date))].sort();
  const quarters: QuarterCheck[] = [];
  for (let q = 0; q < 4; q++) {
    const startIdx = dates.length - 4 * QUARTER + q * QUARTER;
    const endIdx = startIdx + QUARTER - 1;
    const trainEnd = dates[startIdx - AHEAD - 1];
    const testStart = dates[startIdx];
    const testEnd = dates[endIdx];
    const tr = all.filter((r) => r.date <= trainEnd);
    const te = all.filter((r) => r.date >= testStart && r.date <= testEnd);
    const model = fitRidge(tr.map((r) => r.x), tr.map((r) => r.yRv), LAMBDA);
    const bias = mean(tr.map((r) => r.yRv - r.lv20));
    const pred = te.map((r) => predictRidge(model, r.x));
    const y = te.map((r) => r.yRv);
    const mse = mean(pred.map((p, i) => (p - y[i]) ** 2));
    const mseA = mean(te.map((r, i) => (r.lv20 + bias - y[i]) ** 2));
    const meanLogErr = mean(pred.map((p, i) => p - y[i]));
    quarters.push({
      quarter: q,
      testStart,
      testEnd,
      nTrain: tr.length,
      nTest: te.length,
      meanLogErr: round(meanLogErr, 4),
      mse: round(mse, 5),
      mseA: round(mseA, 5),
      skillVsA: round(1 - mse / mseA, 4),
      meanPredMove: round(mean(pred.map(moveFromLog)), 3),
      meanRealMove: round(mean(y.map(moveFromLog)), 3),
      biasOk: Math.abs(meanLogErr) <= 0.15,
      beatsA: mse < mseA,
    });
  }
  const P1 = quarters.filter((x) => x.biasOk).length;
  const P2 = quarters.filter((x) => x.beatsA).length;
  return { quarters, verdict: { P1, P2, pass: P1 >= 3 && P2 >= 3 } };
}
