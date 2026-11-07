// Edge Function market-ml-volprod: perkiraan gerak harian 10 hari ke depan untuk saham aktif di watchlist,
// ditulis ke ml_vol. Auth sama: header x-cron-secret.
//  {check: true}  hanya menjalankan pemeriksaan empat kuartal terakhir (tidak menulis apa pun)
//  {dry: true}    menghitung dan melaporkan perkiraan tanpa menulis
//  {} atau {}     menghitung dan menulis (upsert per user, saham, dan tanggal)
import { createClient } from 'npm:@supabase/supabase-js@2';
import { VOL_MODEL_VERSION, checkForecast, forecastLatest } from './volprod.ts';

const UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
/** Data harga lebih tua dari ini (hari kalender) dianggap basi dan tidak ditulis. */
const MAX_STALE_DAYS = 5;

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { 'Content-Type': 'application/json' } });

type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    const t0 = Date.now();
    const { data: wl, error: wErr } = await db.from('watchlist').select('user_id,ticker').eq('is_active', true);
    if (wErr) throw new Error(`watchlist: ${wErr.message}`);
    const list = (wl ?? []) as { user_id: string; ticker: string }[];
    const wanted = new Set([...UNIVERSE, ...list.map((w) => w.ticker)]);
    const since = new Date(Date.now() - 365 * 6 * 86400000).toISOString().slice(0, 10);
    const { data, error } = await db.rpc('ml_price_json', { since });
    if (error) throw new Error(`ml_price_json: ${error.message}`);
    const series = (data as Raw[]).filter((s) => wanted.has(s.ticker)).map((s) => ({
      ticker: s.ticker,
      bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
    }));
    const universe = new Set(UNIVERSE);
    if (body.check === true) {
      const res = checkForecast(series.filter((s) => universe.has(s.ticker)), universe);
      return json({ ms: Date.now() - t0, model: VOL_MODEL_VERSION, ...res });
    }
    const { forecasts, nTrain } = forecastLatest(series, universe);
    const byTicker = new Map(forecasts.map((f) => [f.ticker, f]));
    const written: unknown[] = [];
    const skipped: unknown[] = [];
    const errors: string[] = [];
    for (const w of list) {
      const f = byTicker.get(w.ticker);
      if (!f) {
        skipped.push({ ticker: w.ticker, why: 'tidak ada data' });
        continue;
      }
      if ((Date.now() - Date.parse(f.asOf)) / 86400000 > MAX_STALE_DAYS) {
        skipped.push({ ticker: w.ticker, why: `data harga basi (${f.asOf})` });
        continue;
      }
      written.push({ ticker: w.ticker, asOf: f.asOf, move: f.move });
      if (body.dry === true) continue;
      const { error: uErr } = await db.from('ml_vol').upsert(
        { user_id: w.user_id, ticker: w.ticker, as_of: f.asOf, model_version: VOL_MODEL_VERSION, forecast_move: f.move },
        { onConflict: 'user_id,ticker,as_of,model_version' },
      );
      if (uErr) errors.push(`${w.ticker}: ${uErr.message}`);
    }
    return json({ ms: Date.now() - t0, dry: body.dry === true, model: VOL_MODEL_VERSION, nTrain, written, skipped, errors });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
