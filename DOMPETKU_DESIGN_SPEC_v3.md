# DompetKu — Spesifikasi Desain UI v3 (Light · “Paper & Ink”)

> Dokumen ini diturunkan 1:1 dari `dompetku-mockup-3-1.html`. Semua token, ukuran, teks, dan perilaku di bawah adalah yang terlihat di mockup itu.
> Sumber aturan visual: `anti-ai-slop.md` (dipatuhi penuh).

---

## 0. BACA DULU — Catatan untuk AI / developer

**Ruang lingkup pekerjaan ini: REVISI DESAIN SAJA. JANGAN mengubah fitur.**

1. **Pertahankan semua fitur yang sudah ada di aplikasi saat ini.** Logika bisnis, controller, repository, service, rumus, validasi, alur navigasi, dan penyimpanan data **tidak boleh diubah**. Pekerjaan ini hanya mengganti *tampilan* (warna, tipografi, spacing, bentuk komponen, ikon, microcopy visual).
2. **Fitur di aplikasi saat ini sedikit berbeda dari mockup.** Ada perubahan kecil dan ada fitur tambahan yang dibuat setelah mockup ini. Itu normal dan **tidak perlu disamakan dengan mockup**. Aturannya:
   - Jika sebuah fitur/layar/komponen **ada di app tetapi tidak ada di mockup** → **tetap pertahankan fiturnya**, cukup **sesuaikan desainnya** memakai design system di dokumen ini (token warna, font, radius, komponen di §2–§4). Jangan menghapus atau menyembunyikannya.
   - Jika sebuah fitur **ada di mockup tetapi berbeda implementasinya di app** → ikuti **implementasi app**, ambil hanya gaya visualnya dari mockup.
   - Jika ada layar di mockup yang **belum ada di app** → **jangan membuatnya** dalam pekerjaan ini kecuali diminta terpisah.
3. **Alasan revisi:** desain lama terasa generik (“AI slop”): gradien teal→hijau di mana-mana, emoji sebagai ikon, kartu bulat berbayangan, warna ungu/indigo bawaan framework. Desain baru menggantinya dengan arah **kertas hangat + tinta hijau tua + angka monospace**, flat, bergaris tipis.
4. **Mode tema:** hanya **light mode**. Jangan menambahkan dark mode.
5. **Nama/branding:** nama aplikasi tetap **DompetKu**. Jangan memakai istilah “buku kas” di UI (istilah itu dipakai di mockup sebagai nama arah desain internal saja, bukan copy produk). Gunakan kata “Beranda”, “Transaksi”, “Anggaran”, “Laporan”, “Profil” seperti biasa.
6. **Angka di mockup adalah data contoh**, bukan nilai yang harus muncul di app.

Checklist cepat sebelum merge:
- [ ] Tidak ada `LinearGradient`/gradien apa pun di UI.
- [ ] Tidak ada emoji di tombol, judul, label, atau list item — semua ikon SVG/IconData monoline.
- [ ] Tidak ada hex `#6366F1 #4F46E5 #4338CA #3730A3 #8B5CF6 #7C3AED #A855F7`.
- [ ] Warna aksen `#0E5E55` hanya muncul di **tombol tambah (FAB)**; maksimal 2 pemakaian per layar.
- [ ] Semua nominal rupiah memakai font monospace tabular.
- [ ] Kartu memakai border 1px, **bukan** box-shadow (kecuali bottom nav dan popover).
- [ ] Tidak ada kartu dengan border-kiri berwarna.

---

## 1. Arah desain

**Konsep:** halaman catatan di atas kertas hangat. Latar krem, teks tinta hijau-hitam, satu blok tinta pekat untuk saldo, sisanya kartu krem dengan garis 1px. Angka selalu monospace supaya kolom rupiah sejajar. Satu “gerakan berani”: angka saldo besar bergaya serif (Fraunces) di atas blok tinta.

**Proporsi:** ±80% pola standar (bottom nav 5 slot, bottom sheet, chips, list), ±20% ciri khas (serif untuk judul & angka saldo, blok tinta, baris “laju belanja/hari”, tombol `000`).

**Yang dilarang** (lihat §0 checklist): gradien, emoji ikon, bayangan lembut besar, radius > 14 dp pada kartu, warna indigo/ungu bawaan, teks placeholder “lorem/feature one”.

---

## 2. Design tokens

### 2.1 Warna

