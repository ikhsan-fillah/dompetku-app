# Tally (DompetKu) — Panduan Pengembangan Desain v4

> Dokumen ini dibaca **sebelum** menulis kode. Isinya menerjemahkan mockup `tally-mockup-v4.html` (dengan revisi recap dari v5) menjadi spesifikasi yang bisa langsung dikerjakan di repo `dompetku_app`.
>
> `DOMPETKU_TALLY_SPEC_v4.md` dan `tally-mockup-v4.html` yang disebut di bawah tidak ada di repo ini. Sebagai gantinya dipakai dokumen ini, `README.md`, `tally-mockup-v5.html`, dan `docs/UPDATE_LOG.md`.

---

## 0. Urutan sumber kebenaran

| Prioritas | Sumber | Dipakai untuk |
|---|---|---|
| 1 | `DOMPETKU_TALLY_SPEC_v4.md` (tidak ada di repo; lihat `README.md` dan `docs/UPDATE_LOG.md`) | Arsitektur, token, data model, urutan fase, keputusan produk |
| 2 | Dokumen ini (`DOMPETKU_TALLY_DESIGN_V4_DEV.md`) | Detail per layar, state, copy, dan perilaku |
| 3 | `tally-mockup-v5.html` | Acuan visual dan perilaku interaksi. Jika berbeda dengan dokumen, dokumen yang menang |

Aturan konflik:
- Revisi **v5** mengalahkan **v4** untuk entry point recap dan halaman Recaps (lihat §12).
- Jika repo berbeda dengan dokumen ini (misalnya layout yang sudah diubah, lihat spec §10 poin 9), **laporkan dulu** sebelum mengubah.

---

## 1. Ruang lingkup

**Ditambahkan di v4:**
- PIN cadangan (opsional)
- Auto-detect dan Drafts dari notifikasi (Android saja)
- Transaksi berulang (Recurring)
- Recap bulanan dan tahunan, plus halaman Recaps (revisi v5)
- Nama tampilan **Tally**. Application ID tetap `com.fillah.dompetku`

**Tidak berubah:**
- Desain Paper & Ink (token dan komponen, lihat §3)
- Layar yang sudah ada: Beranda (struktur dasar), Pilih periode, Form transaksi, Review struk, Transaksi, Anggaran, Form anggaran, Arsip anggaran, Laporan, Kategori, Detail kategori

**Di luar scope:**
- Dark mode
- Auto-detect di iOS
- Akun, cloud, sinkronisasi
- Reset PIN lewat email atau cloud

---

## 2. Aturan desain (ringkasan dari spec §3)

Ini ringkasan untuk pengecekan cepat. Nilai lengkap ada di `app_colors.dart` dan `app_text.dart`.

**Warna utama**

| Token | Hex | Pemakaian |
|---|---|---|
| `paper` | `#F4EFE4` | Latar utama |
| `paper2` | `#EBE4D4` | Latar sekunder, track progress, chip tidak aktif |
| `card` | `#FFFCF5` | Kartu, sheet, bottom nav |
| `ink` | `#1A2724` | Teks utama, kartu saldo, tombol utama |
| `ink2` | `#44524E` | Teks sekunder |
| `mut` | `#7C847F` | Label, metadata |
| `line` / `line2` | `#D8D0BF` / `#E8E1D1` | Border 1px / pemisah tipis |
| `accent` | `#0E5E55` | **Hanya FAB.** Maksimal 2 pemakaian per layar |
| `spend` / `earn` | `#A8432F` / `#2E6B3C` | Pengeluaran / pemasukan |
| `warn` / `crit` | `#9A6A12` / `#9C3B12` | Budget 75% / 90% |

**Aturan visual yang wajib dijaga**
- Kartu: border 1px `line`, radius 10, **tanpa box-shadow**. Pengecualian: bottom nav dan popover.
- Tidak ada gradien, emoji sebagai ikon, bulatan dekoratif, border kiri berwarna.
- Ikon: monoline (Lucide), ukuran 18–22, stroke 1.6–1.8.
- Kartu saldo `ink` dengan teks `paper`. Usahakan hanya satu blok tinta per layar.
- Bottom sheet: radius 22 di atas, grab handle 40×4, latar `card`.
- Keypad: grid 3 kolom. Tombol 000 dibuat lebih redup.
- Chip periode aktif: latar `ink`, teks `paper`. Tidak aktif: border `line`.
- Progress budget berubah warna di 75% (`warn`), 90% (`crit`), dan 100% (`spend`).

