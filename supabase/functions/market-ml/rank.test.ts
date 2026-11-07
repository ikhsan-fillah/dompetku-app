// Uji unit lab ranking. Jalankan: node --test supabase/functions/market-ml/rank.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildPanel, COST, evalRank, periodAt, spearman, tStat } from './rank.ts';
import type { Series } from './lib.ts';

const mk = (ticker: string, closes: number[]): Series => ({
  ticker,
  bars: closes.map((c, k) => ({ date: `2024-${String(Math.floor(k / 28) + 1).padStart(2, '0')}-${String((k % 28) + 1).padStart(2, '0')}`, open: c, high: c, low: c, close: c, volume: 1 })),
});

test('spearman: urutan sama 1, terbalik -1', () => {
  assert.equal(spearman([1, 2, 3, 4], [10, 20, 30, 40]), 1);
  assert.equal(spearman([1, 2, 3, 4], [4, 3, 2, 1]), -1);
});

test('tStat: deret konstan positif tidak terdefinisi, deret bervariasi positif', () => {
  assert.ok(Number.isNaN(tStat([1, 1, 1])));
  assert.ok(tStat([1, 2, 3, 2, 3]) > 3);
});

test('periodAt: saham dengan tren naik teratas, imbal hasil maju dihitung dari hari i', () => {
  const n = 80;
  const s: Series[] = [];
  for (let k = 0; k < 25; k++) s.push(mk(`S${k}`, Array.from({ length: n }, (_, d) => 100 * (1 + 0.001 * (k - 12)) ** d)));
  const p = buildPanel(s);
  const pr = periodAt(p, 30, 20, 20)!;
  assert.equal(pr.n, 25);
  assert.ok(pr.top > pr.ew && pr.ew > pr.bottom);
  assert.ok(pr.ic > 0.99);
});

test('evalRank: momentum sempurna lulus, acak tidak', () => {
  const n = 400;
  const trend: Series[] = [];
  for (let k = 0; k < 30; k++) trend.push(mk(`S${k}`, Array.from({ length: n }, (_, d) => 100 * (1 + 0.0015 * (k - 15) + 0.0002 * Math.sin(d * (k + 1))) ** d)));
  const r = evalRank(trend);
  assert.equal(r.configs.length, 9);
  assert.ok(r.configs.every((c) => c.grossExcess > 0));
  assert.ok(COST === 0.004);
  let seed = 7;
  const rnd = () => ((seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296) - 0.5;
  const noise: Series[] = [];
  for (let k = 0; k < 30; k++) {
    let c = 100;
    noise.push(mk(`R${k}`, Array.from({ length: n }, () => (c *= 1 + rnd() * 0.04))));
  }
  assert.equal(evalRank(noise).verdict, 'tidak lulus');
});
