// The samples under "Localisation and right-to-left" in README.md.
// docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/de.dart';
import 'package:admin_ui/l10n/es.dart';

/// The languages the app ships the kit in. No other is in its build.
const languages = AdminLanguages([adminEn, adminEs, adminDe]);

class ShopStringsEs extends AdminLocalizationsEs {
  const ShopStringsEs();

  @override
  String get searchPlaceholder => 'Buscar pedidos…';
}

final shopLanguages = AdminLanguages([
  adminEn,
  adminEs.copyWith(strings: const ShopStringsEs()),
]);