**Tipografi**

| Peran | Font | Ukuran |
|---|---|---|
| Saldo besar | Fraunces w500 | 38 |
| Judul halaman | Fraunces w500 | 26 |
| Judul kartu | Manrope w700 | 13 |
| Isi | Manrope w400 | 14 |
| Nominal di daftar | JetBrains Mono, tabular | 12.5 |
| Label | Manrope w700, uppercase, letter-spacing .06em | 10.5 |

**Format angka:** `Rp 1.250.000` (titik ribuan). Semua nominal memakai JetBrains Mono.

**Bahasa:** copy baru memakai bahasa Inggris. Copy lama di repo tetap bahasa Indonesia (spec §9). Lihat pertanyaan terbuka di §13.

**Status wajib:** setiap layar baru harus punya state **loading, empty, error, dan success**.

---

## 3. Navigasi dan entry point

**Bottom nav:** Beranda · Transaksi · **[FAB +]** · Anggaran · Profil.
- FAB membuka Form transaksi (bottom sheet yang sudah ada).
- Drafts, Recurring, Auto-detect, dan Recaps **tidak** ada di bottom nav.

| Layar baru | Dibuka dari |
|---|---|
| Drafts | Banner "N drafts waiting for you" di Beranda (hanya muncul jika ada draft). Profil → Automation → Drafts |
| Auto-detect | Profil → Automation → Auto-detect |
| Recurring | Profil → Automation → Recurring |
| Tambah recurring | Tombol di halaman Recurring |
| Recaps (halaman) | Profil → baris "Recaps" |
| Recap bulanan | Halaman Recaps (ketuk bulan), atau teks Beranda tanggal 1–3 (v5) |
| Recap tahunan | Halaman Recaps (ketuk baris tahun), atau tombol "Watch your 2026 recap" di kartu penutup recap bulanan |
| Biometric setup → Create PIN | Tautan "Use a PIN" di layar Biometric setup |

---

## 4. Urutan layar di Profil (v5)

Urutan dari atas ke bawah:

1. **Header:** nama tampilan (dari layar yang sudah ada)
2. **Security**
   - Biometric lock: sakelar
   - PIN lock: status **On** atau **Off**, subtitle "Optional backup". Ketuk membuka Create PIN (jika Off) atau Ubah PIN (jika On)
   - Auto-lock: nilai dari `AppConstants`
3. **Recaps:** satu baris, ketuk membuka halaman Recaps
4. **Automation**
   - Auto-detect
   - Drafts (dengan badge jumlah draft pending)
   - Recurring
5. Baris lama yang sudah ada (kelola kategori, tema, reset data aman)

Tema tetap terkunci ke Light.

---

## 5. Spesifikasi layar: alur autentikasi

### 5.1 Splash
- Wordmark "Tally" (Fraunces) dan loader. Durasi sekitar 2 detik.
- Setelah itu: ke Login jika belum pernah login, atau ke Beranda jika sudah (aturan `FinancialRouteGuard`).

### 5.2 Login (layar yang sudah ada)
- Tiga janji produk dan tombol "Start & set up biometric lock".
- Copy tetap seperti sekarang sampai keputusan di §13.

### 5.3 Biometric setup
- Judul: "Verify once" (sesuaikan dengan copy yang sudah ada).
- Teks privasi singkat: data tetap di perangkat.
- Tombol utama: **Verify biometrics**.
- Tautan: **"No biometrics on this phone? Use a PIN"** → Create PIN (lihat §5.4).
- Jika verifikasi biometrik gagal: tampilkan error dan tombol coba lagi. Jangan langsung masuk.

### 5.4 Create PIN (dua langkah)
- PIN 6 digit. Indikator berupa 6 titik.
- **Langkah 1:** judul "Create a PIN". Masukkan 6 digit.
- **Langkah 2:** judul "Confirm your PIN". Masukkan lagi 6 digit yang sama.
- Jika tidak cocok: kembali ke langkah 1, tampilkan toast "PINs don't match. Try again."
- Jika cocok: simpan (lihat §8.1), set flag PIN aktif, lalu lanjut ke Beranda.
- Keypad: angka 1–9, 0, dan tombol hapus. Tidak ada tombol 000.

