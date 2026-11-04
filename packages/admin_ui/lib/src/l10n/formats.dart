import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:material_ui/material_ui.dart';

import 'admin_ui_localizations.dart';

/// Numbers, percentages and byte sizes in the app's locale.
///
/// The locale is the app's own ([Localizations.maybeLocaleOf]), not the one
/// the kit's strings are in: an app running in German gets German digits and
/// separators even though the kit has no German strings. Outside any
/// [Localizations] it is intl's current locale.
///
/// ```dart
/// final formats = context.adminFormats;
/// formats.decimal(1234.5); // '1,234.5' in English, '1 234,5' in French
/// formats.bytes(757760); // '758 kB'
/// ```
class AdminFormats {
  /// Formats for [locale], an intl locale name such as 'de' or 'fr_CA'; one
  /// intl has no data for falls back to English. Byte units come from
  /// `messages`.
  AdminFormats(String locale, {this._messages = const AdminLocalizationsEn()})
    : locale = Intl.verifiedLocale(
        locale,
        NumberFormat.localeExists,
        onFailure: (_) => 'en',
      )!;

  /// The formats for [context]'s locale, with its [AdminLocalizations]
  /// byte units.
  static AdminFormats of(BuildContext context) {
    final locale =
        Localizations.maybeLocaleOf(context)?.toString() ??
        Intl.getCurrentLocale();
    final messages = AdminLocalizations.of(context);
    if (_cache.length > 32) _cache.clear();
    return _cache[(locale, messages)] ??= AdminFormats(
      locale,
      messages: messages,
    );
  }

  static final _cache = <(String, AdminLocalizations), AdminFormats>{};

  /// The intl locale the numbers are formatted in.
  final String locale;

  final AdminLocalizations _messages;

  late final _decimal = NumberFormat.decimalPattern(locale);
  late final NumberSymbols _symbols = _decimal.symbols;

