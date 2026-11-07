-- Faktor yang menjelaskan skor model 5 hari di tiap siklus (fitur, nilai, sumbangan ke log-odds),
-- supaya kartu faktor di aplikasi bisa menampilkan 10 hari dan 5 hari berdampingan.
-- Hanya menambah satu kolom; baris dan kolom lain tidak berubah. Diisi oleh Edge Function market-ml-drivers5.

alter table public.ml_cycle add column drivers5 jsonb;