### 5.5 Biometric unlock
- Ikon sidik jari (monoline), judul "Unlock Tally", tombol coba lagi.
- Counter gagal ditampilkan (misalnya "2 of 5 attempts").
- Tautan **"Use PIN instead"** hanya muncul jika PIN sudah dibuat.
- Setelah 5 kali gagal: pindah ke layar Locked (§5.7).

### 5.6 PIN unlock
- 6 titik dan keypad yang sama dengan Create PIN.
- Tautan **"Use biometrics"** kembali ke layar Biometric unlock. Tautan ini hanya muncul jika perangkat punya biometrik.
- Tautan **"Forgot PIN?"** menampilkan penjelasan singkat (lihat §13 poin 4 untuk perilaku final).
- PIN salah: tampilkan error di bawah titik dan kosongkan input. Counter gagal ikut naik.

### 5.7 Locked (lockout)
- Muncul setelah 5 kali gagal, berlaku bersama untuk biometrik dan PIN.
- Countdown mm:ss dari 5 menit.
- Setelah countdown habis, counter gagal direset.
- Counter tetap bertahan setelah app ditutup dan dibuka lagi (simpan di tempat yang sama dengan `biometric_lockout.dart`).

---

## 6. Spesifikasi layar: Beranda

**Susunan dari atas (spec §4, mengikuti v5):**
1. App bar: nama "Tally" dan chip tanggal (membuka Pilih periode)
2. Chip periode: Today, 1 Week, 1 Month, 3 Months, This year, 1 Year, All, Custom
3. Kartu saldo `ink`: saldo besar (Fraunces 38), In dan Out
4. Banner draft (hanya jika ada draft): "N drafts waiting for you". Ketuk membuka Drafts. Bukan pop-up
5. **Baris recap (v5):** teks kecil "Your {Bulan} recap is ready". Lihat §12
6. Empat kartu kategori favorit
7. Kartu donat per kategori
8. Kartu tren batang
9. Kartu transaksi terbaru (4 item)
10. Insight (teks deskriptif, tidak menghakimi)

**Yang dihapus di v5 (perlu konfirmasi):** ring budget dan kartu "Top spend". Keduanya tidak ada di spec §4. Lihat §13 poin 6.

**Aturan data:** saldo, In, Out, dan donat harus berasal dari service kalkulasi yang sama dengan Laporan. Tidak boleh ada angka yang berbeda untuk periode yang sama.

**Default periode:** tanggal 1 bulan berjalan sampai hari ini.

---

## 7. Spesifikasi layar: Drafts

**Rute:** `/drafts` (tambahkan ke `app_routes.dart`). Tidak dilindungi guard lama, tetapi berada di dalam flow yang sudah login.

**Header:** judul "Drafts". Subjudul "Detected from payment notifications".

**Kartu per draft:**
- Sumber (misalnya chip "GoPay" atau "BCA mobile")
- Nominal (JetBrains Mono)
- Merchant atau sumber
- Kategori kandidat (ikon dan nama)
- Metode bayar
- Waktu terdeteksi
- Aksi: **Confirm** (tombol `ink`), **Edit** (tombol garis), **Dismiss** (teks)

**Confirm all:** muncul di header atau bawah jika draft pending lebih dari satu.

**Aksi:**
- **Confirm:** buat transaksi baru dari draft. Status draft menjadi `confirmed`.
- **Edit:** buka Form transaksi yang sudah terisi. Setelah disimpan, draft ikut dikonfirmasi.
- **Dismiss:** status menjadi `dismissed`. Baris **tidak dihapus**, supaya `dedupe_key` tetap mencegah deteksi ulang.

**State:**
- Loading: skeleton kartu
- Empty: "No drafts right now. Detected payments will show up here."
- Error: pesan singkat dan tombol coba lagi

**Footer wajib:** "Raw notification text is never saved."

---

## 8. Spesifikasi layar: Auto-detect

