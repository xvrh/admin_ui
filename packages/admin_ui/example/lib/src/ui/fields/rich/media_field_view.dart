import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

MediaItem _img(int i, {MediaStatus status = MediaStatus.ready, double p = 0}) =>
    MediaItem(
      id: 'img$i',
      name: 'photo_$i.jpg',
      bytes: 1024 * (320 + i * 140),
      swatch: demoPalette[i % demoPalette.length],
      status: status,
      progress: p,
    );

class MediaFieldDemo extends StatelessWidget {
  @Preview(name: 'Media / upload', wrapper: adminUiPreview)
  const MediaFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        DemoVariant(
          'Empty — multiple images, drop zone',
          const FieldShell(
            label: 'Gallery',
            child: MediaBody(accept: 'PNG, JPG · up to 10 MB'),
          ),
        ),
        DemoVariant(
          'Empty — drag hovering (drop target lit)',
          const FieldShell(
            label: 'Gallery',
            active: true,
            child: MediaBody(dragOver: true, accept: 'PNG, JPG'),
          ),
        ),
        DemoVariant(
          'Empty — single image',
          const FieldShell(label: 'Cover', child: MediaBody(maxItems: 1)),
        ),
        DemoVariant(
          'Images — mixed states (uploading · processing · error · ready)',
          FieldShell(
            label: 'Gallery',
            child: MediaBody(
              items: [
                _img(0),
                _img(1, status: MediaStatus.uploading, p: 0.62),
                _img(2, status: MediaStatus.processing),
                _img(3, status: MediaStatus.error),
                _img(5),
              ],
            ),
          ),
        ),
        DemoVariant(
          'Images — with capabilities + draft override',
          FieldShell(
            label: 'Gallery',
            modified: true,
            help: const HelpButton(
              text: 'Up to 12 images. First one is the cover.',
            ),
            comments: const CommentsButton(
              count: 1,
              messages: [
                CommentEntry(
                  author: 'Lena Fritz',
                  initials: 'LF',
                  color: Color(0xFFd97706),
                  time: '3m',
                  body: 'Swap the 2nd shot for the wide angle?',
                ),
              ],
            ),
            history: const HistoryButton(
              draft: '3 images',
              baseline: '2 images',
            ),
            child: MediaBody(cover: true, items: [_img(0), _img(1), _img(4)]),
          ),
        ),
        DemoVariant(
          'Translated<Gallery> — per-locale assets (rare)',
          FieldShell(
            label: 'Gallery',
            language: LanguagePill(
              value: const {'EN'},
              activeLocale: 'EN',
              sourceLocale: 'EN',
              locales: const [
                LocaleInfo(
                  code: 'EN',
                  native: 'English',
                  status: LocaleStatus.source,
                ),
                LocaleInfo(
                  code: 'FR',
                  native: 'Français',
                  status: LocaleStatus.translated,
                ),
              ],
              onChanged: (_) {},
            ),
            child: MediaBody(items: [_img(2), _img(3)]),
          ),
        ),
        DemoVariant(
          'Files — mixed states',
          const FieldShell(
            label: 'Attachments',
            child: MediaBody(
              kind: MediaKind.file,
              items: [
                MediaItem(id: 'f1', name: 'press-kit.pdf', bytes: 2_400_000),
                MediaItem(
                  id: 'f2',
                  name: 'launch-video.mp4',
                  bytes: 48_000_000,
                  status: MediaStatus.uploading,
                  progress: 0.34,
                ),
                MediaItem(
                  id: 'f3',
                  name: 'pricing.xlsx',
                  bytes: 88_000,
                  status: MediaStatus.error,
                  errorText: 'File too large (max 25 MB)',
                ),
                MediaItem(
                  id: 'f4',
                  name: 'notes.txt',
                  bytes: 1200,
                  status: MediaStatus.processing,
                ),
              ],
            ),
          ),
        ),
        DemoVariant(
          'File — single, read-only',
          const FieldShell(
            label: 'Contract',
            child: MediaBody(
              kind: MediaKind.file,
              maxItems: 1,
              readOnly: true,
              items: [
                MediaItem(id: 'c', name: 'signed-2026.pdf', bytes: 540_000),
              ],
            ),
          ),
        ),
        DemoVariant(
          'Read-only & empty — the box stays, with a neutral "No media"',
          const FieldShell(label: 'Gallery', child: MediaBody(readOnly: true)),
        ),
        DemoVariant(
          'Disabled — dimmed, no add, remove or reorder',
          FieldShell(
            label: 'Gallery',
            enabled: false,
            child: MediaBody(items: [_img(0), _img(1)]),
          ),
        ),
        DemoVariant(
          'Validation error — empty: the drop zone turns red',
          const FieldShell(
            label: 'Hero image',
            errorText: 'A hero image is required before publishing.',
            child: MediaBody(maxItems: 1, accept: 'PNG, JPG'),
          ),
        ),
        DemoVariant(
          'Limit reached — add hidden at cap + warning row',
          FieldShell(
            label: 'Gallery',
            warning: 'Maximum of 3 images reached.',
            child: MediaBody(
              maxItems: 3,
              cover: true,
              items: [_img(0), _img(1), _img(2)],
            ),
          ),
        ),
        DemoVariant(
          'Field-level error',
          const FieldShell(
            label: 'Attachments',
            errorText: 'Some files were rejected — PDF or PNG only.',
            child: MediaBody(
              kind: MediaKind.file,
              items: [MediaItem(id: 'a', name: 'brief.pdf', bytes: 220_000)],
            ),
          ),
        ),
        DemoVariant(
          'Interactive — add, upload, reorder, remove',
          const _Live(),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag a thumbnail or the file handle to reorder. '
          'Drag-and-drop and the picker are Screen concerns; this View '
          'only models the drop highlight + add callback.',
          style: TextStyle(fontSize: 12, color: context.colors.foregroundMuted),
        ),
      ],
    );
  }
}

