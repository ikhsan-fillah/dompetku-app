-- Pemanggil cron untuk Edge Function market-ml-drivers5, sama polanya dengan public.ml_invoke_cycle.
create or replace function public.ml_invoke_drivers5()
  returns bigint
  language sql
  security definer
  set search_path to ''
as $function$
  select net.http_post(
    url := 'https://kktdetgwahzpjwjzbeek.supabase.co/functions/v1/market-ml-drivers5',
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', public.ml_cron_secret()),
    timeout_milliseconds := 120000
  );
$function$;

revoke execute on function public.ml_invoke_drivers5() from public, anon, authenticated;

-- Jalan setelah market-ml-cycle-daily (13.30 UTC) dan market-ml-cycle-retrain (Jumat 19.30 UTC)
-- supaya siklus baru langsung punya faktor 5 hari. Tanpa siklus tertunda, fungsinya tidak melakukan apa pun.
select cron.schedule('market-ml-drivers5-daily', '45 13 * * 1-5', $$select public.ml_invoke_drivers5()$$);
select cron.schedule('market-ml-drivers5-retrain', '0 20 * * 5', $$select public.ml_invoke_drivers5()$$);
