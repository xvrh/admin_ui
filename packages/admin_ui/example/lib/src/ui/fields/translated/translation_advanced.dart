import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// Stress-test for the translation field: every capability at once, plus
/// per-lane actions/state driven through the [LaneStack] `laneTrailing` slot
/// (AI-translate, status changes) and the field-level draft background.
class TranslationAdvancedDemo extends StatelessWidget {
  final bool _rightToLeft;

  @Preview(name: 'Translation · advanced', wrapper: adminUiPreview)
  const TranslationAdvancedDemo({super.key}) : _rightToLeft = false;

  /// Lanes in a language written the other way from the admin: each lane is
  /// laid out in its own language's direction, while the label row, the
  /// gutter and the lane actions follow the admin's.
  @Preview(name: 'Translation · right-to-left lanes', wrapper: adminUiPreview)
  const TranslationAdvancedDemo.rightToLeft({super.key}) : _rightToLeft = true;

  @override
  Widget build(BuildContext context) {
    if (_rightToLeft) {
      return const DemoPage(
        maxWidth: 560,
        children: [
          DemoSection('English admin — Arabic and Hebrew targets'),
          _AdminIn(Locale('en'), child: _RtlTargets()),
          Gap(AdminSpacing.xl),

          DemoSection('Arabic admin — a French target'),
          _AdminIn(Locale('ar'), child: _FrenchTarget()),
        ],
      );
    }
    return const DemoPage(
      maxWidth: 560,
      children: [
        DemoSection('Full field — per-lane actions, status & draft'),
        _Flagship(),
        Gap(AdminSpacing.xl),

        DemoSection('One lane in view — its actions and banner stay'),
        _Flagship(initialVisible: {'de'}, initialActive: 'de'),
        Gap(AdminSpacing.xl),

        DemoSection('Inheritance — inherit | custom, beside the actions menu'),
        _Inheritable(),
        Gap(AdminSpacing.xl),

        DemoSection('Translated select — any body via laneBuilder'),
        _TranslatedSelect(),
        Gap(AdminSpacing.xl),

        DemoSection('With a validation error'),
        _WithError(),
      ],
    );
  }
}

const _source = 'en';
const _natives = {
  'en': 'English',
  'fr': 'Français',
  'nl': 'Nederlands',
  'de': 'Deutsch',
};

class _Flagship extends StatefulWidget {
  final Set<String> initialVisible;
  final String initialActive;

  const _Flagship({
    this.initialVisible = const {'en', 'fr', 'nl', 'de'},
    this.initialActive = 'fr',
  });

  @override
  State<_Flagship> createState() => _FlagshipState();
}

class _FlagshipState extends State<_Flagship> {
  late Set<String> _visible = widget.initialVisible;
  late String _active = widget.initialActive;

  final Map<String, String> _values = {
    'en': 'Summer sale',
    'fr': 'Soldes d’été',
    'nl': '',
    'de': 'Sommerschlussverkauf',
  };
  final Map<String, LocaleStatus> _status = {
    'en': LocaleStatus.source,
    'fr': LocaleStatus.translated,
    'nl': LocaleStatus.missing,
    'de': LocaleStatus.outdated,
  };
  // fr was just edited — the field shows a draft background, fr the accent.
  final Set<String> _modified = {'fr'};

  void _edit(String code, String value) => setState(() {
    _values[code] = value;
    _modified.add(code);
  });

  void _aiTranslate(String code) => setState(() {
    _values[code] = '${_values[_source]} (${code.toUpperCase()})';
    _status[code] = LocaleStatus.review;
    _modified.add(code);
  });

  void _setStatus(String code, LocaleStatus status) => setState(() {
    _status[code] = status;
    _modified.add(code);
  });

  void _clear(String code) => setState(() {
    _values[code] = '';
    _status[code] = LocaleStatus.missing;
    _modified.add(code);
  });

  List<LocaleInfo> get _all => [
    for (final code in const ['en', 'fr', 'nl', 'de'])
      LocaleInfo(code: code, native: _natives[code]!, status: _status[code]!),
  ];

  List<LocaleInfo> get _lanes {
    final byCode = {for (final l in _all) l.code: l};
    return [
      if (_visible.contains(_source)) byCode[_source]!,
      for (final l in _all)
        if (l.code != _source && _visible.contains(l.code)) l,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Title',
      locales: _all,
      visibleLocales: _visible,
      sourceLocale: _source,
      activeLocale: _active,
      values: _values,
      modifiedLanes: _modified,
      headerTrailing: const HelpButton(text: 'Shown as the product heading.'),
      onVisibleLocalesChanged: (codes) => setState(() {
        _visible = codes;
        if (!_visible.contains(_active)) _active = _lanes.first.code;
      }),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      onChanged: _edit,
      laneTrailing: _laneActions,
      retranslate: (lane) =>
          () => _aiTranslate(lane.code),
    );
  }

