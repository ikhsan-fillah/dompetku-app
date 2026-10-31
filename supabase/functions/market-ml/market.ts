// Model pasar (IHSG) dan pengumpul berita. Murni TypeScript, bisa diuji dengan Node.
//
// Model IHSG memakai teknikal IHSG ditambah data global yang SUDAH tersedia saat
// bursa Jakarta tutup (bar global dengan tanggal < tanggal IHSG), supaya tidak
// ada kebocoran data masa depan. Berita belum menjadi fitur model karena belum
// ada riwayat; skor berita disimpan sebagai konteks dan bahan latih nanti.
import { indicators, type Row, type Series } from './lib.ts';

export const IHSG = '^JKSE';
/** Simbol Yahoo: IHSG, ETF MSCI Indonesia (EIDO), ETF MSCI EM (EEM), S&P 500, VIX,
 *  Brent, USD/IDR, indeks dolar, imbal hasil US 10Y, emas, Hang Seng. */
export const MACRO = ['^JKSE', 'EIDO', 'EEM', '^GSPC', '^VIX', 'BZ=F', 'IDR=X', 'DX-Y.NYB', '^TNX', 'GC=F', '^HSI'];

export const MARKET_FEATURES = [
  'ihsg_ret1',
  'ihsg_ret5',
  'ihsg_ret20',
  'ihsg_ret60',
  'ihsg_vol20',
  'ihsg_rsi',
  'ihsg_stochK',
  'ihsg_macdHistPct',
  'ihsg_distSma50',
  'ihsg_sma20vs50',
  'ihsg_rangePos20',
  'eido_ret1',
  'eido_ret5',
  'eem_ret5',
  'spx_ret1',
  'spx_ret5',
  'vix_level',
  'vix_chg5',
  'brent_ret5',
  'brent_ret20',
  'usdidr_ret5',
  'usdidr_ret20',
  'dxy_ret5',
  'us10y_chg5',
  'gold_ret5',
  'hsi_ret1',
];

type G = { dates: string[]; c: number[]; ptr: number };

const days = (a: string, b: string) => (Date.parse(b) - Date.parse(a)) / 86400000;
const lr = (c: number[], j: number, k: number) => (j - k >= 0 ? Math.log(c[j] / c[j - k]) : NaN);

/** Geser penunjuk ke bar terakhir bertanggal < d; -1 bila tidak ada atau basi (> 7 hari). */
function before(g: G | null, d: string): number {
  if (!g) return -1;
  while (g.ptr + 1 < g.dates.length && g.dates[g.ptr + 1] < d) g.ptr++;
  if (g.ptr < 0 || days(g.dates[g.ptr], d) > 7) return -1;
  return g.ptr;
}

export type MarketRows = { up: Row[]; down: Row[] };

/**
 * Baris harian IHSG. Label triple-barrier dua arah dengan batas k*sigma20*akar(H):
 * up = batas atas tersentuh lebih dulu, down = batas bawah lebih dulu (hari yang
 * sama dihitung turun, konservatif). Baris terakhir tanpa label dipakai untuk prediksi.
 */
