import 'package:admin_ui/history.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/catalogue_keys.dart';
import '../../l10n/ref_strings.dart';
import 'catalogue_widgets.dart';
import 'product_diff.dart';

/// The History tab: the versions newest first beside what changed between
/// the one picked and the current one, each restorable whole or field by
/// field.
class ProductHistoryView extends StatefulWidget {
  /// Newest first; the first is the current version.
  final List<ProductRevision>? revisions;
  final Object? error;
  final VoidCallback onRetry;
  final CatalogueLookups lookups;

  /// Restores a whole version; null for a role that may not.
  final void Function(ProductRevision version)? onRestore;

  /// Takes one field back from a version into the editor.
  final void Function(ProductRevision version, String fieldKey)? onRestorePart;

  const ProductHistoryView({
    super.key,
    required this.revisions,
    required this.error,
    required this.onRetry,
    required this.lookups,
    this.onRestore,
    this.onRestorePart,
  });

  @override
  State<ProductHistoryView> createState() => _ProductHistoryViewState();
}

class _ProductHistoryViewState extends State<ProductHistoryView> {
  String? _baseId;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.catalogue;
    if (widget.error case final error?) {
      return ErrorState(
        message: ErrorTextScope.describe(context, error),
        onRetry: widget.onRetry,
      );
    }
    final revisions = widget.revisions;
    if (revisions == null) {
      return const SkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(height: 56),
            Gap(AdminSpacing.md),
            Skeleton(height: 56),
            Gap(AdminSpacing.md),
            Skeleton(height: 56),
          ],
        ),
      );
    }
    if (revisions.length < 2) {
      return EmptyState(icon: Icons.history, title: strings.noHistory);
    }
    final current = revisions.first;
    final base =
        revisions
            .skip(1)
            .where((r) => 'v${r.version}' == _baseId)
            .firstOrNull ??
        revisions[1];
    final refs = [
      for (final (i, r) in revisions.indexed)
        versionRef(context, r, current: i == 0),
    ];
    final onRestore = widget.onRestore;
    final onRestorePart = widget.onRestorePart;
    final diff = DiffView(
      key: CatalogueKeys.diff,
      diff: productDiff(
        context,
        base: base,
        compare: current,
        compareIsCurrent: true,
        lookups: widget.lookups,
      ),
      restoreLabel: strings.restore,
      onRestore: onRestore == null ? null : () => onRestore(base),
      onRestorePart: onRestorePart == null
          ? null
          : (target) => onRestorePart(base, target.fieldKey),
    );
    final timeline = VersionTimeline(
      key: CatalogueKeys.timeline,
      versions: refs,
      baseId: 'v${base.version}',
      compareId: 'v${current.version}',
      onTap: (v) {
        if (v.id != 'v${current.version}') setState(() => _baseId = v.id);
      },
    );
    if (AdminBreakpoint.of(context).isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 232, child: Panel(child: timeline)),
          const Gap(AdminSpacing.md),
          Expanded(child: Panel(child: diff)),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 300, child: Panel(child: timeline)),
        const Gap(AdminSpacing.lg),
        Expanded(child: Panel(child: diff)),
      ],
    );
  }
}