**Rute:** `/auto-detect`. Entry point hanya tampil di Android. Di iOS, baris Auto-detect disembunyikan.

**Susunan dari atas:**
1. **Penjelasan privasi:** apa yang dibaca (notifikasi pembayaran dari app yang dipilih) dan apa yang tidak (OTP, promo, dan teks mentah tidak pernah disimpan).
2. **Status izin:** "Notification access: On / Off". Tombol **Open notification access** membuka pengaturan Android.
3. **Aplikasi yang dipantau:** daftar per app dengan sakelar.
   - Default aktif: BCA mobile, GoPay, ShopeePay, DANA
   - Default nonaktif: OVO
4. **Save automatically:** sakelar, default **mati**. Subteks: "Off: detected payments wait in Drafts."
5. **Quiet mode:** sakelar. Subteks: "No pop-ups while you use other apps. Drafts wait on Home."
6. **Battery:** kartu dengan langkah "Unrestricted battery use" untuk mencegah sistem membunuh service.

**State:**
- Izin belum diberikan: tampilkan penjelasan dan tombol buka pengaturan
- Izin sudah diberikan tapi tidak ada app yang dipilih: "Choose at least one app."

---

## 9. Spesifikasi layar: Recurring

**Rute:** `/recurring` dan `/recurring/add`.

### 9.1 Daftar
- Di atas: dua total, **Out per month** dan **In per month**. Nilainya dihitung dari item aktif yang dikonversi ke bulanan (lihat §13 poin 11).
- Daftar item. Setiap item menampilkan:
  - Ikon kategori dan nama
  - Nominal
  - Jadwal, misalnya "Monthly · due 1st" atau "Weekly · Mon" atau "Yearly · 17 Aug"
  - Mode: "Ask me first" atau "Record automatically"
  - Sakelar aktif. Nonaktif berarti tidak dihapus
- Tombol **+** untuk tambah. Ini bukan FAB utama, jadi tidak memakai `accent`.

**Empty:** "No recurring items yet. Add rent, subscriptions, or bills."

### 9.2 Tambah recurring (bottom sheet)
- Segmen tipe: Expense / Income
- Nama
- Nominal (keypad)
- Kategori (chip)
- Jadwal: segmen Weekly / Monthly / Yearly, lalu pilih hari atau tanggal
- Mode: pilihan **Ask me first** atau **Record automatically**
- Sakelar "Amount varies" (untuk tagihan seperti listrik). Subteks: "You can adjust the amount when you confirm."
- Tombol **Save recurring**

---

## 10. Spesifikasi layar: Recap (bulanan dan tahunan)

### 10.1 Perilaku umum
- Layar penuh, kartu satu per satu.
- **Progress bar** di atas: satu segmen per kartu.
- **Tap kiri** = kartu sebelumnya. **Tap kanan** = kartu berikutnya.
- **Auto-advance 6 detik** per kartu. Berhenti di kartu terakhir.
- Tombol tutup (X) di pojok kanan atas. Kembali ke halaman asal.
- Setiap kartu punya animasi masuk ringan (fade dan slide). Animasi tidak boleh membuat layar terasa lambat.
- Data dihitung dari **satu service** (`RecapCalculationService`, pure, bisa di-test). Recap tidak boleh menampilkan angka berbeda dengan Beranda untuk periode yang sama.
- Recap dihitung ulang setiap kali dibuka. Perubahan transaksi langsung tercermin.
- Periode berjalan diberi label **"so far"**.

### 10.2 Recap bulanan (9 kartu)

