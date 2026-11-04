// The sample under "A minimal app" in README.md, verbatim from the imports
// down. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

class MyAdmin extends StatelessWidget {
  const MyAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = adminThemes.first; // Iris
    return MaterialApp(
      title: 'My admin',
      theme: buildAppTheme(theme.tokens),
      darkTheme: buildAppTheme(theme.dark ?? theme.tokens),
      themeMode: ThemeMode.system,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      // Above the Navigator, so toasts paint over route dialogs too.
      // AdminScope uses this one.
      builder: (context, child) => ToastScope(child: child!),
      // Inside the home route, so back closes a modal before the page.
      home: const AdminScope(child: HomePage()),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      sidebar: Sidebar(
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            selected: true,
            onTap: () {},
          ),
          NavItem('Orders', icon: Icons.receipt_long_outlined, onTap: () {}),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: PageScaffold(
        title: 'Home',
        actions: [
          Button(
            'Say hello',
            variant: ButtonVariant.primary,
            onPressed: () => ToastScope.of(context).show(const Toast('Hello')),
          ),
        ],
        body: Text('Welcome', style: context.type.body),
      ),
    );
  }
}
