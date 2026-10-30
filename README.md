# Tally (DompetKu)

Tally is an offline-first personal finance application for one user on one device. It helps the user record income and expenses, understand spending patterns, manage a monthly budget, and review financial activity without cloud synchronization.

> **Status dokumen (Oktober 2026):** README ini satu-satunya dokumen proyek. Bagian 1 sampai 6 menjelaskan keputusan produk awal; beberapa sudah berubah di Tally v4 dan dirangkum di bagian 7 dan 9:
> PIN cadangan opsional kini ada (biometrik tetap utama), fitur ekspor data dihapus, dan ditambah Auto-detect notifikasi, Drafts, transaksi berulang, Recap, laporan bulanan, tren pengeluaran harian, serta pilihan bahasa Indonesia/Inggris. Bila bagian awal berbeda dengan bagian 7 sampai 9, bagian 7 sampai 9 yang berlaku.

This README is the product specification and the operational notes (release, signing, data rules, version history).

## 1. Final Product Decisions

- **Users:** One user on one device.
- **Connectivity:** Local-only for all financial data. No account system, cloud synchronization, or cloud backup is required for the first version. The optional stock module (section 10) is the only part that uses the network, and it never sends financial data.
- **Default currency:** Indonesian Rupiah (IDR).
- **Wallet model:** One wallet only. Multiple wallets are out of scope for the first version.
- **Transaction types:** Income and expense are both included in MVP 1.
- **Security:** Device biometric authentication is used instead of an application PIN.
- **Session state:** Shared Preferences stores non-sensitive session and preference flags.
- **Sensitive storage:** Secure storage is used only when a sensitive value is required.
- **Biometric lockout:** After five failed biometric attempts, the application blocks another attempt for five minutes.
- **Dashboard default range:** The first day of the current month through today.
- **Categories:** Categories can be created, renamed, archived, reordered, and customized. A category already used by a transaction cannot be deleted.
- **OCR:** The first OCR version prioritizes merchant, date, and total extraction. OCR results must always be reviewed before saving.
- **Theme:** Follow the device theme, with dark mode supported from the beginning.
- **Primary font:** Poppins.
- **Design system:** Customized Material 3.

## 2. Product Vision

Create a private, fast, and clear financial companion that helps the user:

- Record income and expenses reliably.
- Correct older transactions when a record was forgotten.
- Understand spending by category and date range.
- Compare monthly financial performance.
- Set and monitor spending budgets.
- Scan receipts to reduce manual entry.
- Keep financial records available after restarting the application.

## 3. Core User Flows

### 3.1 First Launch and Login

1. The application opens the splash screen.
2. The session state is read from local storage.
3. A new user is taken to the login page.
4. After successful login, the local session state is saved.
5. The application checks device biometric availability.
6. The user is asked to enable biometric protection after login.
7. The user enters the application after security setup is complete.

### 3.2 Returning User

1. The application opens the splash screen.
2. The stored local session state is read.
3. The application never opens the dashboard immediately when a session exists.
4. The biometric unlock state is shown.
5. The user authenticates with the device biometric prompt.
6. On success, the dashboard opens.
7. On failure, the user can retry until the lockout limit is reached.
8. After five failed attempts, biometric authentication is blocked for five minutes.

The application must never store or access raw fingerprint or face data. That data remains managed by the operating system.

### 3.3 App Lock

The application should lock again after returning from the background. The user should eventually be able to configure the auto-lock duration and manually lock the app from Profile.

### 3.4 Add a Transaction

1. The user taps the add transaction action.
2. The form defaults to today's date and the expense type.
3. The user can switch between expense and income.
4. The user enters a name, amount, date, category, payment method, and optional note.
5. The user can optionally attach a receipt image.
6. Validation runs before saving.
7. The transaction is stored locally.
8. The dashboard and transaction history refresh.

The transaction date can be changed to a previous date so forgotten transactions can be recorded.

### 3.5 Scan a Receipt

1. The user opens the receipt scanner from the transaction flow.
2. The user takes a photo or selects an existing image.
3. OCR extracts candidate fields.
4. Uncertain fields are marked for review.
5. The user edits merchant, date, total, category, and other values.
6. The transaction is created only after confirmation.

