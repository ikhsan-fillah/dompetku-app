// Studi deskriptif detektor pola chart besar: hitung deteksi per saham dan contoh titik kunci.
// Statistik hasil 10 hari hanya sebagai informasi, TANPA klaim bahwa pola memprediksi.
import type { Series } from './lib.ts';
import { features, H, COST, MIN_VALUE_IDR, MAX_DAY_MOVE, clusterT, r4, mean } from './scen.ts';
import { detectPatterns, PATTERNS, type PatName } from './patterns.ts';

export function patternStudy(all: Series[], opts: { examples?: number; holdoutFrac?: number } = {}) {
  const nEx = opts.examples ?? 4;
  type Ev = { tk: string; date: string; t: number; name: PatName; key: number[]; net: number | null; ok: boolean };
  const evs: Ev[] = [];
  const perStock: Record<string, Record<string, number>> = {};
  const exampleBars = new Map<string, { tk: string; date: string; name: PatName; key: { date: string; idx: number; h: number; l: number; c: number }[]; t: number; c: number; fwd: number | null }[]>();
  const ewSum = new Map<string, { s: number; n: number }>();
  const years: Record<string, number> = {};
  let bars = 0;
  const lastFire = new Map<string, number>();
  const dateAll: string[] = [];
  all.forEach((s) => {
    const F = features(s);
    const { events } = detectPatterns({ n: F.n, h: F.h, l: F.l, c: F.c, atrPct: F.atrPct });
    perStock[s.ticker] = {};
    bars += F.n;
    for (let t = 200; t + H < F.n; t++) {
      const entry = F.o[t + 1];
      if (!(entry > 0)) continue;
      const net = F.c[t + H] / entry - 1 - COST;
      const a = ewSum.get(F.date[t]) ?? { s: 0, n: 0 };
      a.s += net; a.n++; ewSum.set(F.date[t], a);
    }
    const jumpPre = new Int32Array(F.n + 1);
    for (let q = 0; q < F.n; q++) jumpPre[q + 1] = jumpPre[q] + (q > 0 && Math.abs(Math.log(F.c[q] / F.c[q - 1])) > MAX_DAY_MOVE ? 1 : 0);
    for (const e of events) {
      perStock[s.ticker][e.name] = (perStock[s.ticker][e.name] ?? 0) + 1;
      const t = e.t;
      let net: number | null = null, ok = false;
      if (t >= 200 && t + H < F.n && (F.val20[t] ?? 0) >= MIN_VALUE_IDR && jumpPre[t + H + 1] - jumpPre[Math.max(0, t - 59)] === 0 && F.o[t + 1] > 0) {
        net = F.c[t + H] / F.o[t + 1] - 1 - COST; ok = true;
      }
      const k = `${e.name}|${s.ticker}`;
      const lf = lastFire.get(k); lastFire.set(k, t);
      if (lf !== undefined && t - lf <= 5) ok = false; // dedup 5 hari
      evs.push({ tk: s.ticker, date: F.date[t], t, name: e.name, key: e.key, net, ok });
      const ex = exampleBars.get(e.name) ?? [];
      ex.push({ tk: s.ticker, date: F.date[t], name: e.name, t, c: F.c[t], fwd: t + H < F.n ? r4(F.c[t + H] / F.c[t] - 1) : null,
        key: e.key.map((i) => ({ date: F.date[i], idx: i, h: F.h[i], l: F.l[i], c: F.c[i] })) });
      exampleBars.set(e.name, ex);
    }
    F.date.forEach((d) => dateAll.push(d));
  });
  const dates = [...new Set(dateAll)].sort();
  const ho = dates[Math.floor(dates.length * (1 - (opts.holdoutFrac ?? 0.2)))];
  const counts: Record<string, { total: number; stocksWith: number; perStockYear: number }> = {};
  const stockYears = bars / 252;
  const stat: Record<string, unknown> = {};
  for (const p of PATTERNS) {
    const a = evs.filter((e) => e.name === p);
    counts[p] = { total: a.length, stocksWith: new Set(a.map((e) => e.tk)).size, perStockYear: r4(a.length / stockYears) as number };
    const use = a.filter((e) => e.ok && e.net !== null);
    const mk = (z: Ev[]) => {
      const xs = z.map((e) => { const w = ewSum.get(e.date); return { v: (e.net as number) - (w ? w.s / w.n : 0), g: e.date.slice(0, 7) }; });
      const c = clusterT(xs);
      return { n: z.length, meanNet: r4(mean(z.map((e) => e.net as number))), winRate: r4(mean(z.map((e) => ((e.net as number) > 0 ? 1 : 0)))), meanExcess: r4(c.mean), t: r4(c.t), p: r4(c.p) };
    };
    stat[p] = { dev: mk(use.filter((e) => e.date < ho)), holdout: mk(use.filter((e) => e.date >= ho)) };
  }
  // contoh: sebar merata di waktu (urut tanggal, ambil kuantil) bukan hasil terbaik
  const examples: Record<string, unknown[]> = {};
  for (const p of PATTERNS) {
    const a = (exampleBars.get(p) ?? []).slice().sort((x, y) => (x.date < y.date ? -1 : 1));
    const pick: typeof a = [];
    for (let i = 0; i < Math.min(nEx, a.length); i++) pick.push(a[Math.floor(((i + 0.5) * a.length) / Math.min(nEx, a.length))]);
    examples[p] = pick;
  }
  return { stocks: all.length, stockYears: r4(stockYears), holdoutFrom: ho, counts, perStock, stat, examples };
}
