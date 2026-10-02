# DompetKu Fix Plan

Dibuat dari analisis kode lewat GitHub. File ini hanya dokumen; tidak ada kode aplikasi yang diubah.

## 1. Auth: tidak minta sidik jari lagi

Masalah: `isUnlocked` bernilai false di awal. `HomePage`, middleware `onPageCalled` (app_pages.dart), dan lifecycle di main.dart semua bergantung pada nilai itu, sehingga beranda kosong dan sidik jari diminta ulang.

### auth_controller.dart
Setelah session dibaca dari Shared Preferences, jika `isRegistered.value == true` panggil `unlock()`.

```dart
if (isRegistered.value) {
  unlock();
}
```

### app_pages.dart (onPageCalled)
Ganti syarat dari `isUnlocked` menjadi status login.

```dart
if (!Get.isRegistered<AuthController>() ||
    !Get.find<AuthController>().isRegistered.value) {
  return page.copy(name: AppRoutes.splash, page: () => const SplashPage());
}
return page;
```

### main.dart
Hapus blok lifecycle yang memanggil `Get.offAllNamed(AppRoutes.biometricUnlock)` dan `lockService.shouldLock(...)`. Biometrik dijadikan opsi di Profil (default mati).

### home_page.dart
Hapus cabang `if (!auth.isUnlocked.value)` beserta tombol 'Buka dengan biometrik'. Tampilkan isi beranda langsung.

### Test
Perbarui test/auth_controller_test.dart dan test/profile_controller_test.dart yang menguji perilaku kunci lama.

## 2. Profil kosong (dugaan, perlu dicek)

`ProfileController` didaftarkan dengan `Get.lazyPut` dan beberapa `Get.find()` (reset, export, auth). Jika salah satu layanan belum terdaftar di initial_binding.dart, controller gagal dibuat dan halaman kosong.

Langkah: jalankan `flutter run`, buka tab Profil, baca error `not found`. Daftarkan layanan yang kurang sebelum `ProfileController`.

## 3. Anggaran: tombol Kategori tidak berfungsi

Masalah: di budget_form_controller.dart, `setOverall(false)` tidak mengubah state apa pun.

```dart
final isOverall = true.obs;

void setOverall(bool value) {
  isOverall.value = value;
  if (value) {
    categoryId.value = null;
  } else if (categoryId.value == null && availableCategories.isNotEmpty) {
    categoryId.value = availableCategories.first.id;
  }
  error.value = null;
}
```

Di budget_form_page.dart, ganti sumber `overall` menjadi `controller.isOverall.value`. Saat edit anggaran, set `isOverall.value = budget.categoryId == null`. Validasi simpan menolak mode kategori tanpa kategori terpilih.

## 4. Tambah transaksi: keyboard bawaan HP

Di transaction_form_sheet.dart, ganti tampilan nominal dan keypad kustom dengan satu TextField (pola sama seperti form anggaran).

```dart
TextField(
  controller: _amount,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  textAlign: TextAlign.center,
  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
  decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0', border: InputBorder.none),
)
```

Hapus widget keypad dan state digit-nya. Gunakan `isScrollControlled: true` dan padding `MediaQuery.of(context).viewInsets.bottom` pada bottom sheet. Pindahkan merchant, metode bayar, catatan, dan struk ke bagian 'Detail tambahan' yang bisa dibuka.

## 5. UI transaksi dan anggaran

- Transaksi: ringkasan satu baris di atas, filter jadi chip horizontal atau tombol Filter, item dikelompokkan per tanggal, nominal hijau untuk pemasukan dan rose untuk pengeluaran.
- Anggaran: kartu per anggaran dengan bar progres; warna berubah di 75% (amber), 90%, dan 100% (rose).
- Gunakan AppCard, AppColors, dan AppSpacing yang sudah ada.

## Urutan kerja

1. Auth dan layar kosong
2. Bug anggaran
3. Input nominal
4. Rapikan UI