The first OCR release focuses on merchant, date, and total. Line-item extraction is a later enhancement.

## 4. Functional Scope

### 4.1 Dashboard

The default dashboard range is the first day of the current month through today. The user can choose a preset range or a custom start and end date.

Supported ranges:

- Today
- One week
- One month
- Three months
- Year to date
- One year
- All time
- Custom range

The dashboard should contain:

- Current balance.
- Total income for the selected range.
- Total expenses for the selected range.
- Remaining budget when budgets exist.
- Monthly spending efficiency progress using the actual calendar month length: 28, 29, 30, or 31 days.
- Spending trend chart.
- Four customizable category summary cards.
- Top spending category.
- Recent transactions.
- Budget warnings and useful insights.
- A prominent quick-add transaction action.

The date selector displays a start date and an end date. Tapping either date opens a calendar with quick range buttons.

Suggested order:

1. Greeting and current balance.
2. Date-range selector.
3. Income, expense, and balance summary.
4. Spending efficiency and trend.
5. Four selected category cards.
6. Recent transactions.
7. Budget warnings or insights.

### 4.2 Categories

Default expense categories:

- Food and drinks
- Transportation
- Shopping
- Bills
- Health
- Education
- Sports
- Entertainment
- Family
- Other

Default income categories:

- Salary
- Freelance
- Business
- Investment
- Gift
- Other

The user can create, rename, archive, reorder, and customize categories with an icon and color. Categories can be marked as dashboard favorites. A category already used by a transaction cannot be deleted.

### 4.3 Transactions

Each transaction can contain:

- Income or expense type.
- Name or title.
- Amount in IDR.
- Date and time.
- Category.
- Merchant or source.
- Payment method.
- Optional note.
- Optional receipt image.
- Creation and update timestamps.

Supported payment methods may include cash, e-wallet, QRIS, bank transfer, debit card, and credit card.

Transaction history should support search, date filtering, category filtering, amount filtering, type filtering, sorting, editing, deletion, and duplication.

### 4.4 Budgets

The first budget version supports monthly category budgets and an overall monthly spending limit.

Each budget shows its limit, used amount, remaining amount, usage percentage, progress state, and warnings at 75%, 90%, and 100%. Budgets can be edited or archived without deleting transaction history. Archived budgets can be reviewed and restored from the archive screen.

Implemented behavior (Stage 5A):

- The Budget tab lists budgets as progress cards with loading, empty, and error states, and pull-to-refresh.
- A budget can be overall or tied to one active expense category, with a name, an IDR limit, and a start and end date. The default period is the current calendar month.
- Usage is the sum of expense transactions inside the budget period, filtered by category when the budget has one.
- Budgets can be edited or archived from the card menu. Archiving keeps all transaction history.
- The list refreshes automatically when a budget or transaction changes.
- Still pending: a dashboard budget summary, and an archived-budgets screen.

Feature folder: `lib/features/budget/` with `bindings`, `controllers`, `data`, `models`, `repositories`, and `views`.

### 4.5 Reports

Reports may provide category breakdowns, income versus expense comparison, monthly trends, top merchants, highest spending days, average daily spending, and comparison with the previous equivalent period.

Insights should be descriptive and non-judgmental. For example: "Food spending was 18% higher than the previous month."

The report page implements: income versus expense summary, remaining budget, spending change versus the previous equivalent period, category breakdown, average daily spending, highest spending day, and top merchant.

### 4.6 Profile and Settings

The profile area may contain biometric lock preference, auto-lock duration, IDR display settings, theme preference, category management, budget management, local data deletion, privacy information, and application information.

## 5. Visual Direction

Material 3 is the base design system, customized for personal finance. Use Poppins with semi-bold headings, medium labels, and regular supporting text.

Recommended semantic palette:

- Primary deep teal: `#0F766E`
- Primary container soft mint: `#CCFBF1`
- Secondary warm amber: `#D97706`
- Secondary container light amber: `#FEF3C7`
- Income and success green: `#15803D`
- Expense and destructive rose: `#BE123C`
- Light background: `#F8FAF9`
- Surface: `#FFFFFF`
- Main text: `#1F2937`
- Muted text: `#64748B`
- Divider: `#E2E8F0`

Use teal for primary actions, green for income or positive balance, rose for expenses and destructive actions, and amber for warnings. The same semantic roles should power light and dark themes.