export function buildMarketRows(all: Series[], p: { horizon: number; k: number }): MarketRows {
  const by = new Map(all.map((s) => [s.ticker, s]));
  const ihsg = by.get(IHSG);
  if (!ihsg || ihsg.bars.length < 80) return { up: [], down: [] };
  const g = (sym: string): G | null => {
    const s = by.get(sym);
    return s ? { dates: s.bars.map((b) => b.date), c: s.bars.map((b) => b.close), ptr: -1 } : null;
  };
  const eido = g('EIDO'), eem = g('EEM'), spx = g('^GSPC'), vix = g('^VIX'), brent = g('BZ=F');
  const idr = g('IDR=X'), dxy = g('DX-Y.NYB'), tnx = g('^TNX'), gold = g('GC=F'), hsi = g('^HSI');
  const b = ihsg.bars;
  const c = b.map((x) => x.close);
  const ind = indicators(b);
  const hi20: number[] = [], lo20: number[] = [];
  for (let i = 0; i < b.length; i++) {
    let h = -Infinity, l = Infinity;
    for (let j = Math.max(0, i - 19); j <= i; j++) {
      h = Math.max(h, b[j].high);
      l = Math.min(l, b[j].low);
    }
    hi20.push(h);
    lo20.push(l);
  }
  const H = p.horizon;
  const up: Row[] = [];
  const down: Row[] = [];
  for (let i = 60; i < b.length; i++) {
    const d = b[i].date;
    const J = [eido, eem, spx, vix, brent, idr, dxy, tnx, gold, hsi].map((s) => before(s, d));
    if (J.some((j) => j < 5)) continue;
    const [je, jm, js, jv, jb, ji, jd, jt, jg, jh] = J;
    const sigma = ind.vol20[i];
    if (sigma === null || sigma <= 0 || ind.sma50[i] === null || ind.stochK[i] === null || ind.hist[i] === null) continue;
    const range = hi20[i] - lo20[i];
    const x = [
      lr(c, i, 1),
      lr(c, i, 5),
      lr(c, i, 20),
      lr(c, i, 60),
      sigma,
      (ind.rsi[i] as number) / 100,
      (ind.stochK[i] as number) / 100,
      (ind.hist[i] as number) / c[i],
      c[i] / (ind.sma50[i] as number) - 1,
      (ind.sma20[i] as number) / (ind.sma50[i] as number) - 1,
      range > 0 ? (c[i] - lo20[i]) / range : 0.5,
      lr(eido!.c, je, 1),
      lr(eido!.c, je, 5),
      lr(eem!.c, jm, 5),
      lr(spx!.c, js, 1),
      lr(spx!.c, js, 5),
      Math.log(vix!.c[jv]),
      lr(vix!.c, jv, 5),
      lr(brent!.c, jb, 5),
      jb >= 20 ? lr(brent!.c, jb, 20) : NaN,
      lr(idr!.c, ji, 5),
      ji >= 20 ? lr(idr!.c, ji, 20) : NaN,
      lr(dxy!.c, jd, 5),
      tnx!.c[jt] - tnx!.c[jt - 5],
      lr(gold!.c, jg, 5),
      lr(hsi!.c, jh, 1),
    ];
    if (x.some((v) => !Number.isFinite(v))) continue;
    const width = p.k * sigma * Math.sqrt(H);
    const upper = c[i] * Math.exp(width);
    const lower = c[i] * Math.exp(-width);
    let yUp: number | null = null;
    let yDown: number | null = null;
    let fwd: number | null = null;
    if (i + H < b.length) {
      yUp = 0;
      yDown = 0;
      for (let j = i + 1; j <= i + H; j++) {
        if (b[j].low <= lower) {
          yDown = 1;
          break;
        }
        if (b[j].high >= upper) {
          yUp = 1;
          break;
        }
      }
      fwd = Math.log(c[i + H] / c[i]);
    }
    const base = { ticker: 'IHSG', date: d, x, fwdRet: fwd, upperPct: Math.exp(width) - 1, lowerPct: Math.exp(-width) - 1, close: c[i], valueIdr20: 0 };
    up.push({ ...base, y: yUp });
    down.push({ ...base, y: yDown });
  }
  return { up, down };
}

// ---------------------------------------------------------------- berita

export const NEWS_QUERIES = [
  'IHSG',
  'MSCI Indonesia',
  'FTSE Russell Indonesia',
  'Danantara',
  'Bursa Efek Indonesia',
  'OJK pasar modal',
  'Bank Indonesia suku bunga',
  'harga minyak dunia',
  'rupiah dolar',
  'Wall Street',
  'asing net sell saham',
];
export const googleNewsUrl = (q: string) =>
  `https://news.google.com/rss/search?q=${encodeURIComponent(`${q} when:2d`)}&hl=id&gl=ID&ceid=ID:id`;
export const CNBC_MARKET_RSS = 'https://www.cnbcindonesia.com/market/rss';

export type NewsItem = { title: string; url: string; source: string; published_at: string; query: string };

const decode = (s: string) =>
  s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim();

