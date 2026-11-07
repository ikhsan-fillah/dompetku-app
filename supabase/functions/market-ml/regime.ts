// Uji lab kondisi pasar untuk model 10 hari (TA, triple-barrier). Murni TypeScript (bisa diuji dengan Node).
//
// Dua pertanyaan, kriteria lulus ditetapkan SEBELUM hasil dilihat (7 Nov 2026):
//  P1. Apakah model TA yang sama bagus saat pasar naik? Rezim NAIK = rata-rata return 60 hari semua saham
//      pada tanggal itu > 0. Dalam rezim NAIK, 10% skor teratas (diurutkan di dalam rezim) lulus bila:
//      (a) untung bersih > 0 (setelah biaya 0,4%) di >= 4 dari 5 fold, dan tiap fold punya >= 50 sinyal;
//      (b) untung bersih NAIK lebih besar dari rezim TURUN di >= 4 fold;
//      (c) gabungan untung bersih > rata-rata semua baris rezim NAIK, dan tetap > 0 bila fold terbaik dibuang.
//  P2. Apakah menambah fitur kondisi pasar (return 20/60 hari, lebar pasar, volatilitas pasar) memperbaiki model?
//      Lulus bila: (a) untung bersih 10% teratas model M > model dasar B di >= 4 fold, dan
//      (b) gabungan untung bersih M > 0, tetap > 0 bila fold terbaik dibuang.
// Hanya laporan (bukan kriteria): AUC, logloss, jumlah hari berbeda di sinyal teratas.

import { auc, buildRows, fitLogistic, FEATURES, predict, projectX, round, TA_FEATURES } from './lib.ts';
import type { Row, Series } from './lib.ts';

export const COST = 0.004;
export const HORIZON = 10;
export const FOLDS = 5;
export const MIN_SIGNALS = 50;
export const MARKET = ['mktRet20', 'mktRet60', 'breadth50', 'mktVol20'] as const;

export type MRow = Row & { ta: number[]; xm: number[]; up: boolean };

const idx = (n: string) => (FEATURES as readonly string[]).indexOf(n);

/** Tambahkan fitur pasar per tanggal (rata-rata lintas saham pada tanggal itu; tidak memakai data masa depan). */
export function withMarket(rows: Row[]): MRow[] {
  const i20 = idx('ret20'), i60 = idx('ret60'), iD50 = idx('distSma50'), iV = idx('vol20');
  const by = new Map<string, Row[]>();
  for (const r of rows) {
    const l = by.get(r.date) ?? [];
    l.push(r);
    by.set(r.date, l);
  }
  const mk = new Map<string, number[]>();
  for (const [d, l] of by) {
    const m = (f: (r: Row) => number) => l.reduce((s, r) => s + f(r), 0) / l.length;
    mk.set(d, [m((r) => r.x[i20]), m((r) => r.x[i60]), m((r) => (r.x[iD50] > 0 ? 1 : 0)), m((r) => r.x[iV])]);
  }
  return rows.map((r) => {
    const ta = projectX(r.x, TA_FEATURES);
    const mm = mk.get(r.date)!;
    return { ...r, ta, xm: [...ta, ...mm], up: mm[1] > 0 };
  });
}

export type Stat = { n: number; days: number; meanNet: number | null; win: number | null };

export function statOf(rs: MRow[]): Stat {
  const t = rs.filter((r) => r.holdRet !== null && r.holdRet !== undefined);
  if (!t.length) return { n: 0, days: 0, meanNet: null, win: null };
  const net = t.map((r) => (r.holdRet as number) - COST);
  return {
    n: t.length,
    days: new Set(t.map((r) => r.date)).size,
    meanNet: round((net.reduce((a, b) => a + b, 0) / t.length) * 100, 3),
    win: round(net.filter((v) => v > 0).length / t.length, 4),
  };
}

/** 10% skor tertinggi di dalam himpunan `rs` (skor p sejajar dengan rs). */
export function topShare(rs: MRow[], p: number[], frac = 0.1): MRow[] {
  const o = p.map((v, i) => [v, i] as const).sort((a, b) => b[0] - a[0]);
  return o.slice(0, Math.max(1, Math.floor(o.length * frac))).map(([, i]) => rs[i]);
}

const logloss = (p: number[], y: number[]) =>
  -p.reduce((a, v, i) => a + (y[i] ? Math.log(Math.max(v, 1e-9)) : Math.log(Math.max(1 - v, 1e-9))), 0) / p.length;

export type FoldOut = {
  fold: number;
  testStart: string;
  testEnd: string;
  nTest: number;
  upShare: number;
  B: { auc: number; all: Stat; top: Stat; up: { all: Stat; top: Stat }; down: { all: Stat; top: Stat } };
  M: { auc: number; logloss: number; loglossBase: number; top: Stat; topUpShare: number };
};

