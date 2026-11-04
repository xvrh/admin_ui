// The sample under "A theme of your own" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

final acmeTheme = AdminTheme.from(
  name: 'Acme',
  palette: irisPalette.copyWith(
    primary: const Color(0xFF2563EB),
    primaryStrong: const Color(0xFF1D4ED8),
    primarySubtle: const Color(0xFFDBEAFE),
    primaryFaint: const Color(0xFFEFF6FF),
  ),
  dark: irisDarkPalette.branded(const Color(0xFF2563EB)),
  radii: const AdminRadii(radiusSmall: 4, radius: 6, radiusLarge: 10),
  type: const AdminTypeSpec(fontFamily: 'Inter', uppercaseLabels: false),
  sizes: const AdminControlSizes(small: 28, medium: 36, large: 44),
  table: const AdminTableMetrics(
    rowCompact: 36,
    rowStandard: 48,
    rowComfortable: 60,
    headerHeight: 44,
    cellPaddingX: 12,
    selectionColumnWidth: 44,
  ),
);
