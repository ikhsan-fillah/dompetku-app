// Uji unit model produksi gerak harian. Jalankan: node --test supabase/functions/market-ml/volprod.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildVolRows } from './vol.ts';
import { checkForecast, forecastLatest, moveFromLog } from './volprod.ts';
import type { Series } from './lib.ts';

function synth(n: number, nStocks: number, startDay = 0): Series[] {
  let seed = 3;
  const rnd = () => ((seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296) - 0.5;
  const out: Series[] = [];
  for (let k = 0; k < nStocks; k++) {
    let c = 100;
    const bars = [];
    const amp = 0.008 + 0.004 * (k % 4);
    for (let d = 0; d < n; d++) {
      const o = c;
      c *= 1 + rnd() * amp * 2;
      const date = new Date(Date.UTC(2021, 0, 1 + startDay + d)).toISOString().slice(0, 10);
      bars.push({ date, open: o, high: Math.max(o, c) * 1.004, low: Math.min(o, c) * 0.996, close: c, volume: 1000 + ((d * 7 + k) % 50) });
    }
    out.push({ ticker: `S${k}`, bars });
  }
  return out;
}

test('keepOpen: baris terbaru tanpa hasil ikut, dengan target NaN', () => {
  const s = synth(300, 6);
  const closed = buildVolRows(s);
  const open = buildVolRows(s, { keepOpen: true });
  assert.ok(open.length > closed.length);
  const lastDate = open[open.length - 1].date;
  assert.ok(open.filter((r) => r.date === lastDate).every((r) => Number.isNaN(r.yRv)));
  assert.ok(closed.every((r) => Number.isFinite(r.yRv)));
});

test('forecastLatest: satu perkiraan per saham di tanggal terakhir, masuk akal', () => {
  const s = synth(500, 10);
  const universe = new Set(s.map((x) => x.ticker));
  const { forecasts, nTrain } = forecastLatest(s, universe);
  assert.equal(forecasts.length, 10);
  assert.ok(nTrain > 1000);
  const lastBar = s[0].bars[s[0].bars.length - 1].date;
  for (const f of forecasts) {
    assert.equal(f.asOf, lastBar);
    assert.ok(f.move > 0.2 && f.move < 5, `${f.ticker} ${f.move}`);
  }
  // Saham dengan amplitudo lebih besar diperkirakan lebih liar daripada yang tenang (S0 tenang, S3 liar).
  const by = new Map(forecasts.map((f) => [f.ticker, f.move]));
  assert.ok((by.get('S3') as number) > (by.get('S0') as number));
});

test('saham di luar universe ikut diperkirakan tanpa mengubah angka saham universe', () => {
  const s = synth(500, 10);
  const universe = new Set(s.slice(0, 8).map((x) => x.ticker));
  const withAll = forecastLatest(s, universe).forecasts;
  const only = forecastLatest(s.slice(0, 8), universe).forecasts;
  const a = new Map(withAll.map((f) => [f.ticker, f.move]));
  for (const f of only) assert.ok(Math.abs((a.get(f.ticker) as number) - f.move) < 1e-6, f.ticker);
  assert.ok(a.has('S9'));
});

test('checkForecast: empat kuartal, galat log terukur', () => {
  const s = synth(900, 12);
  const universe = new Set(s.map((x) => x.ticker));
  const res = checkForecast(s, universe);
  assert.equal(res.quarters.length, 4);
  for (const q of res.quarters) {
    assert.ok(q.nTest > 0 && q.nTrain > 0);
    assert.ok(Math.abs(q.meanLogErr) < 0.5, `bias ${q.meanLogErr}`);
  }
  assert.equal(typeof res.verdict.pass, 'boolean');
});

test('moveFromLog membalik transformasi target', () => {
  assert.ok(Math.abs(moveFromLog(Math.log(0.02 + 1e-4)) - 2) < 1e-9);
});
