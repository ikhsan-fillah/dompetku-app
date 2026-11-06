// Edge Function market-ml-pat: detektor pola chart (deskriptif). Hanya membaca price_history.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { patternStudy } from './pat.ts';

const MACRO = new Set(['^JKSE', 'EIDO', 'EEM', '^GSPC', '^VIX', 'BZ=F', 'IDR=X', 'DX-Y.NYB', '^TNX', 'GC=F', '^HSI']);
const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    const t0 = Date.now();
    const { data, error } = await db.rpc('ml_price_json', { since: body.since ?? '2020-06-01' });
    if (error) throw new Error(`ml_price_json: ${error.message}`);
    type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };
    const all = (data as Raw[]).map((s) => ({ ticker: s.ticker, bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })) }));
    const parts = Math.max(1, Number(body.parts ?? 1)), part = Number(body.part ?? 0);
    const stocks = all.filter((s) => !MACRO.has(s.ticker)).sort((a, b) => (a.ticker < b.ticker ? -1 : 1)).filter((_, i) => i % parts === part);
    return json({ ms: Date.now() - t0, part, parts, ...patternStudy(stocks, body) });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
