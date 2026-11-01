// Detektor pola chart bentuk besar (double top/bottom, head and shoulders, segitiga, flag).
// KAUSAL: hasil di bar t hanya memakai data sampai bar t. Titik balik (pivot) ditentukan dengan zigzag yang
// baru terkonfirmasi setelah harga berbalik minimal theta dari puncak/lembah, sehingga tidak ada look-ahead.
// Semua ambang adalah usulan [H] (tidak ada angka dari sumber) dan dikunci sebelum melihat hasil.
// Pola ini deskriptif. Tidak ada klaim bahwa pola memprediksi.

export const PATTERNS = [
  'P-DBOT', 'P-DTOP', 'P-HS', 'P-IHS',
  'P-TRI-asc-up', 'P-TRI-asc-dn', 'P-TRI-desc-up', 'P-TRI-desc-dn', 'P-TRI-sym-up', 'P-TRI-sym-dn',
  'P-FLAG-bull', 'P-FLAG-bear',
] as const;
export type PatName = typeof PATTERNS[number];
/** idx = bar puncak/lembah; at = bar saat pivot itu terkonfirmasi (selalu >= idx). */
export type Pivot = { idx: number; price: number; type: 'H' | 'L'; at: number };
/** t = bar saat pola tertembus (breakout); key = indeks bar titik kunci. dir: +1 bullish, -1 bearish. */
export type PatEvent = { t: number; name: PatName; dir: 1 | -1; key: number[] };
type S = { n: number; h: number[]; l: number[]; c: number[]; atrPct: (number | null)[] };

/** Zigzag: pivot dikonfirmasi saat harga berbalik >= max(3%, 2,5 x ATR14%) dari ekstrem. */
export const ZZ_K = 2.5;
export const ZZ_FLOOR = 0.03;

