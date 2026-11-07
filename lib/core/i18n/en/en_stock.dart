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
  'Prediksi': 'Prediction',
  'Gagal memuat prediksi ML.': 'Failed to load ML predictions.',
  'Belum ada prediksi ML': 'No ML prediction yet',
  'Prediksi muncul setelah pipeline ML menilai saham ini dan model aktif tersedia.':
      'A prediction appears after the ML pipeline scores this stock and an active model is available.',
  'Data harga': 'Price data',
  'Sinyal model': 'Model signal',
  'penyaring.': 'as a filter.',
  'Skor di atas rata-rata': 'Score above average',
  'Skor sekitar rata-rata': 'Score around average',
  'Skor di bawah rata-rata': 'Score below average',
  'Skor @ticker di atas rata-rata saham lain.':
      '@ticker scores above the average stock.',
  'Skor @ticker hampir sama dengan rata-rata saham lain.':
      '@ticker scores about the same as the average stock.',
  'Skor @ticker di bawah rata-rata saham lain.':
      '@ticker scores below the average stock.',
  'Model memberi skor lebih tinggi dari biasanya untuk data pada hari sinyal.':
      'The model gives a higher score than usual for the data on the signal day.',
  'Model tidak melihat keunggulan teknikal khusus pada data hari sinyal.':
      'The model sees no particular technical edge in the data on the signal day.',
  'Model memberi skor lebih rendah dari biasanya untuk data pada hari sinyal.':
      'The model gives a lower score than usual for the data on the signal day.',
  'Yang dihitung model': 'What the model measures',
  'Dalam @days hari bursa, apakah harga menyentuh batas atas sebelum batas bawah?':
      'Within @days trading days, does the price touch the upper barrier before the lower one?',
  'Sekarang': 'Now',
  'Batas bawah': 'Lower barrier',
  'Batas atas': 'Upper barrier',
  'Jawabannya, dari 100 kali': 'The answer, out of 100 times',
  '@ticker pada hari sinyal': '@ticker on the signal day',
  'perkiraan model': 'model estimate',
  'Rata-rata': 'Average',
  'semua saham, data latih': 'all stocks, training data',
  'dari 100': 'of 100',
  'Kotak terisi = berapa kali harga menyentuh batas atas lebih dulu. Sisanya turun ke batas bawah dulu atau tidak menyentuh keduanya.':
      'Filled squares = how many times the price touched the upper barrier first. The rest hit the lower barrier first or touched neither.',
  'Saham ini di luar data latih model, jadi skornya kurang bisa dipercaya.':
      'This stock is outside the model training data, so its score is less reliable.',
  'Kenapa skornya begitu': 'Why the score looks like this',
  'menaikkan skor': 'raises the score',
  'menurunkan skor': 'lowers the score',
  'Makin panjang batang, makin kuat faktor itu menggeser skor.':
      'The longer the bar, the more that factor moves the score.',
  'harga @pct di bawah @ma': 'price @pct below @ma',
  'harga @pct di atas @ma': 'price @pct above @ma',
  'dekat pita bawah': 'near the lower band',
  'dekat pita atas': 'near the upper band',
  'di tengah pita': 'inside the band',
  'Hasil nyata muncul setelah prediksi genap':
      'The actual result appears once a prediction reaches',
  'hari bursa': 'trading days',
  'Hasil nyata prediksi': 'Actual result of prediction',
  'Harga awal dan akhir': 'Start and end price',
  'Hasil bersih': 'Net result',
  'Menyentuh batas atas': 'Touched upper barrier',
  'ya': 'yes',
  'tidak': 'no',
  'Dihitung pada': 'Checked on',
  'Seberapa bisa dipercaya': 'How far to trust it',
  'Uji pada data lama@period: seolah membeli tiap sinyal, lalu menjual setelah @days hari bursa.':
      'Tested on past data@period: as if buying every signal, then selling after @days trading days.',
  'Transaksi yang untung': 'Winning trades',
  'Skor 10% tertinggi': 'Top 10% scores',
  'Semua saham': 'All stocks',
  'transaksi': 'trades',
  'Rata-rata per transaksi, skor 10% tertinggi':
      'Average per trade, top 10% scores',
  'Untung': 'Gain',
  'Rugi': 'Loss',
  'Bersih': 'Net',
  'Skor tinggi lebih sering untung, tetapi besar untung dan rugi ikut menentukan hasil.':
      'High scores win more often, but the size of gains and losses also decides the result.',
  'Setelah biaya @cost, rata-rata per transaksi @net untuk skor 10% tertinggi dan @all untuk semua saham.':
      'After @cost in costs, the average per trade is @net for the top 10% scores and @all for all stocks.',
  'Daya beda model (AUC)': 'Model discrimination (AUC)',
  'Hanya sedikit di atas tebakan acak.':
      'Only slightly better than a random guess.',
  'Di atas tebakan acak, tetapi jauh dari sempurna.':
      'Better than a random guess, but far from perfect.',
  'Antar periode @min sampai @max.': 'Across periods @min to @max.',
  'Garis tipis = batas lolos @gate.': 'Thin line = pass mark @gate.',
  'tebakan acak': 'random guess',
  'sempurna': 'perfect',
  'Bahan pertimbangan, bukan janji untung: hasil bersih rata-rata masih negatif.':
      'Something to weigh, not a promise of profit: the average net result is still negative.',
  'Bahan pertimbangan, bukan janji untung: hasil masa lalu tidak menjamin hasil berikutnya.':
      'Something to weigh, not a promise of profit: past results do not guarantee future ones.',
  'saham': 'stocks',
  'periode uji': 'test periods',
  'Aturan': 'Rule',
  'Model dilatih': 'Model trained',
  'Penyaring informasi, bukan rekomendasi beli atau jual. Bukan nasihat keuangan.':
      'An information filter, not a buy or sell recommendation. Not financial advice.',
  '3 broker teratas = @buy% dari total net beli @label, dan @sell% dari total net jual.':
      'The top 3 brokers = @buy% of total net buying in @label, and @sell% of total net selling.',
  '@code justru net beli @value pada @label.':
      '@code was a net buyer of @value in @label instead.',
  '@count dari 4 rentang searah': '@count of 4 ranges in the same direction',
  '@days hari': '@days days',
  '@down turun · @mixed campuran · @up naik':
      '@down down · @mixed mixed · @up up',
  '@list selalu di sisi net beli: Latest, 7D, 1M, dan 3M.':
      '@list were always net buyers: Latest, 7D, 1M, and 3M.',
  '@list selalu di sisi net jual: Latest, 7D, 1M, dan 3M.':
      '@list were always net sellers: Latest, 7D, 1M, and 3M.',
  '@list. Semuanya @group.': '@list. All of them are @group.',
  '@total broker · 3 teratas = @share%': '@total brokers · top 3 = @share%',
  'AUC, di mana 0,5 berarti tebakan acak':
      'AUC, where 0.5 means a random guess',
  'Batang = @label. Angka kecil = rentang lain. ≈ berarti Stockbit hanya menampilkan angka bulat.':
      'Bars = @label. Small numbers = other ranges. ≈ means Stockbit only shows a rounded value.',
  'Batas lebih lebar dari biasanya.': 'The barriers are wider than usual.',
  'Beli di keempat rentang': 'Buying in all four ranges',
  'Bukan sinyal beli atau jual.': 'Not a buy or sell signal.',
  'Campuran': 'Mixed',
  'Dalam @compare, @group net @value.': 'Over @compare, @group net @value.',
  'Dalam @days hari bursa, mana yang tersentuh lebih dulu: @up atau @down? Model memperkirakan batas atas lebih dulu sekitar @score dari 100 kali.':
      'Within @days trading days, which is touched first: @up or @down? The model expects the upper barrier first about @score times out of 100.',
  'Dua batas yang diuji': 'The two barriers tested',
  'Harga sebulan sampai hari sinyal dan dua batas @days hari':
      'Month of prices up to the signal day and the two @days-day barriers',
  'Jendela tetap sejak sinyal @date selesai pada @end. Hasil nyata dihitung dari jendela ini.':
      'The fixed window from the @date signal ended on @end. The actual result is measured over this window.',
  'Jendela tetap sejak sinyal @date: @days hari bursa ke depan. Belum ada harga baru sesudah sinyal.':
      'Fixed window from the @date signal: the next @days trading days. No new prices yet since the signal.',
  'Jendela tetap sejak sinyal @date: hari ke-@n dari @days hari bursa. Garis hitam di dalam area adalah harga nyata sejauh ini.':
      'Fixed window from the @date signal: day @n of @days trading days. The black line inside the area is the actual price so far.',
  'Siklus 10 hari bursa': '10-trading-day cycle',
  'Sinyal @date · hari ke-@n dari @days': 'Signal @date · day @n of @days',
  'Hari ke-@n dari @days': 'Day @n of @days',
  'Minggu 1 · 5 hari': 'Week 1 · 5 days',
  'Sampai minggu 2 · 10 hari': 'Through week 2 · 10 days',
  'Model 5 hari belum aktif, jadi prediksi 5 hari tidak tampil.':
      'The 5-day model is not active yet, so there is no 5-day prediction.',
  'Revisi tersedia setelah hari ke-5.': 'The revision appears after day 5.',
  'Revisi belum tersedia.': 'The revision is not available yet.',
  'Dihitung ulang dari jalur harga 5 hari, bukan dari model yang belajar dari prediksi 5 hari. Prediksi awal tidak berubah.':
      'Recomputed from the 5-day price path, not from a model learning from the 5-day prediction. The initial prediction does not change.',
  'Batas atas sudah tersentuh di hari 1 sampai 5, jadi hasil 10 hari sudah ditentukan.':
      'The upper barrier was already touched on days 1 to 5, so the 10-day result is already decided.',
  'Batas bawah sudah tersentuh di hari 1 sampai 5, jadi hasil 10 hari sudah ditentukan.':
      'The lower barrier was already touched on days 1 to 5, so the 10-day result is already decided.',
  'Revisi hari ke-5 (@date)': 'Day-5 revision (@date)',
  'skor @score dari 100': 'score @score of 100',
  'naik': 'up',
  'turun': 'down',
  'Skor awal': 'Initial score',
  'Rata-rata semua saham': 'Average of all stocks',
  'Batas atas dan bawah': 'Upper and lower barrier',
  'Hasil nyata': 'Actual result',
  'Riwayat siklus': 'Cycle history',
  'Siklus baru dimulai setelah siklus lama selesai dan model dilatih ulang tiap Sabtu. Prediksi awal dan revisi disimpan terpisah.':
      'A new cycle starts after the old one ends and the model is retrained every Saturday. The initial prediction and the revision are stored separately.',
  '→ revisi @n': '→ revised @n',
  '5 hari': '5 days',
  '10 hari': '10 days',
  'skor @n': 'score @n',
  'Riwayat prediksi': 'Prediction history',
  'Tiap hari ada prediksi baru dengan jendela @days hari bursa sendiri. Jendela yang lama tidak bergeser.':
      'A new prediction is made every day with its own @days-trading-day window. Older windows do not move.',
  'belum jalan': 'not started',
  'hari ke-@n/@days': 'day @n/@days',
  'Jejak: Latest · 7D · 1M · 3M. Kosong = tidak tampil di daftar. 4/4 = searah di semua rentang.':
      'Trail: Latest · 7D · 1M · 3M. Empty = not on the list. 4/4 = same direction in every range.',
  'Jual di keempat rentang': 'Selling in all four ranges',
  'Kemungkinan batas atas dulu': 'Chance of upper barrier first',
  'Keunggulannya tipis. Pakai sebagai penyaring, bukan janji untung.':
      'The edge is thin. Use it as a filter, not a promise of profit.',
  'Kondisi saat ini, bukan sinyal beli atau jual. Skor model dan batas 10 hari ada di tab Prediksi.':
      'Current conditions, not a buy or sell signal. The model score and 10-day barriers are in the Prediction tab.',
  'Kuat': 'Strong',
  'Lebar batas mengikuti volatilitas @ticker 20 hari terakhir. Tidak ada jalur harga ke depan.':
      'The barrier width follows the 20-day volatility of @ticker. No future price path is drawn.',
  'Lemah': 'Weak',
  'Menjelaskan skor model, bukan alasan harga bergerak.':
      'Explains the model score, not why the price moves.',
  'Naik': 'Up',
  'Netral': 'Neutral',
  'Pada @date harga @change (@from ke @to).':
      'On @date the price moved @change (@from to @to).',
  'Penjual terbesar 3M': 'Largest sellers over 3M',
  'Pita bawah Bollinger': 'Lower Bollinger band',
  'Porsi 3 broker teratas': 'Share of the top 3 brokers',
  'RESISTANCE': 'RESISTANCE',
  'Resistance': 'Resistance',
  'SENTIMEN': 'SENTIMENT',
  'SUPPORT': 'SUPPORT',
  'Selama rentang ini harga @change (@from ke @to).':
      'Over this range the price moved @change (@from to @to).',
  'Support': 'Support',
  'Support dan resistance dicari otomatis dari titik balik 60 hari, bisa keliru. Sentimen dari posisi IHSG terhadap MA50 dan MA200.':
      'Support and resistance are found automatically from 60-day turning points and can be wrong. Sentiment comes from the IDX Composite versus its MA50 and MA200.',
  'TREN': 'TREND',
  'Terbesar bulan ini @date (@volume).': 'Largest this month: @date (@volume).',
  'Terbesar bulan ini @date (@volume), hari harga naik @pct%.':
      'Largest this month: @date (@volume), a day the price rose @pct%.',
  'Terbesar bulan ini @date (@volume), hari harga turun @pct%.':
      'Largest this month: @date (@volume), a day the price fell @pct%.',
  'K menguat @days hari berturut-turut, dari @from (@date).':
      'K has risen @days days in a row, from @from (@date).',
  'K melemah @days hari berturut-turut, dari @from (@date).':
      'K has fallen @days days in a row, from @from (@date).',
  'Histogram memudar @days hari berturut-turut sejak @date.':
      'The histogram has faded @days days in a row since @date.',
  'Histogram memekat @days hari berturut-turut sejak @date.':
      'The histogram has deepened @days days in a row since @date.',
  'Tren campuran': 'Mixed trend',
  'Tren naik': 'Uptrend',
  'Tren turun': 'Downtrend',
  'Tren, support, resistance, sentimen pasar, dan indikator ada di tab Chart.':
      'Trend, support, resistance, market sentiment, and indicators are in the Chart tab.',
  'Turun': 'Down',
  'Uji balik': 'Backtest',
  'Volatilitas 20 hari sedang @now% per hari. Dengan volatilitas setahun (@year%), batasnya sekitar @up dan @down.':
      '20-day volatility is currently @now% per day. With one-year volatility (@year%), the barriers would be about @up and @down.',
  'Yang memengaruhi skor': 'What moves the score',
  'Yang menonjol': 'What stands out',
  'biaya': 'cost',
  'hari itu': 'that day',
  'hasil bersih per transaksi setelah biaya':
      'net result per trade after costs',
  'rata-rata semua saham': 'average of all stocks',
  'sampai @price': 'to @price',
  'sebulan': 'one month',
  'seminggu': 'one week',
  'tiga bulan': 'three months',
  'transaksi untung saat skor 10% tertinggi (semua @all%)':
      'of trades profitable at the top 10% score (all @all%)',
  '+ skor': '+ score',
  '− skor': '− score',
  '@group masuk @period, setelah @compare keluar.':
      '@group moved in @period, after moving out over @compare.',
  '@group keluar @period, setelah @compare masuk.':
      '@group moved out @period, after moving in over @compare.',
  '@group masuk @period, searah dengan @compare terakhir.':
      '@group moved in @period, in line with the last @compare.',
  '@group keluar @period, searah dengan @compare terakhir.':
      '@group moved out @period, in line with the last @compare.',
  'otomatis, bisa keliru': 'automatic, may be wrong',
  'Candlestick': 'Candlestick',
  'Pola chart': 'Chart pattern',
  'Skenario katalog': 'Catalog scenarios',
  'Double bottom': 'Double bottom',
  'Double top': 'Double top',
  'Head and shoulders': 'Head and shoulders',
  'Inverse head and shoulders': 'Inverse head and shoulders',
  'Segitiga naik, tembus atas': 'Ascending triangle, upside break',
  'Segitiga naik, tembus bawah': 'Ascending triangle, downside break',
  'Segitiga turun, tembus atas': 'Descending triangle, upside break',
  'Segitiga turun, tembus bawah': 'Descending triangle, downside break',
  'Segitiga simetris, tembus atas': 'Symmetric triangle, upside break',
  'Segitiga simetris, tembus bawah': 'Symmetric triangle, downside break',
  'Flag bullish': 'Bullish flag',
  'Flag bearish': 'Bearish flag',
  'Skor kata berita @date: @score, rata-rata dari @scored judul yang memuat kata bermuatan (total @count judul).':
      'News word score @date: @score, averaged over @scored headlines with loaded words (@count headlines in total).',
  'Posisi': 'Position',
  '@pct% dari bawah rentang 60 hari (@low sampai @high)':
      '@pct% from the bottom of the 60-day range (@low to @high)',
  'tidak ada pola pada @date': 'no pattern on @date',
  '@list pada @date': '@list on @date',
  'Divergence RSI?': 'RSI divergence?',
  'tidak terdeteksi dalam 20 hari': 'none detected in 20 days',
  'harga buat titik terendah baru (@p2, @d2), RSI tidak (@r2 vs @r1 pada @d1). Kasar, sering palsu.':
      'price made a new low (@p2, @d2), RSI did not (@r2 vs @r1 on @d1). Rough, often false.',
  'tidak ada dalam @n hari bursa terakhir': 'none in the last @n trading days',
  'menyerupai @name, tembus @date (titik kunci @keys)':
      'resembles @name, broke out @date (key points @keys)',
  'tidak ada yang aktif (@list syarat)': 'none active (@list conditions)',
  '@codes aktif (hasil uji lemah, bukan sinyal)':
      '@codes active (weak test results, not a signal)',
  'IHSG @pct bln ini': 'IHSG @pct this month',
  'di bawah MA50, MA200': 'below MA50, MA200',
  'di atas MA50, MA200': 'above MA50, MA200',
  'di bawah MA50, di atas MA200': 'below MA50, above MA200',
  'di atas MA50, di bawah MA200': 'above MA50, below MA200',
  'Tutup @price, @pct% di atas support.': 'Close @price, @pct% above support.',
  'Masih di bawah @list.': 'Still below @list.',
  'Di atas @list.': 'Above @list.',
  'Di atas @above, di bawah @below.': 'Above @above, below @below.',
  'RSI di bawah 30': 'RSI below 30',
  'Divergence (kasar)': 'Divergence (rough)',
  'HARI TERPILIH': 'SELECTED DAY',
  'sampai': 'to',
  '@group masuk @period.': '@group moved in @period.',
  '@group keluar @period.': '@group moved out @period.',
  'Risiko': 'Risk',
  '@days HARI BURSA KE DEPAN · DATA SAMPAI @date':
      '@days TRADING DAYS AHEAD · DATA UP TO @date',
  'Seberapa': 'How',
  'liar': 'wild',
  'harganya.': 'the price is.',
  'Tenang': 'Calm',
  'Biasa': 'Usual',
  'Cukup liar': 'Fairly wild',
  'Sangat liar': 'Very wild',
  'Sekitar @x kali lebih tenang dari biasanya.':
      'About @x times calmer than usual.',
  'Sekitar sama dengan biasanya.': 'About the same as usual.',
  'Sekitar @x kali lebih liar dari biasanya.':
      'About @x times wilder than usual.',
  'GERAK HARIAN TERUKUR': 'MEASURED DAILY MOVE',
  'naik atau turun per hari bursa, rata-rata 20 hari terakhir':
      'up or down per trading day, average of the last 20 days',
  'Ini besarnya gerak, bukan arahnya. Tidak ada petunjuk harga akan naik atau turun.':
      'This is the size of the move, not its direction. It gives no hint whether the price will rise or fall.',
  'Gerak biasa @a persen, 20 hari terakhir @b persen':
      'Usual move @a percent, last 20 days @b percent',
  'biasanya': 'usually',
  '20 hari terakhir': 'last 20 days',
  'SEBERAPA SERING CL-MU KENA': 'HOW OFTEN YOUR CL GETS HIT',
  'Setahun terakhir lebih sering kena daripada rata-rata sejak @year: pasar belakangan lebih keras.':
      'The last year was hit more often than the average since @year: the market has been rougher lately.',
  'Setahun terakhir lebih jarang kena daripada rata-rata sejak @year: pasar belakangan lebih tenang.':
      'The last year was hit less often than the average since @year: the market has been calmer lately.',
  '@ticker, dari @n jendela 10 hari bursa sejak @year: berapa kali harga sempat turun sampai batas ini.':
      '@ticker, across @n ten-day windows since @year: how often the price dipped to this level.',
  'sejak @year': 'since @year',
  'setahun': '1 year',
  'Dengan CL @cl%, @ticker tersentuh sekitar @n dari 10 jendela.':
      'With a @cl% CL, @ticker is touched in about @n of 10 windows.',
  'Frekuensi masa lalu dari harga terendah harian, bukan keluaran model. Tidak memperhitungkan lompat harga saat buka.':
      'Past frequency from the daily low, not model output. Opening gaps are not accounted for.',
  'CL @cl persen: @all sejak awal, @recent setahun terakhir':
      'CL @cl percent: @all since the start, @recent in the last year',
  'CL −@cl%': 'CL −@cl%',
  'batasmu': 'your limit',
  'HITUNG UKURAN POSISI': 'POSITION SIZE',
  'contoh angka': 'example numbers',
  'Modal': 'Capital',
  'Rugi maksimal': 'Max loss',
  'modal': 'capital',
  'CL-mu': 'Your CL',
  'Satu lot pun melebihi batas risiko atau modalmu pada CL ini. Perkecil CL, naikkan batas rugi, atau tambah modal.':
      'Not even one lot fits your risk limit or capital at this CL. Tighten the CL, raise the loss limit, or add capital.',
  'Rp @cost pada harga Rp @price. Kena CL di Rp @stop, rugi sekitar Rp @loss.':
      'Rp @cost at a price of Rp @price. Hits the CL at Rp @stop, a loss of about Rp @loss.',
  'Jumlah lot dibatasi modal, jadi rugi di CL lebih kecil dari batas risikomu.':
      'The lot count is capped by capital, so the loss at the CL is below your risk limit.',
  'kena': 'hit',
  'CL lebih ketat memberi lot lebih banyak untuk risiko yang sama, tetapi lebih sering kena oleh gerak biasa. Rugi per kejadian sama, jumlah kejadiannya yang naik.':
      'A tighter CL gives more lots for the same risk, but it gets hit more often by ordinary moves. The loss per event is the same; the number of events goes up.',
  'Rumus: risiko yang kamu tetapkan dibagi selisih harga ke CL. Tidak memperhitungkan biaya dan fraksi harga.':
      'Formula: the risk you set divided by the price gap to the CL. Fees and tick sizes are not included.',
  'Ketuk untuk mengubah': 'Tap to change',
  'SEBERAPA BISA DIPERCAYA': 'HOW MUCH TO TRUST IT',
  'periode uji: model yang menimbang kondisi terkini sedikit lebih akurat dari frekuensi biasa':
      'test periods: a model that weighs current conditions was slightly more accurate than the plain frequency',
  'poin': 'pts',
  'selisih terbesar angka persen model dari kenyataan di pasar terakhir':
      'largest gap between the model\'s percentage and reality in the latest market',
  'Karena angka persen model meleset, tab ini memakai frekuensi harga nyata dan membandingkannya dengan setahun terakhir. Angka model tidak ditampilkan.':
      'Because the model\'s percentages miss, this tab uses real price frequency and compares it with the last year. The model\'s numbers are not shown.',
  'Frekuensi masa lalu bukan jaminan. Pakai untuk menakar risiko, bukan untuk menebak arah.':
      'Past frequency is no guarantee. Use it to gauge risk, not to guess direction.',
  'Uji balik 2023 sampai 2026 · 44 saham · 5 periode berurutan':
      'Backtest 2023 to 2026 · 44 stocks · 5 consecutive periods',
  'Alat bantu menakar risiko, bukan rekomendasi beli atau jual. Bukan nasihat keuangan.':
      'A tool for gauging risk, not a buy or sell recommendation. Not financial advice.',
  'Ukuran posisi': 'Position size',
  'Angka ini disimpan di perangkat ini dan berlaku untuk semua saham.':
      'These numbers are saved on this device and apply to all stocks.',
  'Simpan': 'Save',
  'Modal (Rp)': 'Capital (Rp)',
  'Rugi maksimal (% modal)': 'Max loss (% of capital)',
  'CL (% turun dari harga beli)': 'CL (% below the buy price)',
  'Modal minimal Rp 1.000.000.': 'Minimum capital is Rp 1,000,000.',
  'Rugi maksimal antara 0,1% dan 10% dari modal.':
      'Max loss is between 0.1% and 10% of capital.',
  'CL antara 0,5% dan 20%.': 'CL is between 0.5% and 20%.',
  'Gagal memuat riwayat harga.': 'Failed to load the price history.',
  'Riwayat harga belum cukup': 'Not enough price history',
  'Tab Risiko butuh minimal 80 hari bursa di riwayat harga saham ini.':
      'The Risk tab needs at least 80 trading days of price history for this stock.',
  'SAHAM LAIN, CL @cl% TERSENTUH': 'OTHER STOCKS, CL @cl% HIT',
  'Di saham yang lebih liar, CL ini lebih sering kena. Pilihannya: perkecil lot, atau terima CL lebih lebar dengan lot lebih sedikit.':
      'In wilder stocks this CL gets hit more often. The choice: shrink the lot size, or accept a wider CL with fewer lots.',
  'Angka besar adalah rata-rata sejak awal riwayat; angka kecil adalah setahun terakhir.':
      'The large number is the average since the start of the history; the small number is the last year.',
  '@code: @all sejak awal, @recent setahun terakhir':
      '@code: @all since the start, @recent in the last year',
};
