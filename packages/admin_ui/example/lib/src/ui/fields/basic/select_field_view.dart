import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

List<SelectOption> _status(BuildContext context) => [
  SelectOption(
    value: 'draft',
    label: 'Draft',
    swatch: context.colors.foregroundSubtle,
    description: 'Only visible to editors',
  ),
  SelectOption(
    value: 'review',
    label: 'In review',
    swatch: context.colors.warning,
    description: 'Awaiting an editor sign-off',
  ),
  SelectOption(
    value: 'published',
    label: 'Published',
    swatch: context.colors.success,
    description: 'Live on the site',
  ),
  SelectOption(
    value: 'archived',
    label: 'Archived',
    swatch: context.colors.foregroundFaint,
    description: 'Hidden, kept for the record',
  ),
];

const _priority = [
  SelectOption(value: 'low', label: 'Low'),
  SelectOption(value: 'normal', label: 'Normal'),
  SelectOption(value: 'high', label: 'High'),
];

const _layout = [
  SelectOption(
    value: 'standard',
    label: 'Standard',
    icon: Icons.article_outlined,
    description: 'Title, body and a single hero image',
  ),
  SelectOption(
    value: 'gallery',
    label: 'Gallery',
    icon: Icons.grid_view_rounded,
    description: 'A grid of images with short captions',
  ),
  SelectOption(
    value: 'longform',
    label: 'Long-form',
    icon: Icons.menu_book_rounded,
    description: 'Wide measure tuned for extended reading',
  ),
];

// A deliberately large list to stress the dropdown's filtering and scrolling.
final List<SelectOption> _categories = _makeCategories();

List<SelectOption> _makeCategories() {
  const seeds = [
    'News',
    'Opinion',
    'Culture',
    'Sport',
    'Science & tech',
    'Business',
    'Travel',
    'Food & drink',
    'Politics',
    'Health',
    'Environment',
    'Education',
    'Technology',
    'Markets',
    'Arts',
    'Music',
    'Film',
    'Books',
    'Gaming',
    'Fashion',
  ];
  return [
    for (var i = 0; i < 500; i++)
      SelectOption(
        value: 'cat_$i',
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
    time: '8m',
    body: 'Should this stay in review until legal clears it?',
  ),
];

const _versions = [
  FieldVersion(
    label: 'In review',
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
    time: '2d ago',
  ),
];

/// The single-choice field across appearances and states.
class SelectFieldDemo extends StatelessWidget {
  @Preview(name: 'Select / enum', wrapper: adminUiPreview)
  const SelectFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Dropdown — scales to long lists'),
        DemoVariant(
          'Live — swatch + description rows',
          _Live(label: 'Status', options: _status(context), initial: 'review'),
        ),
        DemoVariant(
          'Empty — placeholder (500 options, filter auto-shows)',
          _Live(
            label: 'Category',
            options: _categories,
            hint: 'Pick a category',
          ),
        ),
        DemoVariant(
          '500 options — type to filter, scrolls, shows N of 500',
          _Live(
            label: 'Category',
            options: _categories,
            initial: _categories[2].value,
          ),
        ),
        DemoVariant(
          'With leading icons',
          const _Live(label: 'Layout', options: _layout, initial: 'standard'),
        ),
        DemoVariant(
          'Filter forced on a short list (searchable: true)',
          _Live(
            label: 'Status',
            options: _status(context),
            initial: 'review',
            searchable: true,
          ),
        ),
        DemoSection('Segmented — a few prominent choices'),
        DemoVariant(
          'Live — tap a pill',
          const _Live(
            label: 'Priority',
            options: _priority,
            initial: 'normal',
            appearance: SelectAppearance.segmented,
          ),
        ),
        DemoVariant(
          'With swatches',
          _Live(
            label: 'Status',
            options: _status(context),
            initial: 'published',
            appearance: SelectAppearance.segmented,
          ),
        ),
        DemoVariant(
          'Read-only (no onChanged) · disabled',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldShell(
                label: 'Priority',
                child: SelectBody(
                  options: _priority,
                  value: 'high',
                  appearance: SelectAppearance.segmented,
                ),
              ),
              const Gap(AdminSpacing.lg),
              FieldShell(
                label: 'Priority',
                enabled: false,
                child: SelectBody(
                  options: _priority,
                  value: 'high',
                  appearance: SelectAppearance.segmented,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        DemoSection('Radio — room for a description each'),
        DemoVariant(
          'Live — tap a row',
          const _Live(
            label: 'Layout',
            options: _layout,
            initial: 'gallery',
            appearance: SelectAppearance.radio,
          ),
        ),
        DemoVariant(
          'Read-only (no onChanged)',
          const FieldShell(
            label: 'Layout',
            child: SelectBody(
              options: _layout,
              value: 'gallery',
              appearance: SelectAppearance.radio,
            ),
          ),
        ),
        DemoVariant(
          'Disabled',
          FieldShell(
            label: 'Layout',
            enabled: false,
            child: SelectBody(
              options: _layout,
              value: 'gallery',
              appearance: SelectAppearance.radio,
              onChanged: (_) {},
            ),
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, no chevron',
          FieldShell(
            label: 'Status',
            child: SelectBody(options: _status(context), value: 'published'),
          ),
        ),
        DemoVariant(
          'Disabled (enabled: false on the shell)',
          FieldShell(
            label: 'Status',
            enabled: false,
            child: SelectBody(
              options: _status(context),
              value: 'published',
              onChanged: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          FieldShell(
            label: 'Status',
            modified: true,
            child: SelectBody(options: _status(context), value: 'review'),
          ),
        ),
        DemoVariant(
          'Validation error',
          _Live(
            label: 'Category',
            options: _categories,
            hint: 'Pick a category',
            error: 'A category is required before publishing.',
          ),
        ),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Pick a status — it drives the draft and "Modified" tint',
          const _FullyLoaded(),
        ),
      ],
    );
  }
}

/// The dropdown pinned open, on a page of its own so the list covers no
/// other variant: the selected option highlighted and scrolled into view.
class SelectFieldOpenDemo extends StatelessWidget {
  @Preview(name: 'Select / open', wrapper: adminUiPreview)
  const SelectFieldOpenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Open on a value deep in 500 options'),
        PinnedOpen(
          reserve: 380,
          child: _Live(
            label: 'Category',
            options: _categories,
            initial: _categories[42].value,
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final List<SelectOption> options;
  final String? initial;
  final SelectAppearance appearance;
  final bool? searchable;
  final String? hint;
  final String? error;

  const _Live({
    required this.label,
    required this.options,
    this.initial,
    this.appearance = SelectAppearance.dropdown,
    this.searchable,
    this.hint,
    this.error,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      errorText: widget.error,
      child: SelectBody(
        options: widget.options,
        value: _value,
        appearance: widget.appearance,
        searchable: widget.searchable,
        hint: widget.hint,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// One field wired with every capability slot. Choosing a status updates the
/// draft, flipping the history chip to "Modified" and tinting the field until
/// reverted.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const _published = 'published';
  String _value = 'review';
  final List<CommentEntry> _messages = [..._comments];

  String _labelOf(String v) =>
      _status(context).firstWhere((o) => o.value == v).label;

  @override
  Widget build(BuildContext context) {
    var modified = _value != _published;
    return FieldShell(
      label: 'Status',
      modified: modified,
      help: const HelpButton(
        text:
            'Status drives where the entry appears. Published entries go '
            'live immediately on save.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: _labelOf(_value),
        baseline: _labelOf(_published),
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: SelectBody(
        options: _status(context),
        value: _value,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}
