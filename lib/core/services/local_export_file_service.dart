import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

class LocalExportFileResult {
  const LocalExportFileResult({required this.fileName});

  final String fileName;
}

/// Membagikan JSON sebagai berkas lokal tanpa mengunggahnya ke layanan apa pun.
abstract interface class LocalExportFileService {
  Future<LocalExportFileResult> shareJson(
    String json, {
    required DateTime exportedAt,
  });
}

class SharePlusExportFileService implements LocalExportFileService {
  const SharePlusExportFileService({SharePlus? share});

  String _fileName(DateTime exportedAt) {
    final utc = exportedAt.toUtc();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'dompetku-export-${utc.year}${twoDigits(utc.month)}'
        '${twoDigits(utc.day)}-${twoDigits(utc.hour)}${twoDigits(utc.minute)}'
        '${twoDigits(utc.second)}.json';
  }

  @override
  Future<LocalExportFileResult> shareJson(
    String json, {
    required DateTime exportedAt,
  }) async {
    final fileName = _fileName(exportedAt);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(json.codeUnits),
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        subject: 'Ekspor data DompetKu',
        text: 'Ekspor data lokal DompetKu',
      ),
    );
    return LocalExportFileResult(fileName: fileName);
  }
}
