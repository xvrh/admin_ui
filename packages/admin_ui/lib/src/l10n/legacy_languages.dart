import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'admin_language.dart';
import 'admin_ui_localizations.dart';
import 'languages/ar/admin_ar.dart';
import 'languages/en/admin_en.dart';
import 'languages/fr/admin_fr.dart';

/// English, French and Arabic: what the deprecated
/// `AdminLocalizations.delegate` loads, as the kit did before
/// [AdminLanguages]. Nothing else refers to them, so an app on
/// [AdminLanguages] ships only the languages it lists.
@internal
const legacyLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

/// The deprecated `AdminLocalizations.lookup`.
@internal
AdminLocalizations legacyLookup(Locale locale) =>
    legacyLanguages.resolve(locale)?.strings ?? const AdminLocalizationsEn();

/// The deprecated `AdminLocalizations.delegate`: the kit's strings in
/// English, French and Arabic, for every locale, English for any other.
@internal
class LegacyAdminLocalizationsDelegate
    extends LocalizationsDelegate<AdminLocalizations> {
  const LegacyAdminLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdminLocalizations> load(Locale locale) {
    legacyLanguages.load();
    return SynchronousFuture(legacyLookup(locale));
  }

  @override
  bool shouldReload(LegacyAdminLocalizationsDelegate old) => false;
}
