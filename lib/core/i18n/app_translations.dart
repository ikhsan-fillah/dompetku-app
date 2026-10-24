import 'package:get/get.dart';

import 'default_category_names.dart';
import 'en/en_auth.dart';
import 'en/en_automation.dart';
import 'en/en_budget.dart';
import 'en/en_category.dart';
import 'en/en_common.dart';
import 'en/en_data.dart';
import 'en/en_home.dart';
import 'en/en_profile.dart';
import 'en/en_recap.dart';
import 'en/en_report.dart';
import 'en/en_transaction.dart';

/// Terjemahan Inggris. Kunci memakai teks Indonesia; Indonesia adalah bawaan.
final Map<String, String> englishStrings = {
  ...enCommon,
  ...enAuth,
  ...enHome,
  ...enTransaction,
  ...enBudget,
  ...enCategory,
  ...enReport,
  ...enRecap,
  ...enAutomation,
  ...enProfile,
  ...enData,
};

final Map<String, String> _english = {
  ...englishStrings,
  ...englishCategoryNames,
};

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'id_ID': {...indonesianCategoryNames, 'Recurring': 'Berulang'},
    'en_US': _english,
  };
}
