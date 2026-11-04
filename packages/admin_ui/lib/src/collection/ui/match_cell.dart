import 'package:material_ui/material_ui.dart';

import '../../common/ui/highlighted_text.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'collection_table.dart';

/// A collection-table cell explaining why a row matched the active search: a
/// body excerpt with the term highlighted ([snippet] + [highlights]), or a
/// muted "Matched: Name" note for a title match. [matchField] is the matched
/// field's label ("Name", "Description", "Body"), shown as given; null renders
/// nothing.
class MatchCell extends StatelessWidget {
  final String? matchField;
  final String? snippet;
  final List<int> highlights;

  const MatchCell({
    super.key,
    this.matchField,
    this.snippet,
    this.highlights = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (snippet != null) {
      return HighlightedText(
        snippet!,
        ranges: highlights,
        maxLines: 2,
        style: tableMutedStyle(context, context.type.caption),
      );
    }
    if (matchField == null) return const SizedBox.shrink();
    final muted = tableMutedStyle(context, context.type.caption);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.title_rounded,
          size: context.iconSizes.sm,
          color: muted.color,
        ),
        const Gap(AdminSpacing.xs),
        Flexible(
          child: Text(
            context.adminL10n.collection.matchedIn(matchField!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
      ],
    );
  }
}
