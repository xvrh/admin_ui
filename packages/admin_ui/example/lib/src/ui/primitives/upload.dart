import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

UploadItem _u(
  String name, {
  UploadStatus status = UploadStatus.done,
  double p = 0,
  int? bytes = 740 * 1024,
  String? errorText,
}) => UploadItem(
  id: name,
  name: name,
  bytes: bytes,
  status: status,
  progress: p,
  errorText: errorText,
);

/// Every drop-target and row state. The hovered and focused targets are
/// pinned through their states controller, with the keyboard highlight forced
/// on while this page is up so the focus ring shows in a static render.
class UploadZoneDemo extends StatefulWidget {
  @Preview(name: 'Upload zone', wrapper: adminUiPreview)
  const UploadZoneDemo({super.key});

  @override
  State<UploadZoneDemo> createState() => _UploadZoneDemoState();
}

class _UploadZoneDemoState extends State<UploadZoneDemo> {
  final _hovered = WidgetStatesController({WidgetState.hovered});
  final _focused = WidgetStatesController({WidgetState.focused});

  @override
  void dispose() {
    _hovered.dispose();
    _focused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 560,
        children: [
          const DemoSection('Idle — empty drop target'),
          const UploadZone(accept: 'PNG, JPG, PDF · up to 25 MB'),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Drag hovering (target lit)'),
          const UploadZone(dragOver: true, accept: 'PNG, JPG, PDF'),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Single file'),
          const UploadZone(multiple: false, accept: 'A single PDF'),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Hovered'),
          UploadZone(
            accept: 'PNG, JPG, PDF',
            onBrowse: () {},
            statesController: _hovered,
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Keyboard focus'),
          UploadZone(
            accept: 'PNG, JPG, PDF',
            onBrowse: () {},
            statesController: _focused,
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection(
            'Every row state — done, uploading, queued, failed',
          ),
          UploadZone(
            accept: 'PNG, JPG, PDF',
            onCancel: (_) {},
            onRetry: (_) {},
            onRemove: (_) {},
            onClearCompleted: () {},
            items: [
              _u('hero_banner.jpg'),
              _u('product_shot.png', status: UploadStatus.uploading, p: 0.62),
              _u('spec_sheet.pdf', status: UploadStatus.uploading, p: 0.18),
              _u('archive.zip', status: UploadStatus.queued),
              _u(
                'huge_render.psd',
                status: UploadStatus.error,
                errorText: 'File exceeds 25 MB',
              ),
            ],
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('All done'),
          UploadZone(
            onRemove: (_) {},
            onClearCompleted: () {},
            items: [_u('a.jpg'), _u('b.png'), _u('notes.pdf')],
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Live — simulate an upload'),
          const _LiveUpload(),
        ],
      ),
    );
  }
}

class _LiveUpload extends StatefulWidget {
  const _LiveUpload();

  @override
  State<_LiveUpload> createState() => _LiveUploadState();
}

class _LiveUploadState extends State<_LiveUpload> {
  final _items = <UploadItem>[];
  Timer? _timer;
  int _seq = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add() {
    var id = 'file_${_seq++}.jpg';
    setState(() {
      _items.add(UploadItem(id: id, name: id, status: UploadStatus.uploading));
    });
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          var it = _items[i];
          if (it.status != UploadStatus.uploading) continue;
          var p = it.progress + 0.08;
          _items[i] = p >= 1
              ? UploadItem(
                  id: it.id,
                  name: it.name,
                  bytes: it.bytes,
                  status: UploadStatus.done,
                )
              : UploadItem(
                  id: it.id,
                  name: it.name,
                  bytes: it.bytes,
                  status: UploadStatus.uploading,
                  progress: p,
                );
        }
      });
      if (_items.every((i) => i.status != UploadStatus.uploading)) {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button('Add a file', icon: Icons.add, onPressed: _add),
        ),
        const Gap(AdminSpacing.lg),
        UploadZone(
          accept: 'PNG, JPG · up to 25 MB',
          items: _items,
          onBrowse: _add,
          onCancel: (id) =>
              setState(() => _items.removeWhere((i) => i.id == id)),
          onRemove: (id) =>
              setState(() => _items.removeWhere((i) => i.id == id)),
          onClearCompleted: () => setState(
            () => _items.removeWhere(
              (i) =>
                  i.status == UploadStatus.done ||
                  i.status == UploadStatus.error,
            ),
          ),
        ),
      ],
    );
  }
}
