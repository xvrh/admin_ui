import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';
import '../../translation_kit.dart';

const _locales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'ES', native: 'Español', status: LocaleStatus.translated),
  LocaleInfo(code: 'FR', native: 'Français', status: LocaleStatus.review),
];

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '12m',
    body: 'Should this really be featured on the ES homepage too?',
  ),
];

const _versions = [
  FieldVersion(
    label: 'Set to On',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: 'Published Off',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '3d ago',
  ),
];

/// The on/off field across its states — live, disabled, draft and validation.
class BooleanFieldDemo extends StatelessWidget {
  @Preview(name: 'Boolean / toggle', wrapper: adminUiPreview)
  const BooleanFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Switch'),
        DemoVariant(
          'Live — tap to toggle',
          const _Live(
            label: 'Featured',
            description: 'Pin this story to the top of the homepage',
          ),
        ),
        DemoVariant(
          'Off — plain On/Off label',
          const FieldShell(
            label: 'Comments',
            child: BooleanBody(value: false, onChanged: _ignore),
          ),
        ),
        DemoVariant(
          'On — with description',
          const FieldShell(
            label: 'Visible',
            child: BooleanBody(
              value: true,
              description: 'Shown in the main navigation',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoSection('Checkbox — compact, for minor flags'),
        DemoVariant(
          'Live — tap to toggle',
          const _Live(
            label: 'Pinned',
            appearance: BooleanAppearance.checkbox,
            description: 'Keep at the top of the list',
          ),
        ),
        DemoVariant(
          'Off — plain label',
          const FieldShell(
            label: 'Allow embeds',
            child: BooleanBody(
              value: false,
              appearance: BooleanAppearance.checkbox,
              onChanged: _ignore,
            ),
          ),
        ),
        DemoSection('Segmented — prominent either/or'),
        DemoVariant(
          'Live — Yes / No',
          const _Live(
            label: 'Published',
            appearance: BooleanAppearance.segmented,
            onText: 'Yes',
            offText: 'No',
          ),
        ),
        DemoVariant(
          'With description',
          const FieldShell(
            label: 'Access',
            child: BooleanBody(
              value: false,
              appearance: BooleanAppearance.segmented,
              onText: 'Public',
              offText: 'Private',
              description: 'Who can read this entry once published',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, a Tab stop',
          const FieldShell(
            label: 'Indexed',
            child: BooleanBody(
              value: true,
              description: 'Managed by the publishing workflow',
            ),
          ),
        ),
        DemoVariant(
          'Read-only checkbox and segmented',
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldShell(
                label: 'Archived',
                child: BooleanBody(
                  value: true,
                  appearance: BooleanAppearance.checkbox,
                  description: 'Hidden from every listing',
                ),
              ),
              SizedBox(height: 16),
              FieldShell(
                label: 'Access',
                child: BooleanBody(
                  value: true,
                  appearance: BooleanAppearance.segmented,
                  onText: 'Public',
                  offText: 'Private',
                ),
              ),
            ],
          ),
        ),
        DemoVariant(
          'Disabled',
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldShell(
                label: 'Indexed',
                enabled: false,
                child: BooleanBody(
                  value: true,
                  description: 'Managed by the publishing workflow',
                  onChanged: _ignore,
                ),
              ),
              SizedBox(height: 16),
              FieldShell(
                label: 'Archived',
                enabled: false,
                child: BooleanBody(
                  value: true,
                  appearance: BooleanAppearance.checkbox,
                  description: 'Hidden from every listing',
                  onChanged: _ignore,
                ),
              ),
            ],
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'Terms',
            errorText: 'Accept the terms to publish.',
            child: BooleanBody(
              value: false,
              appearance: BooleanAppearance.checkbox,
              description: 'I have the rights to publish this image',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          const FieldShell(
            label: 'Featured',
            modified: true,
            child: BooleanBody(
              value: true,
              description: 'Pin this story to the top of the homepage',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Long description wraps',
          const FieldShell(
            label: 'Newsletter',
            child: BooleanBody(
              value: true,
              description:
                  'Include this entry in the next scheduled digest '
                  'sent to every subscriber who opted into long-form updates',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoSection('All capabilities — help · language · comments · history'),
        DemoVariant(
          'Toggle drives the draft — flip it back to On to clear "Modified"',
          const _FullyLoaded(),
        ),
        DemoSection('Translated<bool> — the same BooleanBody, one per locale'),
        DemoVariant(
          'Side-by-side lanes; switch the language pill to single',
          const _TranslatedBoolean(),
        ),
        Text(
          'Tab to the switch — the label turns primary while focused.',
          style: TextStyle(fontSize: 12, color: context.colors.foregroundMuted),
        ),
      ],
    );
  }
}

/// One field wired with every capability slot. Toggling the switch updates the
/// draft, so the history chip flips to "Modified" and the field gains the amber
/// tint until reverted — showing how the slots tie back to the body's value.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const _published = true;
  bool _value = false;
  Set<String> _visible = {'EN'};
  final List<CommentEntry> _messages = [..._comments];

  String _asText(bool v) => v ? 'On' : 'Off';

  @override
  Widget build(BuildContext context) {
    var modified = _value != _published;
    return FieldShell(
      label: 'Featured',
      modified: modified,
      help: const HelpButton(
        text:
            'Featured stories appear in the hero slot. Only one per section '
            'can be featured at a time.',
      ),
      language: LanguagePill(
        value: _visible,
        activeLocale: _visible.first,
        locales: _locales,
        sourceLocale: 'EN',
        onChanged: (next) => setState(() => _visible = next),
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: _asText(_value),
        baseline: _asText(_published),
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: BooleanBody(
        value: _value,
        description: 'Pin this story to the top of the homepage',
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// The payoff of the View/body split: a `Translated<bool>` editor built by
/// dropping the very same [BooleanBody] into each lane of a [TranslatableField].
/// No boolean-specific code lives in the translatable composer — it just calls
/// the lane builder.
class _TranslatedBoolean extends StatefulWidget {
  const _TranslatedBoolean();

  @override
  State<_TranslatedBoolean> createState() => _TranslatedBooleanState();
}

class _TranslatedBooleanState extends State<_TranslatedBoolean> {
  final _translation = TranslationController(sourceCode: demoSourceCode);

  // Source value (English). Inheriting lanes live-link to it.
  bool _source = true;

  // Required field — no None state. Absent mode ⇒ Inherit.
  final Map<String, LaneMode> _mode = {'ES': LaneMode.custom};
  final Map<String, bool> _custom = {'ES': false};

  LaneMode _modeOf(String code) => _mode[code] ?? LaneMode.inherit;

  String get _sourceNative =>
      demoLocales.firstWhere((l) => l.code == demoSourceCode).native;

  @override
  void initState() {
    super.initState();
    _translation.setVisible({'EN', 'ES', 'FR'});
    _translation.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _translation.removeListener(_onChanged);
    _translation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Show cookie banner',
      locales: demoLocales,
      visibleLocales: _translation.visible,
      sourceLocale: demoSourceCode,
      activeLocale: _translation.active,
      values: const {},
      onVisibleLocalesChanged: _translation.setVisible,
      onActiveLocaleChanged: _translation.setActive,
      showLaneStatus: false,
      laneTrailing: _laneTrailing,
      laneBuilder: _laneBody,
    );
  }

  Widget _laneBody(LocaleInfo lane) {
    if (lane.code == demoSourceCode) {
      return BooleanBody(
        value: _source,
        description: 'Show the cookie banner',
        onChanged: (v) => setState(() => _source = v),
      );
    }
    return InheritedBody(
      inheriting: _modeOf(lane.code) == LaneMode.inherit,
      preview: BooleanBody(
        value: _source,
        description: 'Show the cookie banner',
      ),
      custom: BooleanBody(
        value: _custom[lane.code] ?? false,
        description: 'Show the cookie banner',
        onChanged: (v) => setState(() => _custom[lane.code] = v),
      ),
    );
  }

  Widget? _laneTrailing(LocaleInfo lane) {
    if (lane.code == demoSourceCode) return null;
    return InheritModeDropdown(
      mode: _modeOf(lane.code),
      onModeChanged: (m) => setState(() => _mode[lane.code] = m),
      sourceLabel: _sourceNative,
      noun: 'setting',
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final String? description;
  final BooleanAppearance appearance;
  final String? onText;
  final String? offText;

  const _Live({
    required this.label,
    this.description,
    this.appearance = BooleanAppearance.toggle,
    this.onText,
    this.offText,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      child: BooleanBody(
        value: _value,
        appearance: widget.appearance,
        description: widget.description,
        onText: widget.onText,
        offText: widget.offText,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

void _ignore(bool _) {}