| Token | Hex | Pemakaian |
|---|---|---|
| `paper` | `#F4EFE4` | Latar layar (scaffold background) |
| `paper2` | `#EBE4D4` | Permukaan sekunder: keypad, segmented control track, chip kategori aktif, kartu “Kategori teratas”, ring/donut track |
| `card` | `#FFFCF5` | Latar kartu, bottom sheet, popover, bottom nav, input |
| `ink` | `#1A2724` | Teks utama; latar blok saldo (hero); chip aktif; tombol utama; FAB-nya BUKAN ini |
| `ink2` | `#44524E` | Teks sekunder (deskripsi, subjudul) |
| `mut` | `#7C847F` | Teks redup: label, metadata, placeholder |
| `line` | `#D8D0BF` | Border kartu, border chip/tombol outline, divider tegas |
| `line2` | `#E8E1D1` | Divider halus antar baris list |
| `accent` | `#0E5E55` | **Hanya** FAB tambah transaksi + garis scan struk. Maks 2 titik per layar |
| `accentSoft` | `#DCEBE6` | Cadangan (tidak dipakai di mockup) |
| `spend` | `#A8432F` | Pengeluaran: nominal negatif, segmented “Pengeluaran” aktif, badge Habis, tombol danger |
| `spendSoft` | `#F3E1DA` | Latar badge Habis, latar ikon hapus, lingkar fpbtn gagal |
| `earn` | `#2E6B3C` | Pemasukan: nominal positif, segmented “Pemasukan” aktif, badge Aman, titik “live” |
| `earnSoft` | `#E0EDDD` | Latar badge Aman, delta positif |
| `warn` | `#9A6A12` | Badge Waspada (75–89%), progress waspada, ikon banner peringatan |
| `warnSoft` | `#F4E8CB` | Latar badge Waspada, latar banner `.am`, latar field OCR “Periksa” |
| `crit` | `#9C3B12` | Badge Kritis (90–99%), progress kritis |
| `critSoft` | `#F3DDD0` | Latar badge Kritis |

Teks di atas `ink` (blok saldo, chip aktif, tombol utama) memakai `paper` `#F4EFE4`. Garis pemisah di dalam blok saldo: `rgba(244,239,228,.18)`.

**Warna kategori pengeluaran** (ikon putih di atas warna ini):

| Kategori | Hex | Ikon |
|---|---|---|
| Makanan | `#C4892A` | food (garpu/pisau) |
| Transportasi | `#3F7A9E` | bus |
| Belanja | `#8A5A3B` | bag |
| Tagihan | `#5B7B6A` | doc |
| Lainnya | `#8A8F8B` | dots (⋯ sebagai SVG) |
| Kesehatan | `#B2556A` | heart |
| Pendidikan | `#4E6A8F` | book |
| Hiburan | `#C9743A` | star |

**Warna kategori pemasukan:** Gaji `#2E6B3C` (wallet), Freelance `#4C7A3F` (edit), Bisnis `#0E5E55` (bag), Investasi `#6F8A2E` (up), Hadiah `#9A5A6A` (star), Lainnya `#8A8F8B` (dots). Ikon transaksi pemasukan di daftar selalu memakai `#2E6B3C` dengan ikon panah bawah (“down” = uang masuk).

### 2.2 Tipografi

Tiga keluarga font (Google Fonts): **Fraunces** (display, serif, weight 300–500, italic tersedia), **Manrope** (body, 400–800), **JetBrains Mono** (angka, 400–500). Di Flutter gunakan `google_fonts`.

| Peran | Font | Ukuran / weight | Catatan |
|---|---|---|---|
| Angka saldo (hero) | Fraunces | 38 / 500, line-height 1.05, letter-spacing −0.01em | Prefix “Rp” kecil 13 px JetBrains Mono, opacity .7, posisi superscript |
| Judul layar (`pagetitle`) | Fraunces | 26 / 500 | “Transaksi”, “Anggaran”, “Laporan”, “Profil”, “Kategori”, “Periksa struk” |
| Nama app di beranda (`who h1`) | Fraunces | 21 / 500 | “DompetKu” |
| Judul bottom sheet / dialog | Fraunces | 19–20 / 500 | “Tambah transaksi”, “Hapus semua data?” |
| Judul layar auth (`sheetw h2`) | Fraunces | 24 / 500, line-height 1.15 | |
| Hitung mundur lockout | JetBrains Mono | 44 / 500 | warna `spend` |
| Nominal besar di sheet (`amount b`) | Fraunces | 36 / 500 | warna `spend`/`earn` sesuai jenis |
| Judul kartu (`card h3`) | Manrope | 13 / 700, letter-spacing .01em | |
| Isi teks | Manrope | 13–14 / 400 | |
| Nama transaksi | Manrope | 13 / 700 | ellipsis 1 baris |
| Nominal di daftar/pill/fav | JetBrains Mono | 12–13 / 500, `tabular-nums`, letter-spacing −0.02em | |
| Label kecil (`lbl`, `grp`) | Manrope / JetBrains Mono | 10.5 / 700, **uppercase**, letter-spacing .06em, warna `mut` | “KATEGORI”, “METODE PEMBAYARAN”, “28 SEP 2026” |
| Metadata (`mut`) | Manrope | 10.5–11 / 400, warna `mut` | |
| Chip | Manrope | 12 / 600 | |
| Tombol utama | Manrope | 14 / 700 | |
| Status bar jam | JetBrains Mono | 12 / 700 | |

Semua yang menampilkan angka uang WAJIB `fontFeatures: [FontFeature.tabularFigures()]`.

### 2.3 Ukuran & bentuk