export function evalRegime(all: Series[], only?: number): FoldOut[] {
  const rows = withMarket(buildRows(all, { horizon: HORIZON, k: 1 }));
  const labeled = rows.filter((r) => r.y !== null);
  const dates = [...new Set(labeled.map((r) => r.date))].sort();
  const minTrain = Math.floor(dates.length * 0.4);
  const block = Math.floor((dates.length - minTrain) / FOLDS);
  const out: FoldOut[] = [];
  const namesM = [...TA_FEATURES, ...MARKET];
  for (let f = 0; f < FOLDS; f++) {
    if (only !== undefined && f !== only) continue;
    const ts = minTrain + f * block;
    const te_ = f === FOLDS - 1 ? dates.length - 1 : ts + block - 1;
    const trainEnd = dates[ts - HORIZON - 1];
    const tr = labeled.filter((r) => r.date <= trainEnd);
    const te = labeled.filter((r) => r.date >= dates[ts] && r.date <= dates[te_]);
    const ytr = tr.map((r) => r.y as number);
    const y = te.map((r) => r.y as number);
    const mB = fitLogistic(tr.map((r) => r.ta), ytr, 1, 4, 25, TA_FEATURES);
    const mM = fitLogistic(tr.map((r) => r.xm), ytr, 1, 4, 25, namesM);
    const pB = te.map((r) => predict(mB, r.ta));
    const pM = te.map((r) => predict(mM, r.xm));
    const base = ytr.reduce((a, b) => a + b, 0) / ytr.length;
    const part = (up: boolean) => {
      const ix = te.map((_, i) => i).filter((i) => te[i].up === up);
      const rs = ix.map((i) => te[i]);
      return { all: statOf(rs), top: rs.length ? statOf(topShare(rs, ix.map((i) => pB[i]))) : statOf([]) };
    };
    const topM = topShare(te, pM);
    out.push({
      fold: f,
      testStart: dates[ts],
      testEnd: dates[te_],
      nTest: te.length,
      upShare: round(te.filter((r) => r.up).length / te.length, 3),
      B: { auc: round(auc(pB, y)), all: statOf(te), top: statOf(topShare(te, pB)), up: part(true), down: part(false) },
      M: {
        auc: round(auc(pM, y)),
        logloss: round(logloss(pM, y)),
        loglossBase: round(logloss(pM.map(() => base), y)),
        top: statOf(topM),
        topUpShare: round(topM.filter((r) => r.up).length / topM.length, 3),
      },
    });
  }
  return out;
}

const wmean = (xs: { n: number; v: number }[]) => {
  const n = xs.reduce((a, x) => a + x.n, 0);
  return n ? xs.reduce((a, x) => a + x.n * x.v, 0) / n : NaN;
};

/** Gabungan terbobot n; `dropBest` membuang fold dengan untung bersih tertinggi. */
function pooled(items: Stat[], dropBest: boolean): number {
  const ok = items.filter((s) => s.n > 0 && s.meanNet !== null);
  const use = dropBest && ok.length > 1 ? [...ok].sort((a, b) => (b.meanNet as number) - (a.meanNet as number)).slice(1) : ok;
  return wmean(use.map((s) => ({ n: s.n, v: s.meanNet as number })));
}

export function verdict(folds: FoldOut[]) {
  const el = (s: Stat) => s.n >= MIN_SIGNALS && s.meanNet !== null;
  const p1a = folds.filter((f) => el(f.B.up.top) && (f.B.up.top.meanNet as number) > 0).length >= 4;
  const p1b = folds.filter((f) => el(f.B.up.top) && el(f.B.down.top) && (f.B.up.top.meanNet as number) > (f.B.down.top.meanNet as number)).length >= 4;
  const upTop = folds.map((f) => f.B.up.top);
  const upAll = folds.map((f) => f.B.up.all);
  const p1c = pooled(upTop, false) > pooled(upAll, false) && pooled(upTop, true) > 0;
  const p2a = folds.filter((f) => el(f.M.top) && el(f.B.top) && (f.M.top.meanNet as number) > (f.B.top.meanNet as number)).length >= 4;
  const mTop = folds.map((f) => f.M.top);
  const p2b = pooled(mTop, false) > 0 && pooled(mTop, true) > 0;
  return {
    P1: { a: p1a, b: p1b, c: p1c, lulus: p1a && p1b && p1c },
    P2: { a: p2a, b: p2b, lulus: p2a && p2b },
    gabungan: {
      B_atas_rezim_naik: round(pooled(upTop, false), 3),
      B_semua_rezim_naik: round(pooled(upAll, false), 3),
      B_atas_rezim_turun: round(pooled(folds.map((f) => f.B.down.top), false), 3),
      B_atas_semua: round(pooled(folds.map((f) => f.B.top), false), 3),
      M_atas_semua: round(pooled(mTop, false), 3),
      M_atas_tanpa_fold_terbaik: round(pooled(mTop, true), 3),
    },
  };
}
