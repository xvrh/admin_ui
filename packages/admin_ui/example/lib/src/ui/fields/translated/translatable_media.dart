import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import '../../translation_kit.dart';

/// A `Translated<media>` editor that treats inheritance as an explicit, chosen
/// state — not the mere absence of a value. Each non-source locale is one of:
///
///  • **Inherit** — a *live link* to the source image. Reflects the source
///    automatically (replace English and watch the inheriting lanes change),
///    never goes outdated, counts as done. The default for a new locale.
///  • **Custom** — its own image for this locale.
///  • **None** — explicitly no image here (the field is optional), distinct
///    from inheriting the source.
///
/// The lane says which state it's in and lets the user switch deliberately.
class TranslatableMediaDemo extends StatelessWidget {
  @Preview(name: 'Media', wrapper: adminUiPreview)
  const TranslatableMediaDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Per-locale hero image · optional',
            style: TextStyle(
              fontSize: 11.5,
              color: context.colors.foregroundMuted,
            ),
          ),
        ),
        const _TranslatedMedia(),
        const SizedBox(height: 16),
        Text(
          'English is the source. Inheriting lanes are live-linked — '
          'replace the English image and they follow. Switch a lane to '
          'Custom for its own image, or None to show nothing there.',
          style: TextStyle(
            fontSize: 12,
            color: context.colors.foregroundMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TranslatedMedia extends StatefulWidget {
  const _TranslatedMedia();

  @override
  State<_TranslatedMedia> createState() => _TranslatedMediaState();
}

class _TranslatedMediaState extends State<_TranslatedMedia> {
  final _translation = TranslationController(sourceCode: demoSourceCode);

  // The source asset (English). Always present, always editable. Swatch cycles
  // on replace so the live link to inheriting lanes is visible.
  static const _sourceSwatches = [
    Color(0xFF6366f1),
    Color(0xFFec4899),
    Color(0xFF22c55e),
  ];
  int _sourceTick = 0;
  late final List<MediaItem> _source = [_asset('en', _sourceSwatches[0])];

  // Explicit per-locale state. Absent ⇒ the default, Inherit.
  final Map<String, LaneMode> _mode = {'ES': LaneMode.custom};
  final Map<String, List<MediaItem>> _custom = {
    'ES': [_asset('es', const Color(0xFF0ea5e9))],
  };

  LaneMode _modeOf(String code) => _mode[code] ?? LaneMode.inherit;

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

  bool _isSource(String code) => code == demoSourceCode;

  String get _sourceNative =>
      demoLocales.firstWhere((l) => l.code == demoSourceCode).native;

  void _setMode(String code, LaneMode mode) {
    setState(() {
      _mode[code] = mode;
      if (mode == LaneMode.custom) _custom.putIfAbsent(code, () => []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Hero image',
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
    if (_isSource(lane.code)) return _sourceLane();
    return InheritedBody(
      inheriting: _modeOf(lane.code) == LaneMode.inherit,
      preview: _inheritedPreview(),
      custom: _customBody(lane.code),
    );
  }

  Widget? _laneTrailing(LocaleInfo lane) {
    if (_isSource(lane.code)) return null;
    return InheritModeDropdown(
      mode: _modeOf(lane.code),
      onModeChanged: (m) => _setMode(lane.code, m),
      sourceLabel: _sourceNative,
      noun: 'image',
    );
  }

  // The source: a plain editable single-asset body. Re-adding cycles the swatch
  // so inheriting lanes visibly follow.
  Widget _sourceLane() {
    return MediaBody(
      kind: MediaKind.image,
      maxItems: 1,
      items: _source,
      accept: 'PNG, JPG · up to 10 MB',
      onAddRequested: () => setState(() {
        _sourceTick++;
        _source.add(_asset('en', _sourceSwatches[_sourceTick % 3]));
      }),
      onRemove: (id) => setState(() => _source.removeWhere((m) => m.id == id)),
    );
  }

  /// The live-linked source image — the lane dims it and makes it inert.
  Widget _inheritedPreview() {
    return MediaBody(
      kind: MediaKind.image,
      maxItems: 1,
      items: _source,
      readOnly: true,
    );
  }

  Widget _customBody(String code) {
    var items = _custom[code] ?? const <MediaItem>[];
    return MediaBody(
      kind: MediaKind.image,
      maxItems: 1,
      items: items,
      accept: 'PNG, JPG · up to 10 MB',
      onAddRequested: () =>
          setState(() => (_custom[code] ??= []).add(_asset(code, _tint(code)))),
      onRemove: (id) =>
          setState(() => _custom[code]?.removeWhere((m) => m.id == id)),
    );
  }

  Color _tint(String code) => switch (code) {
    'FR' => const Color(0xFF14b8a6),
    'DE' => const Color(0xFF8b5cf6),
    'JA' => const Color(0xFFf59e0b),
    _ => const Color(0xFF0ea5e9),
  };

  static MediaItem _asset(String code, Color swatch) => MediaItem(
    id: 'hero-$code-${swatch.hashCode}',
    name: 'hero_$code.jpg',
    bytes: 1024 * 480,
    swatch: swatch,
    status: MediaStatus.ready,
  );
}
