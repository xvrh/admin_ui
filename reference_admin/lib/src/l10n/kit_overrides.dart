import 'package:admin_ui/l10n.dart';

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

/// The kit in this shop's three languages, each with its overrides.
final pottingShedKitLanguages = AdminLanguages([
  adminEn.copyWith(strings: const PottingShedKitStringsEn()),
  adminFr.copyWith(strings: const PottingShedKitStringsFr()),
  adminAr.copyWith(strings: const PottingShedKitStringsAr()),
]);
