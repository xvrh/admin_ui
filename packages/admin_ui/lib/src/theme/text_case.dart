import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// [text] in capitals as [locale]'s language writes them. Turkish and
/// Azerbaijani capitalize a dotted i as İ and a dotless ı as I, where
/// [String.toUpperCase], which knows no locale, makes both I.
@internal
String upperCaseIn(String text, Locale? locale) =>
    switch (locale?.languageCode) {
      'tr' || 'az' => text.replaceAll('i', 'İ').replaceAll('ı', 'I'),
      _ => text,
    }.toUpperCase();
