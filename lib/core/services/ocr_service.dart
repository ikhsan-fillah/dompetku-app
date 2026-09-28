import '../../features/transaction/models/ocr_draft_model.dart';

abstract interface class OcrService {
  /// Returns editable candidates only; it must never create a transaction.
  Future<OcrDraftModel> extractReceiptDraft(String imagePath);
}
