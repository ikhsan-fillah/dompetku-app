// Edge Function market-ml-rank: uji lab ranking momentum antar saham. Hanya membaca price_history.
// Auth sama: header x-cron-secret.  {all?: true} memakai semua saham di price_history, bukan 44 saham.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { evalRank } from './rank.ts';

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
    const series = (data as Raw[]).filter((s) => body.all === true || allowed.has(s.ticker)).map((s) => ({
      ticker: s.ticker,
      bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
    }));
    return json({ ms: Date.now() - t0, universe: body.all === true ? 'semua' : '44', ...evalRank(series) });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
