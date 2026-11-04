import 'package:material_ui/material_ui.dart';

import '../../i18n/locale_status.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../diff_model.dart';
import 'diff_op_style.dart';
import 'text_diff.dart';

/// A block-id-keyed diff of a rich body. Each block is a row carrying a gutter
/// marker on its start edge (added / removed / changed / moved), its type, and
/// its content — changed blocks word-diff their text, moved blocks note the
/// position shift. In [DiffLayout.split] each row shows before | after; in
/// [DiffLayout.unified] one interleaved column. Unchanged blocks are hidden
/// unless [showUnchanged].
class BlockDiff extends StatelessWidget {
  final List<BlockChange> blocks;
  final DiffLayout layout;
  final bool showUnchanged;

  /// The language the body is written in, such as 'ar' or 'pt-BR': each
  /// block's text takes that language's direction and locale
  /// ([LaneLanguage]), while its marker and labels stay in the admin's. Null
  /// or empty keeps the ambient direction.
  final String? language;

  const BlockDiff({
    super.key,
    required this.blocks,
    this.layout = DiffLayout.unified,
    this.showUnchanged = false,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final b in blocks)
        if (showUnchanged || b.op != DiffOp.unchanged) b,
    ];

    if (visible.isEmpty) {
      return Text(
        context.adminL10n.display.noBlockChanges,
        style: context.type.bodyMuted,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.md),
          _BlockRow(change: visible[i], layout: layout, language: language),
        ],
      ],
    );
  }
}

class _BlockRow extends StatelessWidget {
  final BlockChange change;
  final DiffLayout layout;
  final String? language;

  const _BlockRow({
    required this.change,
    required this.layout,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = DiffOpStyle.of(context, change.op);
    // Secondary text sits on the op's fill as well as the page.
    final muted = c.readableOn(
      c.foregroundMuted,
      surfaces: [c.surface, c.background, if (tone.fill.a > 0) tone.fill],
    );

    final radius = context.radii.radiusSmall;
    return Container(
      decoration: BoxDecoration(
        color: tone.fill,
        border: BorderDirectional(
          start: BorderSide(color: tone.accent, width: 3),
        ),
        // Flutter rounds a one-sided border only for a non-zero radius and
        // asserts on a zero one, so a square theme passes none.
        borderRadius: radius > 0
            ? BorderRadiusDirectional.horizontal(end: Radius.circular(radius))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.lg,
        AdminSpacing.md,
      ),
      // Stretched, so the block's text starts at its own language's edge.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, tone, muted),
          const Gap(AdminSpacing.sm),
          _body(context, muted),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, DiffOpStyle tone, Color muted) {
    return Row(
      children: [
        Icon(tone.icon, size: context.iconSizes.xs, color: tone.text),
        const Gap(AdminSpacing.sm),
        Text(
          tone.label.toUpperCase(),
          style: context.type
              .weighted(context.type.micro, FontWeight.w700)
              .copyWith(color: tone.text, letterSpacing: 0.5),
        ),
        const Gap(AdminSpacing.md),
        Text(
          _typeLabel(change.type),
          style: context.type.micro.copyWith(color: muted),
        ),
        if (change.shifted) ...[
          const Spacer(),
          DiffMoveHint(
            change.fromIndex!,
            change.toIndex!,
            style: context.type.micro.copyWith(color: muted),
          ),
        ],
      ],
    );
  }

  Widget _body(BuildContext context, Color muted) {
    final textStyle = _contentStyle(context, change.type);
    final before = change.before ?? '';
    final after = change.after ?? '';

    switch (change.op) {
      case DiffOp.changed:
        if (before.isEmpty && after.isEmpty && change.summary != null) {
          return _summary(context, muted);
        }
        return TextDiff(
          before: before,
          after: after,
          layout: layout,
          style: textStyle,
          language: language,
        );
      case DiffOp.added:
        if (after.isEmpty && change.summary != null) {
          return _summary(context, muted);
        }
        return _oneSided(context, muted, after: after, style: textStyle);
      case DiffOp.removed:
        if (before.isEmpty && change.summary != null) {
          return _summary(context, muted);
        }
        return _oneSided(context, muted, before: before, style: textStyle);
      case DiffOp.moved:
      case DiffOp.unchanged:
        final text = after.isNotEmpty ? after : before;
        if (text.isEmpty && change.summary != null) {
          return _summary(context, muted);
        }
        return _inLanguage(Text(text, style: textStyle));
    }
  }

  /// [content] laid out in the body's [language].
  Widget _inLanguage(Widget content) {
    final code = language;
    if (code == null || code.isEmpty) return content;
    return LaneLanguage(code: code, child: content);
  }

  /// The summary one-liner for a block with no plain text (image, embed, …).
  Widget _summary(BuildContext context, Color muted) => Text(
    change.summary!,
    style: context.type.body.copyWith(
      color: muted,
      fontStyle: FontStyle.italic,
    ),
  );

  /// A pure add / remove. In split layout it occupies its own column and leaves
  /// the opposite side an empty cell, so before/after stay aligned.
  Widget _oneSided(
    BuildContext context,
    Color muted, {
    String? before,
    String? after,
    required TextStyle style,
  }) {
    final isAdd = after != null;
    final content = _inLanguage(Text(after ?? before ?? '', style: style));
    if (layout == DiffLayout.unified) return content;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: isAdd ? _empty(context, muted) : content),
        const Gap(AdminSpacing.xl),
        Expanded(child: isAdd ? content : _empty(context, muted)),
      ],
    );
  }

  Widget _empty(BuildContext context, Color muted) => Text(
    '—',
    semanticsLabel: context.adminL10n.display.empty,
    style: context.type.body.copyWith(color: muted),
  );

  TextStyle _contentStyle(BuildContext context, String type) {
    // A top-level heading takes the heading step; the levels under it stay
    // at body size, bolder than a paragraph.
    if (type.startsWith('heading')) {
      return context.type
          .weighted(
            type == 'heading_1' ? context.type.heading : context.type.body,
            FontWeight.w700,
          )
          .copyWith(color: context.colors.foreground);
    }
    if (type == 'quote') {
      return context.type.body.copyWith(
        fontStyle: FontStyle.italic,
        color: context.colors.foregroundSecondary,
      );
    }
    return context.type.body;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'paragraph':
      return 'Paragraph';
    case 'heading_1':
      return 'Heading 1';
    case 'heading_2':
      return 'Heading 2';
    case 'heading_3':
      return 'Heading 3';
    case 'quote':
      return 'Quote';
    case 'image':
      return 'Image';
    case 'bulleted_list':
      return 'Bulleted list';
    case 'numbered_list':
      return 'Numbered list';
    case 'code':
      return 'Code';
    case 'divider':
      return 'Divider';
    default:
      final words = type.replaceAll('_', ' ');
      return words.isEmpty
          ? words
          : words[0].toUpperCase() + words.substring(1);
  }
}
