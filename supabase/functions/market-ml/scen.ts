// Studi kejadian skenario teknikal (katalog Ikhsan + serah terima 1 Nov 2026).
// Hanya membaca data; tidak menulis apa pun. Semua fitur kausal (bar t memakai data s.d. t).
// Ambang dikunci di sini SEBELUM melihat hasil. Bias di katalog tidak dipakai sebagai label.
import { ema, rma, type Series } from './lib.ts';

/** SMA bergulir O(n); null bila ada null di jendela (sama hasilnya dengan sma di lib). */
function sma(v: Num[], L: number): Num[] {
  const out: Num[] = new Array(v.length).fill(null);
  let sum = 0, nulls = 0;
  for (let i = 0; i < v.length; i++) {
    const x = v[i];
    if (x === null) nulls++; else sum += x;
    if (i >= L) { const y = v[i - L]; if (y === null) nulls--; else sum -= y; }
    if (i >= L - 1 && nulls === 0) out[i] = sum / L;
  }
  return out;
}

type Num = number | null;
export const H = 10;
export const COST = 0.004;
export const MIN_VALUE_IDR = 1e9; // G3: buang hari dengan rata-rata nilai transaksi 20 hari < Rp1 miliar [H]
export const MAX_DAY_MOVE = Math.log(1.5); // data/aksi korporasi: buang jendela yang memuat gerak harian > 50%

/** Fraksi harga IDX (asumsi aturan yang berlaku; belum diverifikasi ulang). */
function tick(p: number): number {
  if (p < 200) return 1;
  if (p < 500) return 2;
  if (p < 2000) return 5;
  if (p < 5000) return 10;
  return 25;
}

/** Maks/min bergulir jendela L (termasuk i), O(n) dengan deque. */
function rollExt(v: number[], L: number, max: boolean): number[] {
  const out = new Array<number>(v.length).fill(NaN);
  const dq = new Int32Array(v.length);
  let head = 0, tail = 0;
  for (let i = 0; i < v.length; i++) {
    while (tail > head && (max ? v[dq[tail - 1]] <= v[i] : v[dq[tail - 1]] >= v[i])) tail--;
    dq[tail++] = i;
    if (dq[head] <= i - L) head++;
    if (i >= L - 1) out[i] = v[dq[head]];
  }
  return out;
}

function rollStd(v: Num[], L: number): Num[] {
  const out: Num[] = new Array(v.length).fill(null);
  for (let i = L - 1; i < v.length; i++) {
    let s = 0, s2 = 0, ok = true;
    for (let j = i - L + 1; j <= i; j++) {
      const x = v[j];
      if (x === null) { ok = false; break; }
      s += x; s2 += x * x;
    }
    if (ok) { const m = s / L; out[i] = Math.sqrt(Math.max(0, (s2 - L * m * m) / (L - 1))); }
  }
  return out;
}

export type Feat = {
  date: string;
  tren: 'UP' | 'DOWN' | 'SIDE' | null;
  [k: string]: unknown;
};

