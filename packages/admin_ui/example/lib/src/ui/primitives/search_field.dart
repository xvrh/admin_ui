import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

const _fruits = [
  'Apple',
  'Apricot',
  'Banana',
  'Blueberry',
  'Cherry',
  'Grapefruit',
  'Mango',
  'Orange',
  'Peach',
  'Pear',
];

class SearchFieldDemo extends StatelessWidget {
  @Preview(name: 'Search field', wrapper: adminUiPreview)
  const SearchFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Focused, prefilled (clear button shows)'),
        // Desktop selection controls: the focus is pinned without a touch
        // caret handle over the text.
        Theme(
          data: Theme.of(context).copyWith(platform: TargetPlatform.macOS),
          child: const SearchField(
            value: 'unsaved',
            hint: 'Search pages',
            autofocus: true,
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Default (stretches to parent)'),
        const SearchField(),
        const Gap(AdminSpacing.xl),

        const DemoSection('With placeholder + fixed width'),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SearchField(width: 260, hint: 'Search by name'),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Sizes — small, medium, large, beside a Button'),
        for (final (size, button) in const [
          (ControlSize.small, ControlSize.small),
          (ControlSize.medium, ControlSize.medium),
          (ControlSize.large, ControlSize.large),
        ]) ...[
          Row(
            children: [
              Expanded(
                child: SearchField(value: size.name, size: size),
              ),
              const Gap(AdminSpacing.md),
              Button(
                'Filter',
                icon: Icons.tune_rounded,
                size: button,
                onPressed: () {},
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
        ],
        const Gap(AdminSpacing.md),

        const DemoSection('Invalid'),
        const SearchField(value: 'id:', errorText: 'Type an id after "id:"'),
        const Gap(AdminSpacing.xl),

        const DemoSection('Read-only — no clear'),
        const SearchField(value: 'status:published', readOnly: true),
        const Gap(AdminSpacing.xl),

        const DemoSection('Disabled'),
        const SearchField(value: 'archived', enabled: false),
        const Gap(AdminSpacing.xl),

        const DemoSection('Live — filters a list'),
        const _LiveSearch(),
      ],
    );
  }
}

class _LiveSearch extends StatefulWidget {
  const _LiveSearch();

  @override
  State<_LiveSearch> createState() => _LiveSearchState();
}

class _LiveSearchState extends State<_LiveSearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = _fruits
        .where((f) => f.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hint: 'Filter fruit',
          onChanged: (q) => setState(() => _query = q),
        ),
        const Gap(AdminSpacing.lg),
        Panel(
          child: matches.isEmpty
              ? EmptyState(
                  title: 'No matches',
                  message: 'Nothing matches "$_query".',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in matches)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AdminSpacing.lg,
                          vertical: AdminSpacing.md,
                        ),
                        child: Text(f, style: context.type.body),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
