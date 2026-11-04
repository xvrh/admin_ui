import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import '../translation_kit.dart';

class FieldGroupDemo extends StatefulWidget {
  @Preview(name: 'Field group', wrapper: adminUiPreview)
  const FieldGroupDemo({super.key});

  @override
  State<FieldGroupDemo> createState() => _FieldGroupDemoState();
}

class _FieldGroupDemoState extends State<FieldGroupDemo> {
  final _translation = TranslationController(sourceCode: demoSourceCode);

  @override
  void dispose() {
    _translation.dispose();
    super.dispose();
  }

  Widget _translatable(
    String label,
    Map<String, String> values, {
    String? help,
  }) {
    return TranslatableFieldView(
      translation: _translation,
      label: label,
      help: help,
      values: values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      // A 600 wide column: the label-row group's medium width, two columns.
      maxWidth: FormGrid.compactMaxWidth + 2 * 32,
      children: [
        const DemoSection('Label rows — with and without capabilities'),
        const _CapabilityFields(),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Field states'),
        const _FieldStates(),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Boxed — translatable fields in a card'),
        FieldGroup(
          title: 'Localized content',
          description: 'Switch or fan out languages from each field’s pill.',
          boxed: true,
          children: [
            const FieldShell(
              label: 'Slug',
              child: TextBody(hint: 'about-us'),
            ),
            _translatable('Title', const {
              'EN': 'A coast that keeps its own time',
              'ES': 'Una costa que marca su tiempo',
              'FR': 'Une côte qui suit son propre rythme',
              'DE': 'Eine Küste mit eigener Zeit',
              'JA': '独自の時を刻む海岸',
            }, help: 'Renders as the page H1 and the browser tab.'),
            _translatable('Subtitle', const {
              'EN': 'Inland, the cider country',
              'ES': 'Tierra de sidra, hacia el interior',
              'FR': 'À l’intérieur, le pays du cidre',
              'DE': '',
              'JA': '',
            }),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bare + collapsible — translatable fields'),
        FieldGroup(
          title: 'SEO',
          collapsible: true,
          children: [
            _translatable('Meta description', const {
              'EN': 'A slow-travel guide to the coast.',
              'ES': 'Una guía de viaje pausado por la costa.',
              'FR': 'Un guide de voyage lent sur la côte.',
            }, help: 'The snippet shown in search results.'),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bare — section header above the fields'),
        const FieldGroup(
          title: 'Content',
          children: [
            FieldShell(
              label: 'Slug',
              child: TextBody(hint: 'about-us'),
            ),
            FieldShell(
              label: 'Title',
              child: TextBody(hint: 'About us'),
            ),
            FieldShell(
              label: 'Subtitle',
              child: TextBody(hint: 'Who we are'),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bare — description + header action'),
        FieldGroup(
          title: 'SEO',
          description: 'How this page appears in search results.',
          actions: [
            Button.ghost(
              'Reset',
              icon: Icons.refresh_rounded,
              onPressed: () {},
            ),
          ],
          children: const [
            FieldShell(
              label: 'Meta title',
              child: TextBody(hint: 'About us · Example Co.'),
            ),
            FieldShell(
              label: 'Meta description',
              child: TextBody(hint: 'A slow-travel guide to the coast.'),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Boxed — header + fields in a card'),
        const FieldGroup(
          title: 'Pricing',
          boxed: true,
          children: [
            FieldShell(
              label: 'Price',
              child: TextBody(hint: '€ 0.00'),
            ),
            FieldShell(
              label: 'Compare-at price',
              child: TextBody(hint: '€ 0.00'),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Boxed + collapsible'),
        FieldGroup(
          title: 'Advanced',
          description: 'Optional settings, tucked away by default.',
          boxed: true,
          collapsible: true,
          initiallyExpanded: false,
          actions: [const Tag('3', dot: false)],
          children: const [
            FieldShell(
              label: 'Canonical URL',
              child: TextBody(hint: 'https://…'),
            ),
            FieldShell(
              label: 'Redirect from',
              child: TextBody(hint: '/old-path'),
            ),
            FieldShell(
              label: 'Template',
              child: TextBody(hint: 'default'),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bare + collapsible'),
        const FieldGroup(
          title: 'Internal notes',
          collapsible: true,
          children: [
            FieldShell(
              label: 'Owner',
              child: TextBody(hint: 'team@example.com'),
            ),
            FieldShell(
              label: 'Notes',
              child: TextBody(hint: 'Anything to flag'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two fields side by side, one with every label-row capability and one with
/// none: their label rows, and so their inputs, line up. Narrower than the
/// grid's medium width, as on a phone, they stack.
class _CapabilityFields extends StatelessWidget {
  const _CapabilityFields();

  @override
  Widget build(BuildContext context) {
    return FieldGroup(
      columns: const FormColumns(compact: 1, medium: 2),
      children: [
        const FieldShell(
          label: 'SKU',
          child: TextBody(hint: 'WKD-HOLDALL-01'),
        ),
        FieldShell(
          label: 'Title',
          help: const HelpButton(text: 'Shown as the product heading.'),
          language: LanguagePill(
            value: const {'EN'},
            activeLocale: 'EN',
            locales: demoLocales,
            sourceLocale: demoSourceCode,
            onChanged: (_) {},
          ),
          comments: const CommentsButton(count: 2),
          history: const HistoryButton(
            draft: 'Weekender Holdall',
            baseline: 'Weekender bag',
            versions: demoVersions,
          ),
          modified: true,
          child: const TextBody(hint: 'Weekender Holdall'),
        ),
      ],
    );
  }
}

/// The field-level options every preset takes, one per row, with the
/// validation messages of the last rows coming from a [FieldErrorsScope].
class _FieldStates extends StatefulWidget {
  const _FieldStates();

  @override
  State<_FieldStates> createState() => _FieldStatesState();
}

class _FieldStatesState extends State<_FieldStates> {
  final _name = _Cell('name', '');
  final _handle = _Cell('handle', 'weekender-holdall');
  final _sku = _Cell('sku', 'WKD-HOLDALL-01');
  final _status = _Cell('status', 'review');
  final _slug = _Cell('slug', 'about us');
  final _notes = _Cell('notes', '');
  final _weight = _Cell('weight', '1.2');

  static const _statuses = [
    SelectOption(value: 'draft', label: 'Draft'),
    SelectOption(value: 'review', label: 'In review'),
    SelectOption(value: 'live', label: 'Live'),
  ];

  @override
  Widget build(BuildContext context) {
    return FieldErrorsScope(
      errors: const {'slug': 'Use lowercase letters, digits and dashes.'},
      child: FieldGroup(
        title: 'Product',
        description: 'Required, described, disabled, read-only and invalid.',
        children: [
          Field(
            _name,
            label: 'Name',
            required: true,
            description: 'The name customers see in the shop.',
            hint: 'Weekender Holdall',
          ),
          Field(
            _handle,
            label: 'Handle',
            enabled: false,
            description: 'Set once the product is published.',
          ),
          Field(_sku, label: 'SKU', readOnly: true),
          SelectField(
            _status,
            label: 'Status',
            options: _statuses,
            readOnly: true,
          ),
          Field(_slug, label: 'Slug', required: true),
          Field(
            _notes,
            label: 'Notes',
            minLines: 3,
            maxLines: 6,
            maxLength: 280,
            hint: 'Anything the team should know',
          ),
          Field(
            _weight,
            label: 'Weight',
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            warning: 'Heavier than the carrier’s 1 kg tier.',
          ),
        ],
      ),
    );
  }
}

class _Cell extends ValueCell<String> with ChangeNotifier {
  @override
  final String id;
  String _value;

  _Cell(this.id, this._value);

  @override
  String get value => _value;

  @override
  void set(String value) {
    _value = value;
    notifyListeners();
  }
}