/** Fitur kanonik v1 per saham. Mengembalikan array kolom (lebih hemat daripada objek per bar). */
export function features(s: Series) {
  const b = s.bars;
  const n = b.length;
  const o = b.map((x) => x.open), h = b.map((x) => x.high), l = b.map((x) => x.low), c = b.map((x) => x.close), v = b.map((x) => x.volume);
  const ch: Num[] = c.map((x, i) => (i === 0 ? null : x - c[i - 1]));
  const g = rma(ch.map((x) => (x === null ? null : Math.max(x, 0))), 14);
  const d = rma(ch.map((x) => (x === null ? null : Math.max(-x, 0))), 14);
  const rsi: Num[] = c.map((_, i) => (g[i] === null || d[i] === null ? null : d[i] === 0 ? 100 : 100 - 100 / (1 + (g[i] as number) / (d[i] as number))));
  // StochRSI (sama dengan lib) untuk E5
  const st: Num[] = new Array(n).fill(null);
  for (let i = 13; i < n; i++) {
    let lo = Infinity, hi = -Infinity, ok = true;
    for (let j = i - 13; j <= i; j++) { const r = rsi[j]; if (r === null) { ok = false; break; } lo = Math.min(lo, r); hi = Math.max(hi, r); }
    if (ok) st[i] = hi === lo ? 0 : (((rsi[i] as number) - lo) / (hi - lo)) * 100;
  }
  const srK = sma(st, 3), srD = sma(srK, 3);
  // Stochastic harga 14 (slow %K = SMA3 dari fast %K) untuk H1
  const fk: Num[] = new Array(n).fill(null);
  for (let i = 13; i < n; i++) {
    let lo = Infinity, hi = -Infinity;
    for (let j = i - 13; j <= i; j++) { lo = Math.min(lo, l[j]); hi = Math.max(hi, h[j]); }
    fk[i] = hi === lo ? 50 : ((c[i] - lo) / (hi - lo)) * 100;
  }
  const stoch = sma(fk, 3);
  const e12 = ema(c, 12), e26 = ema(c, 26);
  const macd: Num[] = c.map((_, i) => (e26[i] === null ? null : (e12[i] as number) - (e26[i] as number)));
  const sig = ema(macd, 9);
  const hist: Num[] = macd.map((m, i) => (m === null || sig[i] === null ? null : m - (sig[i] as number)));
  const tr: Num[] = b.map((x, i) => (i === 0 ? x.high - x.low : Math.max(x.high - x.low, Math.abs(x.high - c[i - 1]), Math.abs(x.low - c[i - 1]))));
  const atr = rma(tr, 14);
  const vma20 = sma(v, 20);
  const sma20 = sma(c, 20), sma50 = sma(c, 50), sma150 = sma(c, 150), sma200 = sma(c, 200);
  const ema20 = ema(c, 20);
  const lr: Num[] = c.map((x, i) => (i === 0 || c[i - 1] <= 0 || x <= 0 ? null : Math.log(x / c[i - 1])));
  const vol20 = rollStd(lr, 20);
  const val20 = sma(b.map((x) => x.close * x.volume), 20);
  const rvol: Num[] = v.map((x, i) => (vma20[i] ? x / (vma20[i] as number) : null));
  const range = h.map((x, i) => x - l[i]);
  // rata-rata rentang dan badan 20 hari (pembanding "bar besar"/"lilin panjang") [H]
  const rangeMed20 = sma(range, 20);
  const bodyMed20 = sma(c.map((x, i) => Math.abs(x - o[i])), 20);
  const atrPct: Num[] = atr.map((a, i) => (a === null ? null : a / c[i]));
  // persentil macdPct 250 bar (MACD relatif riwayat sendiri) dan rsiRel 60 bar
  const pctl = (arr: Num[], i: number, L: number): Num => {
    if (i < L - 1 || arr[i] === null) return null;
    let below = 0, cnt = 0;
    for (let j = i - L + 1; j <= i; j++) { const x = arr[j]; if (x === null) return null; cnt++; if (x < (arr[i] as number)) below++; }
    return below / (cnt - 1 || 1);
  };
  const macdPct: Num[] = macd.map((m, i) => (m === null ? null : m / c[i]));

  const F = {
    ticker: s.ticker, n, o, h, l, c, v, rsi, srK, srD, stoch, macd, sig, hist, atr, rvol, sma20, sma50, sma150, sma200, ema20, vol20, val20, range, rangeMed20, bodyMed20, atrPct, macdPct,
    date: b.map((x) => x.date),
    tren: new Array<string | null>(n).fill(null),
    rsiMin5: new Array<Num>(n).fill(null), rsiMax5: new Array<Num>(n).fill(null), rsiMean60: new Array<Num>(n).fill(null), rsiRel: new Array<Num>(n).fill(null),
    rv5: new Array<Num>(n).fill(null), udv10: new Array<Num>(n).fill(null), clv: new Array<Num>(n).fill(null), spread: new Array<Num>(n).fill(null),
    move5: new Array<Num>(n).fill(null), pos60: new Array<Num>(n).fill(null), dd60: new Array<Num>(n).fill(null), ret60: new Array<Num>(n).fill(null),
    hi60p: new Array<Num>(n).fill(null), lo60p: new Array<Num>(n).fill(null), // high/low 60 bar SEBELUM t
    macdRank250: new Array<Num>(n).fill(null), atrRank120: new Array<Num>(n).fill(null),
    crossUp: new Array<number>(n).fill(0), crossDn: new Array<number>(n).fill(0), fadeState: new Array<number>(n).fill(0), fadeStart: new Array<number>(n).fill(0),
    macdSlope: new Array<Num>(n).fill(null), divBull: new Array<number>(n).fill(0), divBear: new Array<number>(n).fill(0), divJ: new Array<number>(n).fill(-1), divK: new Array<number>(n).fill(-1),
    crosses20: new Array<number>(n).fill(0),
    ema13: ema(c, 13), ema65: ema(c, 65), obv: new Array<number>(n).fill(0), impulse: new Array<string | null>(n).fill(null), zeroCross60: new Array<number>(n).fill(0),
  };
  for (let t = 1; t < n; t++) F.obv[t] = F.obv[t - 1] + (c[t] > c[t - 1] ? v[t] : c[t] < c[t - 1] ? -v[t] : 0);
  let zcRun = 0;
  const hi60 = rollExt(h, 60, true), lo60 = rollExt(l, 60, false);
  for (let t = 0; t < n; t++) {
    if (sma200[t] !== null && t >= 10 && sma50[t - 10] !== null) {
      const s50 = sma50[t] as number, s200 = sma200[t] as number, s50p = sma50[t - 10] as number;
      F.tren[t] = c[t] > s50 && s50 > s200 && s50 > s50p ? 'UP' : c[t] < s50 && s50 < s200 && s50 < s50p ? 'DOWN' : 'SIDE';
    }
    if (t >= 4) {
      let mn = Infinity, mx = -Infinity, ok = true;
      for (let j = t - 4; j <= t; j++) { const r = rsi[j]; if (r === null) { ok = false; break; } mn = Math.min(mn, r); mx = Math.max(mx, r); }
      if (ok) { F.rsiMin5[t] = mn; F.rsiMax5[t] = mx; }
      let s5 = 0, ok5 = true;
      for (let j = t - 4; j <= t; j++) { const r = rvol[j]; if (r === null) { ok5 = false; break; } s5 += r; }
      if (ok5) F.rv5[t] = s5 / 5;
    }
    if (t >= 59) {
      const lo = lo60[t], hi = hi60[t];
      F.pos60[t] = hi === lo ? null : (c[t] - lo) / (hi - lo);
      F.dd60[t] = c[t] / hi - 1;
    }
    if (t >= 60) {
      F.hi60p[t] = hi60[t - 1]; F.lo60p[t] = lo60[t - 1]; F.ret60[t] = c[t] / c[t - 60] - 1;
    }
    if (t >= 10) {
      let up = 0, dn = 0;
      for (let j = t - 9; j <= t; j++) { if (c[j] > c[j - 1]) up += v[j]; else if (c[j] < c[j - 1]) dn += v[j]; }
      F.udv10[t] = dn === 0 ? null : up / dn;
    }
    F.clv[t] = range[t] === 0 ? null : (c[t] - l[t]) / range[t];
    F.spread[t] = atr[t] ? range[t] / (atr[t] as number) : null;
    if (t >= 5 && atr[t]) F.move5[t] = (c[t] - c[t - 5]) / (atr[t] as number);
    if (t >= 2 && hist[t] !== null && hist[t - 1] !== null && hist[t - 2] !== null) {
      const a0 = hist[t] as number, a1 = hist[t - 1] as number, a2 = hist[t - 2] as number;
      const same = (a0 > 0) === (a1 > 0);
      F.fadeState[t] = same && Math.abs(a0) < Math.abs(a1) ? 1 : 0;
      F.fadeStart[t] = same && (a1 > 0) === (a2 > 0) && Math.abs(a1) >= Math.abs(a2) && Math.abs(a0) < Math.abs(a1) ? 1 : 0;
      const m0 = macd[t] as number, m1 = macd[t - 1] as number, s0 = sig[t] as number, s1 = sig[t - 1] as number;
      F.crossUp[t] = m1 <= s1 && m0 > s0 ? 1 : 0;
      if (F.crossUp[t]) F.macdRank250[t] = pctl(macdPct, t, 250);
      F.crossDn[t] = m1 >= s1 && m0 < s0 ? 1 : 0;
      F.macdSlope[t] = m0 - m1;
    }
    if (t >= 1 && F.ema13[t] !== null && F.ema13[t - 1] !== null && hist[t] !== null && hist[t - 1] !== null) {
      const eu = (F.ema13[t] as number) > (F.ema13[t - 1] as number), hu = (hist[t] as number) > (hist[t - 1] as number);
      const ed = (F.ema13[t] as number) < (F.ema13[t - 1] as number), hd = (hist[t] as number) < (hist[t - 1] as number);
      F.impulse[t] = eu && hu ? 'G' : ed && hd ? 'R' : 'B';
    }
    {
      const zc = (q: number) => (q >= 1 && macd[q] !== null && macd[q - 1] !== null && ((macd[q] as number) > 0) !== ((macd[q - 1] as number) > 0) ? 1 : 0);
      zcRun += zc(t) - (t >= 60 ? zc(t - 60) : 0);
      if (t >= 60) F.zeroCross60[t] = zcRun;
    }
    if (rsi[t] !== null && (rsi[t] as number) >= 45 && (rsi[t] as number) <= 55) F.atrRank120[t] = pctl(atrPct, t, 120);
    if (t >= 20) {
      let k = 0;
      for (let j = t - 19; j <= t; j++) k += F.crossUp[j] + F.crossDn[j];
      F.crosses20[t] = k;
    }
    // divergence versi katalog: low/high terendah/tertinggi di t-20..t-5
    if (t >= 20 && rsi[t - 20] !== null && rsi[t] !== null) {
      let j = t - 20, k = t - 20;
      for (let i = t - 20; i < t - 4; i++) { if (l[i] < l[j]) j = i; if (h[i] > h[k]) k = i; }
      F.divJ[t] = j; F.divK[t] = k;
      if (l[t] < l[j] && rsi[j] !== null && (rsi[t] as number) > (rsi[j] as number) + 3) F.divBull[t] = 1;
      if (h[t] > h[k] && rsi[k] !== null && (rsi[t] as number) < (rsi[k] as number) - 3) F.divBear[t] = 1;
    }
  }
  return F;
}
type FT = ReturnType<typeof features>;

