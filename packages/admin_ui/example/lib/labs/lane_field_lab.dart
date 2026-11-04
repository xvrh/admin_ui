import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../src/preview_shell.dart';
import '../src/ui/demo_kit.dart';
import '../src/ui/translation_kit.dart';

/// Lab: a translatable field that edits one language at a time.
///
/// One field skeleton for single and multi language: a status spine, a label
/// row with its capability cluster, then a body that is either a bare editor
/// (single) or one focused lane with the other languages as glanceable rows
/// (multi). Every changed lane can reveal an inline "what changed" diff. None
/// of it ships: [LaneField] is private to this lab.

// ── how the "unpublished" state reads ───────────────────────────────────────
enum CueStyle { spine, tint, badge }

// ── the field ───────────────────────────────────────────────────────────────
class LaneField extends StatefulWidget {
  final String label;
  final String? help;

  final List<LocaleInfo> locales;
  final String sourceLocale;

  /// The language expanded (and focused) on first render. Others start as rows.
  final String activeLocale;

  final Map<String, String> values;
  final Map<String, String> published;

  /// Also start the source language open as a reference above the active lane
  /// (the "translator" default). Off = only the active lane opens.
  final bool sourceReference;

  final CueStyle cue;
  final int maxLines;
  final String? hint;
  final String? errorText;

  final void Function(String code, String value) onChanged;

  /// Optional non-text body per lane (a select, a switch…), to prove the model
  /// is orthogonal to field type.
  final Widget Function(LocaleInfo lane)? laneBuilder;

  const LaneField({
    super.key,
    required this.label,
    required this.locales,
    required this.sourceLocale,
    required this.activeLocale,
    required this.values,
    required this.published,
    required this.onChanged,
    this.help,
    this.sourceReference = false,
    this.cue = CueStyle.spine,
    this.maxLines = 1,
    this.hint,
    this.errorText,
    this.laneBuilder,
  });

  @override
  State<LaneField> createState() => _LaneFieldState();
}

