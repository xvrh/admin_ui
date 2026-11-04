import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class ModalDemo extends StatefulWidget {
  @Preview(name: 'Modal', wrapper: adminUiPreview)
  const ModalDemo({super.key});

  @override
  State<ModalDemo> createState() => _ModalDemoState();
}

class _ModalDemoState extends State<ModalDemo> {
  String _last = '—';

  Future<void> _confirmDelete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete page?',
      message:
          'This permanently removes “Pricing” and its 3 translations. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    setState(() => _last = ok ? 'Deleted' : 'Cancelled');
  }

  Future<void> _confirmPublish() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Publish changes?',
      message: 'The draft will become the live version immediately.',
      confirmLabel: 'Publish',
    );
    setState(() => _last = ok ? 'Published' : 'Cancelled');
  }

  Future<void> _confirmAsync({required bool fail}) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete page?',
      message: 'The action runs inside the dialog — watch the button spin.',
      confirmLabel: 'Delete',
      danger: true,
      onConfirm: () async {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (fail) throw const _Conflict();
      },
      errorText: (e) => e is _Conflict
          ? 'Someone else changed this page. Reload it and try again.'
          : 'Couldn’t delete the page. Try again.',
    );
    setState(() => _last = ok ? 'Deleted' : 'Cancelled');
  }

  Future<void> _customForm() async {
    final saved = await showModal<bool>(
      context,
      builder: (ctx) => Modal(
        title: 'Rename collection',
        onDismiss: () => Navigator.of(ctx).maybePop(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(hintText: 'Collection name')),
          ],
        ),
        actions: [
          Button.ghost('Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          Button.primary('Save', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    setState(() => _last = saved == true ? 'Saved name' : 'Cancelled');
  }

  Future<void> _longModal() async {
    await showModal<void>(
      context,
      builder: (ctx) => Modal(
        title: 'Terms of use',
        onDismiss: () => Navigator.of(ctx).maybePop(),
        message: _terms,
        actions: [
          Button.ghost('Decline', onPressed: () => Navigator.of(ctx).pop()),
          Button.primary('Accept', onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  Future<void> _fullscreen() async {
    await showModal<void>(
      context,
      builder: (ctx) => _EditPageModal(
        onDismiss: () => Navigator.of(ctx).maybePop(),
        onSave: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 600,
      children: [
        const DemoSection('Confirm'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.danger('Delete page…', onPressed: _confirmDelete),
            Button.primary('Publish…', onPressed: _confirmPublish),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Confirm · async (runs in-dialog)'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.danger(
              'Delete (succeeds)…',
              onPressed: () => _confirmAsync(fail: false),
            ),
            Button.danger(
              'Delete (fails)…',
              onPressed: () => _confirmAsync(fail: true),
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Form and long content'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button(
              'Rename…',
              icon: Icons.edit_outlined,
              onPressed: _customForm,
            ),
            Button(
              'Terms…',
              icon: Icons.article_outlined,
              onPressed: _longModal,
            ),
            Button(
              'Fullscreen…',
              icon: Icons.open_in_full_rounded,
              onPressed: _fullscreen,
            ),
          ],
        ),
        const Gap(AdminSpacing.lg),
        Text('Result: $_last', style: context.type.bodyMuted),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Danger confirm (inline)'),
        Center(
          child: Modal(
            title: 'Delete page?',
            alert: true,
            message: _deleteMessage,
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.danger('Delete', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        // The async confirm's two states, as `confirm` lays them out.
        const DemoSection('Danger confirm · running — Cancel waits'),
        Center(
          child: Modal(
            title: 'Delete page?',
            alert: true,
            message: _deleteMessage,
            actions: [
              const Button.ghost('Cancel'),
              Button.danger('Delete', loading: true, onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection(
          'Danger confirm · failed — the error above the actions',
        ),
        Center(
          child: Modal(
            title: 'Delete page?',
            alert: true,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _deleteMessage,
                  style: context.type.body.copyWith(
                    color: context.colors.foregroundSecondary,
                    height: 1.4,
                  ),
                ),
                const Gap(AdminSpacing.lg),
                const Alert(
                  'Someone else changed this page. Reload it and try again.',
                  severity: Severity.danger,
                ),
              ],
            ),
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.danger('Delete', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection(
          'Long content — the body scrolls between a pinned title and footer',
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Modal(
              title: 'Terms of use',
              onDismiss: () {},
              message: _terms,
              actions: [
                Button.ghost('Decline', onPressed: () {}),
                Button.primary('Accept', onPressed: () {}),
              ],
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Narrow — the actions stack, primary on top'),
        Center(
          child: SizedBox(
            width: 312,
            child: Modal(
              title: 'Unsaved changes',
              message: 'Save your edits to “Pricing” before closing?',
              actions: [
                Button.ghost('Keep editing', onPressed: () {}),
                Button.danger('Discard changes', onPressed: () {}),
                Button.primary('Save and close', onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The modal's size presets, its description and its close button, laid out
/// inline.
class ModalSizesDemo extends StatelessWidget {
  @Preview(name: 'Modal sizes', wrapper: adminUiPreview)
  const ModalSizesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 600,
      children: [
        const DemoSection('Description — muted, 8px under the title'),
        Center(
          child: Modal(
            title: 'Invite teammates',
            description: 'They get an email with a link to join this site.',
            body: const TextField(
              decoration: InputDecoration(hintText: 'name@example.com'),
            ),
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.primary('Send invites', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('onDismiss — the close button, and no footer'),
        Center(
          child: Modal(
            title: 'Keyboard shortcuts',
            onDismiss: () {},
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (keys, action) in const [
                  ('⌘ K', 'Search everything'),
                  ('⌘ S', 'Save the draft'),
                  ('⌘ ⇧ P', 'Publish'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AdminSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(action, style: context.type.body)),
                        Text(keys, style: context.type.mono),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Sizes'),
        const _SizeLabel('small · 400'),
        Center(
          child: Modal(
            size: ModalSize.small,
            title: 'Archive 3 pages?',
            message: 'They leave the site but stay in the archive.',
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.primary('Archive', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        const _SizeLabel('medium · 512, the default'),
        Center(
          child: Modal(
            title: 'Move to collection',
            message:
                '“Pricing” and its 3 translations move to Marketing. '
                'Their links keep working.',
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.primary('Move', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        const _SizeLabel('large · 720, scaled down to fit the page'),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Modal(
            size: ModalSize.large,
            title: 'Edit redirect',
            message:
                'Visitors to /pricing-2024 land on /pricing. Search engines '
                'are told the move is permanent.',
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.primary('Save', onPressed: () {}),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        const _SizeLabel(
          'fullscreen — edge to edge, square, no border or shadow '
          '(an 800×500 screen, scaled down)',
        ),
        const _ScreenFrame(
          size: Size(800, 500),
          child: _EditPageModal(onDismiss: _noop, onSave: _noop),
        ),
      ],
    );
  }
}

void _noop() {}

class _SizeLabel extends StatelessWidget {
  final String text;

  const _SizeLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AdminSpacing.md),
    child: Text(text, style: context.type.caption),
  );
}

/// [child] laid out on a screen of [size] and scaled to the page's width,
/// in a hairline frame that stands for the screen's edge.
class _ScreenFrame extends StatelessWidget {
  final Size size;
  final Widget child;

  const _ScreenFrame({required this.size, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(border: Border.all(color: context.colors.border)),
    child: FittedBox(
      child: SizedBox.fromSize(
        size: size,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// A fullscreen editor: its header and footer pinned, the fields between.
class _EditPageModal extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onSave;

  const _EditPageModal({required this.onDismiss, required this.onSave});

  @override
  Widget build(BuildContext context) => Modal(
    size: ModalSize.fullscreen,
    title: 'Edit “Pricing”',
    description: 'Changes stay in the draft until you publish.',
    onDismiss: onDismiss,
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(decoration: InputDecoration(labelText: 'Title')),
        Gap(AdminSpacing.lg),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Summary'),
        ),
      ],
    ),
    actions: [
      Button.ghost('Cancel', onPressed: onDismiss),
      Button.primary('Save draft', onPressed: onSave),
    ],
  );
}

class _Conflict implements Exception {
  const _Conflict();
}

const _deleteMessage =
    'This permanently removes “Pricing” and its 3 translations. '
    'This cannot be undone.';

final _terms = [
  for (var i = 1; i <= 12; i++)
    'Clause $i. Content you publish stays yours; you grant the service the '
        'right to host and display it for as long as it is published.',
].join(' ');