/** Daftar skenario. Ambang dikunci; [H] = ambang usulan tanpa sumber angka. */
export const SCEN = [
  'A1', 'A2', 'A3', 'A4-DOWN', 'A4-UP', 'A4-SIDE', 'A5', 'A6', 'A7', 'A8',
  'B1', 'B2', 'B3', 'B4', 'B5', 'B6',
  'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8-UP', 'C8-OTHER',
  'D1', 'D2', 'D3', 'D4', 'D5',
  'E1', 'E2', 'E3', 'E4-cross', 'E4-cross-clean', 'E5',
  'F1', 'F3',
  'H1-buy', 'H1-sell', 'H2-golden', 'H2-death', 'H2-sma200zone',
  'H3-hammer', 'H3-engulf', 'H3-piercing', 'H3-mstar', 'H3-harami',
  'H4-star', 'H4-engulf', 'H4-darkcloud', 'H4-estar', 'H4-harami',
  'H5a', 'H5b', 'H5c', 'H5d',
  // file lanjutan (kode diberi awalan X- agar tidak bentrok dengan H1-H7 serah terima)
  'X-H2negRev', 'X-H4regime', 'X-I1zero', 'X-I7impulseG', 'X-I8impulseR', 'X-J1obvDiv', 'X-J5dry', 'X-L1gapUp', 'X-M1sma50', 'X-M3hi', 'X-M3lo', 'X-N1', 'X-N2',
  ...(['UP', 'SIDE', 'DOWN'] as const).flatMap((tr) => (['up', 'flat', 'dn'] as const).flatMap((pr) => (['low', 'norm', 'high'] as const).map((vo) => `G-${tr}-${pr}-${vo}` as const))),
] as const;
export type Scen = typeof SCEN[number];

const nn = (...x: unknown[]) => x.every((y) => y !== null && y !== undefined && !(typeof y === 'number' && !Number.isFinite(y)));

function sideways30(F: FT, t: number): { lo: number; hi: number } | null {
  // [H] range sideways >= 30 bar: lebar (high-low) 30 bar sebelum t <= 6 x ATR14[t-1]
  if (t < 31 || F.atr[t - 1] === null) return null;
  let lo = Infinity, hi = -Infinity;
  for (let j = t - 30; j < t; j++) { lo = Math.min(lo, F.l[j]); hi = Math.max(hi, F.h[j]); }
  return hi - lo <= 6 * (F.atr[t - 1] as number) ? { lo, hi } : null;
}

function candles(F: FT, t: number) {
  const { o, h, l, c } = F;
  const out = { hammer: false, bEng: false, pierce: false, mstar: false, bHar: false, star: false, sEng: false, dark: false, estar: false, sHar: false };
  if (t < 22 || F.rangeMed20[t] === null || F.bodyMed20[t] === null) return out;
  if (F.range[t] < 5 * tick(c[t])) return out; // pola hanya bila rentang >= 5 tick
  const body = (i: number) => Math.abs(c[i] - o[i]);
  const up = (i: number) => h[i] - Math.max(o[i], c[i]);
  const dn = (i: number) => Math.min(o[i], c[i]) - l[i];
  const black = (i: number) => c[i] < o[i], white = (i: number) => c[i] > o[i];
  const long = (i: number) => body(i) >= (F.bodyMed20[i] ?? Infinity) && body(i) > 0; // [H] "panjang" = badan >= median badan 20 hari
  const rg = F.range[t], rm = F.rangeMed20[t] as number;
  const down = c[t] < (F.ema20[t] ?? -Infinity) || c[t - 1] < (F.ema20[t - 1] ?? -Infinity);
  const upT = c[t] > (F.ema20[t] ?? Infinity) || c[t - 1] > (F.ema20[t - 1] ?? Infinity);
  if (down) {
    out.hammer = dn(t) >= 2 * body(t) && up(t) <= 0.1 * rg && rg >= rm;
    out.bEng = black(t - 1) && white(t) && o[t] <= c[t - 1] && c[t] >= o[t - 1] && body(t) > body(t - 1);
    out.pierce = black(t - 1) && long(t - 1) && white(t) && o[t] < c[t - 1] && c[t] > (o[t - 1] + c[t - 1]) / 2 && c[t] < o[t - 1];
    out.mstar = black(t - 2) && long(t - 2) && body(t - 1) <= 0.3 * body(t - 2) && Math.max(o[t - 1], c[t - 1]) < c[t - 2] && white(t) && c[t] > (o[t - 2] + c[t - 2]) / 2;
    out.bHar = black(t - 1) && long(t - 1) && white(t) && o[t] > c[t - 1] && c[t] < o[t - 1];
  }
  if (upT) {
    out.star = up(t) >= 2 * body(t) && dn(t) <= 0.1 * rg && rg >= rm;
    out.sEng = white(t - 1) && black(t) && o[t] >= c[t - 1] && c[t] <= o[t - 1] && body(t) > body(t - 1);
    out.dark = white(t - 1) && long(t - 1) && black(t) && o[t] > c[t - 1] && c[t] < (o[t - 1] + c[t - 1]) / 2 && c[t] > o[t - 1];
    out.estar = white(t - 2) && long(t - 2) && body(t - 1) <= 0.3 * body(t - 2) && Math.min(o[t - 1], c[t - 1]) > c[t - 2] && black(t) && c[t] < (o[t - 2] + c[t - 2]) / 2;
    out.sHar = white(t - 1) && long(t - 1) && black(t) && o[t] < c[t - 1] && c[t] > o[t - 1];
  }
  return out;
}

