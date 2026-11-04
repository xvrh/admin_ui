// The appearance sample under "Appearance" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ, and
// appearance_picker_test.dart runs it.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

class MyAdmin extends StatefulWidget {
  const MyAdmin({super.key});

  @override
  State<MyAdmin> createState() => _MyAdminState();
}

class _MyAdminState extends State<MyAdmin> {
  var _look = AdminAppearance(theme: irisTheme);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _look.themeData(Brightness.light),
      darkTheme: _look.themeData(Brightness.dark),
      themeMode: _look.mode,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xxl),
          child: AppearancePicker(
            value: _look,
            onChanged: (look) => setState(() => _look = look),
          ),
        ),
      ),
    );
  }
}