| Properti | Nilai |
|---|---|
| Margin horizontal layar | 16 dp |
| Padding kartu | 16 dp |
| Jarak antarkartu | 12 dp (row2 grid gap 10 dp) |
| Radius kartu (`r`) | 10 dp |
| Radius blok saldo / popover / sheet auth (`rLg`) | 14 dp |
| Radius chip, tombol kecil, input, keypad | 6–8 dp |
| Radius tombol utama | 10 dp |
| Radius bottom sheet (atas) | 22 dp |
| Radius bottom nav | 18 dp |
| FAB | 56 × 56, radius 16, border 4 dp warna `paper` |
| Tinggi bottom nav | 66 dp, floating 12 dp dari tepi kiri/kanan/bawah |
| Tinggi tombol utama | ≥ 48 dp (padding 14) |
| Ikon tombol bulat (`iconbtn`) | 38 × 38, radius 8, border 1px `line`, latar `card` |
| Ikon kategori di list (`ci`) | 36 × 36, radius 8 (40 di beberapa list lama → gunakan 36) |
| Ikon kategori di chip pilih (`cc i`) | 36 × 36, radius 8 |
| Ikon kategori favorit (`fav ci`) | 32 × 32, radius 8 |
| Avatar | 40 (beranda), 54 (profil), 56–64 (unlock); lingkaran; latar `ink`, inisial Fraunces `paper` |
| Divider | 1 dp `line2` (dalam list) / `line` (pemisah tegas) |
| Progress bar | tinggi 6 dp, **radius 0**, track `paper2` |
| Progress mini di kartu favorit | tinggi 3 dp, track `line2` |
| Donut | 136 × 136, r = 54, stroke 18 (24 saat terpilih), track `#EBE4D4` |
| Ring anggaran | 96 × 96, r = 40, stroke 10, linecap round |
| Phone frame mockup | 360 × 740 (hanya untuk referensi proporsi) |

### 2.4 Ikon

SVG monoline, stroke **1.8 px** (1.6 untuk ikon besar ≥ 40 px, 2.2–2.4 untuk check/x kecil), `stroke-linecap: round`, `stroke-linejoin: round`, `currentColor`, viewBox 24. Set yang dipakai: home, list, plus, pie, user, cal, up, down, food, bus, bag, doc, dots, search, finger, lock, camera, bulb, chev, back, shield, tag, dl (download), trash, check, x, filter, target, wallet, heart, book, star, copy, edit, bell, menu (drag handle 2 garis). Di Flutter: pakai `lucide_icons` / `phosphor_flutter` (regular/light) dengan stroke setara, **jangan** Material filled icons dan **jangan** emoji.

### 2.5 Motion & micro-interaction

| Elemen | Perilaku |
|---|---|
| Semua tombol | `translateY(1px)` saat ditekan (scale 0.98 juga boleh) |
| Angka saldo | Saat periode berganti: count-up/count-down dari nilai lama ke baru, 520 ms, easing cubic-out; plus fade-in `opacity .3→1, translateY 4→0` 350 ms |
| Bottom sheet | Slide dari bawah 300 ms `cubic-bezier(.2,.9,.3,1)`; dim `rgba(26,39,36,.5)` fade 250 ms |
| Popover periode | Fade 200 ms |
| Toast | Fade 200 ms, tampil 1.9 detik, posisi 98 dp dari bawah |
| Progress bar | Lebar beranimasi 400 ms |
| Donut segmen | Transisi stroke-width & opacity 250 ms |
| Garis scan struk | Bergerak atas↔bawah 2.2 s loop, tinggi 2 dp, warna `accent`, opacity .6 |
| Loader splash | Garis 120 × 2 dp, segmen 40% bergeser kiri→kanan 1.3 s loop |
| Titik “live” | Lingkaran 6 dp `earn`, **tanpa** animasi pulse |

---

## 3. Komponen

### 3.1 Status bar
Tinggi 42, padding 12 24 0; jam “9:41” JetBrains Mono 12/700; indikator sinyal 3 batang + baterai outline. Warna `ink` di layar terang, `paper` di layar auth gelap. Notch 96 × 26 warna `#141C1A`.

### 3.2 App bar beranda (`appbar`)
Baris flex space-between, padding 6 0 14. Kiri: avatar 40 (inisial “IF”) + kolom [label kecil 11 px `mut` (contoh: “Catatan Ikhsan” — ganti “buku kas” dengan kata netral) ; “DompetKu” Fraunces 21]. Kanan: **date chip**: ikon `cal` 15 + rentang tanggal, JetBrains Mono 11.5/600, padding 7 10, radius 6, border 1px `line`, latar transparan; hover/aktif: border `ink`, latar `card`. **Tidak ada ikon refresh.**

### 3.3 App bar layar lain
Judul `pagetitle` Fraunces 26 di kiri; aksi di kanan (date chip atau `iconbtn` plus). Layar sekunder (Laporan, Kategori, Periksa struk) memakai `back`: `iconbtn` panah kiri + judul.

### 3.4 Kartu (`card`)
Latar `card`, border 1px `line`, radius 10, padding 16, margin-bottom 12. Judul `h3` Manrope 13/700 dengan link kanan opsional (Manrope 11.5/600 `ink2`, underline offset 3 px, warna garis `line`).

