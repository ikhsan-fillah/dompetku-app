import 'dart:io';

import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/i18n/app_language.dart';
import 'package:dompetku_app/core/i18n/app_translations.dart';
import 'package:dompetku_app/core/utils/date_label.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Setiap teks yang dipanggil lewat `'...'.tr` atau `'...'.trParams(...)` harus
/// punya terjemahan Inggris, kalau tidak, pengguna bahasa Inggris melihat
/// teks Indonesia.
void main() {
  final english = AppTranslations().keys['en_US']!;
  final literal = RegExp(
    r'''(?:'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)")\s*\.(?:tr\b|trParams\()''',
  );

  String unescape(String raw) => raw
      .replaceAll(r'\n', '\n')
      .replaceAll(r"\'", "'")
      .replaceAll(r'\"', '"')
      .replaceAll(r'−', '−');

  test('semua teks .tr punya terjemahan Inggris', () {
    final missing = <String>[];
    var found = 0;
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.replaceAll('\\', '/').contains('lib/core/i18n/')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final match in literal.allMatches(source)) {
        found++;
        final key = unescape(match.group(1) ?? match.group(2) ?? '');
        if (!english.containsKey(key)) {
          missing.add('${entity.path}: $key');
        }
      }
    }
    expect(found, greaterThan(300), reason: 'pola pencarian tidak bekerja');
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('peta Inggris tidak berisi terjemahan kosong', () {
    final empty = english.entries.where((e) => e.value.trim().isEmpty);
    expect(empty, isEmpty);
  });

  group('pergantian bahasa', () {
    CategoryModel category({
      required bool isDefault,
      String name = 'Shopping',
    }) => CategoryModel(
      name: name,
      type: TransactionType.expense,
      iconKey: 'shopping_bag',
      colorValue: 0xFF000000,
      isDefault: isDefault,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      Get.clearTranslations();
      Get.addTranslations(AppTranslations().keys);
      Get.fallbackLocale = AppLanguage.localeFor(AppLanguage.indonesian);
    });

    tearDown(() {
      Get.locale = null;
      Get.clearTranslations();
    });

    test('Indonesia adalah bawaan: teks tidak berubah', () {
      Get.locale = AppLanguage.localeFor(AppLanguage.indonesian);

      expect('Laporan'.tr, 'Laporan');
      expect(
        'Pengeluaran naik @percent% dari bulan lalu.'.trParams({
          'percent': '5',
        }),
        'Pengeluaran naik 5% dari bulan lalu.',
      );
      expect(AppLanguage.isEnglish, isFalse);
    });

    test('Inggris menerjemahkan teks dan parameter', () {
      Get.locale = AppLanguage.localeFor(AppLanguage.english);

      expect('Laporan'.tr, 'Report');
      expect(
        'Pengeluaran naik @percent% dari bulan lalu.'.trParams({
          'percent': '5',
        }),
        'Expenses are up 5% from last month.',
      );
      expect(AppLanguage.isEnglish, isTrue);
    });

    test('nama kategori bawaan mengikuti bahasa, kategori buatan tidak', () {
      final builtIn = category(isDefault: true);
      final custom = category(isDefault: false, name: 'Jajan');

      Get.locale = AppLanguage.localeFor(AppLanguage.indonesian);
      expect(builtIn.displayName, 'Belanja');
      expect(custom.displayName, 'Jajan');

      Get.locale = AppLanguage.localeFor(AppLanguage.english);
      expect(builtIn.displayName, 'Shopping');
      expect(custom.displayName, 'Jajan');
    });

    test('nama bulan dan label tanggal mengikuti bahasa', () {
      final date = DateTime(2026, 5, 20);

      Get.locale = AppLanguage.localeFor(AppLanguage.indonesian);
      expect(AppLanguage.monthLong(5), 'Mei');
      expect(DateLabel.day(DateTime(2026, 8, 3)), '3 Agu 2026');

      Get.locale = AppLanguage.localeFor(AppLanguage.english);
      expect(AppLanguage.monthLong(5), 'May');
      expect(DateLabel.day(DateTime(2026, 8, 3)), '3 Aug 2026');
      expect(DateLabel.relativeDay(date, now: date), 'Today');
    });

    test('localeFor memetakan kode bahasa', () {
      expect(AppLanguage.localeFor('en'), const Locale('en', 'US'));
      expect(AppLanguage.localeFor('id'), const Locale('id', 'ID'));
      expect(AppLanguage.localeFor('xx'), const Locale('id', 'ID'));
    });
  });
}
