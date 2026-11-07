// Edge Function market-ml-drivers5: isi kolom ml_cycle.drivers5 (faktor yang menjelaskan skor model 5 hari)
// untuk siklus yang belum punya. Hanya menulis kolom itu; prediksi, batas, dan hasil siklus tidak disentuh.
// Auth sama: header x-cron-secret.  {dry?: true} hanya menghitung dan melaporkan.
//
// Faktor dihitung dari fitur hari sinyal (cycle_start) dan koefisien model 5 hari yang tercatat di siklus itu
// (model5), lalu skornya dicocokkan dengan prob5 yang sudah tersimpan. Bila tidak cocok, tidak ditulis.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { buildRows, drivers, predict, projectX } from './lib.ts';
import type { Model, Series } from './lib.ts';

const UNIVERSE = [
  'BBCA', 'BBRI', 'BMRI', 'BBNI', 'BRIS', 'TLKM', 'ISAT', 'EXCL', 'TOWR', 'ASII',
  'UNTR', 'UNVR', 'ICBP', 'INDF', 'MYOR', 'KLBF', 'SIDO', 'CPIN', 'JPFA', 'AMRT',
  'MAPI', 'ACES', 'ADRO', 'PTBA', 'ITMG', 'ANTM', 'INCO', 'MDKA', 'MEDC', 'PGAS',
  'AKRA', 'BRPT', 'TPIA', 'INKP', 'SMGR', 'INTP', 'CTRA', 'BSDE', 'PWON', 'JSMR',
  'GOTO', 'ARTO', 'AMMN', 'EMTK',
];
/** prob5 tersimpan dibulatkan 4 desimal, jadi selisih sampai 0,0001 wajar. */
const TOLERANCE = 0.0006;

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { 'Content-Type': 'application/json' } });

type Raw = { ticker: string; bars: [string, number, number, number, number, number][] };

Deno.serve(async (req) => {
  const { data: secret } = await db.rpc('ml_cron_secret');
  if (!secret || req.headers.get('x-cron-secret') !== secret) return json({ error: 'unauthorized' }, 401);
  try {
    const body = await req.json().catch(() => ({}));
    const { data: pending, error } = await db
      .from('ml_cycle')
      .select('id,ticker,cycle_start,model5,prob5')
      .not('model5', 'is', null)
      .is('drivers5', null);
    if (error) throw new Error(`ml_cycle: ${error.message}`);
    if (!pending || pending.length === 0) return json({ pending: 0, updated: [], errors: [] });

    const versions = [...new Set(pending.map((c) => c.model5 as string))];
    const { data: models, error: mErr } = await db.from('ml_model').select('version,params').in('version', versions);
    if (mErr) throw new Error(`ml_model: ${mErr.message}`);
    const byVersion = new Map((models ?? []).map((m) => [m.version as string, m.params.model as Model]));

    const since = new Date(Date.now() - 420 * 86400000).toISOString().slice(0, 10);
    const { data, error: pErr } = await db.rpc('ml_price_json', { since });
    if (pErr) throw new Error(`ml_price_json: ${pErr.message}`);
    const allowed = new Set([...UNIVERSE, ...pending.map((c) => c.ticker as string)]);
    const series: Series[] = (data as Raw[]).filter((s) => allowed.has(s.ticker)).map((s) => ({
      ticker: s.ticker,
      bars: s.bars.map(([date, open, high, low, close, volume]) => ({ date, open, high, low, close, volume })),
    }));
    const rows = buildRows(series, { horizon: 5, k: 1 });

    const updated: unknown[] = [];
    const errors: string[] = [];
    for (const c of pending) {
      const label = `${c.ticker} ${c.cycle_start}`;
      const model = byVersion.get(c.model5 as string);
      const row = rows.find((r) => r.ticker === c.ticker && r.date === c.cycle_start);
      if (!model) {
        errors.push(`${label}: model ${c.model5} tidak ditemukan`);
        continue;
      }
      if (!row) {
        errors.push(`${label}: baris fitur hari sinyal tidak ada`);
        continue;
      }
      const x = projectX(row.x, model.features);
      const prob = predict(model, x);
      const diff = Math.abs(prob - Number(c.prob5));
      if (diff > TOLERANCE) {
        errors.push(`${label}: skor hitung ulang ${prob.toFixed(4)} beda dari tersimpan ${c.prob5}`);
        continue;
      }
      const list = drivers(model, x, model.features.length);
      if (!body.dry) {
        const { error: uErr } = await db.from('ml_cycle').update({ drivers5: list }).eq('id', c.id).is('drivers5', null);
        if (uErr) {
          errors.push(`${label}: ${uErr.message}`);
          continue;
        }
      }
      updated.push({ ticker: c.ticker, cycleStart: c.cycle_start, diff: Number(diff.toFixed(5)), top: list.slice(0, 4).map((d) => `${d.feature}:${d.contribution}`) });
    }
    return json({ dry: body.dry === true, pending: pending.length, updated, errors });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
