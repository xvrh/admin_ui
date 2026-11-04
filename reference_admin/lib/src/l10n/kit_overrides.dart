import 'package:admin_ui/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// The kit's documented override path, used for one phrase: its generic
// "Search…" becomes this shop's, wherever the kit shows it.

class PottingShedKitStringsEn extends AdminLocalizationsEn {
  const PottingShedKitStringsEn();
  @override
  String get searchPlaceholder => 'Search orders, plants, customers…';
}

class PottingShedKitStringsFr extends AdminLocalizationsFr {
  const PottingShedKitStringsFr();
  @override
  String get searchPlaceholder => 'Rechercher commandes, plantes, clients…';
}

class PottingShedKitStringsAr extends AdminLocalizationsAr {
  const PottingShedKitStringsAr();
  @override
  String get searchPlaceholder => 'ابحث في الطلبات والنباتات والعملاء…';
}

/// Loads the kit's strings with this shop's overrides. Listed before
/// `AdminLocalizations.localizationsDelegates`, so it wins: the first
/// delegate of a type does.
abstract final class PottingShedKitStrings {
  static const LocalizationsDelegate<AdminLocalizations> delegate = _Delegate();
}

class _Delegate extends LocalizationsDelegate<AdminLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdminLocalizations> load(Locale locale) =>
      SynchronousFuture(switch (locale.languageCode) {
        'fr' => const PottingShedKitStringsFr(),
        'ar' => const PottingShedKitStringsAr(),
        _ => const PottingShedKitStringsEn(),
      });

  @override
  bool shouldReload(_Delegate old) => false;
}