### 3.5 Blok saldo (`hero-card`)
Latar `ink`, radius 14, padding 20 18 16, teks `paper`. Isi:
1. Label uppercase 11.5/700 opacity .7: “SISA · 1 BULAN” (nama preset periode).
2. Angka: `Rp` kecil + nominal Fraunces 38.
3. Garis `rgba(244,239,228,.18)`, lalu **pills** grid 2 kolom: [ikon lingkaran 22 latar `earn` panah atas | “Masuk” 10 px opacity .7 | nominal mono 12.5/500] dan [ikon lingkaran 22 latar `spend` panah bawah | “Keluar” | nominal]; kolom kedua diberi border-left 1px dan padding-left 12.
4. Baris **pace** (border-top, padding-top 10, 10.5 px opacity .85): kiri “Laju belanja **Rp 125.862/hari**”, kanan “Batas **Rp 166.667/hari**” (nominal mono 500). Laju = pengeluaran periode ÷ jumlah hari periode; batas = anggaran bulanan ÷ hari dalam bulan.

Di layar Anggaran blok yang sama dipakai dengan: label “BATAS SEPTEMBER”, angka 30 px “Rp 3.650.000 / Rp 5.000.000” (pembagi 12 px mono opacity .7), progress 8 dp track `rgba(244,239,228,.18)` isi warna status, lalu baris “Sisa Rp …” (mono) dan badge status (latar `paper`, teks warna status, radius 4, 11 px).

Di Profil: blok yang sama padding 16, avatar 54 latar `paper` teks `ink`, nama Fraunces 18, sub 11 px opacity .75.

### 3.6 Chips periode (`chips/chip`)
Baris horizontal scroll, gap 6, padding-bottom 12. Chip: padding 7 12, radius 6, border 1px `line`, Manrope 12/600 `ink2`, latar transparan. Aktif: latar `ink`, teks `paper`, border `ink`. Preset: Hari ini · 1 Minggu · 1 Bulan · 3 Bulan · Tahun ini · Kustom.

### 3.7 Baris “live”
Di bawah chips: titik 6 dp `earn` + teks 10.5 px `mut`: “Tersimpan di perangkat · dihitung ulang tiap transaksi, tanpa tombol refresh”.

### 3.8 Grid 2 kolom (`row2`)
Gap 10. Kiri: kartu “Anggaran bulan ini” dengan ring 96 (track `#EBE4D4`, isi warna status, angka % mono 20/500 di tengah, warna status) dan teks 11 px `mut` tengah “Hari ke-29 dari 30 · **Aman**”. Kanan: kartu latar `paper2` “Paling banyak”: ikon kategori 40, nama 14/700, nominal mono `mut`, badge `st` latar `card` border `line` “38% dari keluar”.

### 3.9 Donut “Pengeluaran per kategori”
Donut 136 kiri; legenda kanan: baris `lg` (padding 5 4, border-bottom `line2`, 11.5 px): kotak 8 × 8 radius 2 warna kategori · nama (ellipsis) · persen mono 11/500. Baris terpilih/hover latar `paper2`. Tengah donut: label 9.5 `mut` “Total” + nominal 12/500; saat segmen diketuk: nama, nominal, persen (warna kategori). Segmen lain opacity .35. Catatan di bawah 11 px `mut`: “Diurutkan dari terbesar ke terkecil · ketuk irisan untuk detail”. Persentase dibulatkan metode sisa terbesar (total selalu 100).

### 3.10 Tren batang (`bars`)
Tinggi 118, padding-top 22, gap 4, border-bottom 1px `line`. Batang: latar `paper2`, border-top 2 dp `line`, radius 2 2 0 0, min-height 6. Aktif: latar & border `ink`; tooltip (`tip`) latar `ink` teks `paper` 9.5 px mono radius 4 di atas batang. Label sumbu 9 px mono `mut`.

### 3.11 Kartu favorit (`favs/fav`)
Grid 2 kolom gap 10. Kartu radius 10 border `line` padding 12; ikon kategori 32 radius 8 (ikon 17, stroke 1.8); nama 11 `mut`; nominal mono 13/500; progress mini 3 dp warna kategori (lebar = porsi terhadap total). Hover: border `ink`. Maks 4 favorit (ditandai bintang di layar Kategori).

### 3.12 Baris transaksi (`tx`)
Flex gap 11, padding 9 0, border-bottom `line2` (terakhir tanpa border). Ikon kategori 36 radius 8 ikon putih. Tengah: nama 13/700 ellipsis; sub 10.5 `mut`: “Makanan · 28 Sep · QRIS” (pemasukan: “Pemasukan · Gaji · 25 Sep · Transfer”). Kanan: nominal mono 12.5/500, “− Rp 45.000” `spend` / “+ Rp 5.000.000” `earn` (tanda minus pakai U+2212).
Baris aksi (`txact`) muncul saat baris diketuk: tombol kecil padding 6 10 radius 6 latar `paper2` 11/700 “Edit”, “Duplikat”, dan “Hapus” (latar `spendSoft`, teks `spend`), indent 47 dp.

Di layar Transaksi, daftar dikelompokkan per tanggal dengan header `grp` mono 10.5/700 uppercase tracking .06em: “HARI INI · 28 SEP 2026”, lalu kartu padding 4 14.

