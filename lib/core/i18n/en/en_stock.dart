const Map<String, String> enStock = {
  'Saham': 'Stocks',
  'Watchlist, data broker, dan analisis':
      'Watchlist, broker data, and analysis',
  'Tambah saham': 'Add stock',
  'Kode saham': 'Stock code',
  'Tambah': 'Add',
  'Email': 'Email',
  'Password': 'Password',
  'Masuk ke Supabase': 'Sign in to Supabase',
  'Keluar dari Supabase': 'Sign out of Supabase',
  'Supabase belum dikonfigurasi': 'Supabase is not configured',
  'Jalankan app dengan --dart-define=SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.':
      'Run the app with --dart-define=SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
  'Email dan password wajib diisi.': 'Email and password are required.',
  'Tidak bisa terhubung ke Supabase.': 'Cannot reach Supabase.',
  'Watchlist masih kosong': 'The watchlist is empty',
  'Tambah saham yang ingin dipantau, contoh BBCA.':
      'Add a stock to follow, for example BBCA.',
  'Saham nonaktif tidak dianalisis lagi, riwayatnya tetap tersimpan.':
      'Inactive stocks are no longer analyzed, but their history is kept.',
  'aktif': 'active',
  'nonaktif': 'inactive',
  'Gagal memuat watchlist.': 'Failed to load the watchlist.',
  'Gagal menambah saham.': 'Failed to add the stock.',
  'Gagal mengubah status saham.': 'Failed to change the stock status.',
  'Kode saham harus 4 huruf, contoh BBCA.':
      'A stock code is 4 letters, for example BBCA.',
  'Gagal memuat data broker.': 'Failed to load broker data.',
  'Belum ada data broker': 'No broker data yet',
  'Data muncul setelah otomatisasi Stockbit mengisinya.':
      'Data appears after the Stockbit automation fills it in.',
  'Tidak ada data untuk rentang ini.': 'No data for this range.',
  'Ritel': 'Retail',
  'Bandar': 'Big player',
  'Asing': 'Foreign',
  'belum diklasifikasi': 'unclassified',
  'Tidak ada broker kelompok ini yang tampil':
      'No broker of this group is shown',
  'beli @buy · jual @sell · @count broker':
      'buy @buy · sell @sell · @count brokers',
  'Belum diklasifikasi: @count broker, net @net (tidak masuk kelompok mana pun)':
      'Unclassified: @count brokers, net @net (not in any group)',
  'Total dihitung dari broker yang tampil di Broker Summary Stockbit, bukan seluruh pasar. Kelompok adalah aturan Anda, bukan fakta pasar.':
      'Totals come from the brokers shown in the Stockbit Broker Summary, not the whole market. Groups are your own rules, not market facts.',
  'T': 'T',
  'Hanya data saham yang disinkronkan. Transaksi, anggaran, dan tabungan tetap di perangkat ini.':
      'Only stock data is synced. Transactions, budgets, and savings stay on this device.',
  'Password tidak disimpan di perangkat, hanya sesi masuknya.':
      'The password is not stored on this device, only the session.',
  'SAHAM DIPANTAU': 'STOCKS FOLLOWED',
  '@count aktif': '@count active',
  '@count nonaktif, riwayat datanya tetap tersimpan':
      '@count inactive, their history is kept',
  'Arah dana per kelompok': 'Money flow by group',
  'dan': 'and',
  'Tidak ada arus bersih pada rentang ini.': 'No net flow in this range.',
  '@names net beli.': '@names net buying.',
  '@names net jual.': '@names net selling.',
  '@buy net beli, @sell net jual.': '@buy net buying, @sell net selling.',
  '@count broker': '@count brokers',
  'Top @count net beli': 'Top @count net buyers',
  'Top @count net jual': 'Top @count net sellers',
  'dari @total broker': 'of @total brokers',
  'jumlah': 'total',
  'Tidak ada broker net beli pada rentang ini.':
      'No net-buying broker in this range.',
  'Tidak ada broker net jual pada rentang ini.':
      'No net-selling broker in this range.',
  'Harga': 'Price',
  'Volume': 'Volume',
  'Rata-rata 20 hari': '20-day average',
  'Stoch RSI': 'Stoch RSI',
  'Garis a': 'Line a',
  'Garis b': 'Line b',
  'MACD': 'MACD',
  'Histogram': 'Histogram',
  'Nama garis a dan b (MACD dan sinyal, K dan D) belum dipastikan dari legenda Stockbit, jadi dinamai netral. Hari yang ditandai tidak akurat tidak digambar. Ini pembacaan angka, bukan saran.':
      'Which of lines a and b is MACD or signal, K or D, is not confirmed from the Stockbit legend, so they are named neutrally. Days marked inaccurate are not drawn. This reads the numbers; it is not advice.',
  'Harga penutupan belum terbaca.': 'The closing price has not been read.',
  'Tutup @price': 'Close @price',
  'Tutup @price (@change)': 'Close @price (@change)',
  'Volume belum terbaca.': 'Volume has not been read.',
  'jauh di atas': 'far above',
  'di atas': 'above',
  'di bawah': 'below',
  'jauh di bawah': 'far below',
  'Volume @pct% dari rata-rata 20 hari, @level':
      'Volume is @pct% of the 20-day average, @level',
  'Hari berjalan, volume masih bertambah.':
      'Today is still running, so volume is still growing.',
  'Stoch RSI belum terbaca.': 'Stoch RSI has not been read.',
  'Di area bawah (20 ke bawah)': 'In the low zone (20 or below)',
  'Di area tengah (20 sampai 80)': 'In the middle zone (20 to 80)',
  'Di area atas (80 ke atas)': 'In the high zone (80 or above)',
  'Dua garis berada di area berbeda': 'The two lines are in different zones',
  'MACD belum terbaca.': 'MACD has not been read.',
  'Histogram positif': 'Histogram positive',
  'Histogram negatif': 'Histogram negative',
  'Histogram nol': 'Histogram zero',
  'Kedua garis di atas nol': 'Both lines above zero',
  'Kedua garis di bawah nol': 'Both lines below zero',
  'Garis berada di dua sisi nol': 'The lines are on both sides of zero',
  'Sentuh atau geser di chart untuk melihat harga dan indikator tiap hari.':
      'Touch or drag on a chart to see the price and indicators for each day.',
  'Buka': 'Open',
  'Tertinggi': 'High',
  'Terendah': 'Low',
  'Perubahan': 'Change',
  'intraday': 'intraday',
  'Hari terakhir': 'Latest day',
  'Data broker @date (Latest)': 'Broker data @date (Latest)',
  'Arah dana muncul setelah data broker saham ini terisi.':
      'Money flow appears once this stock has broker data.',
  'Memuat ringkasan...': 'Loading summary...',
  '@count nonaktif · data broker terbaru @date':
      '@count inactive · latest broker data @date',
  'Tidak ada saham pada pilihan ini.': 'No stocks in this filter.',
  'Tersambung ke Supabase': 'Connected to Supabase',
  'Masuk sebagai @email': 'Signed in as @email',
  'Watchlist terkunci': 'Watchlist is locked',
  'Masuk ke akun Supabase untuk membuka watchlist dan data broker.':
      'Sign in to your Supabase account to open the watchlist and broker data.',
  'Masuk akun': 'Sign in',
  'Tampilkan password': 'Show password',
  'Sembunyikan password': 'Hide password',
  'Broker': 'Broker',
  'Chart': 'Chart',
  'PENUTUPAN': 'CLOSE',
  'HARGA': 'PRICE',
  'Memuat harga': 'Loading price',
  'Harga belum ada': 'No price yet',
  'Mengambil data harian dari Supabase.': 'Fetching daily data from Supabase.',
  'Chart dan indikator muncul setelah data harian saham ini terisi. Data broker sudah bisa dilihat di tab Broker.':
      'The chart and indicators appear once daily data for this stock is filled in. Broker data is already available in the Broker tab.',
  'Tertinggi @high · Terendah @low · Volume @volume lot':
      'High @high · Low @low · Volume @volume lots',
  'Broker teratas': 'Top brokers',
  'Gagal memuat data harga.': 'Failed to load price data.',
  'Belum ada data harga': 'No price data yet',
  'Chart, volume, Stoch RSI, dan MACD muncul setelah otomatisasi Stockbit mengisi data harian saham ini.':
      'The chart, volume, Stoch RSI, and MACD appear once the Stockbit automation fills in daily data for this stock.',
  '@ticker sudah ada di watchlist.': '@ticker is already in the watchlist.',
  'Slot aktif penuh (@max/@max). Nonaktifkan satu saham dulu.':
      'All active slots are used (@max/@max). Deactivate a stock first.',
  'Slot aktif penuh (@max/@max). Nonaktifkan satu saham dulu untuk mengaktifkan ini.':
      'All active slots are used (@max/@max). Deactivate a stock first to activate this one.',
  '@active/@max aktif': '@active/@max active',
  '@active dari @max slot aktif terpakai': '@active of @max active slots used',
  'Hapus @ticker': 'Delete @ticker',
  'Hapus @ticker?': 'Delete @ticker?',
  '@ticker dan seluruh datanya di Supabase (harga harian, broker summary, cek broker, hasil analisis) ikut dihapus dan tidak bisa dikembalikan. Kalau hanya ingin berhenti mengambil data, nonaktifkan saja.':
      '@ticker and all of its data in Supabase (daily prices, broker summary, broker checks, analysis results) will be deleted and cannot be restored. To only stop collecting data, deactivate it instead.',
  '@ticker dihapus.': '@ticker deleted.',
  'Gagal menghapus saham.': 'Failed to delete the stock.',
  'Keluar dari Supabase?': 'Sign out of Supabase?',
  'Watchlist terkunci sampai Anda masuk lagi. Data di Supabase tidak terhapus.':
      'The watchlist stays locked until you sign in again. Your data in Supabase is not deleted.',
  '@count saham': '@count stocks',
  '@count aktif diambil datanya otomatis':
      '@count active, data collected automatically',
  '@count nonaktif': '@count inactive',
  'data broker terbaru @date': 'latest broker data @date',
  'masuk sebagai @email': 'signed in as @email',
  'HARGA BERJALAN': 'LIVE PRICE',
  'Volume dalam lot': 'Volume in lots',
  'Penutupan kemarin @price · volume dalam lot':
      'Previous close @price · volume in lots',
  'BUKA': 'OPEN',
  'TERTINGGI': 'HIGH',
  'TERENDAH': 'LOW',
  'VOLUME': 'VOLUME',
  '@count hari bursa · @start sampai @end':
      '@count trading days · @start to @end',
  'jumlah @total broker · top @count': '@total brokers in total · top @count',
  'lainnya': 'other',
  'Sinyal': 'Signal',
  'K di atas D': 'K above D',
  'K di bawah D': 'K below D',
  'K sama dengan D': 'K equals D',
  'Histogram positif dan membesar (batang pekat)':
      'Histogram positive and growing (solid bar)',
  'Histogram positif dan menyusut (batang pudar)':
      'Histogram positive and shrinking (faded bar)',
  'Histogram negatif dan membesar (batang pekat)':
      'Histogram negative and growing (solid bar)',
  'Histogram negatif dan menyusut (batang pudar)':
      'Histogram negative and shrinking (faded bar)',
  'MACD di atas sinyal': 'MACD above signal',
  'MACD di bawah sinyal': 'MACD below signal',
  'MACD sama dengan sinyal': 'MACD equals signal',
  'kedua garis di atas nol': 'both lines above zero',
  'kedua garis di bawah nol': 'both lines below zero',
  'garis berada di dua sisi nol': 'lines on both sides of zero',
  'Indikator dihitung dari harga penutupan dengan parameter Stockbit. Batang histogram pekat berarti membesar, pudar berarti mengecil. Hari yang ditandai tidak akurat tidak digambar. Ini pembacaan angka, bukan saran.':
      'Indicators are computed from closing prices with Stockbit\'s parameters. A solid histogram bar means it is growing, a faded one means it is shrinking. Days marked inaccurate are not drawn. This is a reading of numbers, not advice.',
};
