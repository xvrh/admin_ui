// The sample under "The kit's glyphs" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

const _family = 'AcmeIcons';

final acmeIconTheme = AdminTheme.from(
  name: 'Acme',
  palette: irisPalette,
  icons: const AdminIcons(
    close: IconData(0xe1b2, fontFamily: _family),
    check: IconData(0xe06c, fontFamily: _family),
    dropdown: IconData(0xe06d, fontFamily: _family),
    search: IconData(0xe151, fontFamily: _family),
    // It points the reading direction: mirrored right to left.
    chevronForward: IconData(
      0xe06f,
      fontFamily: _family,
      matchTextDirection: true,
    ),
  ),
);
