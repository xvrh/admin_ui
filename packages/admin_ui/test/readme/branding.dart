// The branding sample under "Themes, dark mode and brand accents" in
// README.md, verbatim below the imports. docs_barrels_readme_test.dart fails
// when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

final brand = carbonTheme.branded('Carbon (Acme)', const Color(0xFF0D9488));
// or, on one token set:
final tokens = shadcnTheme.tokens.branded(const Color(0xFFE11D48));