| # | Kartu | Isi |
|---|---|---|
| 1 | Cover | "Your {Month}, in ink." Label "1 – N {Mon} 2026 · Monthly recap". Satu goresan tally per hari |
| 2 | Total | "You spent" dengan angka naik (count-up). "That's Rp X a day. Rp Y more/less than {Bulan lalu}." Chip persentase. Batang perbandingan dengan bulan sebelumnya |
| 3 | Heat map | Kalender Senin–Minggu. Hari tanpa pengeluaran: border putus-putus. Hari termahal: outline `spend`. Legenda Less–More. Statistik: hari termahal dan jumlah hari tanpa pengeluaran |
| 4 | Kategori teratas | Nama kategori teratas (misalnya Food), persentase, nominal, jumlah transaksi. Stacked bar semua kategori dengan legenda |
| 5 | Struk | Struk monospace: "{APP} · MONTHLY", rentang tanggal, baris per kategori dengan jumlah, ITEMS, PER DAY, TOTAL, footer "THANK YOU. SEE YOU IN {BULAN}.", dan barcode dekoratif |
| 6 | Merchant langganan | Tiga merchant teratas dengan jumlah kunjungan, nominal, dan tally per kunjungan |
| 7 | Grafik harian | Batang per hari. Batas harian sebagai garis putus-putus. Batang di atas batas memakai warna `spend`. Teks "N of N days under the line" |
| 8 | Budget report card | Per budget: nama, nominal, persentase, dan stempel **SAFE** (di bawah 75%), **WATCH** (75–89%), **CRITICAL** (90–99%), **OVER** (100% ke atas) |
| 9 | Penutup | "You kept" dengan nominal net, persentase dari pemasukan. Tombol **Save as image** dan **Watch your 2026 recap** |

**Batas harian:** dihitung sebagai total budget aktif bulan itu dibagi jumlah hari. Mockup memakai Rp 5.000.000 / 30 = Rp 166.667. Lihat §13 poin 1.

**Perbandingan:** jika bulan sebelumnya tidak punya transaksi, kartu 2 hanya menampilkan rata-rata per hari dan tidak menampilkan perbandingan.

### 10.3 Recap tahunan (8 kartu)

| # | Kartu | Isi |
|---|---|---|
| 1 | Cover | "2026, so far." Satu tally per bulan yang punya transaksi |
| 2 | In vs Out | Dua angka besar dengan bar pemisah. "You kept {net}, {persen}%" |
| 3 | Bar per bulan | Batang per bulan. Bulan terberat (`spend`) dan teringan (`earn`) diberi label. Bulan tanpa transaksi: kotak putus-putus |
| 4 | Lima kategori teratas | Nama, persentase, nominal |
| 5 | Tempat paling sering | Merchant teratas dengan tally |
| 6 | Quiet streak | Hari berturut-turut tanpa pengeluaran (angka besar), jumlah hari tanpa pengeluaran, dan grid hari |
| 7 | Budget months | Kotak per bulan: **inside** (`ink`), **over** (putus-putus `spend`), **no data** (abu-abu) |
| 8 | Penutup | "2026, net so far". "N months to go". Tombol Save as image dan Back to Tally |

Mockup v5 juga menampilkan "Biggest single expense" di kartu 5. Ini belum ada di spec. Lihat §13 poin 7.

### 10.4 Halaman Recaps (v5)

**Rute:** `/recaps`. Dibuka dari baris "Recaps" di Profil.

**Susunan:**
1. App bar: tombol kembali dan judul "Recaps"
2. Penjelasan singkat: "Replay any month or year. Periods without transactions are greyed out, and future periods are not listed."
3. **Year:** chip tahun. Tahun tanpa transaksi dinonaktifkan. Tahun berjalan diberi label "so far". Baris recap tahunan di bawahnya.
4. **Month · {Tahun}:** grid 3 kolom berisi bulan.
   - Bulan dengan transaksi: nama bulan, total, dan "Rp spent". Ketuk membuka recap bulanan.
   - Bulan tanpa transaksi: abu-abu, border putus-putus, tidak bisa diketuk.
   - Bulan berjalan: label "so far".
   - **Bulan di masa depan tidak ditampilkan sama sekali.**

**Aturan periode:**
- Hanya tahun dan bulan sampai periode berjalan.
- Tahun dari transaksi paling awal sampai tahun berjalan. Tahun tanpa transaksi tetap ditampilkan tapi dinonaktifkan.

### 10.5 Teks recap di Beranda (v5)

- Muncul hanya jika tanggal hari ini **1, 2, atau 3** setiap bulan.
- Teks: "Your {Bulan lalu} recap is ready".
- Hanya muncul jika bulan lalu punya transaksi.
- Ketuk membuka recap bulan lalu.
- Tidak ada kartu recap di Beranda.
- Recap tahunan 1–3 Januari adalah **usulan**. Belum dikonfirmasi (lihat §13 poin 2).

