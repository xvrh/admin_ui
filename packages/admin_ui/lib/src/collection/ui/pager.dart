/// @docImport 'collection_table.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/listbox.dart';
import '../../common/ui/pagination.dart';
import '../../common/ui/popover.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// Offset pager for a [CollectionTable] footer: the range on screen
/// ("1–25 of 1,234"), a [Pagination] and an optional page-size select
/// ("25 / page"). Plain View: maps directly onto the `Slice` shape
/// (offset/total/hasNext) but takes no domain types.
///
/// Given the current [page] and [onPage], it shows numbered pages when it
/// knows the page count — [pageCount], or [total] over [pageSize]; without
/// them only the previous / next arrows do, through [onPrev] and [onNext].
/// A null [total] is a source that can't count its rows: the range reads
/// "1–25", no numbers show and [hasNext] alone enables the next page. As
/// the room narrows it drops the pages beside the current one, then the
/// numbers, then the page-size select.
///
/// Every control is the theme's small control height, and the numbers use
/// tabular figures grouped by the locale. The range reads in the words of
/// [MaterialLocalizations.pageRowsInfoTitle] ("1–25 sur 1 234" in French).
/// The arrows are Tab stops announced as "Previous page" and "Next page";
/// the select as Material's "Rows per page".
class Pager extends StatelessWidget {
  /// 1-based index of the first and last row on this page; [from] is 0 when
  /// the page has none.
  final int from;
  final int to;

  /// Every row across all pages, or null when unknown.
  final int? total;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// The current 1-based page, with [onPage] to jump to another one.
  final int? page;
  final int? pageCount;
  final ValueChanged<int>? onPage;

  final int? pageSize;
  final List<int> pageSizes;
  final ValueChanged<int>? onPageSize;

  const Pager({
    super.key,
    required this.from,
    required this.to,
    required this.total,
    required this.hasPrev,
    required this.hasNext,
    this.onPrev,
    this.onNext,
    this.page,
    this.pageCount,
    this.onPage,
    this.pageSize,
    this.pageSizes = const [10, 25, 50],
    this.onPageSize,
  });

  int? get _pageCount {
    if (pageCount != null) return pageCount;
    final size = pageSize;
    if (total == null || size == null || size <= 0) return null;
    return math.max(1, (total! / size).ceil());
  }

