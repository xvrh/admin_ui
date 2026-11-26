import 'package:common_locale_data/common_locale_data.dart'
    show CommonLocaleData;
import 'package:flutter/foundation.dart';

/// The name [names] gives the language [code], or null when it has none.
/// The code is read in any case, with '_' or '-' between its subtags, and a
/// region or script [names] has no name for falls back to the language
/// alone: "Brazilian Portuguese" for 'pt-BR', "French" for 'fr-XX'.
@internal
String? languageNameIn(CommonLocaleData names, String code) {
  final (language, script, region) = subtagsOf(code);
  final table = names.languages.languages;
  for (final key in [
    if (script != null && region != null) '$language-$script-$region',
    if (region != null) '$language-$region',
    if (script != null) '$language-$script',
    language,
  ]) {
    if (table[key] case final name?) return name.name;
  }
  return null;
}

/// [code]'s language, script and region subtags in their canonical case:
/// 'PT_br' is ('pt', null, 'BR'), 'zh-hant' is ('zh', 'Hant', null).
@internal
(String, String?, String?) subtagsOf(String code) {
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
