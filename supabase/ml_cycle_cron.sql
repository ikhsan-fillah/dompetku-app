-- Jadwal siklus 5/10 hari. Jalankan HANYA setelah migrasi, deploy market-ml-cycle-run, dan pelatihan pertama
-- (mode retrain) selesai, dan setelah Ikhsan menyetujui.
--
-- Harian 20.30 WIB (13.30 UTC) Senin sampai Jumat: setelah market-ml-daily 20.00 mengisi price_history.
-- Mengisi hasil nyata, merevisi prediksi 10 hari di hari ke-5, dan memulai siklus bila sudah waktunya.
select cron.schedule('market-ml-cycle-daily', '30 13 * * 1-5', $$select public.ml_invoke_cycle('{"mode":"daily"}'::jsonb)$$);

-- Sabtu 02.30 WIB (19.30 UTC Jumat): setelah market-ml-retrain 02.00 (model 10 hari baru aktif).
-- Melatih model 5 hari dan model revisi, lalu memulai siklus baru untuk siklus yang sudah selesai.
select cron.schedule('market-ml-cycle-retrain', '30 19 * * 5', $$select public.ml_invoke_cycle('{"mode":"retrain"}'::jsonb)$$);
