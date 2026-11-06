// Uji unit logika siklus dengan data acak deterministik. Jalankan: node --test supabase/functions/market-ml/cycle.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildRows } from './lib.ts';
import type { Bar, Series } from './lib.ts';
import { COST, fitFiveDay, fitRevision, gate, evalFiveDay, latestRows, outcomeFor, pathAfter, revise, summarizeRevision, evalRevision } from './cycle.ts';

let seed = 12345;
const rnd = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
const gauss = () => Math.sqrt(-2 * Math.log(rnd() + 1e-12)) * Math.cos(2 * Math.PI * rnd());

function makeSeries(count: number, n: number): Series[] {
  const dates: string[] = [];
  const d = new Date('2020-01-01');
  while (dates.length < n) {
    d.setDate(d.getDate() + 1);
    if (d.getDay() % 6) dates.push(d.toISOString().slice(0, 10));
  }
  return Array.from({ length: count }, (_, k) => {
    let p = 1000 + 200 * k;
    let vol = 0.015;
    const bars: Bar[] = dates.map((date) => {
      vol = Math.max(0.005, Math.min(0.05, vol * 0.97 + 0.03 * 0.015 + 0.002 * gauss()));
      const open = p;
      const close = open * Math.exp(vol * gauss());
      const high = Math.max(open, close) * (1 + Math.abs(gauss()) * vol * 0.5);
      const low = Math.min(open, close) * (1 - Math.abs(gauss()) * vol * 0.5);
      p = close;
      return { date, open, high, low, close, volume: 1e6 * (1 + rnd()) };
    });
    return { ticker: `T${k}`, bars };
  });
}

const series = makeSeries(20, 900);

test('hasil nyata 10 hari cocok dengan label triple-barrier produksi', () => {
  const rows = buildRows(series, { horizon: 10, k: 1 });
  const byTicker = new Map(series.map((s) => [s.ticker, s.bars]));
  let checked = 0;
  for (const r of rows) {
    if (r.y === null) continue;
    const bars = byTicker.get(r.ticker)!;
    const i = bars.findIndex((b) => b.date === r.date);
    const o = outcomeFor(bars, i, 10, r.upperPct, r.lowerPct)!;
    assert.equal(o.hitUpper, r.y === 1);
    assert.ok(Math.abs(o.retNet - ((r.holdRet as number) - COST)) < 1e-9 || r.holdRet == null);
    checked++;
  }
  assert.ok(checked > 5000);
});

test('hasil nyata null selama hari ke-H belum ada', () => {
  const bars = series[0].bars;
  assert.equal(outcomeFor(bars, bars.length - 5, 10, 0.1, -0.1), null);
  assert.ok(outcomeFor(bars, bars.length - 11, 10, 0.1, -0.1));
});

test('batas yang tersentuh di 5 hari pertama menentukan label 10 hari', () => {
  const rows = buildRows(series, { horizon: 10, k: 1 });
  const byTicker = new Map(series.map((s) => [s.ticker, s.bars]));
  let determined = 0;
  for (const r of rows) {
    if (r.y === null) continue;
    const bars = byTicker.get(r.ticker)!;
    const i = bars.findIndex((b) => b.date === r.date);
    const ps = pathAfter(bars, i, r.upperPct, r.lowerPct)!;
    if (ps.touched !== 0) {
      assert.equal(r.y, ps.touched === 1 ? 1 : 0);
      determined++;
    }
  }
  assert.ok(determined > 500);
});

test('pathAfter null bila belum 5 hari, dan revisi memakai model hanya bila batas belum tersentuh', () => {
  const bars = series[0].bars;
  assert.equal(pathAfter(bars, bars.length - 3, 0.1, -0.1), null);
  const rev = fitRevision(series);
  const calm = { touched: 0 as const, z5: 0.2, maxUp5: 0.4, minDn5: -0.3 };
  const r = revise(rev.model, calm)!;
  assert.equal(r.state, 'diperbarui');
  assert.ok(r.prob > 0 && r.prob < 1);
  assert.equal(revise(rev.model, { ...calm, touched: 1 })!.prob, 1);
  assert.equal(revise(rev.model, { ...calm, touched: -1 })!.state, 'bawah_tersentuh');
  assert.equal(revise(null, calm), null);
  // Makin dekat batas atas, makin tinggi peluangnya.
  const near = revise(rev.model, { touched: 0, z5: 0.8, maxUp5: 0.9, minDn5: -0.1 })!;
  const far = revise(rev.model, { touched: 0, z5: -0.8, maxUp5: 0.1, minDn5: -0.9 })!;
  assert.ok(near.prob > far.prob);
});

test('latestRows hanya saham yang punya data di hari bursa terakhir', () => {
  const rows = buildRows(series, { horizon: 10, k: 1 });
  const latest = latestRows(rows);
  assert.equal(new Set(latest.map((r) => r.date)).size, 1);
  assert.equal(latest.length, 20);
});

test('model 5 hari dan evaluasi lipatan berjalan, data acak tidak lolos gate', () => {
  const f = fitFiveDay(series);
  assert.equal(f.model.features.length, 10);
  assert.ok(f.baseRate > 0.1 && f.baseRate < 0.6);
  const folds = evalFiveDay(series);
  assert.equal(folds.length, 5);
  assert.equal(gate(folds).ok, false);
});

test('ringkasan revisi: jalur harga mengalahkan prediksi hari ke-0 pada data acak', () => {
  const s = summarizeRevision(evalRevision(series));
  assert.equal(s.pathBeatsBase, 5);
  assert.ok(s.meanAuc.path > 0.7);
});
