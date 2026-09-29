/// Membulatkan bagian-bagian menjadi persen bulat yang selalu berjumlah 100
/// (metode sisa terbesar). Nilai masukan dipakai sebagai perbandingan relatif.
List<int> roundPercentages(List<double> values) {
  if (values.isEmpty) return const [];
  final total = values.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return List<int>.filled(values.length, 0);
  final scaled = [for (final v in values) v * 100 / total];
  final floors = [for (final v in scaled) v.floor()];
  var remaining = 100 - floors.fold<int>(0, (a, b) => a + b);
  final order = List<int>.generate(values.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = (scaled[b] - floors[b]).compareTo(scaled[a] - floors[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (final index in order) {
    if (remaining <= 0) break;
    floors[index]++;
    remaining--;
  }
  return floors;
}
