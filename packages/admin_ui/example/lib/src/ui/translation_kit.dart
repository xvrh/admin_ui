import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Shared demo scaffolding for translatable fields: a fake locale set, a
/// document-level [TranslationController], and a [TranslatableFieldView] host
/// that wires a field's draft/published values and comments into the real
/// [TranslatableField] widget. Used by the Translation demo and the edit page.

const demoLocales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'ES', native: 'Español', status: LocaleStatus.translated),
  LocaleInfo(code: 'FR', native: 'Français', status: LocaleStatus.review),
  LocaleInfo(code: 'DE', native: 'Deutsch', status: LocaleStatus.outdated),
  LocaleInfo(code: 'JA', native: '日本語', status: LocaleStatus.missing),
];

final demoSourceCode = demoLocales
    .firstWhere((l) => l.status == LocaleStatus.source)
    .code;

const demoVersions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'live',
    current: true,
  ),
  FieldVersion(
    label: 'Published v3',
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: 'Yesterday',
  ),
  FieldVersion(
    label: 'Created from outline',
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: '3 days ago',
  ),
];

/// Shared, document-level translation state. (Stand-in for the real
/// LocaleService.) [visible] is the set of locales in view — one means single,
/// several means side by side. [active] is the focused locale within that set.
class TranslationController extends ChangeNotifier {
  final String sourceCode;
  Set<String> visible;
  String active;

  TranslationController({required this.sourceCode, String initial = 'ES'})
    : active = initial,
      visible = {initial};

  void setVisible(Set<String> next) {
    if (next.isEmpty) return;
    visible = next;
    if (!visible.contains(active)) {
      active = visible.contains(sourceCode) ? sourceCode : visible.first;
    }
    notifyListeners();
  }

  void setActive(String code) {
    if (code == active || !visible.contains(code)) return;
    active = code;
    notifyListeners();
  }
}

/// Per-field host (Screen-ish): owns this field's draft + published values and
/// comments, reads the shared [translation] controller for single vs
/// side-by-side, and scopes every capability to the right locale.
class TranslatableFieldView extends StatefulWidget {
  final TranslationController translation;
  final String label;
  final String? help;
  final Map<String, String> values;
  final Map<String, String>? published;
  final Map<String, List<CommentEntry>>? commentsByLocale;
  final List<CommentEntry>? fieldComments;

  const TranslatableFieldView({
    super.key,
    required this.translation,
    required this.label,
    required this.values,
    this.help,
    this.published,
    this.commentsByLocale,
    this.fieldComments,
  });

  @override
  State<TranslatableFieldView> createState() => _TranslatableFieldViewState();
}

class _TranslatableFieldViewState extends State<TranslatableFieldView> {
  late final Map<String, String> _values = {...widget.values};
  late final Map<String, String> _published = {...?widget.published};
  late final Map<String, List<CommentEntry>> _localeComments = {
    for (var e in (widget.commentsByLocale ?? const {}).entries)
      e.key: [...e.value],
  };
  late final List<CommentEntry> _fieldComments = [...?widget.fieldComments];

  bool get _hasLocaleComments => widget.commentsByLocale != null;
  bool get _hasFieldComments => widget.fieldComments != null;
  bool get _hasHistory => widget.published != null;

  bool _modified(String code) =>
      _published.containsKey(code) && (_values[code] ?? '') != _published[code];

  @override
  void initState() {
    super.initState();
    widget.translation.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() => setState(() {});

  @override
  void dispose() {
    widget.translation.removeListener(_onTranslationChanged);
    super.dispose();
  }

  CommentEntry _you(String body) => CommentEntry(
    author: 'You',
    initials: 'Yo',
    color: const Color(0xFF5b5bd6),
    time: 'now',
    body: body,
  );

  Widget _localeCommentsButton(String code) {
    var messages = _localeComments[code] ?? const <CommentEntry>[];
    return CommentsButton(
      count: messages.length,
      messages: messages,
      onReply: (text) =>
          setState(() => (_localeComments[code] ??= []).add(_you(text))),
      onResolve: () => setState(() => _localeComments[code]?.clear()),
    );
  }

  Widget _fieldCommentsButton() {
    return CommentsButton(
      count: _fieldComments.length,
      messages: _fieldComments,
      onReply: (text) => setState(() => _fieldComments.add(_you(text))),
      onResolve: () => setState(_fieldComments.clear),
    );
  }

  Widget _historyButton(String code) {
    return HistoryButton(
      draft: _values[code] ?? '',
      baseline: _published[code],
      versions: demoVersions,
      onRevert: () => _revert(code),
    );
  }

  void _revert(String code) {
    setState(() => _values[code] = _published[code] ?? '');
  }

  HelpButton? _helpButton() =>
      widget.help != null ? HelpButton(text: widget.help!) : null;

  Widget? _headerTrailing() =>
      _cluster([?_helpButton(), if (_hasFieldComments) _fieldCommentsButton()]);

  Widget? _laneCapabilities(LocaleInfo lane) => _cluster([
    if (_hasLocaleComments) _localeCommentsButton(lane.code),
    if (_hasHistory) _historyButton(lane.code),
  ]);

  Widget? _cluster(List<Widget> items) {
    if (items.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          items[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var translation = widget.translation;
    return TranslatableField(
      label: widget.label,
      locales: demoLocales,
      visibleLocales: translation.visible,
      sourceLocale: demoSourceCode,
      activeLocale: translation.active,
      values: _values,
      modifiedLanes: {
        for (var l in demoLocales)
          if (_modified(l.code)) l.code,
      },
      onVisibleLocalesChanged: translation.setVisible,
      onActiveLocaleChanged: translation.setActive,
      onChanged: (code, value) => _values[code] = value,
      headerTrailing: _headerTrailing(),
      laneTrailing: (_hasLocaleComments || _hasHistory)
          ? _laneCapabilities
          : null,
    );
  }
}
