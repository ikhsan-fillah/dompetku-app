import 'package:shared_preferences/shared_preferences.dart';

/// Isian hitung ukuran posisi: modal, rugi maksimal per transaksi, dan CL.
/// Disimpan di perangkat, berlaku untuk semua saham.
class RiskInputs {
  const RiskInputs({
    this.capital = 50000000,
    this.riskPercent = 1,
    this.cutLossPercent = 5,
    this.isExample = true,
  });

  /// Modal dalam rupiah.
  final double capital;

  /// Rugi maksimal per transaksi, persen dari modal.
  final double riskPercent;

  /// CL dalam persen turun dari harga beli.
  final double cutLossPercent;

  /// True selama angka masih bawaan dan belum pernah diisi pemakai.
  final bool isExample;

  RiskInputs copyWith({
    double? capital,
    double? riskPercent,
    double? cutLossPercent,
  }) => RiskInputs(
    capital: capital ?? this.capital,
    riskPercent: riskPercent ?? this.riskPercent,
    cutLossPercent: cutLossPercent ?? this.cutLossPercent,
    isExample: false,
  );
}

/// Penyimpanan [RiskInputs] di SharedPreferences. Gagal baca atau tulis tidak
/// pernah melempar: kartu tetap jalan dengan angka contoh.
class RiskPrefs {
  const RiskPrefs();

  static const _kCapital = 'stockRiskCapital';
  static const _kRisk = 'stockRiskPercent';
  static const _kCutLoss = 'stockRiskCutLoss';

  Future<RiskInputs> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final capital = prefs.getDouble(_kCapital);
      final risk = prefs.getDouble(_kRisk);
      final cutLoss = prefs.getDouble(_kCutLoss);
      if (capital == null || risk == null || cutLoss == null) {
        return const RiskInputs();
      }
      return RiskInputs(
        capital: capital,
        riskPercent: risk,
        cutLossPercent: cutLoss,
        isExample: false,
      );
    } catch (_) {
      return const RiskInputs();
    }
  }

  Future<void> save(RiskInputs inputs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCapital, inputs.capital);
      await prefs.setDouble(_kRisk, inputs.riskPercent);
      await prefs.setDouble(_kCutLoss, inputs.cutLossPercent);
    } catch (_) {
      // Tidak tersimpan: angka tetap berlaku sampai tab ditutup.
    }
  }
}