  String _range(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    String n(int v) => l10n.formatDecimal(v);
    final total = this.total;
    if (to <= 0 || from <= 0 || from > to) {
      return total == null ? '' : context.adminL10n.countOf(0, total);
    }
    if (total == null) return '${n(from)}–${n(to)}';
    // Material's built-in English, used without its delegates, prints the
    // counts ungrouped ("1–25 of 1234"): its template, grouped.
    if (l10n is DefaultMaterialLocalizations) {
      return '${n(from)}–${n(to)} of ${n(total)}';
    }
    return l10n.pageRowsInfoTitle(from, to, total, false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final metrics = context.tableMetrics;
    final label = _range(context);
    final labelStyle = context.type.bodyMuted.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final showSize = pageSize != null && onPageSize != null;
    final count = _pageCount;
    final current = page;

    return Container(
      constraints: BoxConstraints(
        minHeight: math.max(
          metrics.headerHeight,
          sizes.small + 2 * AdminSpacing.sm,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: metrics.cellPaddingX),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.maxWidth;
          final labelWidth = _textWidth(context, label, labelStyle);
          final selectWidth = showSize
              ? _PageSizeSelect.widthOf(context, pageSizes)
              : 0.0;

          double need(double pagination, {required bool select}) =>
              labelWidth +
              AdminSpacing.md +
              pagination +
              (select ? AdminSpacing.md + selectWidth : 0);

          Widget? pagination;
          if (onPage != null && current != null) {
            // The widest run of numbers that fits, else the arrows alone.
            for (final siblings in count == null ? const <int>[] : [1, 0]) {
              final width = Pagination.widthOf(
                context,
                page: current,
                pageCount: count,
                siblings: siblings,
                size: ControlSize.small,
              );
              if (need(width, select: showSize) <= room) {
                pagination = Pagination(
                  page: current,
                  pageCount: count,
                  siblings: siblings,
                  size: ControlSize.small,
                  onChanged: onPage,
                );
                break;
              }
            }
            pagination ??= Pagination(
              page: current,
              pageCount: null,
              hasNext: count == null ? hasNext : current < count,
              size: ControlSize.small,
              onChanged: onPage,
            );
          } else {
            // [page] only orders the two arrows here: no number is drawn.
            final at = hasPrev && onPrev != null ? 2 : 1;
            pagination = Pagination(
              page: at,
              pageCount: null,
              hasNext: hasNext && onNext != null,
              size: ControlSize.small,
              onChanged: (p) => p < at ? onPrev!() : onNext!(),
            );
          }
          final arrowsWidth = 2 * sizes.small + AdminSpacing.xs;
          final select = showSize && need(arrowsWidth, select: true) <= room;

          return Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              const Gap(AdminSpacing.md),
              pagination,
              if (select) ...[
                const Gap(AdminSpacing.md),
                SizedBox(
                  width: selectWidth,
                  child: _PageSizeSelect(
                    value: pageSize!,
                    options: pageSizes,
                    onChanged: onPageSize!,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

double _textWidth(BuildContext context, String text, TextStyle style) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width.ceilToDouble();
  painter.dispose();
  return width;
}

String _perPage(BuildContext context, int size) =>
    context.adminL10n.collection.perPage(size);

/// Material's "Rows per page:", without the colon of a label beside a
/// value: the select's accessible name.
String _rowsPerPage(BuildContext context) =>
    MaterialLocalizations.of(context).rowsPerPageTitle
        .replaceFirst(RegExp(r'\s*:\s*$'), '');

/// The page-size select: a small [FieldTrigger] reading "25 / page" over a
/// listbox of the sizes, as wide as its widest option so choosing one never
/// moves the controls beside it.
class _PageSizeSelect extends StatefulWidget {
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _PageSizeSelect({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// The trigger's border and padding, its widest label and the chevron's
  /// slot.
  static double widthOf(BuildContext context, List<int> options) {
    final sizes = context.sizes;
    final style = context.type.fieldText.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    var text = 0.0;
    for (final o in options) {
      text = math.max(text, _textWidth(context, _perPage(context, o), style));
    }
    return 2 * sizes.fieldPaddingX +
        text +
        IconActionSize.inline.box +
        sizes.fieldIconGap -
        (IconActionSize.inline.box - sizes.fieldIcon);
  }

  @override
  State<_PageSizeSelect> createState() => _PageSizeSelectState();
}

class _PageSizeSelectState extends State<_PageSizeSelect> {
  final _listbox = ListboxController();

  @override
  void dispose() {
    _listbox.dispose();
    super.dispose();
  }

  void _onOpenChanged(bool open) {
    if (!open) return;
    final at = widget.options.indexOf(widget.value);
    _listbox.reset(
      widget.options.length,
      selected: at < 0 ? null : at,
      labelOf: (i) => _perPage(context, widget.options[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: PopoverSide.top,
      align: PopoverAlign.end,
      autofocus: false,
      closeOnFocusOut: true,
      onOpenChanged: _onOpenChanged,
      anchor: (context, controller) => FieldTrigger(
        controller: controller,
        size: ControlSize.small,
        chevron: true,
        semanticLabel: _rowsPerPage(context),
        child: Builder(
          builder: (context) => Text(
            _perPage(context, widget.value),
            maxLines: 1,
            softWrap: false,
            style: fieldTextStyle(context)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
      content: (context, controller) => ListboxMenu(
        controller: _listbox,
        anchorWidth: controller.anchorWidth,
        itemCount: widget.options.length,
        semanticLabel: _rowsPerPage(context),
        onSelect: (i) => widget.onChanged(widget.options[i]),
        itemBuilder: (context, i) {
          final size = widget.options[i];
          return ListboxOption(
            controller: _listbox,
            index: i,
            label: _perPage(context, size),
            selected: size == widget.value,
            onTap: () {
              Popover.dismiss(context);
              widget.onChanged(size);
            },
          );
        },
      ),
    );
  }
}
