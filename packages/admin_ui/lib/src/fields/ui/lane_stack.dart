import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/status_pill.dart';
import '../../common/ui/text_link.dart';
import '../../common/ui/tip.dart';
import '../../i18n/locale_status.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_shell.dart';

/// A multi-lane body: one editable lane per visible locale, grouped in a
/// headerless bordered box. This is a *body* — it carries no label or field-level
/// capabilities; drop it inside a [FieldShell]. It's the translatable counterpart
/// to a single-value body like [TextBody].
///
/// Each lane is built by [laneBuilder], so any body type can be translated,
/// and laid out in its language ([LaneLanguage]): an Arabic lane is edited
/// right to left whatever the admin's direction. A start gutter carries the
/// lane's locale identity — its code and a status dot (the status word lives
/// in a tooltip) — plus an optional per-lane [laneTrailing] (its
/// comments/history); a lane in [modifiedLanes] gets a contained draft
/// accent. An outdated lane says so under its body, with a re-translate action
/// when [retranslate] offers one for it.
///
/// A lone visible locale drops the box and the gutter — the field's label and
/// language pill already name it — but keeps what belongs to the lane: its
/// [laneTrailing] beside the body and the outdated banner below it.
///
/// For assistive technology each lane's body is named by its language, and
/// where it is one control among several — another lane, a trailing action —
/// by the enclosing [FieldShell]'s label too ("Title, French"), so it never
/// depends on a group being announced.
class LaneStack extends StatelessWidget {
  /// Visible lanes, in display order (source first by convention).
  final List<LocaleInfo> lanes;

  /// The control for one lane — host any body, value- or controller-backed.
  final Widget Function(LocaleInfo lane) laneBuilder;

  /// The code of the locale being edited, whose lane code is emphasised.
  final String? activeLocale;

  final bool showLaneStatus;

  /// Lanes whose draft differs from the baseline value.
  final Set<String> modifiedLanes;

  /// Reports the lane whose body took focus, so the shell can track the active
  /// locale. Omit to leave focus untracked.
  final ValueChanged<String>? onActiveLocaleChanged;

  /// Per-lane capability cluster (its comments, history) on the code row.
  final Widget? Function(LocaleInfo lane)? laneTrailing;

  /// The action that re-translates a lane from the source, offered in its
  /// "Source changed" banner while it is outdated. Null, or null for a lane,
  /// leaves that lane's banner a plain warning.
  final VoidCallback? Function(LocaleInfo lane)? retranslate;

  const LaneStack({
    super.key,
    required this.lanes,
    required this.laneBuilder,
    this.activeLocale,
    this.showLaneStatus = true,
    this.modifiedLanes = const {},
    this.onActiveLocaleChanged,
    this.laneTrailing,
    this.retranslate,
  });

