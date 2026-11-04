// The fonts sample under "Using admin_ui outside this repo" in README.md,
// verbatim below the imports. docs_barrels_readme_test.dart fails when the
// two differ.

import 'package:admin_ui/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'minimal_app.dart' show MyAdmin;

void main() {
  AdminFonts.resolver = (family, style) =>
      GoogleFonts.asMap().containsKey(family)
      ? GoogleFonts.getFont(family, textStyle: style)
      : null;
  runApp(const MyAdmin());
}
