// Uji unit lab volatilitas. Jalankan: node --test supabase/functions/market-ml/vol.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { AHEAD, evalVol, fitRidge, predictRidge, targetsAt, verdict } from './vol.ts';
import type { Bar, Series } from './lib.ts';

test('targetsAt: drawdown dan besar gerak dihitung dari bar berikutnya', () => {
  const bars: Bar[] = Array.from({ length: 30 }, (_, k) => ({ date: `d${k}`, open: 100, high: 101, low: 99, close: 100, volume: 1 }));
  bars[5].low = 90; // drawdown 10% dalam 10 bar sejak i=0
  const t = targetsAt(bars, 0)!;
  assert.ok(Math.abs(t.yDd - Math.log(0.1 + 0.01)) < 1e-9);
  assert.ok(Math.abs(t.yRv - Math.log(1e-4)) < 1e-9); // close datar: return nol
  assert.equal(targetsAt(bars, 30 - AHEAD), null);
});

test('ridge menemukan hubungan linear', () => {
  const X = Array.from({ length: 200 }, (_, i) => [i % 7, (i * 3) % 5]);
  const y = X.map((x) => 2 * x[0] - x[1] + 1);
  const m = fitRidge(X, y, 0.001);
  assert.ok(Math.abs(predictRidge(m, [3, 2]) - 5) < 0.05);
});

// Volatilitas yang bergerombol (GARCH sederhana): model harus punya skill positif di atas persistensi atau sama.
let seed = 7;
const rnd = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
const gauss = () => Math.sqrt(-2 * Math.log(rnd() + 1e-12)) * Math.cos(2 * Math.PI * rnd());

test('evalVol berjalan dan memberi verdict yang terstruktur', () => {
  const dates: string[] = [];
  const d = new Date('2019-01-01');
  while (dates.length < 1100) {
    d.setDate(d.getDate() + 1);
    if (d.getDay() % 6) dates.push(d.toISOString().slice(0, 10));
  }
  const series: Series[] = Array.from({ length: 8 }, (_, k) => {
    let p = 1000 + 100 * k;
    let h = 0.0004;
    let prev = 0;
    const bars = dates.map((date) => {
      h = 0.00001 + 0.1 * prev * prev + 0.88 * h;
      const r = Math.sqrt(h) * gauss();
      prev = r;
      const o = p;
      const c = o * Math.exp(r);
      p = c;
      return { date, open: o, high: Math.max(o, c) * 1.004, low: Math.min(o, c) * 0.996, close: c, volume: 1e6 };
    });
    return { ticker: `T${k}`, bars };
  });
  const folds = evalVol(series);
  assert.equal(folds.length, 5);
  const v = verdict(folds);
  assert.equal(v.rv.folds, 5);
  // Pada data GARCH, regresi HAR/ridge harus menyamai atau melampaui persistensi murni.
  assert.ok(v.rv.meanSkillVsA.M > -0.05);
  assert.ok(folds[0].dd.hitRate!.M.length === 4);
});