### 3.13 Banner insight (`banner`)
Flex gap 11, radius 10, padding 12, border 1px `line`, margin-bottom 10. Ikon kotak 34 radius 8 latar `card` border `line`. Judul 12.5/… , sub 10.5 `ink2`. Varian `am`: latar `warnSoft`, border transparan, ikon `bell` warna `warn` (“Tagihan tinggal Rp 12.000 lagi” / “97% dari batas bulan ini · ketuk untuk geser batas”). Varian `tl`: latar `card`, ikon `pie` warna `ink` (“Makanan +18% dibanding bulan lalu” / “Angka contoh · detail di Laporan”). Teks insight bernada netral, tidak menghakimi.

### 3.14 Bottom navigation (`nav`)
Floating: left/right/bottom 12, tinggi 66, latar `card`, border 1px `line`, radius 18, shadow `0 14px 30px rgba(26,39,36,.14)` (satu-satunya bayangan yang diizinkan selain popover). Grid 5 kolom `1fr 1fr 74px 1fr 1fr`. Item: ikon 20 (stroke 1.6) dalam `ib` padding 4 14 radius 8 + label 10 px/600 `mut`. Aktif: teks `ink` 800, `ib` latar `paper2`. Urutan: Beranda · Transaksi · [FAB] · Anggaran · Profil.
**FAB**: 56 × 56, radius 16, latar `accent`, ikon plus putih 24 stroke 2.4, border 4 dp `paper`, shadow `0 10px 22px rgba(14,94,85,.35)`, margin-top −30 (menonjol ke atas). Hover naik 2 dp.

### 3.15 Bottom sheet (`sheet`)
Posisi bawah, max-height 92%, latar `card`, border-top 1px `line`, radius 22 22 0 0, padding 10 16 18, grabber 40 × 4 `line` di tengah. Dim di belakang `rgba(26,39,36,.5)`.

### 3.16 Segmented control (`seg`)
Track latar `paper2`, radius 8, padding 3, gap 3. Tombol padding 9, radius 6, Manrope 12.5/700 `mut`. Aktif: `ex` → latar `spend` teks putih; `in` → latar `earn` teks putih; `g` (netral, dipakai di Laporan/Kategori) → latar `card` teks `ink` border `line`.

### 3.17 Chip kategori pilih (`cc`)
Kolom 60 dp: ikon 36 radius 8 + nama 10 px `mut`; padding 6 0, radius 8, border 1px transparan. Aktif: border `ink`, latar `paper2`, teks `ink` 700.

### 3.18 Chip metode bayar / tanggal (`pay`)
Padding 7 11, radius 6, border `line`, Manrope 11.5/600, inline-flex gap 6 (boleh berisi ikon 13). Aktif: latar `ink` teks `paper`. Nilai: Tunai · E-wallet · QRIS · Transfer · Kartu debit · Kartu kredit. Chip tanggal “Hari ini · 29 Sep” (ikon `cal`) aktif; tombol “Scan struk” (ikon `camera`) di sebelahnya.

### 3.19 Input (`field`)
Padding 11 14, radius 8, border 1px `line`, latar `card`, 12.5 px. Fokus: border `ink`. Placeholder `mut`. Kolom cari di Transaksi: ikon `search` 18 di kiri (padding-left 42), placeholder “Cari warung, merchant, catatan…”.

### 3.20 Keypad (`keys`)
Grid 3 kolom gap 6. Tombol padding 11, radius 8, latar `paper2`, JetBrains Mono 17/500. Tombol `000` ukuran 13 px warna `mut` (pintasan, bukan angka). Tombol `⌫` boleh glyph atau ikon. Tekan: latar `line`, turun 1 dp. Batas input 10 digit; nol di depan ditolak.

### 3.21 Tombol (`btn`)
Lebar penuh, padding 14, radius 10, Manrope 14/700, latar `ink` teks `paper`; hover `#0F1917`. Varian: `ghost` latar `paper2` teks `ink`; `line` transparan border 1px `ink`; `danger` latar `spend` teks putih; `sm` padding 9 14, 12 px, radius 8, lebar auto. Ikon di tombol 18 px, stroke 2.2.

### 3.22 Popover periode (`pop`)
Posisi top 96, left/right 12; latar `card`, border `line`, radius 14, shadow `0 20px 44px rgba(26,39,36,.22)`, padding 14. Judul `lbl`. Baris preset `pr`: padding 10, radius 6, border-bottom `line2`; nama 12.5/700 + rentang mono 10.5 `mut`; aktif/hover latar `paper2`, centang `ink` di kanan. “Rentang kustom”: dua kotak `dates` latar `paper2` radius 6 (label 9.5 “Mulai/Selesai” + tanggal mono 12/500), tombol `btn sm` lebar penuh “Terapkan rentang”.

### 3.23 Toast
Latar `ink`, teks `paper` 12 px, padding 10 16, radius 8, shadow `0 10px 24px rgba(0,0,0,.25)`. Contoh: “Tersimpan · dashboard diperbarui otomatis”, “Transaksi dihapus”, “Maksimal 4 kategori favorit”, “Isi jumlah lebih dulu”.

