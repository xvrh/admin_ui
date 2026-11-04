import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

List<SelectOption> _channels(BuildContext context) => [
  SelectOption(value: 'web', label: 'Web', swatch: context.colors.primary),
  SelectOption(value: 'ios', label: 'iOS', swatch: context.colors.success),
  SelectOption(
    value: 'android',
    label: 'Android',
    swatch: context.colors.warning,
  ),
  SelectOption(value: 'email', label: 'Email', swatch: context.colors.info),
];

const _features = [
  SelectOption(
    value: 'comments',
    label: 'Comments',
    icon: Icons.forum_outlined,
    description: 'Readers can discuss under the article',
  ),
  SelectOption(
    value: 'related',
    label: 'Related links',
    icon: Icons.link_rounded,
    description: 'Show a rail of related entries',
  ),
  SelectOption(
    value: 'newsletter',
    label: 'Newsletter CTA',
    icon: Icons.mark_email_unread_outlined,
    description: 'Inline sign-up block mid-body',
  ),
  SelectOption(
    value: 'paywall',
    label: 'Paywall',
    icon: Icons.lock_outline_rounded,
    description: 'Gate the body for non-subscribers',
  ),
];

final List<SelectOption> _topics = _makeTopics();

List<SelectOption> _makeTopics() {
  const seeds = [
    'Climate',
    'Markets',
    'Elections',
    'AI',
    'Health',
    'Space',
    'Culture',
    'Sport',
    'Education',
    'Energy',
    'Privacy',
    'Housing',
    'Transport',
    'Migration',
    'Cyber',
    'Trade',
    'Labour',
    'Justice',
    'Media',
    'Food',
  ];
  return [
    for (var i = 0; i < 60; i++)
      SelectOption(
        value: 'topic_$i',
        label: i < seeds.length
            ? seeds[i]
            : '${seeds[i % seeds.length]} ${i ~/ seeds.length + 1}',
      ),
  ];
}

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '12m',
    body: "Let's not ship to Android until the layout bug is fixed.",
  ),
];

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: 'Published',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '1d ago',
  ),
];

/// The multi-choice field across appearances and states.
class MultiSelectFieldDemo extends StatelessWidget {
  @Preview(name: 'Multi-select / tags', wrapper: adminUiPreview)
  const MultiSelectFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Tokens — scales to long lists'),
        DemoVariant(
          'Live — tap to add, ✕ on a token to remove',
          _Live(
            label: 'Channels',
            options: _channels(context),
            initial: const {'web', 'ios'},
          ),
        ),
        DemoVariant(
          'Empty — placeholder',
          _Live(
            label: 'Topics',
            options: _topics,
            initial: const {},
            hint: 'Add topics',
          ),
        ),
        DemoVariant(
          '60 options — filter auto-shows, ✓ marks selected',
          _Live(
            label: 'Topics',
            options: _topics,
            initial: {_topics[0].value, _topics[3].value, _topics[7].value},
          ),
        ),
        DemoVariant(
          'Open — the first checked option highlighted',
          PinnedOpen(
            reserve: 372,
            child: _Live(
              label: 'Topics',
              options: _topics,
              initial: {_topics[3].value, _topics[7].value},
            ),
          ),
        ),
        DemoSection('Checklist — room for a description each'),
        DemoVariant(
          'Live — tap a row',
          const _Live(
            label: 'Page features',
            options: _features,
            initial: {'comments', 'related'},
            appearance: MultiSelectAppearance.checklist,
          ),
        ),
        DemoVariant(
          'Read-only (no onChanged) · disabled',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldShell(
                label: 'Page features',
                child: MultiSelectBody(
                  options: _features,
                  value: {'comments'},
                  appearance: MultiSelectAppearance.checklist,
                ),
              ),
              const Gap(AdminSpacing.lg),
              FieldShell(
                label: 'Page features',
                enabled: false,
                child: MultiSelectBody(
                  options: _features,
                  value: const {'comments'},
                  appearance: MultiSelectAppearance.checklist,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        DemoSection('Segmented — a few prominent choices'),
        DemoVariant(
          'Live — toggle pills',
          _Live(
            label: 'Channels',
            options: _channels(context),
            initial: const {'web'},
            appearance: MultiSelectAppearance.segmented,
          ),
        ),
        DemoSection('Tags — creatable, free-form values'),
        DemoVariant(
          'Type a value and press enter to add it',
          _Live(
            label: 'Keywords',
            options: _channels(context),
            initial: const {'web', 'launch-2026'},
            creatable: true,
            hint: 'Add keywords',
          ),
        ),
        DemoSection('Constraints & states'),
        DemoVariant(
          'Capped at 2 — extras go inert at the cap',
          _Live(
            label: 'Channels (max 2)',
            options: _channels(context),
            initial: const {'web', 'ios'},
            maxItems: 2,
          ),
        ),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, no chevron or ✕',
          FieldShell(
            label: 'Channels',
            child: MultiSelectBody(
              options: _channels(context),
              value: const {'web', 'email'},
            ),
          ),
        ),
        DemoVariant(
          'Disabled (enabled: false on the shell)',
          FieldShell(
            label: 'Channels',
            enabled: false,
            child: MultiSelectBody(
              options: _channels(context),
              value: const {'web', 'email'},
              onChanged: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          FieldShell(
            label: 'Channels',
            modified: true,
            child: MultiSelectBody(
              options: _channels(context),
              value: const {'web', 'ios', 'android'},
            ),
          ),
        ),
        DemoVariant(
          'Validation — at least one required',
          _Live(
            label: 'Channels',
            options: _channels(context),
            initial: const {},
            hint: 'Pick channels',
            error: 'Choose at least one channel before publishing.',
          ),
        ),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Channels drive the draft and "Modified" tint',
          const _FullyLoaded(),
        ),
      ],
    );
  }
}

/// Live variant: owns the selection set and drives UI updates.
class _Live extends StatefulWidget {
  final String label;
  final List<SelectOption> options;
  final Set<String> initial;
  final MultiSelectAppearance appearance;
  final int? maxItems;
  final bool creatable;
  final String? hint;
  final String? error;

  const _Live({
    required this.label,
    required this.options,
    required this.initial,
    this.appearance = MultiSelectAppearance.tokens,
    this.maxItems,
    this.creatable = false,
    this.hint,
    this.error,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late Set<String> _value = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      errorText: widget.error,
      child: MultiSelectBody(
        options: widget.options,
        value: _value,
        appearance: widget.appearance,
        maxItems: widget.maxItems,
        creatable: widget.creatable,
        hint: widget.hint,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// Fully wired: every capability slot. Editing the channels updates the draft,
/// flipping the history chip to "Modified" and tinting the field.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const _published = {'web', 'ios'};
  Set<String> _value = {'web', 'ios'};
  final List<CommentEntry> _messages = [..._comments];

  String _summary(Set<String> v) {
    if (v.isEmpty) return 'none';
    return [
      for (var o in _channels(context))
        if (v.contains(o.value)) o.label,
    ].join(', ');
  }

  bool _eq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Widget build(BuildContext context) {
    var modified = !_eq(_value, _published);
    return FieldShell(
      label: 'Channels',
      modified: modified,
      help: const HelpButton(
        text:
            'Which surfaces this entry ships to. Leave a channel off to hold '
            'it back there.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: _summary(_value),
        baseline: _summary(_published),
        versions: _versions,
        onRevert: () => setState(() => _value = {..._published}),
      ),
      child: MultiSelectBody(
        options: _channels(context),
        value: _value,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}