/** Flag skenario untuk bar t. lastA1: indeks A1 terakhir di saham ini (untuk A2). */
function flags(F: FT, t: number, ihsg: string | null, state: { lastA1: number; a2Done: number }): Scen[] {
  const out: Scen[] = [];
  const { c, h, l, o, rsi, macd, hist, atr, rvol } = F;
  const tren = F.tren[t];
  const r = rsi[t], m = macd[t], hs = hist[t], a = atr[t], rv = rvol[t];
  if (!nn(r, m, hs, a, rv) || t < 61) return out;
  const R = r as number, M = m as number, HS = hs as number, A = a as number, RV = rv as number;
  const clv = F.clv[t], spread = F.spread[t], dd60 = F.dd60[t], pos60 = F.pos60[t], rv5 = F.rv5[t], move5 = F.move5[t], udv10 = F.udv10[t];
  const rsiMin5 = F.rsiMin5[t], rsiMax5 = F.rsiMax5[t];
  const dC = c[t] - c[t - 1];

  // A1 (diselaraskan dengan teks; RSI memakai rsiMin5 <= 25 sesuai usulan serah terima)
  if (nn(dd60, clv, spread, rsiMin5) && (dd60 as number) <= -0.2 && RV >= 3 && (spread as number) >= 1.5 && (clv as number) >= 0.5 && (rsiMin5 as number) <= 25 && M < 0) {
    out.push('A1'); state.lastA1 = t;
  }
  // A2: 5-30 bar setelah A1, low dalam ±3% low climax, rvol<0.8, RSI > RSI climax, clv>=0.5 (sekali per A1)
  const k = state.lastA1;
  if (k >= 0 && t - k >= 5 && t - k <= 30 && state.a2Done !== k && nn(clv, rsi[k]) && Math.abs(l[t] / l[k] - 1) <= 0.03 && RV < 0.8 && R > (rsi[k] as number) && (clv as number) >= 0.5) {
    out.push('A2'); state.a2Done = k;
  }
  // A3: divBull, RSI low kedua < 40, RSI low pertama < 30, volume low kedua lebih kecil
  const j = F.divJ[t];
  if (F.divBull[t] && j >= 0 && R < 40 && nn(rsi[j], rvol[j]) && (rsi[j] as number) < 30 && RV < (rvol[j] as number)) out.push('A3');
  // A4: crossUp, MACD<0, rsiMin5<=20, rvol kemarin >= 1; cabang tren
  if (F.crossUp[t] && M < 0 && nn(rsiMin5, rvol[t - 1]) && (rsiMin5 as number) <= 20 && (rvol[t - 1] as number) >= 1 && tren) {
    out.push(tren === 'DOWN' ? 'A4-DOWN' : tren === 'UP' || c[t] > (F.sma200[t] as number) ? 'A4-UP' : 'A4-SIDE');
  }
  // A5: fadeStart, hist<0, MACD<0, RSI 25-35, rv5<1
  if (F.fadeStart[t] && HS < 0 && M < 0 && R >= 25 && R <= 35 && nn(rv5) && (rv5 as number) < 1) out.push('A5');
  // A6 spring / C4 upthrust: range sideways 30 bar [H]
  const sw = sideways30(F, t);
  if (sw && l[t] < sw.lo && c[t] >= sw.lo && RV < 1) out.push('A6');
  if (sw && h[t] > sw.hi && c[t] < sw.hi && nn(clv) && (clv as number) < 0.4 && RV >= 1.5) out.push('C4');
  // A7: dasar sideways setelah tren turun; bar naik rvol>=2, spread>=1.5, clv>=0.7, RSI menembus 60, MACD baru di atas nol (<0 dalam 5 bar)
  if (sw && F.tren[t - 30] === 'DOWN' && RV >= 2 && nn(spread, clv, rsi[t - 1]) && (spread as number) >= 1.5 && (clv as number) >= 0.7 && (rsi[t - 1] as number) < 60 && R >= 60 && M > 0 && Math.min(...[1, 2, 3, 4, 5].map((q) => (macd[t - q] ?? 0))) < 0) out.push('A7');
  // A8 failure swing bullish
  {
    let ia = -1;
    for (let q = t - 1; q >= t - 20; q--) if ((rsi[q] ?? 100) < 30) { ia = q; break; }
    if (ia > 0 && ia < t - 2) {
      let ip = ia + 1;
      for (let q = ia + 1; q < t; q++) if ((rsi[q] ?? -1) > (rsi[ip] ?? -1)) ip = q;
      if (ip < t - 1) {
        let iq = ip + 1;
        for (let q = ip + 1; q < t; q++) if ((rsi[q] ?? 999) < (rsi[iq] ?? 999)) iq = q;
        const P = rsi[ip] as number, Q = rsi[iq] as number;
        if (Q > 30 && Q < P && (rsi[t - 1] as number) <= P && R > P) out.push('A8');
      }
    }
  }
  // B1: tren UP, move5<=-1, rv5<0.8, RSI 40-50, MACD>0, hist<0, fadeState
  if (tren === 'UP' && nn(move5, rv5) && (move5 as number) <= -1 && (rv5 as number) < 0.8 && R >= 40 && R <= 50 && M > 0 && HS < 0 && F.fadeState[t]) out.push('B1');
  // B2: tren UP, crossUp, macdPct -1%..+0.5%, RSI 45-55
  if (tren === 'UP' && F.crossUp[t] && M / c[t] >= -0.01 && M / c[t] <= 0.005 && R >= 45 && R <= 55) out.push('B2');
  // B3: close > high 60 bar sebelumnya, rvol>=2, clv>=0.7, RSI 60-75, udv10>1.3
  if (nn(F.hi60p[t], clv, udv10) && c[t] > (F.hi60p[t] as number) && RV >= 2 && (clv as number) >= 0.7 && R >= 60 && R <= 75 && (udv10 as number) > 1.3) out.push('B3');
  // B4: positive reversal (Cardwell): tren UP, low[t] = low terendah 5 bar, higher low vs low j, RSI lower low, RSI 30-50
  if (tren === 'UP' && j >= 0 && nn(rsi[j]) && l[t] === Math.min(...l.slice(t - 4, t + 1)) && l[t] > l[j] && R < (rsi[j] as number) - 3 && R >= 30 && R <= 50) out.push('B4');
  // B5: tren UP, RSI 75-85 lima bar, MACD>0, hist>0 melebar, rvol 1-2
  if (tren === 'UP' && [0, 1, 2, 3, 4].every((q) => (rsi[t - q] ?? 0) >= 75 && (rsi[t - q] ?? 100) <= 85) && M > 0 && HS > 0 && HS > (hist[t - 1] ?? Infinity) && RV >= 1 && RV <= 2) out.push('B5');
  // B6 bendera [H]: naik >= 3 ATR dalam 10 bar berakhir di t-q (q 5..15), lalu q bar sideways (rentang <= 2 ATR), rv5<0.7, RSI 50-62, hist>0 memudar, MACD>0
  if (nn(rv5) && (rv5 as number) < 0.7 && R >= 50 && R <= 62 && HS > 0 && F.fadeState[t] && M > 0) {
    for (let q = 5; q <= 15; q++) {
      const e = t - q; if (e < 11 || atr[e] === null) continue;
      const base = Math.min(...c.slice(e - 10, e));
      if (c[e] - base < 3 * (atr[e] as number)) continue;
      const hi = Math.max(...h.slice(e + 1, t + 1)), lo = Math.min(...l.slice(e + 1, t + 1));
      if (hi - lo <= 2 * A) { out.push('B6'); break; }
    }
  }
  // C1: pos60>=0.9, naik 60 bar >= 30%, rvol>=3, spread>=1.5, clv<=0.5, rsiMax5>=80
  if (nn(pos60, F.ret60[t], spread, clv, rsiMax5) && (pos60 as number) >= 0.9 && (F.ret60[t] as number) >= 0.3 && RV >= 3 && (spread as number) >= 1.5 && (clv as number) <= 0.5 && (rsiMax5 as number) >= 80) out.push('C1');
  // C2 [H]: tren naik 20 bar lalu, rentang 20 bar <= 4 ATR, pos60>0.6, udv10<0.8, hari naik bervolume kecil
  if (F.tren[t - 20] === 'UP' && nn(pos60, udv10) && (pos60 as number) > 0.6 && (udv10 as number) < 0.8 && dC > 0 && RV < 0.8) {
    const hi = Math.max(...h.slice(t - 19, t + 1)), lo = Math.min(...l.slice(t - 19, t + 1));
    if (hi - lo <= 4 * A) out.push('C2');
  }
  // C3: divBear, RSI high pertama >= 70, hist dan rvol di high kedua lebih kecil
  const kk = F.divK[t];
  if (F.divBear[t] && kk >= 0 && nn(rsi[kk], hist[kk], rvol[kk]) && (rsi[kk] as number) >= 70 && HS < (hist[kk] as number) && RV < (rvol[kk] as number)) out.push('C3');
  // C5: pos60>0.8, rvol>=2, |dC|<0.3 ATR, spread<=0.8
  if (nn(pos60, spread) && (pos60 as number) > 0.8 && RV >= 2 && Math.abs(dC) < 0.3 * A && (spread as number) <= 0.8) out.push('C5');
  // C6: pos60>0.8, move5>=1, rv5<0.7, RSI 60-72 dan < RSI di high 60 bar sebelumnya
  if (nn(pos60, move5, rv5) && (pos60 as number) > 0.8 && (move5 as number) >= 1 && (rv5 as number) < 0.7 && R >= 60 && R <= 72) {
    let ih = t - 60; for (let q = t - 60; q < t - 4; q++) if (h[q] > h[ih]) ih = q;
    if (nn(rsi[ih]) && R < (rsi[ih] as number)) out.push('C6');
  }
  // C7: 3 bar naik >= 1 ATR, rvol naik tiap bar, RSI >= 85
  if ([0, 1, 2].every((q) => c[t - q] - c[t - q - 1] >= (atr[t - q] ?? Infinity)) && RV > (rvol[t - 1] ?? Infinity) && (rvol[t - 1] ?? 0) > (rvol[t - 2] ?? Infinity) && R >= 85) out.push('C7');
  // C8: crossDn, MACD>0, rsiMax5>=80, hist positif memudar sebelum cross
  if (F.crossDn[t] && M > 0 && nn(rsiMax5, hist[t - 1], hist[t - 2]) && (rsiMax5 as number) >= 80 && (hist[t - 1] as number) > 0 && (hist[t - 1] as number) < (hist[t - 2] as number)) {
    out.push(tren === 'UP' ? 'C8-UP' : 'C8-OTHER');
  }
  // D1: close < low 60 bar sebelumnya, rvol>=2, clv<=0.3, MACD<0
  if (nn(F.lo60p[t], clv) && c[t] < (F.lo60p[t] as number) && RV >= 2 && (clv as number) <= 0.3 && M < 0) out.push('D1');
  // D2: tren DOWN, move5>=1, rv5<0.8, RSI 50-62 dan turun dari kemarin, MACD<0
  if (tren === 'DOWN' && nn(move5, rv5, rsi[t - 1]) && (move5 as number) >= 1 && (rv5 as number) < 0.8 && R >= 50 && R <= 62 && R < (rsi[t - 1] as number) && M < 0) out.push('D2');
  // D3: RSI<30 >= 8 dari 10 bar, hist<0 melebar, udv10<0.6, clv<0.3
  if (nn(udv10, clv, hist[t - 1]) && [...Array(10).keys()].filter((q) => (rsi[t - q] ?? 100) < 30).length >= 8 && HS < 0 && HS < (hist[t - 1] as number) && (udv10 as number) < 0.6 && (clv as number) < 0.3) out.push('D3');
  // D4: tren DOWN, move5<=-1, rv5<0.7
  if (tren === 'DOWN' && nn(move5, rv5) && (move5 as number) <= -1 && (rv5 as number) < 0.7) out.push('D4');
  // D5 [H]: gap turun >= 1 ATR dengan rvol>=2 di t-q (q 1..3), lalu q bar naik dengan rvol menyusut, gap belum tertutup
  for (let q = 1; q <= 3; q++) {
    const gq = t - q; if (gq < 2 || atr[gq - 1] === null) continue;
    if (!(o[gq] <= c[gq - 1] - (atr[gq - 1] as number) && (rvol[gq] ?? 0) >= 2)) continue;
    let ok = true;
    for (let u = gq + 1; u <= t; u++) if (!(c[u] > c[u - 1] && (rvol[u] ?? Infinity) < (rvol[u - 1] ?? 0))) ok = false;
    if (ok && Math.max(...h.slice(gq, t + 1)) < c[gq - 1]) { out.push('D5'); break; }
  }
  // E1 [H]: ATR% di persentil <= 10% dari 120 bar, rv5<0.6, RSI 45-55, |MACD%|<0.5%
  if (nn(F.atrRank120[t], rv5) && (F.atrRank120[t] as number) <= 0.1 && (rv5 as number) < 0.6 && R >= 45 && R <= 55 && Math.abs(M / c[t]) < 0.005) out.push('E1');
  // E2: kemarin..3 hari lalu close tembus high 60 bar dengan rvol<1, hari ini close kembali di bawah level itu (pertama kali)
  for (let q = 1; q <= 3; q++) {
    const e = t - q; if (F.hi60p[e] === null) continue;
    const lvl = F.hi60p[e] as number;
    if (c[e] > lvl && (rvol[e] ?? 9) < 1 && c[t] < lvl && c.slice(e + 1, t).every((x) => x >= lvl)) { out.push('E2'); break; }
  }
  // E3: pos60<0.25, rvol>=2, harga turun < 0.3 ATR, clv>=0.5
  if (nn(pos60, clv) && (pos60 as number) < 0.25 && RV >= 2 && dC <= 0 && -dC < 0.3 * A && (clv as number) >= 0.5) out.push('E3');
  // E4: crossUp saat whipsaw (>= 3 persilangan dalam 20 bar) vs tidak
  if (F.crossUp[t]) out.push(F.crosses20[t] >= 3 ? 'E4-cross' : 'E4-cross-clean');
  // E5: StochRSI K memotong D ke atas di bawah 20, RSI 40-50, tren SIDE
  if (tren === 'SIDE' && nn(F.srK[t], F.srD[t], F.srK[t - 1], F.srD[t - 1]) && (F.srK[t - 1] as number) <= (F.srD[t - 1] as number) && (F.srK[t] as number) > (F.srD[t] as number) && (F.srK[t] as number) < 20 && R >= 40 && R <= 50) out.push('E5');
  // F1: RSI<30, udv10<0.6, clv<0.3
  if (R < 30 && nn(udv10, clv) && (udv10 as number) < 0.6 && (clv as number) < 0.3) out.push('F1');
  // F3: fadeState, hist<0, macdSlope<0 (bar pertama keadaan ini)
  if (F.fadeState[t] && HS < 0 && (F.macdSlope[t] ?? 0) < 0 && !(F.fadeState[t - 1] && (hist[t - 1] ?? 0) < 0 && (F.macdSlope[t - 1] ?? 0) < 0)) out.push('F3');
  // H1 Moving Momentum (ChartSchool): SMA20 vs SMA150, Stochastic harga <20 (>80) dalam 5 bar, histogram berubah positif (negatif)
  if (nn(F.sma20[t], F.sma150[t], hist[t - 1])) {
    const st5 = [0, 1, 2, 3, 4].map((q) => F.stoch[t - q] ?? 50);
    if ((F.sma20[t] as number) > (F.sma150[t] as number) && Math.min(...st5) < 20 && (hist[t - 1] as number) <= 0 && HS > 0) out.push('H1-buy');
    if ((F.sma20[t] as number) < (F.sma150[t] as number) && Math.max(...st5) > 80 && (hist[t - 1] as number) >= 0 && HS < 0) out.push('H1-sell');
  }
  // H2: golden/death cross SMA50/200; zona SMA200 [H]: tren UP-ish (SMA200 naik 20 bar), close 0..3% di atas SMA200
  if (nn(F.sma50[t], F.sma200[t], F.sma50[t - 1], F.sma200[t - 1])) {
    const a50 = F.sma50[t] as number, a200 = F.sma200[t] as number, p50 = F.sma50[t - 1] as number, p200 = F.sma200[t - 1] as number;
    if (p50 <= p200 && a50 > a200) out.push('H2-golden');
    if (p50 >= p200 && a50 < a200) out.push('H2-death');
    const z0 = c[t] / a200 - 1, z1 = c[t - 1] / p200 - 1;
    if (nn(F.sma200[t - 20]) && a200 > (F.sma200[t - 20] as number) && z0 >= 0 && z0 < 0.03 && !(z1 >= 0 && z1 < 0.03)) out.push('H2-sma200zone');
  }
  // H3/H4 candlestick (dalam tren turun/naik versi EMA20 sumber)
  const cd = candles(F, t);
  if (cd.hammer) out.push('H3-hammer');
  if (cd.bEng) out.push('H3-engulf');
  if (cd.pierce) out.push('H3-piercing');
  if (cd.mstar) out.push('H3-mstar');
  if (cd.bHar) out.push('H3-harami');
  if (cd.star) out.push('H4-star');
  if (cd.sEng) out.push('H4-engulf');
  if (cd.dark) out.push('H4-darkcloud');
  if (cd.estar) out.push('H4-estar');
  if (cd.sHar) out.push('H4-harami');
  // H5
  const bull = cd.hammer || cd.bEng;
  if (bull && c[t] < (F.ema20[t] ?? -Infinity) && nn(rsiMin5) && (rsiMin5 as number) <= 30 && RV >= 1.5 &&
    ((F.sma200[t] !== null && Math.abs(l[t] / (F.sma200[t] as number) - 1) <= 0.03) || (F.lo60p[t] !== null && Math.abs(l[t] / (F.lo60p[t] as number) - 1) <= 0.03))) out.push('H5a');
  if (bull && HS < 0 && hist[t - 1] !== null && Math.abs(HS) > Math.abs(hist[t - 1] as number)) out.push('H5b');
  if (cd.bEng && RV < 0.8) out.push('H5c');
  if ((cd.star || cd.sEng) && nn(pos60, udv10) && (pos60 as number) >= 0.9 && F.divBear[t] && (udv10 as number) < 0.8) out.push('H5d');
  // ---- file lanjutan
  const kd = F.divK[t];
  if (tren === 'DOWN' && kd >= 0 && nn(rsi[kd]) && h[t] === Math.max(...h.slice(t - 4, t + 1)) && h[t] < h[kd] && R > (rsi[kd] as number) + 3 && R >= 50 && R <= 70) out.push('X-H2negRev');
  { let mx = -1; for (let q = t - 60; q < t; q++) mx = Math.max(mx, rsi[q] ?? 100); if (mx <= 60 && R >= 65 && RV >= 1.5) out.push('X-H4regime'); }
  if ((macd[t - 1] ?? 1) <= 0 && M > 0 && RV >= 1.5 && c[t] > (F.sma50[t] ?? Infinity) && F.zeroCross60[t] <= 2) out.push('X-I1zero');
  if (M < 0 && F.impulse[t] === 'G' && F.impulse[t - 1] !== 'G' && R >= 25 && R <= 40) out.push('X-I7impulseG');
  if (tren === 'UP' && F.impulse[t] === 'R' && F.impulse[t - 1] !== 'R') out.push('X-I8impulseR');
  { let mc = Infinity, mo = Infinity; for (let q = t - 20; q < t; q++) { mc = Math.min(mc, c[q]); mo = Math.min(mo, F.obv[q]); } if (c[t] < mc && F.obv[t] > mo) out.push('X-J1obvDiv'); }
  if (nn(pos60) && (pos60 as number) < 0.25 && [...Array(7).keys()].filter((q) => (rvol[t - q] ?? 9) < 0.5).length >= 5) out.push('X-J5dry');
  if (l[t] > h[t - 1] && RV >= 2 && ((F.dd60[t - 1] ?? 0) <= -0.2 || sw !== null)) out.push('X-L1gapUp');
  if (tren === 'UP' && nn(F.sma50[t], rv5) && Math.abs(l[t] / (F.sma50[t] as number) - 1) <= 0.01 && (rv5 as number) < 0.8 && R >= 40 && R <= 50) {
    const body = Math.abs(c[t] - o[t]), lw = Math.min(o[t], c[t]) - l[t], uw = h[t] - Math.max(o[t], c[t]);
    if ((lw >= 2 * body && uw <= body) || F.impulse[t] !== 'R') out.push('X-M1sma50');
  }
  if (nn(F.sma50[t])) { const ds = c[t] / (F.sma50[t] as number) - 1; if (ds > 0.2 && R >= 80) out.push('X-M3hi'); if (ds < -0.2 && R <= 20) out.push('X-M3lo'); }
  if (nn(F.ema65[t], F.srK[t], F.srK[t - 1], rsi[t - 1])) {
    const os = (i: number) => (F.srK[i] as number) < 20 || ((rsi[i] as number) >= 30 && (rsi[i] as number) <= 45);
    if (os(t) && !os(t - 1)) out.push(c[t] > (F.ema65[t] as number) ? 'X-N1' : 'X-N2');
  }
  // grid 27: tren x harga 5 bar x volume 5 bar
  if (tren && nn(move5, rv5)) {
    const pr = (move5 as number) >= 1 ? 'up' : (move5 as number) <= -1 ? 'dn' : 'flat';
    const vo = (rv5 as number) < 0.8 ? 'low' : (rv5 as number) > 1.5 ? 'high' : 'norm';
    out.push(`G-${tren}-${pr}-${vo}` as Scen);
  }
  void ihsg;
  return out;
}

