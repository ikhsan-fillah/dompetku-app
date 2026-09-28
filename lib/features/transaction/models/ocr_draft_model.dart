class OcrDraftModel {
  const OcrDraftModel({
    this.merchant,
    this.date,
    this.total,
    this.uncertainFields = const {},
  });

  final String? merchant;
  final DateTime? date;
  final int? total;
  final Set<String> uncertainFields;
}