  /// The per-translation control: source gets nothing, an empty target offers
  /// "Translate with AI", a filled target gets a status/actions menu.
  Widget? _laneActions(LocaleInfo lane) {
    if (lane.code == _source) return null;
    if ((_values[lane.code] ?? '').isEmpty) {
      return Button.ghost(
        'Translate with AI',
        icon: Icons.auto_awesome,
        size: ControlSize.small,
        onPressed: () => _aiTranslate(lane.code),
      );
    }
    return Menu(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      entries: [
        MenuItem(
          'Request review',
          icon: Icons.fact_check_outlined,
          onSelect: () => _setStatus(lane.code, LocaleStatus.review),
        ),
        MenuItem(
          'Mark up to date',
          icon: Icons.check_circle_outline,
          onSelect: () => _setStatus(lane.code, LocaleStatus.translated),
        ),
        MenuItem(
          'Mark outdated',
          icon: Icons.history_toggle_off,
          onSelect: () => _setStatus(lane.code, LocaleStatus.outdated),
        ),
        const MenuDivider(),
        MenuItem(
          'Re-translate with AI',
          icon: Icons.auto_awesome,
          onSelect: () => _aiTranslate(lane.code),
        ),
        MenuItem(
          'Clear',
          icon: Icons.clear,
          danger: true,
          onSelect: () => _clear(lane.code),
        ),
      ],
      builder: (context, controller) => IconAction(
        Icons.more_horiz,
        label: 'Translation actions',
        size: IconActionSize.small,
        expanded: controller.isOpen,
        onPressed: controller.toggle,
      ),
    );
  }
}

class _Inheritable extends StatefulWidget {
  const _Inheritable();

  @override
  State<_Inheritable> createState() => _InheritableState();
}

class _InheritableState extends State<_Inheritable> {
  Set<String> _visible = {'en', 'fr', 'de', 'nl'};
  String _active = 'en';

  String _sourceValue = 'Free shipping';
  final Map<String, LaneMode> _mode = {
    'fr': LaneMode.custom,
    'de': LaneMode.inherit,
    'nl': LaneMode.inherit,
  };
  final Map<String, String> _custom = {'fr': 'Livraison gratuite'};
  final Set<String> _modified = {};

  static const _locales = [
    LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
    LocaleInfo(code: 'fr', native: 'Français', status: LocaleStatus.translated),
    LocaleInfo(code: 'de', native: 'Deutsch', status: LocaleStatus.translated),
    LocaleInfo(
      code: 'nl',
      native: 'Nederlands',
      status: LocaleStatus.translated,
    ),
  ];

  List<LocaleInfo> get _lanes => [
    for (final l in _locales)
      if (_visible.contains(l.code)) l,
  ];

  void _setMode(String code, LaneMode mode) => setState(() {
    _mode[code] = mode;
    _modified.add(code);
  });

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Promo banner',
      locales: _locales,
      visibleLocales: _visible,
      sourceLocale: 'en',
      activeLocale: _active,
      values: const {},
      showLaneStatus: false,
      modifiedLanes: _modified,
      headerTrailing: const HelpButton(
        text:
            'Inherited locales mirror English live; switch to custom to '
            'override.',
      ),
      onVisibleLocalesChanged: (codes) => setState(() {
        _visible = codes;
        if (!_visible.contains(_active)) _active = _lanes.first.code;
      }),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      laneBuilder: _laneBody,
      laneTrailing: _laneTrailing,
    );
  }

  Widget _laneBody(LocaleInfo lane) {
    if (lane.code == 'en') {
      return TextBody(
        value: _sourceValue,
        onChanged: (v) => setState(() => _sourceValue = v),
      );
    }
    final inheriting = _mode[lane.code] == LaneMode.inherit;
    return InheritedBody(
      inheriting: inheriting,
      preview: TextBody(value: _sourceValue, onChanged: null),
      custom: TextBody(
        value: _custom[lane.code] ?? '',
        onChanged: (v) => setState(() {
          _custom[lane.code] = v;
          _modified.add(lane.code);
        }),
      ),
    );
  }

  Widget? _laneTrailing(LocaleInfo lane) {
    if (lane.code == 'en') return null;
    final mode = _mode[lane.code]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InheritModeDropdown(
          mode: mode,
          sourceLabel: 'English',
          noun: 'banner',
          onModeChanged: (m) => _setMode(lane.code, m),
        ),
        if (mode == LaneMode.custom) ...[
          const Gap(AdminSpacing.sm),
          _actions(lane.code),
        ],
      ],
    );
  }

  Widget _actions(String code) {
    return Menu(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      entries: [
        MenuItem(
          'Re-translate with AI',
          icon: Icons.auto_awesome,
          onSelect: () => setState(() {
            _custom[code] = '$_sourceValue (${code.toUpperCase()})';
            _modified.add(code);
          }),
        ),
        MenuItem(
          'Clear',
          icon: Icons.clear,
          danger: true,
          onSelect: () => setState(() {
            _custom[code] = '';
            _modified.add(code);
          }),
        ),
      ],
      builder: (context, controller) => IconAction(
        Icons.more_horiz,
        label: 'Translation actions',
        size: IconActionSize.small,
        expanded: controller.isOpen,
        onPressed: controller.toggle,
      ),
    );
  }
}