---

## 11. Data model dan migrasi

### 11.1 Tabel baru (dari spec §6.2)

**`recurring_rules`**
`id` · `name` · `type` (`income`/`expense`) · `category_id` FK · `amount` · `frequency` (`weekly`/`monthly`/`yearly`) · `day_of_month` atau weekday (sesuai frequency) · `start_date` · `mode` (`ask`/`auto`) · `is_active` · `last_generated_on` · `created_at` · `updated_at`

**`drafts`**
`id` · `source` · `kind` (`income`/`expense`) · `amount` · `merchant` · `category_id` · `payment_method` · `detected_at` · `status` (`pending`/`confirmed`/`dismissed`) · `dedupe_key` UNIQUE · `needs_review` · `recurring_rule_id` FK nullable

**Catatan privasi:** teks notifikasi mentah **tidak pernah disimpan**. Kolom apa pun yang berisi teks notifikasi dilarang.

### 11.2 Migrasi
- Naikkan `AppConstants.databaseVersion`.
- Tambahkan blok `if (oldVersion < N)` di `Migrations.onUpgrade`.
- Jangan ubah atau hapus kolom yang sudah rilis.
- Jangan panggil `LocalDataResetService` dari alur update.
- **Uji upgrade dengan install di atas APK sebelumnya**, bukan uninstall.

---

## 12. Layanan dan logika (pure, bisa di-test)

| Service | Tanggung jawab | Test minimal |
|---|---|---|
| `PinService` | Hash PIN dengan salt. Simpan di `flutter_secure_storage`. Flag aktif di `shared_prefs` | Hash cocok, hash salah ditolak, PIN tidak pernah tersimpan plain |
| Lockout (perluas yang ada) | Counter gagal bersama biometrik dan PIN. 5 gagal = 5 menit | Counter naik, reset setelah 5 menit, bertahan setelah restart |
| `RecurringGenerator` | Buat transaksi atau draft untuk item yang jatuh tempo. Dipanggil saat app dibuka dan saat unlock | Tidak ada duplikat (`last_generated_on`), bulan 31 hari, tahun kabisat |
| `DraftDedupe` | `dedupe_key` dari sumber, nominal, dan waktu yang dibulatkan | Notifikasi sama dalam jendela waktu menghasilkan key sama |
| `NotificationParser` (per app) | Regex per app. Mulai dari empat app | Unit test dengan contoh teks, termasuk OTP dan promo yang harus diabaikan |
| `RecapCalculationService` | Semua angka recap bulanan dan tahunan | Angka cocok dengan Beranda untuk periode yang sama. Bulan tanpa data tidak merusak perhitungan |

---

## 13. Pertanyaan yang belum diputuskan

Jangan memutuskan sendiri. Tanyakan ke pemilik produk sebelum mengerjakan bagian ini.

1. **Batas harian recap.** Mockup memakai total budget / jumlah hari. Apakah ini benar, atau batas harian punya sumber lain?
2. **Recap tahunan 1–3 Januari.** Usulan, belum dikonfirmasi.
3. **Quiet streak.** Apakah bulan tanpa transaksi dihitung sebagai hari tanpa pengeluaran? Mockup mengabaikannya.
4. **Lupa PIN di perangkat tanpa biometrik.** Belum ada jalan pulih. Kalau user lupa PIN dan tidak punya biometrik, data tidak bisa dibuka. Perlu keputusan: reset data penuh, atau tidak ada reset sama sekali dengan peringatan jelas saat membuat PIN?
5. **Bahasa layar lama.** Spec §9 bilang copy lama tetap bahasa Indonesia. Mockup v4 dan v5 memakai bahasa Inggris untuk seluruh UI. Usulan: layar baru bahasa Inggris, layar lama tetap sampai ada keputusan terpisah.
6. **Ring budget dan kartu Top spend di Beranda.** Dihapus di v5 karena tidak ada di spec §4. Konfirmasi, atau dikembalikan.
7. **Biggest single expense** di recap tahunan. Ada di mockup, belum ada di spec.
8. **Auto-lock default.** Ambil dari `AppConstants`. Konfirmasi nilainya.
9. **Layout repo.** Spec §10 poin 9: user menyebut ada perubahan layout yang belum tercatat di commit `086a16c`. Periksa sebelum mulai Fase A.
10. **Dedupe window.** Berapa menit pembulatan waktu untuk `dedupe_key`? Usulan 5 menit, perlu dikonfirmasi.
11. **Konversi recurring ke bulanan.** Mingguan dikali 52 dibagi 12, bulanan 1, tahunan dibagi 12. Konfirmasi.

