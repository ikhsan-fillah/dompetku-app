// Uji lab ranking momentum antar saham. Murni TypeScript (bisa diuji dengan Node).
// Tidak ada model yang dilatih: sinyal = imbal hasil L hari terakhir, portofolio = 20% saham teratas
// (sama bobot) ditahan H hari, dibanding rata-rata semua saham (bobot sama, tanpa biaya).
//
// Kriteria lulus ditetapkan SEBELUM hasil dilihat (7 Nov 2026). Satu konfigurasi (L, H) lulus bila:
//  A. selisih bersih (setelah biaya 0,4% tiap pergantian) > 0 di >= 4 dari 5 blok waktu
//  B. t-stat selisih bersih (deret tanpa tumpang tindih, offset 0) >= 2,8   (koreksi 9 konfigurasi)
//  C. rata-rata rank IC > 0 di >= 4 dari 5 blok
//  D. selisih bersih rata-rata > 0 di keempat offset tanggal mulai
// Verdict "lulus" hanya bila ada konfigurasi yang memenuhi A, B, C, dan D sekaligus.

type Bar = { date: string; open: number; high: number; low: number; close: number; volume: number };
export type Series = { ticker: string; bars: Bar[] };

export const FORM = [20, 60, 120] as const;
export const HOLD = [20, 40, 60] as const;
export const COST = 0.004; // pulang-pergi, dianggap berganti penuh tiap rebalance (konservatif)
export const TOP_FRAC = 0.2;
export const OFFSETS = 4;
export const BLOCKS = 5;
export const T_MIN = 2.8;

export type Panel = { dates: string[]; tickers: string[]; close: Float64Array[] };

/** Susun matriks penutupan [saham][hari]; hari kalender = tanggal yang dimiliki >= 50% saham. */
export function buildPanel(series: Series[]): Panel {
  const cnt = new Map<string, number>();
  for (const s of series) for (const b of s.bars) cnt.set(b.date, (cnt.get(b.date) ?? 0) + 1);
  const need = series.length * 0.5;
  const dates = [...cnt.entries()].filter(([, c]) => c >= need).map(([d]) => d).sort();
  const idx = new Map(dates.map((d, i) => [d, i]));
  const close = series.map((s) => {
    const a = new Float64Array(dates.length).fill(NaN);
    for (const b of s.bars) {
      const i = idx.get(b.date);
      if (i !== undefined && b.close > 0) a[i] = b.close;
    }
    return a;
  });
  return { dates, tickers: series.map((s) => s.ticker), close };
}

function ranks(v: number[]): number[] {
  const o = v.map((_, i) => i).sort((a, b) => v[a] - v[b]);
  const r = new Array<number>(v.length);
  for (let i = 0; i < o.length;) {
    let j = i;
    while (j + 1 < o.length && v[o[j + 1]] === v[o[i]]) j++;
    const avg = (i + j) / 2 + 1;
    for (let k = i; k <= j; k++) r[o[k]] = avg;
    i = j + 1;
  }
  return r;
}

export function spearman(a: number[], b: number[]): number {
  const ra = ranks(a), rb = ranks(b);
  const n = a.length;
  const ma = ra.reduce((s, x) => s + x, 0) / n, mb = rb.reduce((s, x) => s + x, 0) / n;
  let sab = 0, saa = 0, sbb = 0;
  for (let i = 0; i < n; i++) {
    sab += (ra[i] - ma) * (rb[i] - mb);
    saa += (ra[i] - ma) ** 2;
    sbb += (rb[i] - mb) ** 2;
  }
  return saa > 0 && sbb > 0 ? sab / Math.sqrt(saa * sbb) : 0;
}

export type Period = { i: number; n: number; top: number; bottom: number; ew: number; ic: number };

/** Satu periode: peringkat di hari i dari imbal hasil L hari, lalu imbal hasil maju H hari. */
export function periodAt(p: Panel, i: number, L: number, H: number): Period | null {
  const m: number[] = [], f: number[] = [];
  for (let k = 0; k < p.close.length; k++) {
    const c0 = p.close[k][i], cp = p.close[k][i - L], c1 = p.close[k][i + H];
    if (!(c0 > 0 && cp > 0 && c1 > 0)) continue;
    m.push(c0 / cp - 1);
    f.push(c1 / c0 - 1);
  }
  const n = m.length;
  if (n < 20) return null;
  const order = m.map((_, j) => j).sort((a, b) => m[b] - m[a]);
  const nt = Math.max(3, Math.round(TOP_FRAC * n));
  const mean = (ids: number[]) => ids.reduce((s, j) => s + f[j], 0) / ids.length;
  return { i, n, top: mean(order.slice(0, nt)), bottom: mean(order.slice(n - nt)), ew: mean(order), ic: spearman(m, f) };
}

