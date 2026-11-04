import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// One inherited value above the anchor, mutated while a modal is open: the
/// modal follows it live, which is what [ModalAnchor] is for.
class _DemoCount extends InheritedWidget {
  final int n;
  const _DemoCount(this.n, {required super.child});

  static int of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_DemoCount>()!.n;

  @override
  bool updateShouldNotify(_DemoCount old) => n != old.n;
}

/// [ModalAnchor], the modal layer built on an `OverlayPortal`. Unlike
/// [showModal] and [showSideSheet], which push a route, the content is an
/// element child of the anchor, so call-site InheritedWidgets (here
/// [_DemoCount]) stay visible and live inside the open modal.
class ModalAnchorDemo extends StatefulWidget {
  @Preview(name: 'Modal anchor', wrapper: adminUiPreview)
  const ModalAnchorDemo({super.key});

  @override
  State<ModalAnchorDemo> createState() => _ModalAnchorDemoState();
}

class _ModalAnchorDemoState extends State<ModalAnchorDemo> {
  final _modals = ModalAnchorController();
  int _count = 0;
  String? _last;

  Future<void> _openDialog() async {
    final result = await _modals.show<String>(
      builder: (context) => Modal(
        title: 'Portal dialog',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inherited count: ${_DemoCount.of(context)} — bump it while '
              'this dialog is open; a route-pushed dialog would never see '
              'the change.',
              style: context.type.body.copyWith(
                color: context.colors.foregroundSecondary,
              ),
            ),
            const Gap(AdminSpacing.lg),
            Button(
              'Increment outside state',
              icon: Icons.add_rounded,
              onPressed: () => setState(() => _count++),
            ),
          ],
        ),
        actions: [
          Button.ghost('Cancel', onPressed: () => _modals.close()),
          Button.primary('Done', onPressed: () => _modals.close('done')),
        ],
      ),
    );
    setState(() => _last = result ?? '(dismissed)');
  }

  Future<void> _openSheet() async {
    final result = await _modals.showSheet<String>(
      width: 380,
      builder: (context) => SideSheet(
        title: 'Portal side sheet',
        onDismiss: () => _modals.close(),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button.primary('Save', onPressed: () => _modals.close('saved')),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          children: [
            Text(
              'Same SideSheet surface, no route underneath: Escape and the '
              'scrim resolve the future with null, and the inherited count '
              '(${_DemoCount.of(context)}) updates live.',
              style: context.type.body.copyWith(
                color: context.colors.foregroundSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    setState(() => _last = result ?? '(dismissed)');
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCount(
      _count,
      child: ModalAnchor(
        controller: _modals,
        child: DemoPage(
          maxWidth: 520,
          children: [
            const DemoSection(
              'Live inheritance — modal follows call-site state',
            ),
            DemoRow(
              'Count is $_count. Open, then increment from inside the dialog: '
              'the text re-renders because the modal inherits from the anchor.',
              Button(
                'Open dialog',
                icon: Icons.open_in_new_rounded,
                onPressed: _openDialog,
              ),
            ),
            const DemoSection('Side-sheet geometry'),
            DemoRow(
              'showSheet reproduces the 240ms sheet entrance without a '
              'dialog route.',
              Button(
                'Open sheet',
                icon: Icons.view_sidebar_outlined,
                onPressed: _openSheet,
              ),
            ),
            if (_last != null)
              DemoRow('Last result', Text(_last!, style: context.type.body)),
          ],
        ),
      ),
    );
  }
}