  @override
  Widget build(BuildContext context) {
    if (lanes.length == 1) return _single(context, lanes.first);
    final gutter = _gutterWidth(context);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lanes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.borderSubtle),
            _lane(context, lanes[i], gutter),
          ],
        ],
      ),
    );
  }

  /// The lone lane: its body at full width with the trailing cluster beside
  /// it and the outdated banner below. The body keeps its place in the tree
  /// whether or not either shows, so a status flip never drops its focus.
  Widget _single(BuildContext context, LocaleInfo lane) {
    final trailing = laneTrailing?.call(lane);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Without a trailing action the lane is the field's only
            // control, which the shell's label already names.
            Expanded(child: _body(context, lane, withField: trailing != null)),
            ..._trailing(context, trailing),
          ],
        ),
        if (lane.status == LocaleStatus.outdated) ...[
          const Gap(AdminSpacing.md),
          _outdated(context, lane),
        ],
      ],
    );
  }

  Widget _lane(BuildContext context, LocaleInfo lane, double gutter) {
    final modified = modifiedLanes.contains(lane.code);
    final trailing = laneTrailing?.call(lane);
    // Only the changed lane is tinted (a faint draft fill + amber accent); the
    // field-level changed marker in the label row carries the overview.
    // The decoration is always non-null with a constant-width start border
    // (transparent when clean) so toggling the accent never inserts/removes a
    // DecoratedBox — that would re-parent the lane body and drop its focus.
    final rail = context.stroke.indicator;
    return Container(
      // Past the accent rail, the content sits 12 in on every side.
      padding: EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg - rail,
        AdminSpacing.lg,
        AdminSpacing.lg,
        AdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: modified ? context.colors.modifiedFill : null,
        border: BorderDirectional(
          start: BorderSide(
            color: modified ? context.colors.warning : Colors.transparent,
            width: rail,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gutter(context, lane, gutter),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _body(context, lane, withField: true),
                if (lane.status == LocaleStatus.outdated) ...[
                  const Gap(AdminSpacing.md),
                  _outdated(context, lane),
                ],
              ],
            ),
          ),
          ..._trailing(context, trailing),
        ],
      ),
    );
  }

  /// A lane's [laneTrailing], centred on its body's first control row.
  List<Widget> _trailing(BuildContext context, Widget? trailing) {
    if (trailing == null) return const [];
    return [
      const Gap(AdminSpacing.md),
      SizedBox(
        height: _controlRow(context),
        child: Center(widthFactor: 1, child: trailing),
      ),
    ];
  }

  /// The lane's identity rail: a quiet locale code with the status carried by a
  /// single dot (its word lives in a tooltip, not a chip). Sits in a start
  /// gutter so the input — not the chrome — is the field's visual weight,
  /// centred on the body's first control row.
  Widget _gutter(BuildContext context, LocaleInfo lane, double width) {
    final active = lane.code == activeLocale;
    final meta = localeStatusMeta(context)[lane.status]!;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLaneStatus) ...[
          StatusDot(color: meta.color, ring: meta.ring, size: _dot),
          const Gap(AdminSpacing.sm),
        ],
        // Weight as well as colour marks the active lane, so the cue survives
        // without colour vision.
        Text(
          lane.code.toUpperCase(),
          style: _codeStyle(context, active: active).copyWith(
            color: active
                ? context.colors.primaryText
                : context.colors.foregroundSecondary,
          ),
        ),
      ],
    );
    return SizedBox(
      width: width,
      height: _controlRow(context),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: showLaneStatus ? Tip(message: meta.label, child: row) : row,
      ),
    );
  }

  static const _dot = 7.0;

  /// The height of the body's first control row: a medium field, grown by
  /// as much as its text at a large text size.
  static double _controlRow(BuildContext context) =>
      context.sizes.medium + textGrowthOf(context, context.type.fieldText);

  static TextStyle _codeStyle(BuildContext context, {required bool active}) =>
      context.type.weighted(
        context.type.micro,
        active ? FontWeight.w800 : FontWeight.w600,
      );

  /// The gutter's width, the same for every lane so their bodies line up:
  /// 40, or as wide as the longest code needs ('PT-BR'), set in the active
  /// weight so moving focus never reflows the lanes.
  double _gutterWidth(BuildContext context) {
    final inherited = DefaultTextStyle.of(context).style;
    var width = 40.0;
    for (final lane in lanes) {
      final painter = TextPainter(
        text: TextSpan(
          text: lane.code.toUpperCase(),
          style: inherited.merge(_codeStyle(context, active: true)),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final dot = showLaneStatus ? _dot + AdminSpacing.sm : 0.0;
      width = math.max(width, (dot + painter.width).ceilToDouble());
      painter.dispose();
    }
    return width;
  }

  /// The lane's body, named by its language — and [withField], by the
  /// enclosing [FieldShell]'s label first — and laid out in that language
  /// ([LaneLanguage]).
  Widget _body(
    BuildContext context,
    LocaleInfo lane, {
    required bool withField,
  }) {
    final field = withField
        ? context.findAncestorWidgetOfExactType<FieldShell>()?.label
        : null;
    final language = languageNameOf(context, lane.code);
    // One control among several is a node of its own, whether or not its
    // language marks it as one. Always built, so a trailing action coming
    // or going never re-parents the body and drops its focus.
    Widget child = Semantics(
      container: withField,
      child: LaneLanguage.forLane(
        lane,
        child: Semantics(
          label: field == null
              ? language
              : context.adminL10n.fields.fieldInLanguage(field, language),
          child: laneBuilder(lane),
        ),
      ),
    );
    if (onActiveLocaleChanged == null) return child;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) {
        if (f) onActiveLocaleChanged!(lane.code);
      },
      child: child,
    );
  }

  /// "Source changed" under an outdated lane, in the outdated status colour,
  /// with the re-translate action when there is one.
  Widget _outdated(BuildContext context, LocaleInfo lane) {
    final color = localeStatusMeta(context)[LocaleStatus.outdated]!.text;
    final action = retranslate?.call(lane);
    final l10n = context.adminL10n.fields;
    return Wrap(
      spacing: AdminSpacing.lg,
      runSpacing: AdminSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem_rounded,
              size: context.iconSizes.sm,
              color: color,
            ),
            const Gap(AdminSpacing.sm),
            Flexible(
              child: Text(
                l10n.sourceChanged,
                style: context.type.weighted(
                  context.type.caption.copyWith(color: color),
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (action != null)
          TextLink(
            l10n.retranslate,
            semanticLabel: l10n.retranslateLanguage(
              languageNameOf(context, lane.code),
            ),
            onPressed: action,
          ),
      ],
    );
  }
}
