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
