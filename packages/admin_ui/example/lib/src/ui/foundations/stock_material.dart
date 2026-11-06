import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Stock Material widgets under `buildAppTheme`: what an app gets from the
/// widgets it has not moved to the kit. The accent is drawn where it holds
/// its contrast: a button's label and a selected tile in `primaryText`; a
/// checked, selected or on control and a tab indicator in `controlAccent`.
/// The second column lays a light accent over the theme, the case where
/// `primary` itself reads too faintly on the page.
class StockMaterialDemo extends StatelessWidget {
  @Preview(name: 'Stock Material', wrapper: adminUiPreview)
  const StockMaterialDemo({super.key});

  static const _lightAccent = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    return DemoPage(
      maxWidth: 1000,
      children: [
        Wrap(
          spacing: AdminSpacing.xxl,
          runSpacing: AdminSpacing.xxl,
          children: [
            _Widgets("The theme's accent", tokens),
            _Widgets('A light accent', tokens.branded(_lightAccent)),
          ],
        ),
      ],
    );
  }
}

class _Widgets extends StatelessWidget {
  final String title;
  final AdminTokens tokens;

  const _Widgets(this.title, this.tokens);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAppTheme(tokens),
      child: Builder(
        builder: (context) => SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DemoSection(title),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.sm,
                children: [
                  OutlinedButton(onPressed: _noop, child: const Text('Edit')),
                  ElevatedButton(onPressed: _noop, child: const Text('Export')),
                  FilledButton(onPressed: _noop, child: const Text('Save')),
                  TextButton(onPressed: _noop, child: const Text('Cancel')),
                ],
              ),
              const Gap(AdminSpacing.lg),
              Row(
                children: [
                  Checkbox(value: true, onChanged: _toggle),
                  RadioGroup<int>(
                    groupValue: 1,
                    onChanged: _pick,
                    child: const Row(
                      children: [Radio(value: 1), Radio(value: 2)],
                    ),
                  ),
                  Switch(value: true, onChanged: _toggle),
                ],
              ),
              const Gap(AdminSpacing.lg),
              const DefaultTabController(
                length: 3,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'Pricing'),
                    Tab(text: 'Shipping'),
                  ],
                ),
              ),
              const Gap(AdminSpacing.lg),
              const ListTile(
                selected: true,
                leading: Icon(Icons.inbox_outlined),
                title: Text('A selected tile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _noop() {}

void _toggle(bool? _) {}

void _pick(int? _) {}