const avg = (v: number[]) => (v.length ? v.reduce((s, x) => s + x, 0) / v.length : NaN);
const r4 = (v: number) => (Number.isFinite(v) ? Math.round(v * 1e4) / 1e4 : null);

export function tStat(v: number[]): number {
  const n = v.length;
  if (n < 3) return NaN;
  const m = avg(v);
  const sd = Math.sqrt(v.reduce((s, x) => s + (x - m) ** 2, 0) / (n - 1));
  return sd > 0 ? m / (sd / Math.sqrt(n)) : NaN;
}

export type RankConfig = {
  form: number;
  hold: number;
  periods: number; // jumlah periode offset 0
  netExcess: number; // rata-rata semua offset, dalam persen
  grossExcess: number;
  bottomExcess: number; // 20% terbawah minus rata-rata (kotor), diagnosis
  t: number | null;
  byOffset: (number | null)[];
  blocks: { n: number; netExcess: number | null; ic: number | null; hit: number | null }[];
  bestBlockShare: number | null; // porsi laba terbesar dari satu blok terhadap jumlah blok positif
  A: boolean;
  B: boolean;
  C: boolean;
  D: boolean;
  pass: boolean;
};

export function evalConfig(p: Panel, L: number, H: number): RankConfig {
  const N = p.dates.length;
  const first = L, last = N - 1 - H;
  const span = last - first + 1;
  const byOff: Period[][] = [];
  for (let o = 0; o < OFFSETS; o++) {
    const arr: Period[] = [];
    for (let i = first + Math.floor((o * H) / OFFSETS); i <= last; i += H) {
      const pr = periodAt(p, i, L, H);
      if (pr) arr.push(pr);
    }
    byOff.push(arr);
  }
  const net = (x: Period) => x.top - x.ew - COST;
  const all = byOff.flat();
  const blocks = Array.from({ length: BLOCKS }, (_, b) => {
    const ps = all.filter((x) => Math.min(BLOCKS - 1, Math.floor(((x.i - first) / span) * BLOCKS)) === b);
    return {
      n: ps.length,
      netExcess: ps.length ? avg(ps.map(net)) : NaN,
      ic: ps.length ? avg(ps.map((x) => x.ic)) : NaN,
      hit: ps.length ? ps.filter((x) => net(x) > 0).length / ps.length : NaN,
    };
  });
  const offMeans = byOff.map((a) => (a.length ? avg(a.map(net)) : NaN));
  const t = tStat(byOff[0].map(net));
  const A = blocks.filter((b) => b.netExcess > 0).length >= 4;
  const B = Number.isFinite(t) && t >= T_MIN;
  const C = blocks.filter((b) => b.ic > 0).length >= 4;
  const D = offMeans.every((x) => x > 0);
  const pos = blocks.map((b) => b.netExcess).filter((x) => x > 0);
  const bestShare = pos.length ? Math.max(...pos) / pos.reduce((s, x) => s + x, 0) : NaN;
  const pct = (v: number) => (Number.isFinite(v) ? r4(v * 100) : null);
  return {
    form: L,
    hold: H,
    periods: byOff[0].length,
    netExcess: r4(avg(all.map(net)) * 100)!,
    grossExcess: r4(avg(all.map((x) => x.top - x.ew)) * 100)!,
    bottomExcess: r4(avg(all.map((x) => x.bottom - x.ew)) * 100)!,
    t: r4(t),
    byOffset: offMeans.map(pct),
    blocks: blocks.map((b) => ({ n: b.n, netExcess: pct(b.netExcess), ic: r4(b.ic), hit: r4(b.hit) })),
    bestBlockShare: r4(bestShare),
    A,
    B,
    C,
    D,
    pass: A && B && C && D,
  };
}

export function evalRank(series: Series[]) {
  const p = buildPanel(series);
  const configs: RankConfig[] = [];
  for (const L of FORM) for (const H of HOLD) configs.push(evalConfig(p, L, H));
  return {
    stocks: p.tickers.length,
    days: p.dates.length,
    from: p.dates[0],
    to: p.dates[p.dates.length - 1],
    verdict: configs.some((c) => c.pass) ? 'lulus' : 'tidak lulus',
    passing: configs.filter((c) => c.pass).map((c) => `L${c.form}/H${c.hold}`),
    configs,
  };
}
