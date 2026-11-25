// An app that ships the kit in English alone. tool/check_tree_shaking.dart
// builds it for the web and fails when its main.dart.js holds another of
// the kit's languages, Material's other languages, or names of languages
// in any language but English.
//
// It reaches what each language brings: the kit's strings, Material's (a
// text field), intl's dates (a calendar) and CLDR's names (a lane label).

import 'dart:convert';

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

const languages = AdminLanguages([adminEn]);

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildAppTheme(defaultTokens),
    localizationsDelegates: languages.delegates,
    supportedLocales: languages.locales,
    home: const Home(),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // An app's own JSON, read untyped, as apps do.
    final Object? json = jsonDecode('{"title": "Orders"}');
    return Scaffold(
      body: ListView(
        children: [
          Text('${(json as dynamic)['title']}'),
          Text(context.adminL10n.unsavedChanges),
          Text(languageNameOf(context, 'es')),
          Text(context.adminFormats.decimal(1234.5)),
          Calendar(value: DateTime(2026), onChanged: (_) {}),
          const TextField(),
        ],
      ),
    );
  }
}
