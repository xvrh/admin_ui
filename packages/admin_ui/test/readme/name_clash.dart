// The first sample under "Name clashes" in README.md, verbatim from the
// imports down. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart' hide AdminTokensContext;
import 'package:material_ui/material_ui.dart';

/// The app's own `context.colors`, which the kit's would clash with.
extension BrandColors on BuildContext {
  Color get colors => const Color(0xFF0D9488);
}

Widget price(BuildContext context) => Text(
  '42 €',
  style: context.adminTokens.typography.body.copyWith(color: context.colors),
);
