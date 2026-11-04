import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The table tokens on their own: every row fill a grid layers — the page, the
/// stripe, hover over each of them, the selection and a hovered selection —
/// with its contrast against the page, then the theme's metrics as a mock
/// grid at each density, holding a control of the size that density is for.
class TableTokensDemo extends StatelessWidget {
  @Preview(name: 'Table tokens', wrapper: adminUiPreview)
  const TableTokensDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.tableMetrics;
    final hover = c.tableRowHover;
    return DemoPage(
      maxWidth: 760,
      children: [
        Text(
          'rows ${_px(m.rowCompact)} / ${_px(m.rowStandard)} / '
          '${_px(m.rowComfortable)} · header ${_px(m.headerHeight)} '
          '(${m.headerText.name}) · padding ${_px(m.cellPaddingX)} · '
          'selection ${_px(m.selectionColumnWidth)}',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Row fills, standard density'),
        _Grid(
          rowHeight: m.rowStandard,
          rows: [
            ('Row', c.surface, false),
            ('Stripe', c.tableRowStripe, false),
            ('Hover', Color.alphaBlend(hover, c.surface), false),
            (
              'Hover on stripe',
              Color.alphaBlend(hover, c.tableRowStripe),
              false,
            ),
            ('Selected', c.tableRowSelected, true),
            ('Selected, hovered', c.tableRowSelectedHover, true),
          ],
        ),
        const Gap(AdminSpacing.xl),
        for (final density in TableDensity.values) ...[
          DemoSection('${density.name} · ${_px(m.rowHeight(density))}'),
          _Grid(
            rowHeight: m.rowHeight(density),
            control: density == TableDensity.compact
                ? ControlSize.small
                : ControlSize.medium,
            rows: [
              ('Row', c.surface, false),
              ('Selected', c.tableRowSelected, true),
            ],
          ),
          const Gap(AdminSpacing.lg),
        ],
      ],
    );
  }
}

String _px(double v) => v.toStringAsFixed(0);

/// A mock grid on the page surface: the header, then one row per entry —
/// its checkbox, its role, and its contrast against the page — or, with a
/// [control], a button of that size in the last cell.
class _Grid extends StatelessWidget {
  final double rowHeight;
  final List<(String, Color, bool)> rows;
  final ControlSize? control;

  const _Grid({required this.rowHeight, required this.rows, this.control});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.tableMetrics;
    final type = context.type;
    final muted = c.readableOn(
      c.foregroundMuted,
      surfaces: [c.tableRowStripe, c.tableRowSelected],
    );
    final headerStyle =
        switch (m.headerText) {
          TableHeaderText.caption => type.weighted(
            type.caption,
            FontWeight.w600,
          ),
          TableHeaderText.label => type.bodyStrong,
        }.copyWith(
          color: c.readableOn(c.foregroundMuted, surfaces: [c.surfaceMuted]),
        );

    Widget cell(Widget child, {double? width, bool end = false}) {
      final padded = Padding(
        padding: EdgeInsets.symmetric(horizontal: m.cellPaddingX),
        child: Align(
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      );
      return width == null
          ? Expanded(child: padded)
          : SizedBox(width: width, child: padded);
    }

    String ratio(Color fill) =>
        '${contrastRatio(fill, c.surface).toStringAsFixed(2)}:1';

    // Rows and the header grow with their text, as the table's do, and so
    // does the last column, which holds a header word of its own.
    final lastWidth = 120 + textGrowthOf(context, headerStyle);
    Widget row(Color fill, double height, List<Widget> children) => Container(
      height: height + textGrowthOf(context, type.body),
      decoration: BoxDecoration(
        color: fill,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(children: children),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      child: Column(
        children: [
          Container(
            height: m.headerHeight + textGrowthOf(context, headerStyle),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                SizedBox(width: m.selectionColumnWidth),
                cell(Text('Role', style: headerStyle)),
                cell(Text('Detail', style: headerStyle)),
                cell(
                  Text(
                    control == null ? 'On page' : 'Action',
                    style: headerStyle,
                  ),
                  width: lastWidth,
                  end: true,
                ),
              ],
            ),
          ),
          for (final (name, fill, selected) in rows)
            row(fill, rowHeight, [
              SizedBox(
                width: m.selectionColumnWidth,
                child: Center(
                  child: Check(
                    value: selected,
                    onChanged: (_) {},
                    semanticLabel: 'Select $name',
                  ),
                ),
              ),
              cell(Text(name, style: type.bodyStrong)),
              cell(
                Text(
                  'SKU-1042 · muted',
                  style: type.body.copyWith(color: muted),
                ),
              ),
              cell(
                control == null
                    ? Text(
                        ratio(fill),
                        style: type.body.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      )
                    : Button('Open', size: control!, onPressed: () {}),
                width: lastWidth,
                end: true,
              ),
            ]),
        ],
      ),
    );
  }
}
