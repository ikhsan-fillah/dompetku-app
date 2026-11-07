// Uji unit rencana level. Jalankan: node --test supabase/functions/market-ml/levels.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { COST, HOLD, NEED, WAIT, evalLevels, nearestSR, pivots, simulate } from './levels.ts';
import type { Bar, Series } from './lib.ts';

const flat = (n: number, p = 100): Bar[] =>
  Array.from({ length: n }, (_, k) => ({ date: `2024-01-${String(k + 1).padStart(2, '0')}`, open: p, high: p + 1, low: p - 1, close: p, volume: 1000 }));
const levels = (cl: number, tp: number) => () => ({ cl, tp });

test('data kurang dari NEED hari: null', () => {
  assert.equal(simulate(flat(NEED), 0, null, levels(90, 110)), null);
  assert.notEqual(simulate(flat(NEED + 1), 0, null, levels(90, 110)), null);
});

test('beli buka besok, TP tersentuh', () => {
  const b = flat(30);
  b[3].high = 112;
  const s = simulate(b, 0, null, levels(90, 110))!;
  assert.equal(s.code, 1);
  assert.ok(Math.abs(s.ret - (110 / 100 - 1 - COST)) < 1e-9);
});

test('CL dan TP di hari yang sama: CL dulu', () => {
  const b = flat(30);
  b[2].high = 115;
  b[2].low = 85;
  const s = simulate(b, 0, null, levels(90, 110))!;
  assert.equal(s.code, 2);
  assert.ok(Math.abs(s.ret - (90 / 100 - 1 - COST)) < 1e-9);
});

test('gap turun melewati CL: keluar di harga buka', () => {
  const b = flat(30);
  b[4] = { ...b[4], open: 80, high: 82, low: 78, close: 80 };
  const s = simulate(b, 0, null, levels(90, 110))!;
  assert.equal(s.code, 2);
  assert.ok(Math.abs(s.ret - (80 / 100 - 1 - COST)) < 1e-9);
});

test('limit tidak tersentuh dalam WAIT hari: tidak terisi, hasil 0', () => {
  const b = flat(30);
  const s = simulate(b, 0, 95, levels(90, 110))!;
  assert.deepEqual(s, { code: 0, ret: 0 });
});

test('limit terisi di tengah hari: TP di hari terisi diabaikan, CL dicek', () => {
  const b = flat(30);
  b[1].low = 94;
  b[1].high = 120; // TP 110 tersentuh di hari terisi tapi urutan tidak diketahui
  const s = simulate(b, 0, 95, levels(90, 110))!;
  assert.equal(s.code, 3);
  const b2 = flat(30);
  b2[1].low = 89;
  assert.equal(simulate(b2, 0, 95, levels(90, 110))!.code, 2);
});

test('gap naik di atas limit terisi di harga buka', () => {
  const b = flat(30);
  b[2] = { ...b[2], open: 94, high: 96, low: 93, close: 95 };
  const s = simulate(b, 0, 95, levels(90, 110))!;
  assert.notEqual(s.code, 0);
});

test('waktu habis: keluar di penutupan hari terakhir', () => {
  const b = flat(40);
  b[1 + HOLD].close = 103;
  const s = simulate(b, 0, null, levels(90, 110))!;
  assert.equal(s.code, 3);
  assert.ok(Math.abs(s.ret - (103 / 100 - 1 - COST)) < 1e-9);
});

test('pivot hanya terkonfirmasi setelah 3 bar', () => {
  const b = flat(20);
  for (let k = 0; k < 20; k++) {
    const v = 100 + Math.abs(10 - k); // lembah di indeks 10
    b[k] = { ...b[k], open: v, close: v, high: v + 0.5, low: v - 0.5 };
  }
  const pv = pivots(b);
  assert.equal(pv.low[10], true);
  assert.equal(nearestSR(b, pv, 12).sup, null); // belum terkonfirmasi di indeks 12
  assert.ok(nearestSR(b, pv, 14).sup !== null || b[14].close <= b[10].low);
});

// Data acak deterministik: pastikan pipeline berjalan dan keluaran masuk akal.
let seed = 99;
const rnd = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
test('evalLevels berjalan pada data acak', () => {
  const dates: string[] = [];
  const d = new Date('2020-01-01');
  while (dates.length < 900) {
    d.setDate(d.getDate() + 1);
    if (d.getDay() % 6) dates.push(d.toISOString().slice(0, 10));
  }
  const series: Series[] = Array.from({ length: 8 }, (_, k) => {
    let p = 1000 + 100 * k;
    const bars = dates.map((date) => {
      const o = p;
      const c = o * (1 + (rnd() - 0.5) * 0.04);
      p = c;
      return { date, open: o, high: Math.max(o, c) * 1.005, low: Math.min(o, c) * 0.995, close: c, volume: 1e6 };
    });
    return { ticker: `T${k}`, bars };
  });
  const folds = evalLevels(series, 2);
  assert.equal(folds.length, 1);
  const f = folds[0];
  assert.ok(f.nTrain > 1000 && f.nTest > 100);
  assert.equal(f.fixedMean.length, 27);
  const s = f.strategies.modelPilihRencana;
  assert.ok(s.fillRate > 0 && s.fillRate <= 1);
  // Pada jalan acak tanpa informasi, tidak boleh ada keunggulan besar setelah biaya.
  assert.ok(f.strategies.rataRata27Rencana.meanPerSignal < 0.002);
  assert.ok(WAIT === 3);
});
