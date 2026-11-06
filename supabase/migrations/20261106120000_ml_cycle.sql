-- Siklus prediksi 10 hari bursa: prediksi 5 hari + prediksi 10 hari awal, revisi 10 hari di hari ke-5,
-- dan hasil nyata keduanya. Hanya menambah tabel dan fungsi baru; ml_prediction, market-ml, dan cron
-- yang berjalan tidak disentuh.
--
-- Satu baris = satu siklus satu saham. cycle_start adalah hari ke-0 (hari bursa terakhir saat sinyal dibuat).
-- Prediksi 10 hari awal juga ada di ml_prediction (trade_date = cycle_start, model_version = model10)
-- bila saham itu ikut pipeline harian pada tanggal tersebut; kolom di sini menyimpannya sendiri
-- supaya siklus tidak bergantung pada baris itu.

create table public.ml_cycle (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id),
  ticker text not null check (ticker = upper(ticker)),
  cycle_start date not null,
  created_at timestamptz not null default now(),
  close0 numeric not null,

  -- Prediksi 10 hari awal, dikunci di hari ke-0 (batas dan peluang tidak pernah ditimpa).
  model10 text not null references public.ml_model (version),
  prob10 numeric not null,
  base10 numeric not null,
  signal10 text not null check (signal10 in ('peluang', 'netral', 'risiko')),
  upper10 numeric not null,
  lower10 numeric not null,

  -- Prediksi 5 hari, dikunci di hari ke-0. Null bila belum ada model 5 hari yang lolos gate.
  model5 text references public.ml_model (version),
  prob5 numeric,
  base5 numeric,
  signal5 text check (signal5 in ('peluang', 'netral', 'risiko')),
  upper5 numeric,
  lower5 numeric,

  -- Revisi prediksi 10 hari di hari ke-5. Prediksi awal di atas tidak berubah.
  -- state: diperbarui = dihitung model dari jalur harga; *_tersentuh = batas sudah tersentuh di hari 1 sampai 5,
  -- hasil label 10 hari sudah pasti (rev_prob 1 atau 0).
  rev_model text references public.ml_model (version),
  rev_date date,
  rev_state text check (rev_state in ('diperbarui', 'atas_tersentuh', 'bawah_tersentuh')),
  rev_prob numeric,
  rev_base numeric,
  rev_z5 numeric,
  rev_max_up numeric,
  rev_min_dn numeric,

  -- Hasil nyata 5 hari dan 10 hari, aturan sama dengan ml_prediction.outcome_*
  -- (beli harga buka hari bursa setelah hari ke-0, jual penutupan hari ke-H, minus biaya 0,4%).
  out5_date date,
  out5_entry numeric,
  out5_exit numeric,
  out5_ret_net numeric,
  out5_win boolean,
  out5_hit_upper boolean,
  out10_date date,
  out10_entry numeric,
  out10_exit numeric,
  out10_ret_net numeric,
  out10_win boolean,
  out10_hit_upper boolean,

  unique (user_id, ticker, cycle_start)
);

comment on table public.ml_cycle is 'Siklus 10 hari bursa per saham: prediksi 5 hari, prediksi 10 hari awal, revisi hari ke-5, hasil nyata';
comment on column public.ml_cycle.cycle_start is 'Hari ke-0: hari bursa terakhir yang dipakai membuat prediksi';
comment on column public.ml_cycle.rev_state is 'diperbarui = dihitung model dari jalur harga 5 hari; atas_tersentuh/bawah_tersentuh = hasil 10 hari sudah pasti';

create index ml_cycle_user_ticker_start on public.ml_cycle (user_id, ticker, cycle_start desc);

alter table public.ml_cycle enable row level security;

create policy "ml_cycle milik sendiri" on public.ml_cycle
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Pemanggil cron untuk Edge Function market-ml-cycle-run, sama polanya dengan public.ml_invoke.
create or replace function public.ml_invoke_cycle(body jsonb)
  returns bigint
  language sql
  security definer
  set search_path to ''
as $function$
  select net.http_post(
    url := 'https://kktdetgwahzpjwjzbeek.supabase.co/functions/v1/market-ml-cycle-run',
    body := body,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', public.ml_cron_secret()),
    timeout_milliseconds := 300000
  );
$function$;

revoke execute on function public.ml_invoke_cycle(jsonb) from public, anon, authenticated;
