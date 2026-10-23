# DompetKu Update Log

Catatan perubahan lanjutan setelah rilis dan aturan agar update aplikasi tidak menghapus data pengguna.

## Identitas Aplikasi (tetap, jangan diubah)

| Item | Nilai |
|---|---|
| Application ID | `com.fillah.dompetku` |
| Namespace | `com.fillah.dompetku` |
| Keystore release | `android/app/upload-keystore.jks` (alias `upload`) |
| Konfigurasi signing | `android/key.properties` |
| SHA-256 sertifikat | `D9:63:E3:1D:BE:BD:F2:DF:6F:77:3D:2C:8A:81:D9:78:D5:A1:AC:16:64:58:BC:FF:2E:34:10:84:90:32:FB:6F` |

Aturan wajib:

- Application ID tidak boleh berubah setelah rilis. Berubah = aplikasi dianggap baru dan data lama hilang.
- Keystore dan `key.properties` tidak boleh hilang atau diganti. Keduanya harus disimpan di tempat aman (backup terenkripsi di luar repo). Kalau hilang, update tidak bisa dipasang lagi di perangkat pengguna.
- Keystore dan `key.properties` tidak boleh di-commit. Sudah dicakup `.gitignore` (`key.properties`, `*.jks`).
- Semua build release harus memakai keystore yang sama.

## Aturan Update Data

- Perubahan skema database wajib menaikkan `AppConstants.databaseVersion` dan menambah blok `if (oldVersion < N)` di `Migrations.onUpgrade`.
- Jangan mengubah atau menghapus kolom/tabel yang sudah dirilis tanpa migrasi.
- Sebelum rilis update, uji upgrade dari APK versi sebelumnya (install di atas, bukan uninstall) dan pastikan data masih tampil.
- Jangan memanggil `LocalDataResetService` dari alur update.

## Cara Build Release

```powershell
flutter build apk --release --android-skip-build-dependency-validation
```

Untuk Play Store:

```powershell
flutter build appbundle --release
```

Hasil APK: `build\app\outputs\flutter-apk\app-release.apk`.

## Riwayat

### 1.1.0+2 (Oktober 2026)

- Auto-detect: BRImo dan Jago ditambahkan, semua app dipantau otomatis tanpa toggle. Status izin di-refresh saat kembali dari Settings, ada tombol buka info app.
- Drafts: confirm tanpa kategori memilih kategori dulu, error ditampilkan, dialog edit dirapikan.
- Beranda: "Rp" dihapus dari saldo periode ini.
- Biometrik: tombol sidik jari dipindah ke bawah tengah layar.
- Recap bulanan: warna slide penutup diperbaiki.

### 1.0.0+1 (Oktober 2026)

- Hapus fitur ekspor data dan dependensi `excel`, `share_plus`.
- Hapus test spike Excel yang kosong.
- Snackbar sukses hapus transaksi dihapus; snackbar gagal tetap.
- Perbaikan test: profil (tema light-only), splash (animasi tanpa spinner), transaksi.
- Application ID diubah dari `com.example.dompetku_app` ke `com.fillah.dompetku` (belum pernah dirilis, data test boleh hilang).
- `MainActivity` dipindah ke `com.fillah.dompetku`.
- Release signing memakai keystore `upload-keystore.jks` (menggantikan debug key).
- Build release APK terverifikasi (applicationId dan signer benar).

## Rencana Lanjutan

- Buat AAB untuk Play Store setelah fitur final.
- Naikkan `version` di `pubspec.yaml` setiap rilis (`versionCode` harus selalu naik).
- Pertimbangkan ubah keystore ke format PKCS12 (saran dari keytool, tidak wajib).

### Tally v4 (Oktober 2026)

- Nama tampilan Tally. Application ID tetap `com.fillah.dompetku`.
- PIN cadangan opsional (hash + salt, secure storage), lockout dibagi dengan biometrik.
- Skema database v3: tabel `recurring_rules` dan `drafts`. Migrasi diuji dari v2 dengan data.
- Recurring: tambah, aktif/nonaktif, hapus (geser). Mode auto membuat transaksi, mode ask membuat draft.
- Drafts: Confirm, Edit, Dismiss, Confirm all, banner Beranda. Dismiss tidak menghapus baris (dedupe_key).
- Auto-detect Android: parser BCA/GoPay/ShopeePay/DANA, OTP dan promo diabaikan, teks mentah tidak disimpan.
- Recap bulanan dan tahunan, halaman Recaps, teks Beranda tanggal 1-3.

Keputusan §13 (sudah diputuskan dan dikerjakan): batas harian recap = total budget keseluruhan / jumlah hari,
quiet streak dihitung sejak transaksi pertama, total recurring (mingguan x52/12, tahunan /12), Forgot PIN hanya bisa menghapus data, biggest single expense ditampilkan.

Wajib sebelum rilis: uji Auto-detect di HP nyata dan uji upgrade dari APK sebelumnya (tanpa uninstall).

### 1.1.2+4 (Oktober 2026)

