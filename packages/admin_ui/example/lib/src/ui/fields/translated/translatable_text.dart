import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import '../../translation_kit.dart';

/// A `Translated<String>` editor over the explicit-inheritance lane: the same
/// [InheritableLane] and the same [TextBody] the standalone text field uses,
/// proving the pattern is field-agnostic. Required field, so None is off —
/// every locale is either Inherit (live-linked to the source text) or Custom.
class TranslatableTextDemo extends StatelessWidget {
  @Preview(name: 'Text', wrapper: adminUiPreview)
  const TranslatableTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Per-locale CTA label · required',
            style: TextStyle(
              fontSize: 11.5,
              color: context.colors.foregroundMuted,
            ),
          ),
        ),
        const _TranslatedText(),
        const SizedBox(height: 16),
        Text(
          'Edit the English text and the inheriting lanes follow live. '
          'Override one to give it its own label.',
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

class _TranslatedText extends StatefulWidget {
  const _TranslatedText();

  @override
  State<_TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<_TranslatedText> {
  final _translation = TranslationController(sourceCode: demoSourceCode);

  // Source text (English). Inheriting lanes live-link to it.
  final _source = TextEditingController(text: 'Read the guide');

  // Required field — no None. Absent mode ⇒ Inherit.
  final Map<String, LaneMode> _mode = {'ES': LaneMode.custom};
  final Map<String, String> _custom = {'ES': 'Lee la guía'};

  LaneMode _modeOf(String code) => _mode[code] ?? LaneMode.inherit;

  String get _sourceNative =>
      demoLocales.firstWhere((l) => l.code == demoSourceCode).native;

  @override
  void initState() {
    super.initState();
    _translation.setVisible({'EN', 'ES', 'FR'});
    _translation.addListener(_onChanged);
    // Repaint inheriting previews as the source text is typed.
    _source.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _translation.removeListener(_onChanged);
    _translation.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Button label',
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
      return TextBody(controller: _source, hint: 'Call to action');
    }
    return InheritedBody(
      inheriting: _modeOf(lane.code) == LaneMode.inherit,
      preview: TextBody(value: _source.text),
      custom: TextBody(
        value: _custom[lane.code] ?? '',
        hint: 'Call to action',
        onChanged: (v) => _custom[lane.code] = v,
      ),
    );
  }

  Widget? _laneTrailing(LocaleInfo lane) {
    if (lane.code == demoSourceCode) return null;
    return InheritModeDropdown(
      mode: _modeOf(lane.code),
      onModeChanged: (m) => setState(() => _mode[lane.code] = m),
      sourceLabel: _sourceNative,
      noun: 'text',
    );
  }
}