class _TranslatedSelect extends StatefulWidget {
  const _TranslatedSelect();

  @override
  State<_TranslatedSelect> createState() => _TranslatedSelectState();
}

class _TranslatedSelectState extends State<_TranslatedSelect> {
  Set<String> _visible = {'en', 'fr'};
  String _active = 'en';
  final Map<String, String> _tone = {'en': 'formal', 'fr': 'casual'};

  static const _options = [
    SelectOption(value: 'formal', label: 'Formal'),
    SelectOption(value: 'casual', label: 'Casual'),
    SelectOption(value: 'playful', label: 'Playful'),
  ];

  static const _locales = [
    LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
    LocaleInfo(code: 'fr', native: 'Français', status: LocaleStatus.translated),
  ];

  List<LocaleInfo> get _lanes => [
    for (final l in _locales)
      if (_visible.contains(l.code)) l,
  ];

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Tone of voice',
      locales: _locales,
      visibleLocales: _visible,
      sourceLocale: 'en',
      activeLocale: _active,
      values: const {},
      showLaneStatus: false,
      onVisibleLocalesChanged: (codes) => setState(() {
        _visible = codes;
        if (!_visible.contains(_active)) _active = _lanes.first.code;
      }),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      laneBuilder: (lane) => SelectBody(
        options: _options,
        value: _tone[lane.code],
        onChanged: (v) => setState(() => _tone[lane.code] = v),
      ),
    );
  }
}

class _WithError extends StatefulWidget {
  const _WithError();

  @override
  State<_WithError> createState() => _WithErrorState();
}

class _WithErrorState extends State<_WithError> {
  final Map<String, String> _values = {'en': ''};

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Slug',
      locales: const [
        LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
      ],
      visibleLocales: const {'en'},
      sourceLocale: 'en',
      activeLocale: 'en',
      values: _values,
      showLaneStatus: false,
      errorText: _values['en']!.isEmpty
          ? 'The source value is required.'
          : null,
      onVisibleLocalesChanged: (_) {},
      onChanged: (code, v) => setState(() => _values[code] = v),
    );
  }
}

/// [child] in an admin running in [locale] — its strings and its direction —
/// whatever the preview's axes say.
class _AdminIn extends StatelessWidget {
  final Locale locale;
  final Widget child;

  const _AdminIn(this.locale, {required this.child});

  @override
  Widget build(BuildContext context) =>
      Localizations.override(context: context, locale: locale, child: child);
}

class _RtlTargets extends StatefulWidget {
  const _RtlTargets();

  @override
  State<_RtlTargets> createState() => _RtlTargetsState();
}

class _RtlTargetsState extends State<_RtlTargets> {
  Set<String> _visible = {'en', 'ar', 'he'};
  String _active = 'ar';

  final Map<String, String> _values = {
    'en': 'Summer sale: 20% off every bag.',
    'ar': 'تخفيضات الصيف: خصم 20% على كل الحقائب.',
    'he': '',
  };

  static const _locales = [
    LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
    LocaleInfo(code: 'ar', native: 'العربية', status: LocaleStatus.review),
    LocaleInfo(code: 'he', native: 'עברית', status: LocaleStatus.missing),
  ];

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Headline',
      locales: _locales,
      visibleLocales: _visible,
      sourceLocale: 'en',
      activeLocale: _active,
      values: _values,
      modifiedLanes: const {'ar'},
      maxLines: 2,
      onVisibleLocalesChanged: (codes) => setState(() => _visible = codes),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      onChanged: (code, value) => setState(() => _values[code] = value),
      laneTrailing: (lane) => lane.code == 'en'
          ? null
          : IconAction(
              Icons.more_horiz,
              label: 'Translation actions',
              size: IconActionSize.small,
              onPressed: () {},
            ),
    );
  }
}

class _FrenchTarget extends StatefulWidget {
  const _FrenchTarget();

  @override
  State<_FrenchTarget> createState() => _FrenchTargetState();
}

class _FrenchTargetState extends State<_FrenchTarget> {
  Set<String> _visible = {'ar', 'fr'};
  String _active = 'fr';

  final Map<String, String> _values = {
    'ar': 'حقيبة سفر مصنوعة لتدوم.',
    'fr': 'Un sac de voyage fait pour durer.',
  };

  static const _locales = [
    LocaleInfo(code: 'ar', native: 'العربية', status: LocaleStatus.source),
    LocaleInfo(code: 'fr', native: 'Français', status: LocaleStatus.outdated),
  ];

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'العنوان',
      locales: _locales,
      visibleLocales: _visible,
      sourceLocale: 'ar',
      activeLocale: _active,
      values: _values,
      onVisibleLocalesChanged: (codes) => setState(() => _visible = codes),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      onChanged: (code, value) => setState(() => _values[code] = value),
      retranslate: (_) => () {},
    );
  }
}