### 3.24 Badge status (`st`)
Padding 3 7, radius 4, 10 px/700, letter-spacing .02em. Ambang: Aman < 75% (`earnSoft`/`earn`), Waspada ≥ 75% (`warnSoft`/`warn`), Kritis ≥ 90% (`critSoft`/`crit`), Habis ≥ 100% (`spendSoft`/`spend`). Progress bar memakai warna solid yang sama.

### 3.25 Baris pengaturan (`set`)
Padding 12 0, border-bottom `line2`. Ikon kotak 34 radius 8 latar `paper2` warna `ink`. Judul 13/700, sub 10.5 `mut`. Kanan: toggle `sw`, badge `st`, atau chevron.
**Toggle `sw`:** 42 × 24, radius 24, track `line`; knob 18 putih, shadow kecil; aktif: track `ink`, knob geser ke kanan.

### 3.26 Baris kategori / anggaran (`bd`)
Padding 12 0, border-bottom `line2`, gap 12. Di Anggaran: ikon kategori 36 · [nama 12.5/700 + badge status di kanan] · progress 6 dp · “Rp 1.387.000 dari Rp 1.500.000” mono 11 `mut`. Di Kategori: handle drag `menu` warna `line` · ikon kategori · nama 13/700 + sub “Bawaan · tidak bisa dihapus bila dipakai” · bintang 20 (`ink` jika favorit, `line` jika tidak).

### 3.27 Struk OCR (`receipt`, `of`)
Kartu struk: latar `#FFFEFA`, radius 4, padding 16, border `line`, shadow `0 10px 24px rgba(26,39,36,.14)`, **rotasi −1°**, font JetBrains Mono 11 warna `#3A3A3A`, garis putus `#B9B2A3`; garis scan `accent` bergerak. Field hasil (`of`): padding 10 12, radius 6, latar `card`, border `line`, label 10 `mut` + nilai mono; status kanan “✓ Yakin” → ikon `check` 13 + teks 11/700 `earn`; “Periksa” → ikon `bell` + teks `warn`, kartu latar `warnSoft` border `warn`; “Ubah” → teks `ink` underline. Catatan tengah: ikon `lock` 12 + “Belum ada yang tersimpan sampai kamu menekan Konfirmasi.” Dua tombol: `ghost` “Foto ulang” · `btn` “Konfirmasi”.

---

## 4. Spesifikasi per layar (14 layar)

Urutan dan isi mengikuti mockup. Fitur yang ada di app tetapi tidak tercantum di sini: tetap ada, cukup di-restyle (lihat §0).

### 4.1 Splash
Layar penuh latar `ink`, teks `paper`. Status bar terang. Garis atas (`rule`, top 52, border-top `rgba(244,239,228,.2)`) dengan teks mono 10.5 uppercase kiri “PENCATAT KEUANGAN” (ganti dari “buku kas pribadi”) dan kanan “v1.0.0”. Tengah: kotak logo 84 × 84 radius 20 latar `paper` ikon `wallet` 40 `ink`; wordmark Fraunces 40 “Dompet*Ku*” (“Ku” italic 300); tagline 13 px opacity .75 “Uangmu, catatanmu, tetap di ponselmu.”; loader 120 × 2. Durasi dari inisialisasi sesi nyata, bukan delay tetap. Lanjut ke Login (baru) atau Unlock (pengguna lama).

### 4.2 Login / Onboarding
Latar `ink`. `rule`: “MULAI” · “01 / 02”. Bagian atas (padding 40 22 0): label mono 11 opacity .6 “CONTOH TAMPILAN DATA”; empat baris contoh transaksi dengan border `rgba(244,239,228,.14)` (nama 13 · nominal mono 400 opacity .9: Gaji September +5.000.000, Listrik PLN −438.000, Warung Sederhana −45.000, Gojek −32.000); baris “Sisa” + Fraunces 26 “Rp 4.485.000”.
Bawah: kartu `sheetw` (latar `card`, radius 14, padding 22 20): h2 Fraunces 24 “Catat uang tanpa menyerahkannya ke siapa pun.”; p 12 `ink2` “Pemasukan, pengeluaran, anggaran — semuanya dihitung dan disimpan di perangkat ini.”; tiga baris `feat` (ikon kotak 28 radius 6 latar `paper2`): shield “Dibuka dengan sidik jari / wajah”, lock “Tanpa akun, tanpa cloud, tanpa iklan”, camera “Scan struk, lalu kamu yang memutuskan”; tombol `btn` “Mulai & pasang kunci biometrik ›”.

### 4.3 Setup biometrik
Latar `ink`. `rule`: “KUNCI” · “02 / 02”. Tengah: `fpbtn` 104 lingkaran latar `paper` ikon `finger` 52 `ink` (ring `rgba(244,239,228,.12)` 10 dp); saat berhasil ikon `check`. Kartu bawah: h2 “Pasang kunci dulu.” / sukses “Terkunci rapi.”; p “Verifikasi biometrik sekali. Angka tidak akan tampil sebelum kamu lolos. DompetKu tidak menyimpan data sidik jari/wajah — itu urusan sistem operasi.” / sukses “Membuka dashboard…”; `btn` ikon finger “Verifikasi biometrik” (saat proses: opacity .6, teks “Memverifikasi…”); `btn line` “Perangkat tanpa biometrik? Pakai PIN” (jika app sudah punya fallback PIN, hubungkan ke sana).

