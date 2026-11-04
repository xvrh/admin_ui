import 'package:common_locale_data/ar.dart' show CommonLocaleDataAr;
import 'package:common_locale_data/common_locale_data.dart'
    show CommonLocaleData, Language;
import 'package:common_locale_data/en.dart' show CommonLocaleDataEn;
import 'package:common_locale_data/fr.dart' show CommonLocaleDataFr;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:material_ui/material_ui.dart';

import '../common/ui/status_pill.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/tokens.dart';

final _en = CommonLocaleDataEn();
final _fr = CommonLocaleDataFr();
final _ar = CommonLocaleDataAr();

/// The display name of the language [code], from CLDR: "Spanish" for 'es',
/// 'ES' or 'es_ES', "Brazilian Portuguese" for 'pt-BR'. The code is read in
/// any case, with '_' or '-' between its subtags, and a region or script the
/// data has no name for falls back to the language alone; a language it does
/// not know at all reads as the upper-cased code.
///
/// The name is in the language of [displayLocale]: English, French or
/// Arabic, the kit's own languages ("espagnol" for French), and English for
/// any other or none. Each is imported on its own — never
/// `common_locale_data_all.dart`, which pulls in every locale and wrecks
/// tree-shaking. [languageNameOf] names it in the app's language.
String languageName(String code, {Locale? displayLocale}) {
  final names = switch (displayLocale?.languageCode) {
    'fr' => _fr,
    'ar' => _ar,
    _ => _en,
  };
  final (language, script, region) = _subtags(code);
  for (final key in [
    if (script != null && region != null) '$language-$script-$region',
    if (region != null) '$language-$region',
    if (script != null) '$language-$script',
    language,
  ]) {
    if (_names(names)[key] case final name?) return name.name;
  }
  return code.toUpperCase();
}

/// [languageName] in the language of [context]'s locale.
String languageNameOf(BuildContext context, String code) =>
    languageName(code, displayLocale: Localizations.maybeLocaleOf(context));

Map<String, Language> _names(CommonLocaleData data) => data.languages.languages;

/// [code]'s language, script and region subtags in their canonical case:
/// 'PT_br' is ('pt', null, 'BR'), 'zh-hant' is ('zh', 'Hant', null).
(String, String?, String?) _subtags(String code) {
  final parts = code.trim().split(RegExp('[-_]'));
  final language = parts.first.toLowerCase();
  String? script;
  String? region;
  for (final part in parts.skip(1)) {
    if (part.length == 4 && script == null && region == null) {
      script = part[0].toUpperCase() + part.substring(1).toLowerCase();
    } else if (region == null &&
        (part.length == 2 ||
            (part.length == 3 && int.tryParse(part) != null))) {
      region = part.toUpperCase();
    }
  }
  return (language, script, region);
}

/// [code] as a [Locale]; an empty code is the undetermined language 'und'.
Locale _localeOf(String code) {
  final (language, script, region) = _subtags(code);
  return Locale.fromSubtags(
    languageCode: language.isEmpty ? 'und' : language,
    scriptCode: script,
    countryCode: region,
  );
}

/// The direction [code]'s language is written in, by intl's list of
/// right-to-left languages and scripts.
TextDirection _directionOf(String code) =>
    Bidi.isRtlLanguage(code.trim().toLowerCase())
    ? TextDirection.rtl
    // Physical: the language's own direction, not the admin's.
    : TextDirection.ltr;

/// Per-locale translation status. `source` is a role (the locale others
/// translate from); `outdated` is derived when the source changes, and
/// `missing` is a translation that does not exist yet.
enum LocaleStatus { source, translated, review, outdated, missing }

/// Each [LocaleStatus] in [context]'s words and theme colours: muted for
/// the source, green up to date, info for review, red outdated, and a muted
/// ring for a translation that does not exist yet.
Map<LocaleStatus, StatusMeta> localeStatusMeta(BuildContext context) {
  final c = context.colors;
  final l10n = context.adminL10n.fields;
  return {
    LocaleStatus.source: StatusMeta(l10n.translationSource, c.foregroundMuted),
    LocaleStatus.translated: StatusMeta(
      l10n.translationUpToDate,
      c.success,
      text: c.successText,
    ),
    LocaleStatus.review: StatusMeta(
      l10n.translationNeedsReview,
      c.info,
      text: c.infoText,
    ),
    LocaleStatus.outdated: StatusMeta(
      l10n.translationOutdated,
      c.danger,
      text: c.dangerText,
    ),
    LocaleStatus.missing: StatusMeta(
      l10n.translationMissing,
      c.foregroundMuted,
      ring: true,
    ),
  };
}

/// One locale as the language chrome shows it. Equal by value, so a scope
/// holding a list of these can tell when a status changed.
@immutable
class LocaleInfo {
  /// The language's code, such as 'es' or 'pt-BR', in any case.
  final String code;

  /// The language's name for itself, such as 'Español', for the host's own
  /// labels. The kit's chrome names a language from its [code] instead, in
  /// the app's language ([languageNameOf]).
  final String native;