// ---------------------------------------------------------------- statistik

type Ev = { t: number; fold: number; month: string; net: number; ex: number; y: number; yEx: number; absRet: number; ihsg: string | null };

export function clusterT(xs: { v: number; g: string }[]) {
  const n = xs.length;
  if (n < 2) return { mean: n ? xs[0].v : null, se: null, t: null, p: null, clusters: n };
  const mean = xs.reduce((a, x) => a + x.v, 0) / n;
  const by = new Map<string, number>();
  for (const x of xs) by.set(x.g, (by.get(x.g) ?? 0) + (x.v - mean));
  const G = by.size;
  if (G < 2) return { mean, se: null, t: null, p: null, clusters: G };
  let s = 0; for (const e of by.values()) s += e * e;
  const se = Math.sqrt((s / (n * n)) * (G / (G - 1)));
  const t = se > 0 ? mean / se : 0;
  return { mean, se, t, p: 2 * (1 - phi(Math.abs(t))), clusters: G };
}
function phi(x: number) { // CDF normal standar (Abramowitz-Stegun 26.2.17)
  const k = 1 / (1 + 0.2316419 * x);
  const p = 0.3989423 * Math.exp(-x * x / 2) * k * (0.3193815 + k * (-0.3565638 + k * (1.781478 + k * (-1.821256 + k * 1.330274))));
  return 1 - p;
}
export const r4 = (v: number | null | undefined) => (v === null || v === undefined || !Number.isFinite(v) ? null : Math.round(v * 1e4) / 1e4);
export const mean = (a: number[]) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : null);

