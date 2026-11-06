// Gradient boosting pohon keputusan (logloss) berbasis histogram, tanpa dependensi.
// Dibuat kecil supaya muat di batas CPU Edge Function.

export type Node = { f: number; t: number; l: number; r: number; v: number }; // f = -1 berarti daun
export type GbmModel = {
  kind: 'gbm';
  features: string[];
  base: number; // log-odds awal
  lr: number;
  trees: Node[][];
};

export type GbmParams = {
  trees: number;
  depth: number;
  lr: number;
  bins: number;
  subsample: number;
  minHess: number;
  lambda: number;
  seed: number;
};

export const GBM_DEFAULT: GbmParams = {
  trees: 80,
  depth: 3,
  lr: 0.08,
  bins: 32,
  subsample: 0.3,
  minHess: 30,
  lambda: 5,
  seed: 7,
};

const sigmoid = (z: number) => 1 / (1 + Math.exp(-Math.max(-30, Math.min(30, z))));

function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

/** Batas bin per fitur dari kuantil data latih. */
function edgesOf(X: number[][], bins: number): number[][] {
  const d = X[0].length;
  const out: number[][] = [];
  const step = Math.max(1, Math.floor(X.length / 4000)); // sampel untuk kuantil
  for (let j = 0; j < d; j++) {
    const v: number[] = [];
    for (let i = 0; i < X.length; i += step) v.push(X[i][j]);
    v.sort((a, b) => a - b);
    const e: number[] = [];
    for (let b = 1; b < bins; b++) {
      const q = v[Math.floor((b / bins) * (v.length - 1))];
      if (!e.length || q > e[e.length - 1]) e.push(q);
    }
    out.push(e);
  }
  return out;
}

function binOf(x: number, e: number[]): number {
  let lo = 0;
  let hi = e.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (x <= e[mid]) hi = mid;
    else lo = mid + 1;
  }
  return lo; // 0..e.length
}