Keep the UI practical: use cards for repeated summaries, keep add transaction easy to reach, show exact values alongside charts, and provide loading, empty, error, and success states.

## 6. Product Success Criteria

The product direction is considered complete when the specification is clear about:

- A private local-only financial experience.
- Biometric protection before financial data is shown.
- Income and expense recording with editable historical dates.
- A dashboard with preset and custom date ranges.
- Monthly summaries that respect the actual calendar month.
- Customizable categories and a single-wallet model.
- Reviewed OCR-assisted receipt entry.
- Budgets, reports, and profile settings as part of the product direction.
- A consistent Material 3 and Poppins visual identity.

## 7. Implementation Status

| Area | Status |
|---|---|
| Local database, models, repositories | Done |
| Login, biometric unlock, optional backup PIN, app route guard | Done |
| Transactions (history, form, search, filter, sort) | Done |
| Dashboard / home (balance, category donut, daily spending trend per month) | Done |
| Budgets (list, create, edit, archive, restore, warning levels 75% / 90% / 100%) | Done |
| Reports (monthly: category ring, comparison, income vs expense, daily bars) | Done |
| Categories (custom icons, colors, favorites, order, archive) | Done |
| Recurring transactions, Drafts, Auto-detect payment notifications (Android) | Done |
| Monthly and yearly Recap (shareable as image) | Done |
| OCR receipt scan (on-device ML Kit, review before save) | Done |
| Language: Indonesian (default) and English | Done |
| Profile and settings | Done |

Quality gate: `flutter analyze` reports no issues and `flutter test` passes.

## 8. Rilis, Tanda Tangan, dan Aturan Data

### 8.1 Identitas aplikasi (tetap, jangan diubah)

| Item | Nilai |
|---|---|
| Application ID | `com.fillah.dompetku` |
| Namespace | `com.fillah.dompetku` |
| Keystore release | `android/app/upload-keystore.jks` (alias `upload`) |
| Konfigurasi signing | `android/key.properties` |
| SHA-256 sertifikat | `D9:63:E3:1D:BE:BD:F2:DF:6F:77:3D:2C:8A:81:D9:78:D5:A1:AC:16:64:58:BC:FF:2E:34:10:84:90:32:FB:6F` |

Aturan wajib:

- Application ID tidak boleh berubah setelah rilis. Berubah berarti aplikasi dianggap baru dan data lama hilang.
- Keystore dan `key.properties` tidak boleh hilang atau diganti. Simpan backup terenkripsi di luar repo; kalau hilang, update tidak bisa dipasang lagi di perangkat pengguna.
- Keduanya tidak boleh di-commit (sudah dicakup `.gitignore`: `key.properties`, `*.jks`).
- Semua build release memakai keystore yang sama.

### 8.2 Aturan update data

- Perubahan skema database wajib menaikkan `AppConstants.databaseVersion` dan menambah blok `if (oldVersion < N)` di `Migrations.onUpgrade`.
- Jangan mengubah atau menghapus kolom atau tabel yang sudah dirilis tanpa migrasi.
- Sebelum rilis, uji upgrade dari APK versi sebelumnya (pasang di atasnya, bukan uninstall) dan pastikan data masih tampil.
- Jangan memanggil `LocalDataResetService` dari alur update.
- Nama kategori bawaan tersimpan dalam bahasa Inggris di database; tampilannya lewat `CategoryModel.displayName`.

### 8.3 Build release

Naikkan `version` di `pubspec.yaml` setiap rilis (angka setelah `+` harus selalu naik). Versi di Splash dan Profil dibaca otomatis dari sana.

```powershell
# APK per arsitektur (arm64-v8a untuk HP modern, armeabi-v7a untuk HP lama)
flutter build apk --release --split-per-abi --android-skip-build-dependency-validation

# hanya arm64
flutter build apk --release --split-per-abi --target-platform android-arm64 --android-skip-build-dependency-validation

# jalankan langsung di HP yang tersambung (otomatis sesuai arsitektur HP, tanpa hot reload)
flutter run --release

# Play Store
flutter build appbundle --release
```

