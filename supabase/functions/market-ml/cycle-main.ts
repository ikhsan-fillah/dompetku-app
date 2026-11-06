// Edge Function market-ml-cycle: uji kelayakan siklus 5 hari + revisi 10 hari.
// Hanya membaca price_history; tidak menulis apa pun. Auth sama: header x-cron-secret.
//   {mode:'five', fold?:0..4}    model TA 5 hari saham + gate
//   {mode:'revise', fold?:0..4}  revisi 10 hari di hari ke-5 vs pembanding
import { createClient } from 'npm:@supabase/supabase-js@2';
import { evalFiveDay, evalRevision, gate, summarizeRevision } from './cycle.ts';

const UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    const t0 = Date.now();
    const since = new Date(Date.now() - 365 * 6 * 86400000).toISOString().slice(0, 10);
    const { data, error } = await db.rpc('ml_price_json', { since });
    if (error) throw new Error(`ml_price_json: ${error.message}`);
    type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };
    const allowed = new Set(UNIVERSE);
    const series = (data as Raw[]).filter((s) => allowed.has(s.ticker)).map((s) => ({
      ticker: s.ticker,
      bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
    }));
    const fold = body.fold === undefined ? undefined : Number(body.fold);
    if (body.mode === 'five') {
      const folds = evalFiveDay(series, fold);
      return json({ ms: Date.now() - t0, tickers: series.length, gate: gate(folds), folds });
    }
    if (body.mode === 'revise') {
      const folds = evalRevision(series, fold);
      return json({ ms: Date.now() - t0, tickers: series.length, summary: summarizeRevision(folds), folds });
    }
    return json({ error: 'mode tidak dikenal' }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