export function fitGbm(X: number[][], y: number[], names: readonly string[], p: GbmParams = GBM_DEFAULT): GbmModel {
  const n = X.length;
  const d = X[0].length;
  const edges = edgesOf(X, p.bins);
  const nb = edges.map((e) => e.length + 1);
  const maxB = Math.max(...nb);
  const B = new Uint8Array(n * d);
  for (let i = 0; i < n; i++) for (let j = 0; j < d; j++) B[i * d + j] = binOf(X[i][j], edges[j]);

  const mean = y.reduce((a, v) => a + v, 0) / n;
  const base = Math.log(Math.max(1e-6, mean) / Math.max(1e-6, 1 - mean));
  const F = new Float64Array(n).fill(base);
  const Y = Float64Array.from(y);
  const g = new Float64Array(n);
  const h = new Float64Array(n);
  const node = new Int32Array(n); // node tiap baris sampel (urut naik supaya ramah cache)
  const sample = new Int32Array(n);
  const rand = rng(p.seed);
  const trees: Node[][] = [];
  const slotsMax = 1 << (p.depth - 1);
  const HG = new Float64Array(slotsMax * d * maxB);
  const HH = new Float64Array(slotsMax * d * maxB);

  for (let m = 0; m < p.trees; m++) {
    let ns = 0;
    for (let i = 0; i < n; i++) {
      if (rand() < p.subsample) {
        const pr = 1 / (1 + Math.exp(-F[i]));
        g[i] = pr - Y[i];
        h[i] = Math.max(1e-6, pr * (1 - pr));
        node[i] = 0;
        sample[ns++] = i;
      }
    }
    const tree: Node[] = [{ f: -1, t: 0, l: -1, r: -1, v: 0 }];
    const bins: number[] = [-1];
    let frontier = [0];
    for (let depth = 0; depth < p.depth && frontier.length; depth++) {
      const slot = new Map<number, number>();
      frontier.forEach((nd, k) => slot.set(nd, k));
      const S = frontier.length;
      const sz = d * maxB;
      HG.fill(0, 0, S * sz);
      HH.fill(0, 0, S * sz);
      const GS = new Float64Array(S);
      const HS = new Float64Array(S);
      const slotOf = new Int32Array(tree.length).fill(-1);
      for (const [nd, k] of slot) slotOf[nd] = k;
      for (let q = 0; q < ns; q++) {
        const i = sample[q];
        const k = slotOf[node[i]];
        if (k < 0) continue;
        const gi = g[i];
        const hi = h[i];
        GS[k] += gi;
        HS[k] += hi;
        const o = i * d;
        const base2 = k * sz;
        for (let j = 0; j < d; j++) {
          const idx = base2 + j * maxB + B[o + j];
          HG[idx] += gi;
          HH[idx] += hi;
        }
      }
      const next: number[] = [];
      const splitF = new Int32Array(tree.length).fill(-1);
      const splitB = new Int32Array(tree.length);
      const leftOf = new Int32Array(tree.length);
      for (let k = 0; k < S; k++) {
        const nd = frontier[k];
        const G = GS[k];
        const H = HS[k];
        tree[nd].v = -G / (H + p.lambda);
        if (H < 2 * p.minHess) continue;
        const parent = (G * G) / (H + p.lambda);
        let best = 0;
        let bf = -1;
        let bb = -1;
        for (let j = 0; j < d; j++) {
          let gl = 0;
          let hl = 0;
          const o = k * sz + j * maxB;
          for (let b = 0; b < nb[j] - 1; b++) {
            gl += HG[o + b];
            hl += HH[o + b];
            const hr = H - hl;
            if (hl < p.minHess || hr < p.minHess) continue;
            const gr = G - gl;
            const gain = (gl * gl) / (hl + p.lambda) + (gr * gr) / (hr + p.lambda) - parent;
            if (gain > best) {
              best = gain;
              bf = j;
              bb = b;
            }
          }
        }
        if (bf < 0) continue;
        const l = tree.length;
        tree.push({ f: -1, t: 0, l: -1, r: -1, v: 0 }, { f: -1, t: 0, l: -1, r: -1, v: 0 });
        bins.push(-1, -1);
        tree[nd].f = bf;
        tree[nd].t = edges[bf][bb];
        tree[nd].l = l;
        tree[nd].r = l + 1;
        bins[nd] = bb;
        splitF[nd] = bf;
        splitB[nd] = bb;
        leftOf[nd] = l;
        next.push(l, l + 1);
      }
      for (let q = 0; q < ns; q++) {
        const i = sample[q];
        const nd = node[i];
        if (nd < splitF.length && splitF[nd] >= 0) node[i] = B[i * d + splitF[nd]] <= splitB[nd] ? leftOf[nd] : leftOf[nd] + 1;
      }
      frontier = next;
    }
    // daun di kedalaman maksimum
    if (frontier.length) {
      const GS = new Map<number, number>();
      const HS = new Map<number, number>();
      const isF = new Uint8Array(tree.length);
      for (const nd of frontier) isF[nd] = 1;
      for (let q = 0; q < ns; q++) {
        const i = sample[q];
        const nd = node[i];
        if (!isF[nd]) continue;
        GS.set(nd, (GS.get(nd) ?? 0) + g[i]);
        HS.set(nd, (HS.get(nd) ?? 0) + h[i]);
      }
      for (const nd of frontier) tree[nd].v = -(GS.get(nd) ?? 0) / ((HS.get(nd) ?? 0) + p.lambda);
    }
    // perbarui skor semua baris lewat bin (bukan hanya sampel)
    for (let i = 0; i < n; i++) {
      let k = 0;
      const o = i * d;
      while (tree[k].f >= 0) k = B[o + tree[k].f] <= bins[k] ? tree[k].l : tree[k].r;
      F[i] += p.lr * tree[k].v;
    }
    trees.push(tree.map((t) => ({ ...t, v: Math.round(t.v * 1e6) / 1e6 })));
  }
  return { kind: 'gbm', features: [...names], base, lr: p.lr, trees };
}

function leaf(tree: Node[], x: number[]): number {
  let k = 0;
  while (tree[k].f >= 0) k = x[tree[k].f] <= tree[k].t ? tree[k].l : tree[k].r;
  return tree[k].v;
}

export function predictGbm(m: GbmModel, x: number[]): number {
  let z = m.base;
  for (const t of m.trees) z += m.lr * leaf(t, x);
  return sigmoid(z);
}

/** Seberapa sering fitur dipakai untuk split (proksi pentingnya fitur). */
export function gbmImportance(m: GbmModel, top = 8) {
  const c = new Array(m.features.length).fill(0);
  for (const t of m.trees) for (const nd of t) if (nd.f >= 0) c[nd.f]++;
  return c
    .map((v, j) => ({ feature: m.features[j], splits: v }))
    .sort((a, b) => b.splits - a.splits)
    .slice(0, top);
}
