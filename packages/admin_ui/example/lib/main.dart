import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import 'src/catalog.dart';
import 'src/utils/debug.dart';
import 'src/utils/themable_test_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runDebugApp(const _CatalogApp());
}

class _CatalogApp extends StatelessWidget {
  const _CatalogApp();

  @override
  Widget build(BuildContext context) {
    return UICatalog(
      title: 'Admin UI',
      catalog: genericCatalog,
      formFactor: (_) => FormFactor.desktop,
      // ThemableTestApp exposes a "Theme" swatch picker in the top bar and
      // applies it. Opt-in by composition: a demo that shouldn't follow the
      // theme can be wrapped in plain TestApp instead.
      appBuilder: (context, child) => ThemableTestApp(child: child),
    );
  }
}
