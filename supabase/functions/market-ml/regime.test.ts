// Uji unit lab kondisi pasar. Jalankan: node --test supabase/functions/market-ml/regime.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { evalRegime, MARKET, statOf, topShare, verdict, withMarket } from './regime.ts';
import { buildRows } from './lib.ts';
import type { Series } from './lib.ts';

function synth(n: number, nStocks: number): Series[] {
  let seed = 11;
  const rnd = () => ((seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296) - 0.5;
  const out: Series[] = [];
  const mkt: number[] = [];
  for (let d = 0; d < n; d++) mkt.push(rnd() * 0.02 + (Math.floor(d / 200) % 2 ? -0.001 : 0.001));
  for (let k = 0; k < nStocks; k++) {
    let c = 100;
    const bars = [];
    for (let d = 0; d < n; d++) {
      const o = c;
      c *= 1 + mkt[d] + rnd() * 0.02;
      const date = new Date(Date.UTC(2021, 0, 1 + d)).toISOString().slice(0, 10);
      bars.push({ date, open: o, high: Math.max(o, c) * 1.005, low: Math.min(o, c) * 0.995, close: c, volume: 1000 + ((d * 7 + k) % 50) });
    }
    out.push({ ticker: `S${k}`, bars });
  }
  return out;
}

test('withMarket: fitur pasar sama untuk semua saham di tanggal yang sama', () => {
  const rows = withMarket(buildRows(synth(260, 8), { horizon: 10, k: 1 }));
  const d = rows[100].date;
  const same = rows.filter((r) => r.date === d);
  assert.ok(same.length >= 5);
  assert.ok(same.every((r) => r.xm.slice(-MARKET.length).every((v, j) => v === same[0].xm.slice(-MARKET.length)[j])));
  assert.equal(same[0].xm.length, same[0].ta.length + MARKET.length);
});

test('statOf dan topShare: biaya 0,4% dikurangkan, 10% teratas diambil', () => {
  const base = { ticker: 'A', date: 'd', x: [], y: 1, fwdRet: 0, upperPct: 0, lowerPct: 0, close: 1, valueIdr20: 1, ta: [], xm: [], up: true };
  const rs = Array.from({ length: 20 }, (_, i) => ({ ...base, date: `d${i}`, holdRet: i === 19 ? 0.104 : 0.004 }));
  const s = statOf(rs);
  assert.equal(s.n, 20);
  assert.ok(Math.abs((s.meanNet as number) - 0.5) < 1e-6); // (0*19 + 10)/20 = 0.5%
  const top = topShare(rs, rs.map((_, i) => i));
  assert.equal(top.length, 2);
  assert.equal(statOf(top).meanNet, 5.0); // (0 + 10)/2 = 5%
});

test('evalRegime: berjalan pada data sintetis dan menghasilkan verdict tanpa error', () => {
  const folds = evalRegime(synth(900, 12));
  assert.equal(folds.length, 5);
  assert.ok(folds.every((f) => f.nTest > 0 && f.B.top.n > 0 && f.M.top.n > 0));
  const v = verdict(folds);
  assert.equal(typeof v.P1.lulus, 'boolean');
  assert.equal(typeof v.P2.lulus, 'boolean');
});