### 4.4 Unlock (pengguna kembali)
Latar `paper`. Konten tengah: avatar 64 inisial; h2 Fraunces 26 “Selamat datang kembali” (mockup memakai kalimat lain — boleh pilih yang netral); p `mut` “Verifikasi untuk membuka”; `fpbtn` latar `ink` ikon finger 52 `paper`, ring `paper2` 10 dp; saat gagal: latar `spend`, ring `spendSoft`. Lima titik `dots` 10 dp border `line`; titik gagal terisi `spend`. Teks `mut`: “Ketuk ikon sidik jari untuk memulai” / “Autentikasi gagal · percobaan 2 dari 5”. Teks bawah mono: “5× gagal = dikunci 5:00”. (Panel “Simulasi hasil” hanya untuk mockup — jangan dibuat.)

### 4.5 Terkunci sementara (lockout)
Latar `paper`. Kotak 88 radius 22 latar `spendSoft` ikon `lock` 42 `spend`; h2 Fraunces 26 “Jeda sebentar.” (atau “Terkunci sementara”); p `mut` maks 250 dp “Terlalu banyak percobaan biometrik. Demi keamanan, coba lagi setelah hitung mundur selesai.”; hitung mundur mono 44/500 `spend` format `m:ss`; teks `mut` “Data keuanganmu tetap tersembunyi”. Setelah 5:00 kembali ke Unlock. (Tombol “Lewati” hanya demo.)

### 4.6 Beranda
Urutan vertikal (padding bawah 110 untuk nav):
1. App bar (§3.2).
2. Blok saldo (§3.5).
3. Chips periode (§3.6).
4. Baris live (§3.7).
5. `row2`: Anggaran bulan ini (ring) · Paling banyak (§3.8).
6. Kartu “Pengeluaran per kategori” + link “Laporan” → donut (§3.9).
7. Kartu “Tren pengeluaran” + label preset `mut` di kanan → batang (§3.10).
8. Favorit 2 × 2 (§3.11).
9. Kartu “Transaksi terbaru” + link “Lihat semua” → 4 baris `tx` tanpa aksi.
10. Banner `am` anggaran + banner `tl` insight (§3.13).
Semua kartu dihitung ulang saat periode berubah, transaksi disimpan, atau app kembali aktif. Tidak ada tombol refresh.

### 4.7 Pilih periode (popover)
§3.22. Preset menutup popover dan memperbarui semua kartu.

### 4.8 Tambah transaksi (bottom sheet)
Header: “Tambah transaksi” Fraunces 19 + `iconbtn` 34 ikon `x`. Segmented Pengeluaran | Pemasukan (§3.16). `amount`: label “Jumlah (IDR)” 11 `mut`, nominal Fraunces 36 warna sesuai jenis, format “Rp 1.250.000”. Baris chip tanggal aktif + “Scan struk” (§3.18). `lbl` “KATEGORI” → chips `cc` scroll horizontal. `lbl` “METODE PEMBAYARAN” → chips `pay`. `lbl` “CATATAN (OPSIONAL)” → `field` placeholder “Contoh: makan siang bersama tim”. Keypad (§3.20). `btn` ikon check “Simpan transaksi” (mockup memakai “Catat ke buku kas” — **gunakan “Simpan transaksi”**). Validasi: jumlah kosong → toast “Isi jumlah lebih dulu”. Sukses → sheet tutup, toast, Beranda diperbarui.

### 4.9 Periksa struk (OCR review)
`back` + judul “Periksa struk”. Kartu struk + garis scan, spacer 16, empat `of`: Merchant (Yakin), Tanggal (Yakin), Total (Periksa — warn), Kategori disarankan (Ubah). Catatan lock. Tombol `row2`: Foto ulang · Konfirmasi. Tidak ada data tersimpan sebelum Konfirmasi.

### 4.10 Transaksi
App bar: judul “Transaksi” + date chip (awal rentang + “…”). Kolom cari. Chips filter: Semua · Pengeluaran · Pemasukan · “Kategori ▾” · “Urutkan ▾” (chip aktif gaya §3.6). `row2` dua kartu ringkas padding 12: “Masuk” nominal `earn` mono, “Keluar” nominal `spend` mono (tanpa latar berwarna). Daftar per tanggal (§3.12). Empty state: kotak 64 radius 12 latar `paper2` ikon `search` 28, judul “Tidak ada hasil” 700, sub “Coba kata kunci atau filter lain.” Pencarian langsung saat mengetik.

### 4.11 Anggaran
App bar: “Anggaran” + `iconbtn` plus. Blok saldo varian anggaran (§3.5). (Kartu “Simulasi” hanya mockup — jangan dibuat.) Banner peringatan sesuai ambang: ≥100 latar `spendSoft` “Batas terlewati / Pengeluaran melewati batas bulan ini”; ≥90 latar `critSoft` “Hampir habis (90%) / Kurangi pengeluaran non-esensial”; ≥75 `am` “Sudah 75% terpakai / Masih ada waktu untuk mengatur ritme”. Kartu “Per kategori” → baris `bd` (§3.26). Warna progress & badge mengikuti §3.24.