---

## 14. Urutan kerja

Setiap fase harus lulus `flutter analyze` dan `flutter test` sebelum fase berikutnya dimulai. Ikuti spec §11.

| Fase | Isi | Selesai jika |
|---|---|---|
| A | Ganti label ke Tally. Bersihkan README, pubspec, dan folder export | Label tampil Tally. Application ID tidak berubah. Analyze hijau |
| B | PIN opsional: service hash, layar Create PIN dan PIN unlock, integrasi lockout | Test PinService lulus. Lockout bersama berjalan. Alur biometrik tetap utama |
| C | Skema v+1, tabel `recurring_rules` dan `drafts`, migrasi | Uji upgrade dari APK sebelumnya berhasil. Data lama utuh |
| D | Recurring: CRUD, generator saat unlock, layar daftar dan tambah | Tidak ada duplikat saat app dibuka berulang kali |
| E | Drafts: layar, Confirm, Edit, Dismiss, Confirm all, banner Beranda | Confirm membuat transaksi. Dismiss tidak memunculkan draft lagi |
| F | Auto-detect Android: izin, service, parser, dedupe | Diuji di perangkat nyata. Tidak ada OTP atau promo yang tersimpan |
| G | Recap: service kalkulasi, halaman Recaps, story, teks Beranda tanggal 1–3 | Angka recap sama dengan Beranda. Bulan tanpa transaksi tidak bisa dibuka |

**Fase F paling berisiko.** Bergantung pada format notifikasi tiap app dan perilaku Android di tiap vendor HP.

---

## 15. Checklist QA sebelum merge

- [ ] Tidak ada box-shadow di kartu (kecuali bottom nav dan popover)
- [ ] Tidak ada gradien, emoji sebagai ikon, atau border kiri berwarna
- [ ] `accent` hanya di FAB, maksimal 2 pemakaian per layar
- [ ] Semua nominal JetBrains Mono dengan tabular figures
- [ ] Format `Rp 1.250.000`
- [ ] Setiap layar baru punya state loading, empty, error, dan success
- [ ] Recap tidak menampilkan bulan atau tahun masa depan
- [ ] Bulan tanpa transaksi di Recaps tidak bisa diketuk
- [ ] Teks notifikasi mentah tidak pernah masuk database atau log
- [ ] Application ID `com.fillah.dompetku` tidak berubah
- [ ] `flutter analyze` dan `flutter test` hijau
- [ ] Upgrade database diuji dari APK sebelumnya

---

## 16. Daftar copy baru (bahasa Inggris)

| Konteks | Copy |
|---|---|
| Biometric setup | "No biometrics on this phone? Use a PIN" |
| Create PIN | "Create a PIN" / "Confirm your PIN" / "PINs don't match. Try again." |
| Biometric unlock | "Use PIN instead" |
| PIN unlock | "Use biometrics" / "Forgot PIN?" |
| Drafts | "N drafts waiting for you" / "Raw notification text is never saved." |
| Auto-detect | "Save automatically" / "Quiet mode" / "Unrestricted battery use" |
| Recurring | "Ask me first" / "Record automatically" / "Save recurring" |
| Recap | "Your {Bulan} recap is ready" / "so far" / "Save as image" / "Watch your 2026 recap" |
| Recaps | "Replay any month or year." / "Periods without transactions are greyed out." |

---

## 17. Lampiran: istilah

| Istilah | Arti |
|---|---|
| Draft | Transaksi terdeteksi yang belum dikonfirmasi |
| Auto-detect | Pembacaan notifikasi pembayaran di Android |
| Recurring rule | Aturan transaksi berulang |
| Recap | Story ringkasan bulanan atau tahunan |
| So far | Label untuk periode yang belum selesai |
| Tally | Nama app di UI (sebelumnya DompetKu) |
