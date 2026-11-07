-- Perkiraan gerak harian 10 hari ke depan per saham (model vol-ridge-rv-v1), ditulis Edge Function market-ml-volprod.
-- Tabel ini hanya berisi angka perkiraan; model dilatih ulang tiap panggilan, jadi tidak ada koefisien tersimpan.
create table public.ml_vol (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id),
  ticker text not null check (ticker = upper(ticker)),
  as_of date not null,
  model_version text not null,
  -- perkiraan rata-rata gerak harian (persen) untuk 10 hari bursa setelah as_of
  forecast_move numeric not null check (forecast_move > 0),
  created_at timestamptz not null default now(),
  unique (user_id, ticker, as_of, model_version)
);

create index ml_vol_user_ticker_asof on public.ml_vol (user_id, ticker, as_of desc);

alter table public.ml_vol enable row level security;

create policy "ml_vol milik sendiri" on public.ml_vol
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Pemanggil cron untuk Edge Function market-ml-volprod, sama polanya dengan public.ml_invoke_drivers5.
create or replace function public.ml_invoke_volprod()
  returns bigint
  language sql
  security definer
  set search_path to ''
as $function$
  select net.http_post(
    url := 'https://kktdetgwahzpjwjzbeek.supabase.co/functions/v1/market-ml-volprod',
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', public.ml_cron_secret()),
    timeout_milliseconds := 120000
  );
$function$;

revoke execute on function public.ml_invoke_volprod() from public, anon, authenticated;

-- Senin sampai Jumat 13.50 UTC (20.50 WIB), setelah market-ml-cycle-daily (13.30) dan market-ml-drivers5-daily (13.45).
select cron.schedule('market-ml-volprod-daily', '50 13 * * 1-5', $$select public.ml_invoke_volprod()$$);