function tag(block: string, name: string): string {
  const m = block.match(new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`));
  return m ? decode(m[1]) : '';
}

export function parseRss(xml: string, query: string, google: boolean): NewsItem[] {
  const out: NewsItem[] = [];
  for (const m of xml.matchAll(/<item>([\s\S]*?)<\/item>/g)) {
    const blk = m[1];
    let title = tag(blk, 'title');
    const url = tag(blk, 'link') || tag(blk, 'guid');
    const pub = new Date(tag(blk, 'pubDate'));
    let source = google ? tag(blk, 'source') : 'CNBC Indonesia';
    if (google) {
      // Google News menambahkan " - Nama Sumber" di akhir judul.
      const dash = title.lastIndexOf(' - ');
      if (dash > 0) {
        if (!source) source = title.slice(dash + 3);
        title = title.slice(0, dash);
      }
    }
    if (!title || !url || Number.isNaN(pub.getTime())) continue;
    out.push({ title, url, source: source || 'tidak diketahui', published_at: pub.toISOString(), query });
  }
  return out;
}

// Leksikon sederhana bahasa Indonesia. Frasa dicek dulu lalu dihapus, supaya
// "turunkan suku bunga" tidak terhitung sebagai kata negatif "turun".
const POS_PHRASES = ['turunkan suku bunga', 'pangkas suku bunga', 'pemangkasan suku bunga', 'net buy', 'beli bersih', 'dana asing masuk', 'inflow'];
const NEG_PHRASES = ['naikkan suku bunga', 'kenaikan suku bunga', 'net sell', 'jual bersih', 'dana asing keluar', 'outflow', 'trading halt', 'auto reject', 'gagal bayar', 'perang dagang'];
const POS_WORDS = new Set(['menguat', 'naik', 'melonjak', 'melesat', 'meroket', 'rebound', 'rekor', 'tertinggi', 'hijau', 'borong', 'positif', 'optimis', 'optimisme', 'surplus', 'stimulus', 'upgrade', 'akumulasi', 'reli', 'rally', 'bullish', 'pulih', 'membaik', 'cuan', 'laba', 'tumbuh', 'bangkit']);
const NEG_WORDS = new Set(['melemah', 'turun', 'anjlok', 'ambles', 'ambruk', 'terjun', 'merosot', 'longsor', 'koreksi', 'merah', 'negatif', 'pesimis', 'defisit', 'resesi', 'perang', 'tarif', 'sanksi', 'krisis', 'downgrade', 'bearish', 'tertekan', 'tekanan', 'panik', 'suspensi', 'arb', 'manipulasi', 'skandal', 'freeze', 'delisting', 'rugi', 'terendah', 'gejolak', 'jatuh', 'boncos', 'lesu', 'ambrol', 'terkapar']);

export const TOPICS: Record<string, string[]> = {
  MSCI: ['msci'],
  FTSE: ['ftse'],
  Danantara: ['danantara'],
  'BEI/OJK': ['bei', 'bursa efek', 'idx', 'ojk', 'free float', 'suspensi', 'short selling', 'papan pemantauan'],
  Pemerintah: ['presiden', 'prabowo', 'pemerintah', 'menkeu', 'kemenkeu', 'apbn', 'kebijakan', 'dpr', 'purbaya'],
  'Suku bunga': ['bank indonesia', 'bi rate', 'suku bunga', 'the fed', 'fed'],
  Global: ['wall street', 'global', 'amerika', 'as', 'china', 'trump', 'tarif', 'perang', 'eropa', 'jepang'],
  Komoditas: ['minyak', 'oil', 'batu bara', 'coal', 'emas', 'nikel', 'cpo'],
  Rupiah: ['rupiah', 'dolar', 'kurs'],
  Asing: ['asing', 'foreign', 'net sell', 'net buy'],
};
const TOPIC_RE = Object.entries(TOPICS).map(([k, words]) => [k, new RegExp(`(^|[^a-z])(${words.join('|')})([^a-z]|$)`)] as const);

export function scoreTitle(title: string): { score: number | null; pos: number; neg: number; topics: string[] } {
  let t = ` ${title.toLowerCase()} `;
  let pos = 0;
  let neg = 0;
  for (const p of POS_PHRASES) while (t.includes(p)) { pos++; t = t.replace(p, ' '); }
  for (const p of NEG_PHRASES) while (t.includes(p)) { neg++; t = t.replace(p, ' '); }
  for (const w of t.split(/[^a-z0-9]+/)) {
    if (POS_WORDS.has(w)) pos++;
    else if (NEG_WORDS.has(w)) neg++;
  }
  const low = title.toLowerCase();
  const topics = TOPIC_RE.filter(([, re]) => re.test(low)).map(([k]) => k);
  return { score: pos + neg ? (pos - neg) / (pos + neg) : null, pos, neg, topics };
}

export type NewsSummary = {
  count: number;
  scored: number;
  score: number | null;
  positive: number;
  negative: number;
  topics: { topic: string; n: number; score: number | null }[];
};

export function summarize(items: { title: string }[]): NewsSummary {
  const s = items.map((i) => scoreTitle(i.title));
  const scored = s.filter((x) => x.score !== null);
  const mean = (a: number[]) => (a.length ? a.reduce((p, v) => p + v, 0) / a.length : null);
  const topics = Object.keys(TOPICS)
    .map((topic) => {
      const sel = s.filter((x) => x.topics.includes(topic));
      return { topic, n: sel.length, score: mean(sel.filter((x) => x.score !== null).map((x) => x.score as number)) };
    })
    .filter((x) => x.n > 0)
    .sort((a, b) => b.n - a.n);
  return {
    count: items.length,
    scored: scored.length,
    score: mean(scored.map((x) => x.score as number)),
    positive: scored.filter((x) => (x.score as number) > 0).length,
    negative: scored.filter((x) => (x.score as number) < 0).length,
    topics,
  };
}