  /// [value] with the locale's separators. [fractionDigits] fixes the
  /// number of decimals (`decimal(2, fractionDigits: 2)` is '2.00');
  /// [maxFractionDigits] only caps them. By default up to three are shown.
  String decimal(num value, {int? fractionDigits, int? maxFractionDigits}) {
    if (fractionDigits != null) {
      return NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: fractionDigits,
      ).format(value);
    }
    if (maxFractionDigits != null) {
      return (NumberFormat.decimalPattern(locale)
            ..minimumFractionDigits = 0
            ..maximumFractionDigits = maxFractionDigits)
          .format(value);
    }
    return _decimal.format(value);
  }

  /// [value] with the locale's group separator: '12,345'.
  String integer(int value) => _decimal.format(value);

  /// [value] abbreviated for a chart axis or a stat, to three significant
  /// digits: '1.23K', '3.4M' in English, '1,23 k' in French.
  String compact(num value) =>
      NumberFormat.compact(locale: locale).format(value);

  /// [fraction] (0.42 for 42%) as a percentage with [decimals] decimals, in
  /// the locale's own pattern: '42%' in English, '42 %' in French.
  String percent(double fraction, {int decimals = 0}) =>
      (NumberFormat.percentPattern(locale)
            ..minimumFractionDigits = decimals
            ..maximumFractionDigits = decimals)
          .format(fraction);

  /// A byte count in SI units (1 kB is 1000 bytes), with a decimal below
  /// ten: '512 B', '1.5 kB', '758 kB', '12 MB'. The unit names come from
  /// [AdminLocalizations.byteSize]: 'ko', 'Mo' in French.
  String bytes(int bytes) {
    if (bytes.abs() < 1000) return _messages.byteSize(integer(bytes), 0);
    var value = bytes / 1000;
    var power = 1;
    while (power < 4 && value.abs().round() >= 1000) {
      value /= 1000;
      power++;
    }
    final amount = decimal(value, maxFractionDigits: value.abs() < 10 ? 1 : 0);
    return _messages.byteSize(amount, power);
  }

  /// [format], writing its digits as [decimal] does, so a date and a count
  /// in one surface share a numbering system.
  ///
  /// The two can differ: once Material's delegates load the date data,
  /// Arabic dates come in Arabic-Indic digits, while intl writes Arabic
  /// numbers in Latin ones. Dates follow the numbers, which every count,
  /// badge and table cell in the kit shows.
  DateFormat dateFormat(DateFormat format) =>
      format..useNativeDigits = _symbols.ZERO_DIGIT != '0';

  /// A number typed in the locale's own notation, or null when [input] is
  /// not one or could be read two ways.
  ///
  /// The locale's decimal and group separators are accepted, as are ASCII
  /// digits alongside the locale's own. Groups must be well formed, so a
  /// separator that could be either is refused rather than guessed: '1,5'
  /// is null in English and '1.5' null in German, while '1,234.5' parses in
  /// English and '1.234,5' in German. Where '.' is neither separator, as in
  /// French, it is read as the decimal point too.
  num? parseDecimal(String input) {
    var text = input.replaceAll(_bidiMarks, '').trim();
    if (text.isEmpty) return null;

    var negative = false;
    final minus = _symbols.MINUS_SIGN.replaceAll(_bidiMarks, '');
    for (final sign in {'-', '\u2212', minus, '+'}) {
      if (sign.isNotEmpty && text.startsWith(sign)) {
        negative = sign != '+';
        text = text.substring(sign.length).trimLeft();
        break;
      }
    }

    final zero = _symbols.ZERO_DIGIT.codeUnitAt(0);
    final digits = StringBuffer();
    for (final unit in text.codeUnits) {
      digits.writeCharCode(
        unit >= zero && unit <= zero + 9 ? 0x30 + unit - zero : unit,
      );
    }
    text = digits.toString();

    final group = _symbols.GROUP_SEP;
    final groups = <String>{
      group,
      if (_spaces.contains(group)) ..._spaces,
      if (group == "'") '’',
    };
    final decimals = <String>{
      _symbols.DECIMAL_SEP,
      if (!groups.contains('.')) '.',
    };

    var at = -1;
    for (var i = 0; i < text.length; i++) {
      if (!decimals.contains(text[i])) continue;
      if (at != -1) return null;
      at = i;
    }
    final whole = at == -1 ? text : text.substring(0, at);
    final fraction = at == -1 ? '' : text.substring(at + 1);
    if (!_ascii.hasMatch(fraction)) return null;

    final parts = whole.split(RegExp(groups.map(RegExp.escape).join('|')));
    if (parts.length > 1 && !_wellGrouped(parts)) return null;
    final integral = parts.join();
    if (!_ascii.hasMatch(integral) || integral.isEmpty && fraction.isEmpty) {
      return null;
    }
    return num.tryParse(
      '${negative ? '-' : ''}${integral.isEmpty ? '0' : integral}'
      '${fraction.isEmpty ? '' : '.$fraction'}',
    );
  }

  /// Whether [parts], split at the group separator, follow the locale's
  /// grouping: 3-digit groups, or 2 then 3 in an Indian pattern
  /// ('#,##,##0').
  bool _wellGrouped(List<String> parts) {
    final pattern = _symbols.DECIMAL_PATTERN.split('.').first.split(',');
    final primary = pattern.last.length;
    final secondary = pattern.length > 2
        ? pattern[pattern.length - 2].length
        : primary;
    for (var i = 0; i < parts.length; i++) {
      final length = parts[i].length;
      final ok = i == parts.length - 1
          ? length == primary
          : i == 0
          ? length >= 1 && length <= secondary
          : length == secondary;
      if (!ok) return false;
    }
    return true;
  }

  static final _bidiMarks = RegExp('[\u200E\u200F\u061C\u200B]');
  static final _ascii = RegExp(r'^[0-9]*$');
  static const _spaces = {' ', '\u00A0', '\u202F', '\u2009'};
}

/// Reads [AdminFormats] from a [BuildContext].
extension AdminFormatsContext on BuildContext {
  /// [AdminFormats.of] this context.
  AdminFormats get adminFormats => AdminFormats.of(this);
}
