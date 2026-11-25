import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// The locale intl writes [requested]'s dates in: [requested] itself, or the
/// nearest one it has date data for ('fr' for 'fr_CA'). Null when it has
/// none, so a `DateFormat` given it uses intl's current locale.
///
/// Never throws. Before any date data is loaded intl knows en_US alone, and
/// its `DateFormat.localeExists` throws for any other locale rather than
/// answering false.
@internal
String? dateLocaleOf(String? requested) {
  if (requested == null) return null;
  try {
    return Intl.verifiedLocale(
      requested,
      DateFormat.localeExists,
      onFailure: (_) => null,
    );
  } on Exception {
    return null;
  }
}
