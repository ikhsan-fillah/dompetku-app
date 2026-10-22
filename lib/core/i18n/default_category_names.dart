/// Nama kategori bawaan tersimpan dalam bahasa Inggris di database. Peta ini
/// menampilkannya dalam bahasa yang dipilih pengguna.
const Map<String, String> indonesianCategoryNames = {
  'Food and drinks': 'Makanan & minuman',
  'Transportation': 'Transportasi',
  'Shopping': 'Belanja',
  'Bills': 'Tagihan',
  'Health': 'Kesehatan',
  'Education': 'Pendidikan',
  'Sports': 'Olahraga',
  'Entertainment': 'Hiburan',
  'Family': 'Keluarga',
  'Other': 'Lainnya',
  'Salary': 'Gaji',
  'Freelance': 'Freelance',
  'Business': 'Bisnis',
  'Investment': 'Investasi',
  'Gift': 'Hadiah',
};

final Map<String, String> englishCategoryNames = {
  for (final name in indonesianCategoryNames.keys) name: name,
};
