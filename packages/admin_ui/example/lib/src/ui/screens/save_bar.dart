import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

class SaveBarDemo extends StatelessWidget {
  @Preview(name: 'Save bar', wrapper: adminUiPreview)
  const SaveBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: ListView(
        children: [
          const _Label('Interactive — drive the flow'),
          const _Interactive(),
          const Gap(AdminSpacing.xxxl),

          const _Label('States'),
          const _StateRow(
            'Clean — no indicator, Discard and Save disabled',
            SaveState.clean,
          ),
          const _StateRow('Unsaved — Save + Discard live', SaveState.unsaved),
          const _StateRow(
            'Saving — Save spins at its width, bar locked',
            SaveState.saving,
          ),
          const _StateRow('Saved', SaveState.saved, savedLabel: '2m ago'),
          const _StateRow('Error', SaveState.error),
          const _StateRow(
            'Error — with the server’s message',
            SaveState.error,
            errorLabel: 'The slug is already taken',
          ),
          const _StateRow(
            'Invalid — unsaved edits with 2 fields in error',
            SaveState.unsaved,
            invalidCount: 2,
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label(
            'Split Publish — resting, publishing, invalid; clean with '
            'Unpublish still live',
          ),
          for (final (state, publishing, invalid) in const [
            (SaveState.unsaved, false, 0),
            (SaveState.unsaved, true, 0),
            (SaveState.unsaved, false, 1),
            (SaveState.clean, false, 0),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.md),
              child: SaveBar(
                state: state,
                committing: publishing,
                commitEnabled: state != SaveState.clean,
                commitDisabledHint: 'No changes to publish',
                invalidCount: invalid,
                onShowInvalid: _noop,
                leading: Text('Edit page', style: context.type.heading),
                overflowActions: const [
                  SaveBarAction(label: 'Duplicate', onPressed: _noop),
                ],
                onDiscard: _noop,
                onCommit: _noop,
                commitMenu: [
                  if (state == SaveState.clean)
                    const SaveBarAction(
                      label: 'Unpublish',
                      icon: Icons.visibility_off_outlined,
                      onPressed: _noop,
                    )
                  else
                    const SaveBarAction(
                      label: 'Schedule…',
                      icon: Icons.schedule,
                      onPressed: _noop,
                    ),
                ],
              ),
            ),
          const Gap(AdminSpacing.xxxl),

          const _Label('With leading + doc-status tag'),
          SaveBar(
            state: SaveState.unsaved,
            leading: Text('About us', style: context.type.heading),
            status: const Tag('Draft', severity: Severity.warning),
            onDiscard: () {},
            onSave: () {},
            onCommit: () {},
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label('Publish only'),
          SaveBar(
            state: SaveState.clean,
            status: const Tag('Published', severity: Severity.success),
            onCommit: () {},
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label('Secondary actions inside the bar'),
          SaveBar(
            state: SaveState.unsaved,
            leading: Text('Edit event', style: context.type.heading),
            actions: [
              IconAction(
                Icons.comment_outlined,
                label: 'Comments',
                onPressed: () {},
              ),
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            onCommit: () {},
            commitLabel: MaterialLocalizations.of(context).saveButtonLabel,
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label('Clean — primary shown but disabled (not hidden)'),
          SaveBar(
            state: SaveState.clean,
            leading: Text('Edit event', style: context.type.heading),
            actions: [
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            onCommit: () {},
            commitEnabled: false,
            commitLabel: MaterialLocalizations.of(context).saveButtonLabel,
            commitDisabledHint: 'No changes to save',
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label(
            'Overflow ⋯ menu + split Publish (Schedule / Unpublish)',
          ),
          SaveBar(
            state: SaveState.unsaved,
            leading: Text('Edit page', style: context.type.heading),
            status: const Tag('Changed', severity: Severity.warning),
            actions: [
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            overflowActions: [
              const SaveBarAction(label: 'Open page', icon: Icons.open_in_new),
              SaveBarAction(
                label: 'Duplicate',
                icon: Icons.copy_outlined,
                onPressed: () {},
              ),
              SaveBarAction(
                label: 'Delete page',
                icon: Icons.delete_outline,
                danger: true,
                onPressed: () {},
              ),
            ],
            onCommit: () {},
            commitMenu: [
              SaveBarAction(
                label: 'Schedule…',
                icon: Icons.schedule,
                onPressed: () {},
              ),
              SaveBarAction(
                label: 'Unpublish',
                icon: Icons.visibility_off_outlined,
                onPressed: () {},
              ),
            ],
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label(
            'Narrow — 540px: Discard folds into ⋯, the leading side yields',
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SaveBar(
                    state: SaveState.unsaved,
                    leading: Text(
                      'Spring collection launch page',
                      style: context.type.heading,
                    ),
                    status: const Tag('Draft', severity: Severity.warning),
                    onDiscard: _noop,
                    onSave: _noop,
                    onCommit: _noop,
                  ),
                  const Gap(AdminSpacing.lg),
                  SaveBar(
                    state: SaveState.unsaved,
                    leading: Text('Edit page', style: context.type.heading),
                    status: const Tag('Changed', severity: Severity.warning),
                    actions: [
                      IconAction(
                        Icons.history,
                        label: 'Version history',
                        onPressed: () {},
                      ),
                    ],
                    overflowActions: [
                      SaveBarAction(
                        label: 'Duplicate',
                        icon: Icons.copy_outlined,
                        onPressed: () {},
                      ),
                    ],
                    onCommit: () {},
                    commitMenu: [
                      SaveBarAction(
                        label: 'Schedule…',
                        icon: Icons.schedule,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label('Bottom-docked (hairline on top)'),
          const SaveBar(
            placement: SaveBarPlacement.bottom,
            state: SaveState.unsaved,
            onDiscard: _noop,
            onSave: _noop,
            onCommit: _noop,
          ),
          const Gap(AdminSpacing.xxxl),

          const _Label(
            'Phone: 360 px, fully loaded — the icon actions and Publish’s '
            'alternatives fold into ⋯',
          ),
          const _PhoneWidth(child: _LoadedBar()),
          const Gap(AdminSpacing.xxxl),
        ],
      ),
    );
  }

  static void _noop() {}
}

/// Lays [child] out as a phone window of [width] would: that wide, with the
/// window's width in [MediaQuery] so the page gutter is a phone's.
class _PhoneWidth extends StatelessWidget {
  final Widget child;
  static const width = 360.0;

  const _PhoneWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: width,
        child: MediaQuery(
          data: media.copyWith(size: Size(width, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}

/// Every slot of the bar filled: two icon actions, an overflow menu,
/// Discard, Save and a split Publish.
class _LoadedBar extends StatelessWidget {
  const _LoadedBar();

  @override
  Widget build(BuildContext context) {
    return SaveBar(
      state: SaveState.unsaved,
      leading: Text('Edit page', style: context.type.heading),
      status: const Tag('Changed', severity: Severity.warning),
      actions: [
        IconAction(Icons.comment_outlined, label: 'Comments', onPressed: () {}),
        IconAction(Icons.history, label: 'Version history', onPressed: () {}),
      ],
      overflowActions: [
        SaveBarAction(
          label: 'Duplicate',
          icon: Icons.copy_outlined,
          onPressed: () {},
        ),
        SaveBarAction(
          label: 'Delete page',
          icon: Icons.delete_outline,
          danger: true,
          onPressed: () {},
        ),
      ],
      onDiscard: () {},
      onSave: () {},
      onCommit: () {},
      commitMenu: [
        SaveBarAction(
          label: 'Schedule…',
          icon: Icons.schedule,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _StateRow extends StatelessWidget {
  final String caption;
  final SaveState state;
  final String? savedLabel;
  final String? errorLabel;
  final int invalidCount;

  const _StateRow(
    this.caption,
    this.state, {
    this.savedLabel,
    this.errorLabel,
    this.invalidCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.lg,
            AdminSpacing.sm,
            AdminSpacing.lg,
            AdminSpacing.xs,
          ),
          child: Text(caption, style: context.type.caption),
        ),
        SaveBar(
          state: state,
          savedLabel: savedLabel,
          errorLabel: errorLabel,
          invalidCount: invalidCount,
          onShowInvalid: () {},
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
        ),
      ],
    );
  }
}

class _Interactive extends StatefulWidget {
  const _Interactive();

  @override
  State<_Interactive> createState() => _InteractiveState();
}

class _InteractiveState extends State<_Interactive> {
  SaveState _state = SaveState.unsaved;
  bool _publishing = false;
  String? _savedLabel;

  void _save() {
    setState(() => _state = SaveState.saving);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _state = SaveState.saved;
          _savedLabel = 'just now';
        });
      }
    });
  }

  void _publish() {
    setState(() => _publishing = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _publishing = false;
          _state = SaveState.saved;
          _savedLabel = 'just now';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SaveBar(
          state: _state,
          savedLabel: _savedLabel,
          committing: _publishing,
          leading: Text('Edit page', style: context.type.heading),
          status: Tag(
            _state == SaveState.saved ? 'Published' : 'Draft',
            severity: _state == SaveState.saved
                ? Severity.success
                : Severity.warning,
          ),
          onDiscard: () => setState(() {
            _state = SaveState.clean;
            _savedLabel = null;
          }),
          onSave: _save,
          onCommit: _publish,
        ),
        Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Button.ghost(
              'Mark dirty',
              icon: Icons.edit_outlined,
              onPressed: () => setState(() {
                _state = SaveState.unsaved;
                _savedLabel = null;
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.xl,
        AdminSpacing.lg,
        AdminSpacing.md,
      ),
      child: Text(text, style: context.type.sectionLabel),
    );
  }
}