  final LocaleStatus status;

  /// The direction the language is written in, where [direction] should not
  /// derive it from [code].
  final TextDirection? textDirection;

  const LocaleInfo({
    required this.code,
    this.native = '',
    required this.status,
    this.textDirection,
  });

  /// The direction text in this language runs, which its lane is laid out
  /// in: [textDirection], else right to left for a right-to-left language
  /// such as Arabic, Hebrew, Persian or Urdu (intl's `Bidi.isRtlLanguage`).
  TextDirection get direction => textDirection ?? _directionOf(code);

  /// [code] as a [Locale], in any case and with either separator: 'PT_br'
  /// is `pt_BR`.
  Locale get locale => _localeOf(code);

  /// This locale with the given fields replaced; an explicit [textDirection]
  /// is kept unless one is given.
  LocaleInfo copyWith({
    String? code,
    String? native,
    LocaleStatus? status,
    TextDirection? textDirection,
  }) => LocaleInfo(
    code: code ?? this.code,
    native: native ?? this.native,
    status: status ?? this.status,
    textDirection: textDirection ?? this.textDirection,
  );

  @override
  bool operator ==(Object other) =>
      other is LocaleInfo &&
      other.code == code &&
      other.native == native &&
      other.status == status &&
      other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(code, native, status, textDirection);
}

/// The changed locale codes for a field-level marker of what differs from the
/// baseline — declared order, capped so the label row never overflows; null
/// for an empty set or a single-locale field (nothing to disambiguate).
String? modifiedLocalesDetail(List<LocaleInfo> locales, Set<String> changed) {
  if (changed.isEmpty || locales.length <= 1) return null;
  final codes = [
    for (final l in locales)
      if (changed.contains(l.code)) l.code.toUpperCase(),
  ];
  if (codes.isEmpty) return null;
  if (codes.length <= 3) return codes.join(', ');
  return '${codes.take(2).join(', ')} +${codes.length - 2}';
}

/// Labelled status pill — colour always paired with a word.
class LocaleStatusPill extends StatelessWidget {
  final LocaleStatus status;

  const LocaleStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) =>
      StatusPill(localeStatusMeta(context)[status]!);
}

/// Lays out [child] as content in the language [code]: in that language's
/// direction ([textDirection], else [LocaleInfo.direction]'s rule) and under
/// its locale, so an Arabic target is edited right to left inside a
/// left-to-right admin, and a French one left to right inside an Arabic
/// admin. Wrap a lane's content in it, not its chrome: labels, tags and
/// status pills stay in the direction of the admin around them.
///
/// Only the locale changes. Text shapes and reads in the content's language
/// (a screen reader voices it so, and CJK text takes its own glyphs), while
/// every localization — Material's strings, the kit's, the app's — stays
/// the one the admin loaded, so a lane in a language the app has no strings
/// for loses none of them.
class LaneLanguage extends StatelessWidget {
  /// The content's language, such as 'ar' or 'pt-BR', in any case.
  final String code;

  /// The direction the language is written in, when not the one [code]
  /// implies.
  final TextDirection? textDirection;

  final Widget child;

  const LaneLanguage({
    super.key,
    required this.code,
    this.textDirection,
    required this.child,
  });

  /// [child] in [lane]'s language and [LocaleInfo.direction].
  LaneLanguage.forLane(LocaleInfo lane, {super.key, required this.child})
    : code = lane.code,
      textDirection = lane.textDirection;

  @override
  Widget build(BuildContext context) {
    final content = Directionality(
      textDirection: textDirection ?? _directionOf(code),
      child: child,
    );
    final ambient = Localizations.maybeLocaleOf(context);
    final scope = context.findAncestorWidgetOfExactType<Localizations>();
    final locale = _localeOf(code);
    if (ambient == null || scope == null || _sameLanguage(ambient, locale)) {
      return content;
    }
    return Localizations.override(
      context: context,
      locale: locale,
      delegates: [
        for (final type in {
          for (final d in scope.delegates)
            if (d.isSupported(ambient)) d.type,
        })
          if (Localizations.of<Object?>(context, type) case final loaded?)
            _Loaded(type, loaded),
      ],
      child: content,
    );
  }
}

/// Whether text in [lane] needs no locale of its own under [ambient]: the
/// same language, and the same script and region where [lane] names one.
bool _sameLanguage(Locale ambient, Locale lane) =>
    ambient.languageCode == lane.languageCode &&
    (lane.scriptCode == null || lane.scriptCode == ambient.scriptCode) &&
    (lane.countryCode == null || lane.countryCode == ambient.countryCode);

/// Answers, for any locale, the localization of [type] already loaded above.
class _Loaded extends LocalizationsDelegate<Object?> {
  const _Loaded(this.type, this.resources);

  @override
  final Type type;

  final Object resources;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Object?> load(Locale locale) => SynchronousFuture(resources);

  @override
  bool shouldReload(_Loaded old) =>
      old.type != type || !identical(old.resources, resources);
}