- Bahasa: pilihan Indonesia (bawaan) atau Inggris di Profil, kartu "Tampilan & data", di bawah Tema. Semua teks UI mengikuti pilihan itu, termasuk nama bulan, label tanggal, dan nama kategori bawaan. Pilihan tersimpan di Shared Preferences (`language`).
- Teks baru: kunci terjemahan adalah teks Indonesia (`'Laporan'.tr`), terjemahan Inggris ada di `lib/core/i18n/en/`. `test/translations_coverage_test.dart` gagal bila ada teks `.tr` tanpa terjemahan Inggris.
- Nama kategori bawaan tetap tersimpan dalam bahasa Inggris di database (tanpa migrasi); tampilannya lewat `CategoryModel.displayName`.
- Laporan: dipilih per bulan (panah kiri/kanan), tanpa pilihan tanggal. Ditambah cincin pengeluaran per kategori, perbandingan dengan bulan lalu (bulan berjalan dibandingkan dengan hari yang setara), pemasukan vs pengeluaran, batang pengeluaran harian. "Statistik belanja" menjadi "Statistik pengeluaran". Rincian pengeluaran dipertahankan.
- Auto-detect: notifikasi yang masuk saat app tertutup ditahan sementara di sisi native (maks. 50 item, 24 jam) dan diambil Dart saat app dibuka, lalu dihapus. Sebelumnya notifikasi seperti ini hilang. Draf baru langsung me-refresh Beranda. Nominal yang didahului kata saldo/sisa tidak diambil sebagai nominal transaksi.
- Simpan otomatis (Auto-detect) kini berfungsi: bila aktif, pembayaran yang terdeteksi langsung dicatat sebagai transaksi di kategori "Other" (bawaan) sesuai jenisnya, dan drafnya ditandai selesai. Bila kategori itu tidak ada, draf tetap menunggu di Draf.
- Dedupe notifikasi: key memakai waktu posting persis, dan notifikasi kembar dengan sumber dan nominal sama dalam 2 menit diabaikan (tabel `drafts` tidak berubah). Menggantikan bucket 5 menit.
- Parser notifikasi: kata "transaksi" tidak lagi dianggap sinyal pengeluaran, "ke rekening" tidak menjadi nama merchant, dan nama merchant dipotong di "pada/sebesar/dengan/dari".
- Kata konfirmasi hapus data mengikuti bahasa: HAPUS (Indonesia) dan DELETE (Inggris).
- Dibersihkan: `docs/FIX_PLAN.md` dan `xlsx_export_service.dart` (kosong) dihapus, `.gitattributes` ditambahkan, README dan spec v3 diberi catatan status.

### 1.1.3+5 (Oktober 2026)

- Versi di Splash dan Profil dibaca otomatis dari paket terpasang (`package_info_plus`), jadi ikut naik mengikuti `version` di `pubspec.yaml`.
- Layar Welcome back dirombak: sapaan sesuai jam (pagi 04.00-10.59, siang 11.00-14.59, sore 15.00-17.59, selain itu malam), kartu angka tersamar, dan tombol sidik jari di bawah. Layar pendek bisa di-scroll.
- Ikon aplikasi baru: huruf T Fraunces bold di atas tinta. Sumber: `assets/logo/app_icon.png` dan `app_icon_foreground.png`, dibuat ulang dengan `dart run flutter_launcher_icons`.
- Anggaran terarsip: daftar kini dimuat saat halaman dibuka (sebelumnya layar berputar terus) dan hanya menampilkan anggaran yang benar-benar diarsipkan. Bila kosong tampil "Tidak ada anggaran terarsip".
- Form anggaran: pilihan periode jadi dua segmen (Bulan ini, Bulan depan) dan tanggal mulai/selesai dalam satu kartu. Pilihan "30 hari" dihapus.
- Urutan di Transaksi dan Anggaran memakai satu komponen bersama, `SortChip`: chip di app bar (ikon urut + label singkat + panah) yang membuka menu kecil berisi label lengkap. Anggaran kini punya urutan Nama Z-A.
- Profil: kartu "Nama tampilan" dihapus. Nama diubah langsung di kartu profil lewat pensil kecil di sudut nama (✓ simpan, ✕ batal). Keterangan "1 dompet · data tersimpan…" diganti jumlah transaksi tercatat.
- Profil: isian nama di kartu tinta dibuat bening (sebelumnya berlatar krem sehingga teks krem tidak terbaca).
- Chip urutan: garis, latar, tinggi, dan sudut disamakan dengan tombol ikon app bar (tombol arsip), tidak lagi bergaris hitam.
- Beranda, kartu Tren pengeluaran dibuat ulang: satu batang per hari dalam satu bulan kalender (28, 29, 30, atau 31 hari menurut kalender), pita dua warna per pekan (Senin-Minggu), garis dan keterangan rata-rata per hari, total di bawah, dan ketuk batang untuk melihat tanggal dan nominal. Bulan dipilih dengan panah; hanya bulan yang punya transaksi (dan bulan ini) yang bisa dikunjungi, tanpa bulan depan. Kartu ini tidak lagi mengikuti chip periode Beranda. Kode lama (`SpendingBars`, `TrendBucket`) dihapus.

### 1.1.4+6 (Oktober 2026)

- Rilis berisi perubahan sejak 1.1.3: tren pengeluaran bulanan, perbaikan isian nama profil, dan chip urutan senada tombol app bar.