function summarize(evs: Ev[]) {
  const ex = clusterT(evs.map((e) => ({ v: e.ex, g: e.month })));
  const yx = clusterT(evs.map((e) => ({ v: e.yEx, g: e.month })));
  return {
    n: evs.length,
    clusters: ex.clusters,
    meanNet: r4(mean(evs.map((e) => e.net))),
    winRate: r4(mean(evs.map((e) => (e.net > 0 ? 1 : 0)))),
    meanExcess: r4(ex.mean), tExcess: r4(ex.t), pExcess: r4(ex.p),
    hitRate: r4(mean(evs.map((e) => e.y))),
    hitExcessVsVol: r4(yx.mean), tHit: r4(yx.t),
    meanAbsRetExcess: r4(mean(evs.map((e) => e.absRet))),
  };
}

function spearman(x: number[], y: number[]) {
  const rk = (a: number[]) => { const s = a.map((v, i) => [v, i]).sort((p, q) => p[0] - q[0]); const r = new Array(a.length); s.forEach(([, i], k) => (r[i] = k)); return r; };
  const rx = rk(x), ry = rk(y), n = x.length;
  if (n < 3) return null;
  let d = 0; for (let i = 0; i < n; i++) d += (rx[i] - ry[i]) ** 2;
  return 1 - (6 * d) / (n * (n * n - 1));
}

