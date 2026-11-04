import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/empty_state.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/palette.dart';

/// Every fill a table row can take — plain, striped, selected, each under
/// the pointer — for text that must read on all of them.
List<Color> tableRowSurfaces(AdminPalette colors) => [
  colors.surface,
  colors.tableRowStripe,
  Color.alphaBlend(colors.tableRowHover, colors.tableRowStripe),
  colors.tableRowSelected,
  colors.tableRowSelectedHover,
];

/// The body of a collection view that a search or filter narrowed to
/// nothing, with a "Clear filters" action when [onClearFilters] is set.
class NoResultsState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoResultsState({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final clear = onClearFilters;
    final strings = context.adminL10n;
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: strings.noResults,
      message: strings.collection.noResultsMessage,
      action: clear == null
          ? null
          : Button(strings.collection.clearFilters, onPressed: clear),
    );
  }
}