export function detectPatterns(s: S): { events: PatEvent[]; pivots: Pivot[] } {
  const { n, h, l, c, atrPct } = s;
  const piv: Pivot[] = [];
  const events: PatEvent[] = [];
  const used = new Set<string>();
  const emit = (t: number, name: PatName, dir: 1 | -1, key: number[]) => {
    const id = `${name}:${key.join(',')}`;
    if (used.has(id)) return;
    used.add(id);
    events.push({ t, name, dir, key });
  };
  let dir = 0; // 0 belum tahu, 1 sedang naik (cari puncak), -1 sedang turun (cari lembah)
  let cH = 0, cL = 0;
  for (let i = 1; i < n; i++) {
    const th = Math.max(ZZ_FLOOR, ZZ_K * (atrPct[i] ?? 0));
    if (dir === 0) {
      if (h[i] > h[cH]) cH = i;
      if (l[i] < l[cL]) cL = i;
      if (cL !== i && h[i] >= l[cL] * (1 + th)) { piv.push({ idx: cL, price: l[cL], type: 'L', at: i }); dir = 1; cH = i; }
      else if (cH !== i && l[i] <= h[cH] * (1 - th)) { piv.push({ idx: cH, price: h[cH], type: 'H', at: i }); dir = -1; cL = i; }
    } else if (dir === 1) {
      if (h[i] > h[cH]) cH = i;
      else if (l[i] <= h[cH] * (1 - th)) { piv.push({ idx: cH, price: h[cH], type: 'H', at: i }); dir = -1; cL = i; }
    } else {
      if (l[i] < l[cL]) cL = i;
      else if (h[i] >= l[cL] * (1 + th)) { piv.push({ idx: cL, price: l[cL], type: 'L', at: i }); dir = 1; cH = i; }
    }
    const A = atrPct[i];
    const m = piv.length;
    if (A === null || i < 60 || m < 3) continue;

    // ---- double bottom / double top (titik kunci: [lembah1, puncak tengah, lembah2])
    {
      const a = piv[m - 3], b = piv[m - 2], d = piv[m - 1];
      if (a.type === 'L' && b.type === 'H' && d.type === 'L') {
        const height = b.price / Math.max(a.price, d.price) - 1;
        const gap = d.idx - a.idx;
        if (height >= Math.max(0.05, 3 * A) && Math.abs(d.price / a.price - 1) <= Math.min(0.04, 0.3 * height) &&
          gap >= 10 && gap <= 70 && c[i] > b.price && i - d.idx <= 25) {
          let mx = -Infinity;
          for (let q = Math.max(0, a.idx - 40); q <= a.idx; q++) mx = Math.max(mx, h[q]);
          if (mx >= a.price * (1 + height)) emit(i, 'P-DBOT', 1, [a.idx, b.idx, d.idx]); // datang dari penurunan
        }
      }
      if (a.type === 'H' && b.type === 'L' && d.type === 'H') {
        const height = Math.min(a.price, d.price) / b.price - 1;
        const gap = d.idx - a.idx;
        if (height >= Math.max(0.05, 3 * A) && Math.abs(d.price / a.price - 1) <= Math.min(0.04, 0.3 * height) &&
          gap >= 10 && gap <= 70 && c[i] < b.price && i - d.idx <= 25) {
          let mn = Infinity;
          for (let q = Math.max(0, a.idx - 40); q <= a.idx; q++) mn = Math.min(mn, l[q]);
          if (mn <= a.price / (1 + height)) emit(i, 'P-DTOP', -1, [a.idx, b.idx, d.idx]); // datang dari kenaikan
        }
      }
    }

    // ---- head and shoulders / inverse (titik kunci: [bahu kiri, lembah1, kepala, lembah2, bahu kanan])
    if (m >= 5) {
      const p1 = piv[m - 5], t1 = piv[m - 4], p2 = piv[m - 3], t2 = piv[m - 2], p3 = piv[m - 1];
      const neckAt = (x: number) => t1.price + (t2.price - t1.price) * (x - t1.idx) / (t2.idx - t1.idx);
      const mid = (t1.price + t2.price) / 2;
      const span = p3.idx - p1.idx;
      if (p1.type === 'H' && t1.type === 'L' && p2.type === 'H' && t2.type === 'L' && p3.type === 'H') {
        if (p2.price > Math.max(p1.price, p3.price) * (1 + Math.max(0.02, A)) &&
          Math.abs(p3.price / p1.price - 1) <= 0.1 && Math.abs(t2.price / t1.price - 1) <= 0.08 &&
          p2.price / mid - 1 >= 0.05 && span >= 15 && span <= 120 && i - p3.idx <= 40 && c[i] < neckAt(i)) {
          let mn = Infinity;
          for (let q = Math.max(0, p1.idx - 40); q <= p1.idx; q++) mn = Math.min(mn, l[q]);
          if (mn <= p1.price * (1 - 0.06)) emit(i, 'P-HS', -1, [p1.idx, t1.idx, p2.idx, t2.idx, p3.idx]);
        }
      }
      if (p1.type === 'L' && t1.type === 'H' && p2.type === 'L' && t2.type === 'H' && p3.type === 'L') {
        if (p2.price < Math.min(p1.price, p3.price) * (1 - Math.max(0.02, A)) &&
          Math.abs(p3.price / p1.price - 1) <= 0.1 && Math.abs(t2.price / t1.price - 1) <= 0.08 &&
          mid / p2.price - 1 >= 0.05 && span >= 15 && span <= 120 && i - p3.idx <= 40 && c[i] > neckAt(i)) {
          let mx = -Infinity;
          for (let q = Math.max(0, p1.idx - 40); q <= p1.idx; q++) mx = Math.max(mx, h[q]);
          if (mx >= p1.price * (1 + 0.06)) emit(i, 'P-IHS', 1, [p1.idx, t1.idx, p2.idx, t2.idx, p3.idx]);
        }
      }
    }

    // ---- segitiga: dua sentuhan di garis atas dan dua di garis bawah, harga tetap di dalam sampai breakout
    if (m >= 4) {
      const q4 = [piv[m - 4], piv[m - 3], piv[m - 2], piv[m - 1]];
      const hs = q4.filter((x) => x.type === 'H'), ls = q4.filter((x) => x.type === 'L');
      const span = q4[3].idx - q4[0].idx;
      if (hs.length === 2 && ls.length === 2 && span >= 15 && span <= 80 && i - q4[3].idx <= 30) {
        const [hA, hB] = hs, [lA, lB] = ls;
        const uRel = hB.price / hA.price - 1, lRel = lB.price / lA.price - 1;
        let shape: 'asc' | 'desc' | 'sym' | null = null;
        if (Math.abs(uRel) <= 0.015 && lRel >= 0.03) shape = 'asc';
        else if (Math.abs(lRel) <= 0.015 && uRel <= -0.03) shape = 'desc';
        else if (uRel <= -0.03 && lRel >= 0.03) shape = 'sym';
        if (shape) {
          const up = (x: number) => hA.price + (hB.price - hA.price) * (x - hA.idx) / (hB.idx - hA.idx);
          const lo = (x: number) => lA.price + (lB.price - lA.price) * (x - lA.idx) / (lB.idx - lA.idx);
          const x0 = Math.max(hA.idx, lA.idx);
          const width0 = (up(x0) - lo(x0)) / ((up(x0) + lo(x0)) / 2);
          if (up(i) > lo(i) && width0 >= Math.max(0.05, 3 * A)) {
            const brkUp = c[i] > up(i), brkDn = c[i] < lo(i);
            if (brkUp || brkDn) {
              let ok = true;
              for (let x = x0; x < i; x++) if (h[x] > up(x) * 1.01 || l[x] < lo(x) * 0.99) { ok = false; break; }
              if (ok) emit(i, `P-TRI-${shape}-${brkUp ? 'up' : 'dn'}` as PatName, brkUp ? 1 : -1, q4.map((x) => x.idx));
            }
          }
        }
      }
    }

    // ---- flag: tiang tajam (>= 10% dalam <= 20 bar sebelum puncak/lembah), pullback dangkal (<= 50% tiang)
    // 4-25 bar, lalu harga menembus pucuk tiang. Awal tiang = ekstrem 20 bar sebelum pivot (bukan pivot zigzag).
    for (let j = Math.max(0, m - 7); j <= m - 1; j++) {
      const q = piv[j];
      if (q.idx < 20) continue;
      if (q.type === 'H') {
        let s0 = q.idx - 20;
        for (let x = q.idx - 20; x <= q.idx; x++) if (l[x] < l[s0]) s0 = x;
        const pole = q.price / l[s0] - 1;
        if (pole >= 0.1 && i - q.idx >= 4 && i - q.idx <= 25 && c[i] > q.price && c[i - 1] <= q.price) {
          let minL = Infinity, maxH = -Infinity;
          for (let x = q.idx + 1; x < i; x++) { minL = Math.min(minL, l[x]); maxH = Math.max(maxH, h[x]); }
          if ((q.price - minL) / (q.price - l[s0]) <= 0.5 && maxH <= q.price) emit(i, 'P-FLAG-bull', 1, [s0, q.idx]);
        }
      } else {
        let s0 = q.idx - 20;
        for (let x = q.idx - 20; x <= q.idx; x++) if (h[x] > h[s0]) s0 = x;
        const pole = h[s0] / q.price - 1;
        if (pole >= 0.1 && i - q.idx >= 4 && i - q.idx <= 25 && c[i] < q.price && c[i - 1] >= q.price) {
          let minL = Infinity, maxH = -Infinity;
          for (let x = q.idx + 1; x < i; x++) { minL = Math.min(minL, l[x]); maxH = Math.max(maxH, h[x]); }
          if ((maxH - q.price) / (h[s0] - q.price) <= 0.5 && minL >= q.price) emit(i, 'P-FLAG-bear', -1, [s0, q.idx]);
        }
      }
    }
  }
  return { events, pivots: piv };
}