/// Fakes the full lifecycle: add drops a queued item, a timer drives it
/// uploading → processing → ready; reorder and remove mutate the list.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  final _items = [_img(0), _img(1)];
  final _timers = <Timer>[];
  int _seq = 100;

  @override
  void dispose() {
    for (var t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _add() {
    var id = 'img${_seq++}';
    setState(
      () => _items.add(
        MediaItem(
          id: id,
          name: '$id.jpg',
          bytes: 1024 * 480,
          swatch: demoPalette[_items.length % demoPalette.length],
          status: MediaStatus.uploading,
        ),
      ),
    );
    _drive(id);
  }

  void _drive(String id) {
    var t = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        var i = _items.indexWhere((e) => e.id == id);
        if (i < 0) return timer.cancel();
        var item = _items[i];
        if (item.status == MediaStatus.uploading) {
          var p = item.progress + 0.12;
          _items[i] = p >= 1
              ? MediaItem(
                  id: item.id,
                  name: item.name,
                  bytes: item.bytes,
                  swatch: item.swatch,
                  status: MediaStatus.processing,
                )
              : MediaItem(
                  id: item.id,
                  name: item.name,
                  bytes: item.bytes,
                  swatch: item.swatch,
                  status: MediaStatus.uploading,
                  progress: p,
                );
        } else {
          _items[i] = MediaItem(
            id: item.id,
            name: item.name,
            bytes: item.bytes,
            swatch: item.swatch,
          );
          timer.cancel();
        }
      });
    });
    _timers.add(t);
  }

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: 'Gallery',
      child: MediaBody(
        items: _items,
        onAddRequested: _add,
        onRemove: (id) => setState(() => _items.removeWhere((e) => e.id == id)),
        onReorder: (oldI, newI) => setState(() {
          var item = _items.removeAt(oldI);
          _items.insert(newI, item);
        }),
      ),
    );
  }
}