class _LaneFieldState extends State<LaneField> {
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};

  /// The languages currently expanded into editors. Direct manipulation: tap a
  /// row to add one, hit its close button to drop it back to a row. Nothing is
  /// ever closed implicitly, and the vertical order is fixed (source-first,
  /// then declared order), so lanes never jump.
  final Set<String> _expanded = {};
  String? _focusedCode;
  String? _openDiff;
  bool _hoverField = false;

  /// The reveal-diff control is quiet: it fades in on field hover (or stays
  /// while its diff is open) and is never a loud always-on button.
  bool _reveal(String code) => _hoverField || _openDiff == code;

  void _toggleDiff(String code) =>
      setState(() => _openDiff = _openDiff == code ? null : code);

  /// A discreet, icon-only "see change" toggle that holds its slot (fades, never
  /// reflows) so the row doesn't jump as it appears.
  Widget _diffToggle(String code) {
    final on = _reveal(code);
    final open = _openDiff == code;
    return Opacity(
      opacity: on ? 1 : 0,
      child: IgnorePointer(
        ignoring: !on,
        child: _MiniIcon(
          icon: open ? Icons.close_rounded : Icons.difference_outlined,
          tooltip: open ? 'Hide change' : 'See change',
          onTap: () => _toggleDiff(code),
        ),
      ),
    );
  }

  bool get _single => widget.locales.length <= 1;

  LocaleInfo _info(String code) =>
      widget.locales.firstWhere((l) => l.code == code);

  bool _modified(String code) =>
      widget.published.containsKey(code) &&
      (widget.values[code] ?? '') != widget.published[code];

  Set<String> get _modifiedCodes => {
    for (final l in widget.locales)
      if (_modified(l.code)) l.code,
  };

  /// Expanded lanes in fixed display order (source-first, then declared order).
  List<String> get _expandedList => [
    if (_expanded.contains(widget.sourceLocale)) widget.sourceLocale,
    for (final l in widget.locales)
      if (l.code != widget.sourceLocale && _expanded.contains(l.code)) l.code,
  ];

  List<String> get _collapsed => [
    for (final l in widget.locales)
      if (!_expanded.contains(l.code)) l.code,
  ];

  @override
  void initState() {
    super.initState();
    for (final l in widget.locales) {
      _controllers[l.code] =
          TextEditingController(text: widget.values[l.code] ?? '')..addListener(
            () => widget.onChanged(l.code, _controllers[l.code]!.text),
          );
      _focusNodes[l.code] = FocusNode()..addListener(() => _onFocus(l.code));
    }
    _expanded.add(widget.activeLocale);
    if (widget.sourceReference) _expanded.add(widget.sourceLocale);
  }

  @override
  void didUpdateWidget(covariant LaneField old) {
    super.didUpdateWidget(old);
    for (final l in widget.locales) {
      final c = _controllers[l.code];
      final v = widget.values[l.code] ?? '';
      if (c != null && v != c.text) c.text = v; // external revert/fill
    }
  }

  void _onFocus(String code) {
    final has = _focusNodes[code]!.hasFocus;
    if (has) {
      setState(() => _focusedCode = code);
    } else if (_focusedCode == code) {
      setState(() => _focusedCode = null);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Open a language: add it to the expanded set and focus it. Additive — the
  /// lanes already open stay open.
  void _open(String code) {
    setState(() => _expanded.add(code));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[code]?.requestFocus(),
    );
  }

  /// Close a language back to a row. The last open lane can't be closed, so the
  /// field always keeps at least one editor.
  void _close(String code) {
    if (_expanded.length <= 1) return;
    setState(() {
      _expanded.remove(code);
      if (_openDiff == code) _openDiff = null;
    });
  }

  void _fillFromSource(String code) {
    final src = widget.values[widget.sourceLocale] ?? '';
    setState(() {
      _controllers[code]?.text = src;
      widget.onChanged(code, src);
    });
    _toast(
      'Filled ${code.toUpperCase()} from ${widget.sourceLocale.toUpperCase()}',
    );
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );

  @override
  Widget build(BuildContext context) {
    final modified = _modifiedCodes.isNotEmpty;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, modified),
        const SizedBox(height: 8),
        if (_single) ...[
          _editor(widget.sourceLocale),
          if (_openDiff == widget.sourceLocale) ...[
            const SizedBox(height: 8),
            InlineDiff(
              was: widget.published[widget.sourceLocale] ?? '',
              now: widget.values[widget.sourceLocale] ?? '',
              onClose: () => setState(() => _openDiff = null),
            ),
          ],
        ] else ...[
          for (final code in _expandedList) _expandedLane(context, code),
          if (_collapsed.isNotEmpty) ...[
            const SizedBox(height: 4),
            _rowGroup(context),
          ],
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: 7),
          _message(context, widget.errorText!),
        ],
      ],
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverField = true),
      onExit: (_) => setState(() => _hoverField = false),
      child: _frame(context, modified, body),
    );
  }

  // ── the status spine / tint frame ─────────────────────────────────────────
  Widget _frame(BuildContext context, bool modified, Widget child) {
    final c = context.colors;
    final bad = widget.errorText != null;
    if (widget.cue == CueStyle.tint) {
      final on = modified || bad;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: on
              ? (bad ? c.danger.withValues(alpha: 0.05) : c.modifiedFill)
              : null,
          borderRadius: BorderRadius.circular(context.radii.radius),
          border: Border.all(
            color: on
                ? (bad ? c.danger : c.warning).withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: child,
      );
    }
    final spine = widget.cue == CueStyle.spine
        ? (bad
              ? c.danger
              : modified
              ? c.warning
              : Colors.transparent)
        : Colors.transparent;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 12),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: spine, width: 2)),
      ),
      child: child,
    );
  }

  // ── label row + capability cluster ────────────────────────────────────────
  Widget _header(BuildContext context, bool modified) {
    final c = context.colors;
    final active = _focusedCode != null;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.fieldLabel.copyWith(
                    color: active ? c.primary : c.foregroundMuted,
                  ),
                ),
              ),
              if (widget.help != null) ...[
                const SizedBox(width: 7),
                HelpButton(text: widget.help!),
              ],
              if (widget.cue == CueStyle.badge && modified) ...[
                const SizedBox(width: 10),
                Flexible(child: _badge(context)),
              ],
            ],
          ),
        ),
        if (_single && modified) ...[
          const SizedBox(width: 4),
          _diffToggle(widget.sourceLocale),
        ],
        if (!_single) ...[
          const SizedBox(width: 8),
          LanguagePill(
            value: _expanded,
            activeLocale: _focusedCode ?? widget.activeLocale,
            locales: widget.locales,
            sourceLocale: widget.sourceLocale,
            onChanged: (v) => setState(() {
              if (v.isEmpty) return;
              _expanded
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      ],
    );
  }

  Widget _badge(BuildContext context) {
    final detail = modifiedLocalesDetail(widget.locales, _modifiedCodes);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: context.colors.warning, size: 6),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            detail == null ? 'Unpublished' : 'Unpublished · $detail',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption.copyWith(
              color: context.colors.warningText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── an expanded lane: identity caption + editor + optional diff ────────────
  Widget _expandedLane(BuildContext context, String code) {
    final lane = _info(code);
    final modified = _modified(code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_single) _laneCaption(context, lane, modified),
          if (!_single) const SizedBox(height: 6),
          if (widget.laneBuilder case final build?)
            // The lane is written in its language's direction; the caption
            // above it follows the admin's.
            Directionality(textDirection: lane.direction, child: build(lane))
          else
            _editor(code),
          if (_openDiff == code) ...[
            const SizedBox(height: 8),
            InlineDiff(
              was: widget.published[code] ?? '',
              now: widget.values[code] ?? '',
              onClose: () => setState(() => _openDiff = null),
            ),
          ],
          if (_workflow(lane, code) case final w?) ...[
            const SizedBox(height: 7),
            w,
          ],
        ],
      ),
    );
  }

  Widget _laneCaption(BuildContext context, LocaleInfo lane, bool modified) {
    final c = context.colors;
    final meta = localeStatusMeta(context)[lane.status]!;
    final activeHere = _focusedCode == lane.code;
    return Row(
      children: [
        StatusDot(
          color: modified ? c.warning : meta.color,
          ring: meta.ring,
          size: 7,
        ),
        const SizedBox(width: 8),
        Text(
          lane.code.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: activeHere ? c.primary : c.foregroundSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          lane.native,
          style: context.type.caption.copyWith(color: c.foregroundMuted),
        ),
        const Spacer(),
        if (modified) _diffToggle(lane.code),
        if (_expanded.length > 1)
          _MiniIcon(
            icon: Icons.close_rounded,
            tooltip: 'Close ${lane.code.toUpperCase()}',
            onTap: () => _close(lane.code),
          ),
      ],
    );
  }

  Widget _editor(String code) {
    final field = TextField(
      controller: _controllers[code],
      focusNode: _focusNodes[code],
      minLines: widget.maxLines > 1 ? widget.maxLines : 1,
      maxLines: widget.maxLines,
      style: TextStyle(color: context.colors.foreground),
      decoration: fieldInputDecoration(context, hint: widget.hint),
    );
    return Directionality(textDirection: _info(code).direction, child: field);
  }

  // ── the collapsed rows (every other language) ─────────────────────────────
  Widget _rowGroup(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _collapsed.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.borderSubtle),
            _LaneRow(
              lane: _info(_collapsed[i]),
              value: widget.values[_collapsed[i]] ?? '',
              modified: _modified(_collapsed[i]),
              diffOpen: _openDiff == _collapsed[i],
              revealDiff: _reveal(_collapsed[i]),
              source: _collapsed[i] == widget.sourceLocale,
              onOpen: () => _open(_collapsed[i]),
              onToggleDiff: _modified(_collapsed[i])
                  ? () => _toggleDiff(_collapsed[i])
                  : null,
              action: _workflow(_info(_collapsed[i]), _collapsed[i]),
              diff: _openDiff == _collapsed[i]
                  ? InlineDiff(
                      was: widget.published[_collapsed[i]] ?? '',
                      now: widget.values[_collapsed[i]] ?? '',
                      onClose: () => setState(() => _openDiff = null),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── the coming translation-workflow actions, in situ ──────────────────────
  Widget? _workflow(LocaleInfo lane, String code) {
    final empty = (widget.values[code] ?? '').trim().isEmpty;
    if (empty || lane.status == LocaleStatus.missing) {
      return _WorkflowHint(
        icon: Icons.auto_awesome_rounded,
        text: 'Translate from ${widget.sourceLocale.toUpperCase()}',
        onTap: () => _fillFromSource(code),
      );
    }
    if (lane.status == LocaleStatus.outdated) {
      return _WorkflowHint(
        icon: Icons.sync_problem_rounded,
        text: 'Source changed since this was translated · Re-translate',
        tone: _HintTone.warn,
        onTap: () => _fillFromSource(code),
      );
    }
    if (lane.status == LocaleStatus.review) {
      return _WorkflowHint(
        icon: Icons.done_all_rounded,
        text: 'Mark reviewed',
        onTap: () => _toast('${code.toUpperCase()} marked reviewed'),
      );
    }
    return null;
  }

  Widget _message(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: context.colors.danger),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: context.type.caption.copyWith(color: context.colors.danger),
          ),
        ),
      ],
    );
  }
}

