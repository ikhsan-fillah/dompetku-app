// Uji unit lab peluang CL. Jalankan: node --test supabase/functions/market-ml/risk.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { CLS, evalRisk, verdict } from './risk.ts';
import type { Series } from './lib.ts';

function synth(n: number, nStocks: number): Series[] {
  let seed = 5;
  const rnd = () => ((seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296) - 0.5;
  const out: Series[] = [];
  for (let k = 0; k < nStocks; k++) {
    let c = 100;
    const bars = [];
    const amp = 0.01 + 0.004 * (k % 4); // saham berbeda punya volatilitas berbeda
    for (let d = 0; d < n; d++) {
      const o = c;
      c *= 1 + rnd() * amp * 2;
      const date = new Date(Date.UTC(2021, 0, 1 + d)).toISOString().slice(0, 10);
      bars.push({ date, open: o, high: Math.max(o, c) * 1.004, low: Math.min(o, c) * 0.996, close: c, volume: 1000 + ((d * 7 + k) % 50) });
    }
    out.push({ ticker: `S${k}`, bars });
  }
  return out;
}

test('evalRisk: 5 periode, semua CL terisi, peluang di antara 0 dan 1, Brier dihitung untuk lima peramal', () => {
  const folds = evalRisk(synth(900, 12));
  assert.equal(folds.length, 5);
  for (const f of folds) {
    for (const c of CLS) {
      const cell = f.cl[String(Math.round(c * 100))];
      assert.ok(cell.obs >= 0 && cell.obs <= 1);
      for (const m of ['P0', 'S', 'R', 'H', 'M'] as const) {
        assert.ok(cell.brier[m] >= 0 && cell.brier[m] <= 1, `${m} brier`);
        assert.ok(cell.meanPred[m] > 0 && cell.meanPred[m] < 1, `${m} meanPred`);
      }
    }
    assert.equal(f.cl['5'].bins?.length, 5);
  }
  const v = verdict(folds);
  assert.equal(typeof v.pass, 'boolean');
  assert.equal(Object.keys(v.K1_MbeatsS.counts).length, 4);
});

test('data sintetis dengan volatilitas tetap per saham: M tidak boleh jauh lebih buruk dari S', () => {
  const folds = evalRisk(synth(1200, 16));
  for (const f of folds) {
    const c = f.cl['3'];
    assert.ok(c.brier.M <= c.brier.S * 1.15, `M ${c.brier.M} vs S ${c.brier.S}`);
  }
});
