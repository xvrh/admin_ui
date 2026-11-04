import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import '../../translation_kit.dart';

/// The translation chrome's two menus held open: the language picker, whose
/// check compares a locale side by side and whose row switches to it, and a
/// lane's inherit | custom menu.
class TranslationMenusDemo extends StatelessWidget {
  @Preview(name: 'Translation · open menus', wrapper: adminUiPreview)
  const TranslationMenusDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        DemoVariant(
          'Language picker — English and Spanish in view, Spanish edited',
          PinnedOpen(
            makeRoom: true,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LanguagePill(
                value: const {'EN', 'ES'},
                activeLocale: 'ES',
                locales: demoLocales,
                sourceLocale: demoSourceCode,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        DemoVariant(
          'Lane mode — inheriting from the source',
          PinnedOpen(
            makeRoom: true,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: InheritModeDropdown(
                mode: LaneMode.inherit,
                onModeChanged: (_) {},
                sourceLabel: 'English',
                noun: 'title',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