// ── a single collapsed peer row ───────────────────────────────────────────────
class _LaneRow extends StatelessWidget {
  final LocaleInfo lane;
  final String value;
  final bool modified;
  final bool source;
  final bool diffOpen;
  final bool revealDiff;
  final VoidCallback onOpen;
  final VoidCallback? onToggleDiff;
  final Widget? action;
  final Widget? diff;

  const _LaneRow({
    required this.lane,
    required this.value,
    required this.modified,
    required this.source,
    required this.diffOpen,
    required this.revealDiff,
    required this.onOpen,
    this.onToggleDiff,
    this.action,
    this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = localeStatusMeta(context)[lane.status]!;
    final empty = value.trim().isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: modified ? c.modifiedFill : null,
        border: BorderDirectional(
          start: BorderSide(
            color: modified ? c.warning : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // The row opens the lane; its actions sit beside that tap target,
          // not inside it, so each is a Tab stop of its own.
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Tappable(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        10,
                        0,
                        10,
                      ),
                      child: Row(
                        children: [
                          StatusDot(
                            color: modified ? c.warning : meta.color,
                            ring: meta.ring,
                            size: 7,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 26,
                            child: Text(
                              lane.code.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: c.foregroundSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: empty
                                ? Text(
                                    'Not translated yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.type.bodySmall.copyWith(
                                      color: c.placeholder,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Directionality(
                                    textDirection: lane.direction,
                                    child: Text(
                                      value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.type.bodySmall.copyWith(
                                        color: c.foregroundSecondary,
                                      ),
                                    ),
                                  ),
                          ),
                          if (source) ...[
                            const SizedBox(width: 8),
                            _tag(context, 'source'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Shrinks, ellipsized, where a phone leaves the row no room.
                if (action != null) ...[
                  const SizedBox(width: 6),
                  Flexible(child: action!),
                ],
                if (onToggleDiff != null)
                  Opacity(
                    opacity: revealDiff ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !revealDiff,
                      child: _MiniIcon(
                        icon: diffOpen
                            ? Icons.close_rounded
                            : Icons.difference_outlined,
                        tooltip: diffOpen ? 'Hide change' : 'See change',
                        onTap: onToggleDiff!,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: c.foregroundFaint,
                ),
              ],
            ),
          ),
          if (diff != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 10, 12),
              child: diff!,
            ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: context.colors.surfaceMuted,
      borderRadius: BorderRadius.circular(context.radii.radiusSmall),
    ),
    child: Text(
      text,
      style: context.type.caption.copyWith(
        color: context.colors.foregroundMuted,
      ),
    ),
  );
}

// ── the inline "what changed" diff ────────────────────────────────────────────
class InlineDiff extends StatelessWidget {
  final String was;
  final String now;
  final VoidCallback? onClose;

  const InlineDiff({
    super.key,
    required this.was,
    required this.now,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 6, 6),
            color: c.surfaceMuted,
            child: Row(
              children: [
                Icon(
                  Icons.difference_outlined,
                  size: 13,
                  color: c.foregroundMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'PUBLISHED → DRAFT',
                  style: context.type.caption.copyWith(
                    color: c.foregroundMuted,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onClose != null)
                  _MiniIcon(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onTap: onClose!,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
            child: Text.rich(
              TextSpan(children: _spans(context)),
              style: context.type.bodySmall.copyWith(
                color: c.foreground,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(BuildContext context) {
    final c = context.colors;
    final chunks = _wordDiff(was, now);
    final out = <InlineSpan>[];
    for (var i = 0; i < chunks.length; i++) {
      final ch = chunks[i];
      if (i > 0) out.add(const TextSpan(text: ' '));
      out.add(
        TextSpan(
          text: ch.text,
          style: switch (ch.kind) {
            _DiffKind.removed => TextStyle(
              color: c.danger,
              decoration: TextDecoration.lineThrough,
              decorationColor: c.danger.withValues(alpha: 0.7),
            ),
            _DiffKind.added => TextStyle(
              color: c.success,
              fontWeight: FontWeight.w600,
            ),
            _DiffKind.equal => null,
          },
        ),
      );
    }
    return out;
  }
}

enum _DiffKind { equal, removed, added }

class _Chunk {
  final String text;
  final _DiffKind kind;
  const _Chunk(this.text, this.kind);
}

/// A tiny word-level LCS diff — enough to read a headline change at a glance.
List<_Chunk> _wordDiff(String o, String n) {
  final a = o.trim().isEmpty ? <String>[] : o.trim().split(RegExp(r'\s+'));
  final b = n.trim().isEmpty ? <String>[] : n.trim().split(RegExp(r'\s+'));
  final m = a.length, k = b.length;
  final dp = List.generate(m + 1, (_) => List<int>.filled(k + 1, 0));
  for (var i = m - 1; i >= 0; i--) {
    for (var j = k - 1; j >= 0; j--) {
      dp[i][j] = a[i] == b[j]
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final out = <_Chunk>[];
  var i = 0, j = 0;
  while (i < m && j < k) {
    if (a[i] == b[j]) {
      out.add(_Chunk(a[i], _DiffKind.equal));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.add(_Chunk(a[i], _DiffKind.removed));
      i++;
    } else {
      out.add(_Chunk(b[j], _DiffKind.added));
      j++;
    }
  }
  while (i < m) {
    out.add(_Chunk(a[i++], _DiffKind.removed));
  }
  while (j < k) {
    out.add(_Chunk(b[j++], _DiffKind.added));
  }
  return out;
}

// ── little shared bits ────────────────────────────────────────────────────────
enum _HintTone { info, warn }

class _WorkflowHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final _HintTone tone;
  final VoidCallback onTap;

  const _WorkflowHint({
    required this.icon,
    required this.text,
    required this.onTap,
    this.tone = _HintTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = tone == _HintTone.warn ? c.warningText : c.primary;
    return Tappable(
      onTap: onTap,
      focusRadius: context.radii.radiusSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tip(
    message: tooltip,
    excludeFromSemantics: true,
    child: Tappable(
      onTap: onTap,
      semanticLabel: tooltip,
      excludeSemantics: true,
      focusRadius: context.radii.radiusSmall,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: context.colors.foregroundMuted),
      ),
    ),
  );
}

// ══ the catalog demo ══════════════════════════════════════════════════════════
const _singleLocales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
];

/// The catalog page of the lane-field lab, under Labs.
///
/// Kept for one open question: whether the kit's [TranslatableField] should
/// edit one focused language and list the others as one-line rows, rather
/// than [LaneStack]'s editor per visible language, once an entity has more
/// languages than a stack of editors can show. The kit answers it today by
/// letting the user choose which languages are visible ([LanguagePill]); this
/// page shows the other answer full size, so the two can be compared before
/// either changes.
class LaneFieldLabDemo extends StatefulWidget {
  @Preview(group: 'Labs', name: 'Lane field', wrapper: adminUiPreview)
  const LaneFieldLabDemo({super.key});

  @override
  State<LaneFieldLabDemo> createState() => _LaneFieldLabDemoState();
}

class _LaneFieldLabDemoState extends State<LaneFieldLabDemo> {
  late final _values = <String, Map<String, String>>{
    'title': {
      'EN': 'A coast that keeps its own time',
      'ES': 'Una costa que marca su propio tiempo',
      'FR': 'Une côte qui suit son propre rythme, hiver comme été',
      'DE': 'Eine Küste mit eigener Zeit',
      'JA': '',
    },
    'sub': {
      'EN': 'Inland, the cider country',
      'ES': 'Tierra de sidra, hacia el interior',
      'FR': 'À l’intérieur, le pays du cidre',
      'DE': 'Landeinwärts, das Cidre-Land',
      'JA': '内陸は、シードルの里',
    },
    'seo': {
      'EN': 'Plan a slow week on the northern coast: tides, cider houses, and empty beaches.',
      'ES': 'Planea una semana tranquila en la costa norte: mareas, sidrerías y playas vacías y salvajes.',
      'FR': 'Planifiez une semaine tranquille sur la côte nord : marées, cidreries et plages désertes.',
      'DE': 'Planen Sie eine ruhige Woche an der Nordküste: Gezeiten, Cidre-Häuser und leere Strände.',
      'JA': '',
    },
    'single': {'EN': 'Summer collection 2026'},
  };

  late final _published = <String, Map<String, String>>{
    'title': {
      'EN': 'A coast that keeps its own time',
      'ES': 'Una costa que marca su tiempo',
      'FR': 'Une côte qui suit son propre rythme',
      'DE': 'Eine Küste mit eigener Zeit',
      'JA': '',
    },
    'sub': {..._values['sub']!},
    'seo': {
      ..._values['seo']!,
      'ES': 'Planea una semana tranquila en la costa norte: mareas, sidrerías y playas.',
    },
    'single': {'EN': 'Collection 2026'},
  };

  @override
  Widget build(BuildContext context) {
    final cue = context.knobs.picker('Unpublished cue', const {
      'Amber spine': CueStyle.spine,
      'Soft tint': CueStyle.tint,
      'Word badge (today)': CueStyle.badge,
    }, CueStyle.spine);
    final srcRef = context.knobs.bool('Open source lane too', false);

    return DemoPage(
      maxWidth: 560,
      children: [
        Text(
          'One field skeleton for single and multi language. Multi opens the '
          'active language as an editor and lists every other language as a row '
          '— tap a row to open it, hit its × to close it. Nothing closes on its '
          'own. Change cue + source-lane in the panel.',
          style: TextStyle(color: context.colors.foregroundMuted, height: 1.5),
        ),
        const SizedBox(height: 28),

        const DemoSection('Single language'),
        const SizedBox(height: 16),
        _field('single', 'Title', cue, srcRef, locales: _singleLocales),
        const SizedBox(height: 8),
        Text(
          'No lane chrome, no pill — the multi model collapses to a bare field.',
          style: context.type.caption.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),

        const SizedBox(height: 36),
        const DemoSection('Multi language'),
        const SizedBox(height: 16),
        _field(
          'title',
          'Title',
          cue,
          srcRef,
          help: 'Renders as the page H1 and the browser tab.',
        ),
        const SizedBox(height: 28),
        _field(
          'seo',
          'SEO description',
          cue,
          srcRef,
          maxLines: 3,
          help: 'Shown in search results and social cards.',
        ),
        const SizedBox(height: 28),
        _field('sub', 'Subtitle', cue, srcRef),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _field(
    String key,
    String label,
    CueStyle cue,
    bool srcRef, {
    String? help,
    int maxLines = 1,
    List<LocaleInfo>? locales,
  }) {
    final ls = locales ?? demoLocales;
    final source = ls.first.code;
    return LaneField(
      key: ValueKey('$key-$srcRef'),
      label: label,
      help: help,
      locales: ls,
      sourceLocale: source,
      activeLocale: ls.length == 1 ? source : 'FR',
      values: _values[key]!,
      published: _published[key] ?? const {},
      sourceReference: srcRef,
      cue: cue,
      maxLines: maxLines,
      onChanged: (code, value) => setState(() => _values[key]![code] = value),
    );
  }
}