// ---------------------------------------------------------------- utama

export function study(all: Series[], ihsgSeries: Series | undefined, opts: { holdoutFrac?: number; devFolds?: number; minN?: number; q?: number } = {}) {
  const holdoutFrac = opts.holdoutFrac ?? 0.2, devFolds = opts.devFolds ?? 4, minN = opts.minN ?? 100, Q = opts.q ?? 0.1;
  // tren IHSG per tanggal
  const ihsgTren = new Map<string, string | null>();
  if (ihsgSeries) { const FI = features(ihsgSeries); FI.date.forEach((d, i) => ihsgTren.set(d, FI.tren[i])); }

  // 1) fitur + hasil per saham-hari
  type Obs = { tk: number; t: number; date: string; net: number; y: number; absRet: number; vol: number; flags: Scen[]; cross?: { rsiMin5: number; tren: string | null; above200: boolean; macdRank: number | null } };
  const obs: Obs[] = [];
  let droppedLiq = 0, droppedJump = 0;
  all.forEach((s, tk) => {
    const F = features(s);
    const st = { lastA1: -1, a2Done: -1 };
    const jumpPre = new Int32Array(F.n + 1); // jumlah hari bergerak > 50% s.d. indeks i-1
    for (let q = 0; q < F.n; q++) jumpPre[q + 1] = jumpPre[q] + (q > 0 && Math.abs(Math.log(F.c[q] / F.c[q - 1])) > MAX_DAY_MOVE ? 1 : 0);
    for (let t = 61; t < F.n; t++) {
      const fl = flags(F, t, ihsgTren.get(F.date[t]) ?? null, st);
      if (F.tren[t] === null) continue; // butuh >= 200 bar
      if (t + H >= F.n) continue;
      if ((F.val20[t] ?? 0) < MIN_VALUE_IDR) { droppedLiq++; continue; }
      if (jumpPre[t + H + 1] - jumpPre[Math.max(0, t - 59)] > 0) { droppedJump++; continue; }
      const entry = F.o[t + 1];
      if (!(entry > 0) || F.vol20[t] === null) continue;
      const net = F.c[t + H] / entry - 1 - COST;
      const sigma = F.vol20[t] as number;
      const w = sigma * Math.sqrt(H), up = F.c[t] * Math.exp(w), lo = F.c[t] * Math.exp(-w);
      let y = 0;
      for (let q = t + 1; q <= t + H; q++) { if (F.l[q] <= lo) break; if (F.h[q] >= up) { y = 1; break; } }
      const o: Obs = { tk, t, date: F.date[t], net, y, absRet: Math.abs(F.c[t + H] / F.c[t] - 1), vol: sigma, flags: fl };
      if (F.crossUp[t] && (F.macd[t] as number) < 0 && F.rsiMin5[t] !== null) {
        o.cross = { rsiMin5: F.rsiMin5[t] as number, tren: F.tren[t], above200: F.c[t] > (F.sma200[t] as number), macdRank: F.macdRank250[t] };
      }
      obs.push(o);
    }
  });

  // 2) tanggal, fold, holdout (jeda H hari sebelum holdout)
  const byDate = new Map<string, Obs[]>();
  for (const x of obs) { const a = byDate.get(x.date) ?? []; a.push(x); byDate.set(x.date, a); }
  const dates = [...byDate.keys()].filter((d) => (byDate.get(d) as Obs[]).length >= 20).sort();
  const okDate = new Set(dates);
  const nd = dates.length;
  const hoStart = Math.floor(nd * (1 - holdoutFrac));
  const devEnd = hoStart - H - 1; // jeda
  const foldOf = new Map<string, number>();
  dates.forEach((d, i) => foldOf.set(d, i >= hoStart ? devFolds : i <= devEnd ? Math.min(devFolds - 1, Math.floor((i / (devEnd + 1)) * devFolds)) : -1));

  // 3) pembanding per tanggal: rata-rata net (equal-weight) dan base rate y per desil volatilitas
  const ewNet = new Map<string, number>(), ewAbs = new Map<string, number>();
  for (const d of dates) { const a = byDate.get(d) as Obs[]; ewNet.set(d, mean(a.map((x) => x.net)) as number); ewAbs.set(d, mean(a.map((x) => x.absRet)) as number); }
  // desil vol20 per fold (dihitung di semua observasi fold itu)
  const yByVolDec = new Map<string, number>(); // `${fold}:${dec}`
  const volDec = new Map<Obs, number>();
  for (let f = 0; f <= devFolds; f++) {
    const a = obs.filter((x) => okDate.has(x.date) && foldOf.get(x.date) === f).sort((p, q) => p.vol - q.vol);
    const sums = new Array(10).fill(0), cnt = new Array(10).fill(0);
    a.forEach((x, i) => { const dd = Math.min(9, Math.floor((i / a.length) * 10)); volDec.set(x, dd); sums[dd] += x.y; cnt[dd]++; });
    for (let dd = 0; dd < 10; dd++) yByVolDec.set(`${f}:${dd}`, cnt[dd] ? sums[dd] / cnt[dd] : 0);
  }
  const mkEv = (x: Obs): Ev => {
    const f = foldOf.get(x.date) as number;
    return { t: x.t, fold: f, month: x.date.slice(0, 7), net: x.net, ex: x.net - (ewNet.get(x.date) as number), y: x.y, yEx: x.y - (yByVolDec.get(`${f}:${volDec.get(x) ?? 0}`) as number), absRet: x.absRet - (ewAbs.get(x.date) as number), ihsg: ihsgTren.get(x.date) ?? null };
  };

  // 4) kejadian per skenario. Skenario yang terpicu beruntun di saham yang sama: hanya bar pertama dalam 5 hari (kurangi tumpang tindih)
  const evs = new Map<Scen, Ev[]>();
  const lastFire = new Map<string, number>();
  for (const x of obs) {
    if (!okDate.has(x.date) || foldOf.get(x.date) === -1) continue;
    for (const sc of x.flags) {
      const key = `${sc}|${x.tk}`;
      const lf = lastFire.get(key);
      lastFire.set(key, x.t);
      if (lf !== undefined && x.t - lf <= 5) continue;
      const a = evs.get(sc) ?? []; a.push(mkEv(x)); evs.set(sc, a);
    }
  }

  // 5) ringkasan dev, per fold, holdout; BH di dev untuk skenario n>=minN
  const rows = SCEN.map((sc) => {
    const a = evs.get(sc) ?? [];
    const dev = a.filter((e) => e.fold >= 0 && e.fold < devFolds), ho = a.filter((e) => e.fold === devFolds);
    const perFold = [...Array(devFolds).keys()].map((f) => { const z = dev.filter((e) => e.fold === f); return { n: z.length, meanExcess: r4(mean(z.map((e) => e.ex))) }; });
    const dS = summarize(dev);
    const sameSign = perFold.filter((p) => p.n > 0 && p.meanExcess !== null && dS.meanExcess !== null && Math.sign(p.meanExcess) === Math.sign(dS.meanExcess)).length;
    const byIhsg = Object.fromEntries(['UP', 'SIDE', 'DOWN'].map((k) => { const z = dev.filter((e) => e.ihsg === k); return [k, { n: z.length, meanNet: r4(mean(z.map((e) => e.net))), meanExcess: r4(mean(z.map((e) => e.ex))) }]; }));
    return { scen: sc, tested: dev.length >= minN, dev: dS, foldsSameSign: sameSign, perFold, holdout: summarize(ho), byIhsg };
  });
  const tested = rows.filter((r) => r.tested && r.dev.pExcess !== null).sort((p, q) => (p.dev.pExcess as number) - (q.dev.pExcess as number));
  const m = tested.length;
  // Benjamini-Hochberg pada pExcess
  let kMax = 0;
  tested.forEach((r, i) => { if ((r.dev.pExcess as number) <= ((i + 1) / m) * Q) kMax = i + 1; });
  const bhPass = new Set(tested.slice(0, kMax).map((r) => r.scen));
  const qv = new Map<string, number>();
  { let prev = 1; for (let i = m - 1; i >= 0; i--) { prev = Math.min(prev, ((tested[i].dev.pExcess as number) * m) / (i + 1)); qv.set(tested[i].scen, prev); } }
  const out = rows.map((r) => ({ ...r, qBH: r4(qv.get(r.scen) ?? null), bhPass: bhPass.has(r.scen) }));

  // 6) pertanyaan inti: semua crossUp dengan MACD<0, bin rsiMin5, per cabang tren dan per fold
  const crossEv = obs.filter((x) => x.cross && okDate.has(x.date) && foldOf.get(x.date) !== -1);
  const branch = (x: Obs) => (x.cross!.tren === 'DOWN' ? 'DOWN' : x.cross!.tren === 'UP' || x.cross!.above200 ? 'UP' : 'SIDE');
  const bins = [[-1, 20], [20, 30], [30, 40], [40, 50], [50, 101]] as const;
  const binOf = (r: number) => bins.findIndex(([a, b]) => r > a && r <= b);
  const rsiTable: Record<string, unknown> = {};
  for (const br of ['ALL', 'DOWN', 'UP', 'SIDE']) {
    const z = crossEv.filter((x) => br === 'ALL' || branch(x) === br);
    rsiTable[br] = bins.map((bn, bi) => {
      const zz = z.filter((x) => binOf(x.cross!.rsiMin5) === bi).map(mkEv);
      const dev = zz.filter((e) => e.fold < devFolds), ho = zz.filter((e) => e.fold === devFolds);
      return { bin: `${bn[0] < 0 ? 0 : bn[0]}-${bn[1] > 100 ? 100 : bn[1]}`, dev: summarize(dev), perFold: [...Array(devFolds).keys()].map((f) => { const q = dev.filter((e) => e.fold === f); return { n: q.length, meanExcess: r4(mean(q.map((e) => e.ex))) }; }), holdout: { n: ho.length, meanExcess: r4(mean(ho.map((e) => e.ex))) } };
    });
  }
  // desil rsiMin5 (dev), Spearman per fold
  const devCross = crossEv.map((x) => ({ x, e: mkEv(x) })).filter((p) => p.e.fold < devFolds).sort((p, q) => p.x.cross!.rsiMin5 - q.x.cross!.rsiMin5);
  const deciles = [...Array(10).keys()].map((dd) => {
    const z = devCross.filter((_, i) => Math.min(9, Math.floor((i / devCross.length) * 10)) === dd);
    return { decile: dd + 1, rsiMin5From: r4(z[0]?.x.cross!.rsiMin5), rsiMin5To: r4(z[z.length - 1]?.x.cross!.rsiMin5), n: z.length, meanExcess: r4(mean(z.map((p) => p.e.ex))), meanNet: r4(mean(z.map((p) => p.e.net))), hitExcessVsVol: r4(mean(z.map((p) => p.e.yEx))) };
  });
  const spearmanByFold = [...Array(devFolds).keys()].map((f) => {
    const z = devCross.filter((p) => p.e.fold === f);
    return r4(spearman(z.map((p) => p.x.cross!.rsiMin5), z.map((p) => p.e.ex)));
  });
  // A4-DOWN vs A4-UP: selisih rata-rata excess dengan SE gabungan (klaster bulan per grup)
  const sd = (sc: Scen) => { const a = (evs.get(sc) ?? []).filter((e) => e.fold < devFolds); return clusterT(a.map((e) => ({ v: e.ex, g: e.month }))); };
  const dn = sd('A4-DOWN'), upx = sd('A4-UP');
  const diff = dn.mean !== null && upx.mean !== null ? dn.mean - upx.mean : null;
  const seD = dn.se !== null && upx.se !== null ? Math.sqrt(dn.se ** 2 + upx.se ** 2) : null;

  // pembanding tanpa kondisi
  const allDev = obs.filter((x) => okDate.has(x.date) && (foldOf.get(x.date) as number) >= 0 && (foldOf.get(x.date) as number) < devFolds);
  const allHo = obs.filter((x) => okDate.has(x.date) && foldOf.get(x.date) === devFolds);
  return {
    data: {
      stocks: all.length, obsUsed: obs.length, droppedLowLiquidity: droppedLiq, droppedJump,
      firstDate: dates[0], lastDate: dates[nd - 1], nDates: nd,
      folds: [...Array(devFolds + 1).keys()].map((f) => { const ds = dates.filter((d) => foldOf.get(d) === f); return { fold: f === devFolds ? 'holdout' : f, from: ds[0], to: ds[ds.length - 1], days: ds.length }; }),
      uncond: { dev: { n: allDev.length, meanNet: r4(mean(allDev.map((x) => x.net))), winRate: r4(mean(allDev.map((x) => (x.net > 0 ? 1 : 0)))), hitRate: r4(mean(allDev.map((x) => x.y))) },
        holdout: { n: allHo.length, meanNet: r4(mean(allHo.map((x) => x.net))), winRate: r4(mean(allHo.map((x) => (x.net > 0 ? 1 : 0)))), hitRate: r4(mean(allHo.map((x) => x.y))) } },
    },
    scenariosDefined: SCEN.length, scenariosTested: m, bhQ: Q, minN,
    scenarios: out,
    core: {
      a4DownMinusUp: { diff: r4(diff), se: r4(seD), t: r4(diff !== null && seD ? diff / seD : null) },
      rsiBins: rsiTable, rsiDeciles: deciles, spearmanByFold,
    },
  };
}