Hasil: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`. Flutter menambah versionCode per arsitektur (arm64 = 2xxx, armeabi-v7a = 1xxx, x86_64 = 4xxx).

Ikon aplikasi dibuat ulang dengan `dart run flutter_launcher_icons` dari `assets/logo/app_icon.png` dan `app_icon_foreground.png`.

### 8.4 Terjemahan

Kunci terjemahan adalah teks Indonesia (`'Laporan'.tr`); terjemahan Inggris ada di `lib/core/i18n/en/`. `test/translations_coverage_test.dart` gagal bila ada teks `.tr` tanpa terjemahan Inggris.

## 9. Riwayat Versi

### 1.2.0+10 (Oktober 2026)

- **Tabungan:** halaman tujuan tabungan (total terkumpul, progres, target tanggal, setor/ambil, perayaan saat tercapai), dibuka dari pintasan baru di Beranda (Laporan, Tabungan, Berulang, Rekap) dan dari Profil. Database v5 (tabel `savings_goals`).
- **Geser kartu:** Edit dan Hapus lewat geser di Transaksi, Anggaran, Berulang, Tabungan, dan Kategori; ketuk kartu membuka Edit. Hapus langsung dengan toast Urungkan (kategori tetap minta konfirmasi). Duplikat transaksi dan Arsipkan anggaran ada di lembar Edit.
- **Urutkan & saring:** satu lembar dari chip urutan: urutan (baris geser), kategori sebagai ikon bernama terpisah pengeluaran/pemasukan, rentang nominal, dan tanggal via kalender rentang. Tombol menampilkan jumlah hasil.
- **Notifikasi:** ikon logo Tally; ketuk pengingat berulang membuka Catat Keuangan terisi; pengingat harian "Sudah catat pengeluaran hari ini?" (bawaan 21.00, hanya bila hari itu belum ada transaksi) dengan sakelar dan jam di Profil.
- **Cadangan data:** cadangan seluruh data sebagai berkas `.tally`, pulihkan dengan pratinjau dan konfirmasi, serta ekspor `.xlsx` rapi (lembar Transaksi, Per kategori, Anggaran). Foto struk tidak ikut.
- **Draf:** kartu menampilkan tanggal dan jam notifikasi terbaca (tanggal transaksi mengikuti ini, bukan waktu konfirmasi); Konfirmasi semua di app bar; kategori dipilih langsung di dialog Ubah draf.
- **Tampilan:** angka nominal bergulir per digit; animasi mikro di Beranda dan Laporan; toast di atas menggantikan snackbar; skeleton loading dan getaran halus; ikon kategori Phosphor duotone; kartu detail kategori lebih rapat.
- **Lainnya:** widget layar utama Android (saldo dan anggaran); pengingat transaksi berulang (hari H atau sehari sebelum).

### 1.1.5+9 (Oktober 2026)

- **Laporan:** tren pengeluaran pindah ke Laporan; cincin kategori bisa diketuk.
- **Anggaran:** tanggal dipilih dengan kalender rentang; batang progres membulat.
- **Berulang:** bisa diedit dari kartu; teks jadwal diperbaiki.
- **Tampilan:** semua lembar bawah memakai gaya lembar Catat Keuangan; detail kategori tidak lagi tampak memuat terus.

### 1.1.5+8 (Oktober 2026)

- **Dialog:** semua dialog konfirmasi dan isian memakai `AppDialog` dengan dua `AppButton` (Batal outline, aksi hitam atau merah).
- **Laporan:** kartu Tren pemasukan (batang hijau per hari) mengikuti bulan Laporan.
- **Kategori:** favorit maksimal 4 per jenis dan selalu di urutan atas; bintang terisi; arsip diganti hapus (transaksi pindah ke "Other", anggaran kategori itu ikut terhapus).
- **Pemilih tanggal:** lembar kalender sendiri untuk satu tanggal, rentang kustom di Beranda, dan lompat bulan.
- **Perbaikan:** kategori tampil saat pindah ke tab Anggaran di Catat Keuangan; jarak header Transaksi dan Anggaran sama dengan Beranda.
- **Auto-detect:** tambah OVO, LinkAja, Livin' by Mandiri, BNI Mobile, BSI Mobile, blu by BCA, SeaBank, dan Jenius.

### 1.1.5+7 (Oktober 2026)

- **Anggaran:** judul baris memakai nama kategori sebenarnya dan tidak lagi tampil dua kali; kartu "Per kategori" lebih bersih (persen di kanan, periode dan status satu baris, ketuk baris untuk Edit, Arsipkan, atau Hapus); semua anggaran tampil; anggaran bisa dihapus permanen (aktif maupun terarsip), transaksi tidak ikut terhapus.
- **App bar:** tombol ikon (mis. arsip) persis 38x38 dengan area ketuk 44, sama tinggi dengan chip urutan.
- **Beranda dan Laporan:** perubahan 1.1.4+6 yang belum masuk APK (chip periode dihapus, baca database per periode, laporan bulan kosong tetap tampil) ikut dirilis di sini.

### 1.1.4+6 (Oktober 2026)

- **Tren pengeluaran (Beranda):** satu batang per hari dalam satu bulan kalender (28, 29, 30, atau 31 hari menurut kalender), pita dua warna per pekan (Senin sampai Minggu), garis dan keterangan rata-rata per hari, total di bawah, dan ketuk batang untuk melihat tanggal dan nominal. Bulan dipilih dengan panah; hanya bulan yang punya transaksi dan bulan ini yang bisa dikunjungi. Kartu ini tidak mengikuti periode Beranda.
- **Beranda:** chip periode dihapus; periode dipilih lewat tombol tanggal di app bar ("Bulan ini" ada di pemilih).
- **Profil:** nama diubah lewat pensil kecil di kartu profil (kartu "Nama tampilan" dihapus); keterangan diganti jumlah transaksi tercatat.
- **Urutan:** Transaksi dan Anggaran memakai satu komponen `SortChip` di app bar; Anggaran punya Nama Z-A.
- **Laporan:** per bulan dengan panah; bulan tanpa transaksi tetap menampilkan semua kartu dengan isi kosong.
- **Kinerja:** profil, tren, laporan, dashboard, dan anggaran tidak lagi memuat seluruh transaksi; yang dibaca hanya periode yang dibutuhkan (`count`, `getAll(range:)`). Batas rentang dihitung dalam UTC dari hari kalender lokal, jadi transaksi dini hari tetap di harinya.

### 1.1.3+5

- Layar Welcome back dirombak (sapaan sesuai jam, kartu angka tersamar, tombol sidik jari di bawah).
- Ikon aplikasi baru: huruf T Fraunces bold di atas tinta.
- Versi di Splash dan Profil otomatis.
- Anggaran terarsip: daftar dimuat saat dibuka dan hanya berisi yang diarsipkan; periode form anggaran dirapikan (tanpa "30 hari").

### 1.1.2+4

- Bahasa Indonesia/Inggris di Profil; nama bulan, tanggal, dan nama kategori bawaan ikut bahasa.
- Auto-detect: notifikasi yang masuk saat app tertutup ditahan sementara di sisi native (maks. 50 item, 24 jam), diambil Dart saat app dibuka, lalu dihapus. Simpan otomatis berfungsi (dicatat ke kategori "Other"). Dedupe memakai waktu posting persis dan jendela 2 menit; parser lebih ketat (saldo, "ke rekening").
- Kata konfirmasi hapus data mengikuti bahasa (HAPUS / DELETE).

### 1.1.0+2

- Auto-detect: BRImo dan Jago ditambahkan; status izin di-refresh saat kembali dari Settings.
- Drafts: confirm tanpa kategori memilih kategori dulu.

### Tally v4

- Nama tampilan Tally. PIN cadangan opsional (hash + salt, secure storage), lockout dibagi dengan biometrik.
- Skema database v3: tabel `recurring_rules` dan `drafts`.
- Recurring (mode auto membuat transaksi, mode ask membuat draft), Drafts, Auto-detect Android (BCA, GoPay, ShopeePay, DANA; teks mentah tidak disimpan), Recap bulanan dan tahunan.
- Keputusan: batas harian recap = total budget keseluruhan dibagi jumlah hari; quiet streak dihitung sejak transaksi pertama; total recurring (mingguan x52/12, tahunan /12); Forgot PIN hanya bisa menghapus data.

### 1.0.0+1

- Offline-first personal finance untuk satu pengguna di satu perangkat; proteksi biometrik dengan lockout lima kali gagal selama lima menit.
- Transaksi pemasukan dan pengeluaran, dashboard, anggaran dengan level peringatan 75% / 90% / 100%, laporan, kategori kustom, OCR struk di perangkat (ML Kit).
- Ekspor data dihapus. Application ID menjadi `com.fillah.dompetku`; release signing memakai `upload-keystore.jks`.

Wajib sebelum rilis: uji Auto-detect di HP nyata dan uji upgrade dari APK sebelumnya (tanpa uninstall).

## 10. Modul Saham (Supabase)

Status: skema database sudah dibuat di Supabase. App sudah punya halaman Saham (Profil > Saham): watchlist dengan ringkasan tiap saham, dialog masuk Supabase, detail dengan tab Broker (arah dana ritel, bandar, asing, dan 5 broker teratas di sisi net beli dan net jual) dan tab Chart (harga, volume, Stoch RSI, MACD). Tab Chart baru berisi bila tabel `daily_snapshot` terisi; saat ini tabel itu masih kosong. Input harian dan hasil analisis belum ada di app.

Aturan:

- Hanya data saham yang boleh disinkronkan ke Supabase: watchlist, snapshot harian, Broker Summary harian, dan hasil analisis. Transaksi, anggaran, tujuan, kategori, struk, dan PIN tidak boleh dikirim.
- Satu akun Supabase Auth untuk satu pengguna. Semua tabel memakai RLS dengan kondisi `user_id = auth.uid()`.
- Hanya URL proyek dan publishable key (`sb_publishable_...`) yang boleh ada di app. Keduanya ditanam sebagai nilai bawaan di `SupabaseStockAuth`, karena menurut docs Supabase publishable key aman diekspos di app dan source code selama semua tabel memakai RLS. Kunci secret/`service_role` dan password tidak boleh ada di app, repo, atau chat.
- Skema dikelola lewat migrasi Supabase, bukan lewat `Migrations` SQLite. Aturan migrasi SQLite di bagian 8.2 hanya berlaku untuk database lokal.
- Kelompok broker (ritel, bandar, asing) adalah aturan pengguna, bukan fakta pasar. Isinya disimpan sebagai data di tabel `broker_group` dengan `rule_version`, dan isi awalnya dibuat dengan `rpc('seed_broker_groups')` setelah login.

Tabel: `watchlist`, `broker_group`, `daily_snapshot`, `broker_daily`, `broker_flow_check`, `analysis_result`, `run_log`.

Cara menjalankan modul di app:

- `flutter run` dan `flutter build apk --release` langsung memakai project Supabase bawaan, tanpa `--dart-define`. Untuk project lain, timpa dengan `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
- Supabase diinisialisasi saat halaman Saham dibuka, bukan saat app mulai.
- Login memakai email dan password akun Supabase lewat dialog yang muncul sendiri saat halaman Saham dibuka tanpa sesi. Password tidak disimpan; yang disimpan hanya sesi (refresh token) di flutter_secure_storage. "Hapus data lokal" di Profil juga menghapus sesi ini, jadi login perlu diulang.
- Watchlist: maksimal 5 saham aktif (`maxActiveTickers`), hanya saham aktif yang diambil datanya otomatis, dan saham aktif selalu di urutan atas. Menghapus saham ikut menghapus barisnya di `daily_snapshot`, `broker_range_snapshot`, `broker_daily`, `broker_flow_check`, dan `analysis_result`.
- Total ritel, bandar, dan asing dihitung di app (`BrokerGroupCalculator`) dari baris per broker di `broker_range_snapshot` dan aturan di `broker_group`. Totalnya hanya dari broker yang tampil di Broker Summary Stockbit (broker teratas di tiap sisi), bukan seluruh pasar.
- Tab Chart membaca `daily_snapshot` dan menampilkan satu bulan terakhir (1M), satu baris per tanggal, baris `quality = 'tidak_akurat'` tidak ikut. Stoch RSI 14 14 3 3: `stoch_rsi_a` = K, `stoch_rsi_b` = D. MACD 12 26 9: `macd_a` = MACD, `macd_b` = sinyal. Pembacaan di tiap panel hanya menyebut posisi angka (mis. Stoch RSI di area 80 ke atas), bukan saran beli atau jual.