### 4.12 Laporan
`back` + “Laporan”. Segmented 3 kolom varian `g`: Kategori · Tren · Bandingkan.
- **Kategori:** kartu “Kategori · 1 Bulan” → tiap baris: kotak warna 10 + nama (12 px) kiri, “38% · Rp 1.387.000” 700 kanan, progress 6 dp warna kategori (lebar relatif terhadap kategori terbesar).
- **Tren:** kartu “Pemasukan vs pengeluaran”: `gbar` 110 dp, pasangan batang `earn`/`spend` radius 2 2 0 0, label “Mgg 1–4”, legenda kotak 9 × 9; kartu “Tren harian” (batang §3.10).
- **Bandingkan:** kartu “Dibanding periode sebelumnya setara” → baris `bd`: judul 12.5/700 + sub `mut` “Sekarang Rp … · Sebelumnya Rp …”, `delta` di kanan (mono 10.5/500, radius 4; naik-buruk `spendSoft`/`spend` “+9,9%”, turun-baik `earnSoft`/`earn` “−11%”).
Di bawah semua tab: `row2` “Rata-rata harian / Rp 125.862” · “Hari termahal / 15 Sep · Rp 420.000” (nominal mono); kartu “Merchant teratas” (nomor urut dalam lingkaran 32 latar `paper2` mono, nama 12.5/700, “3 transaksi” `mut`, nominal mono); banner `tl` “Catatan periode” / “Makanan 18% lebih tinggi dari bulan sebelumnya. Tidak ada saran — hanya fakta.”

### 4.13 Profil
Judul “Profil”. Blok identitas (§3.5 varian profil): nama, sub “1 dompet · 128 catatan · tidak pernah meninggalkan ponsel ini” (sesuaikan dengan data app). Kartu “Keamanan”: Kunci biometrik (toggle) “Wajib sebelum data tampil”; Kunci otomatis (badge: Langsung / 1 menit / 5 menit) “Setelah keluar dari aplikasi”. Kartu “Kelola”: Kategori, Anggaran, Laporan (chevron). Kartu “Tampilan & data”: Tema (badge “Terang”; sub “Terang (mode gelap tidak dipakai)”), Ekspor data “Simpan cadangan di perangkat”, Hapus semua data (ikon & teks `spend`, sub “Tidak dapat dibatalkan”). Footer mono `mut` tengah “DompetKu 1.0.0 · tanpa akun · tanpa cloud”.
**Dialog hapus:** sheet mengambang (bottom 16, left/right 14, radius 14, border `line`), ikon trash dalam kotak 56 `spendSoft`, judul Fraunces 20 “Hapus semua data?”, p `mut` “Transaksi, anggaran, dan kategori kustom akan dihapus permanen dari perangkat ini. Ekspor dulu bila perlu.”, tombol `line` “Batal” lalu `danger` “Ya, hapus”.

### 4.14 Kategori
`back` + “Kategori”. Segmented `g`: Pengeluaran | Pemasukan. Teks `mut`: “Ketuk bintang untuk menjadikan favorit di Beranda (maks. 4). Tahan & seret untuk mengurutkan.” Kartu padding 4 14 berisi baris `bd` (§3.26). Tombol `btn` ikon plus “Kategori baru”. Kategori yang sudah dipakai transaksi tidak bisa dihapus, hanya diarsipkan (perilaku app tetap).

---

## 5. Pemetaan ke Flutter (panduan, bukan perubahan fitur)

| Area | Saran implementasi |
|---|---|
| Tema | `ThemeData(brightness: light, scaffoldBackgroundColor: paper, colorScheme: ColorScheme.light(primary: ink, secondary: accent, error: spend, surface: card, outline: line))`, `useMaterial3: true`, `splashFactory: NoSplash` + feedback tekan via scale/translate |
| Font | `GoogleFonts.fraunces`, `GoogleFonts.manrope`, `GoogleFonts.jetBrainsMono`; buat `AppText` dengan style di §2.2 |
| Kartu | `Container(decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: 10))` — **tanpa** `BoxShadow` |
| Blok saldo | `Container` latar `ink`, radius 14; angka memakai `TweenAnimationBuilder<double>` 520 ms curve `Curves.easeOutCubic` |
| Chips | `ChoiceChip` kustom atau `Container` sendiri; hindari default Material chip shape |
| Bottom nav | `Stack` + `Positioned(left:12,right:12,bottom:12)` container radius 18, FAB terpisah dengan `Transform.translate(-30)` |
| Donut/ring/batang | `CustomPainter` atau `fl_chart` dengan warna token; batang **tanpa** gradien |
| Ikon | `lucide_icons` (stroke 1.8) |
| Format uang | `NumberFormat.currency(locale:'id_ID', symbol:'Rp ', decimalDigits:0)`; minus memakai “−” (U+2212) |

Semua widget di atas hanya menggantikan tampilan; sambungkan ke controller/state yang sudah ada tanpa mengubah kontraknya.
