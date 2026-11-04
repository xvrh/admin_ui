import 'package:admin_ui/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'ref_strings.dart';

// FRICTION(F-009): AdminFormats has no currency or relative time, so the app
// formats money and "3 h ago" itself.

final _currency = <String, NumberFormat>{};

/// [cents] as euros in [context]'s locale: `€84.50`, `84,50 €`.
String formatMoney(BuildContext context, int cents) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final format = _currency.putIfAbsent(
    locale,
    () => NumberFormat.currency(locale: locale, name: 'EUR', symbol: '€'),
  );
  return format.format(cents / 100);
}

/// A date in [context]'s locale, through the kit's formats so digits and
/// bidi marks match the rest of the page.
String formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return context.adminFormats.dateFormat(DateFormat.yMMMd(locale)).format(date);
}

/// A date and time in [context]'s locale.
String formatDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return context.adminFormats
      .dateFormat(DateFormat.yMMMd(locale).add_Hm())
      .format(date);
}

/// How long ago [then] was, from [now], in words short enough for a list:
/// `5 min`, `3 h`, `2 d`, then the date.
String formatAgo(BuildContext context, DateTime then, DateTime now) {
  final gap = now.difference(then);
  final formats = context.adminFormats;
  final strings = context.strings.shell;
  if (gap.inMinutes < 60) {
    final minutes = gap.inMinutes.clamp(1, 59);
    return strings.agoMinutes(minutes, formats.integer(minutes));
  }
  if (gap.inHours < 24) {
    return strings.agoHours(gap.inHours, formats.integer(gap.inHours));
  }
  if (gap.inDays < 7) {
    return strings.agoDays(gap.inDays, formats.integer(gap.inDays));
  }
  return formatDate(context, then);
}
