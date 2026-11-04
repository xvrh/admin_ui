import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import '../../translation_kit.dart';

/// The integrated translatable field: language (single + side-by-side),
/// comments and history, fields synced through one shared controller.
class TranslationDemo extends StatefulWidget {
  @Preview(name: 'Translation', wrapper: adminUiPreview)
  const TranslationDemo({super.key});

  @override
  State<TranslationDemo> createState() => _TranslationDemoState();
}

class _TranslationDemoState extends State<TranslationDemo> {
  final _translation = TranslationController(sourceCode: demoSourceCode);

  @override
  void dispose() {
    _translation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        Text(
          'ES and DE drafts differ from last published — those fields '
          'tint amber, with a “Modified” button to compare + revert. '
          'Everything scopes per locale.',
          style: TextStyle(color: context.colors.foregroundMuted),
        ),
        const SizedBox(height: 28),
        const FieldShell(
          label: 'Slug',
          child: TextBody(hint: 'about-us'),
        ),
        const SizedBox(height: 24),
        TranslatableFieldView(
          translation: _translation,
          label: 'Title',
          help: 'Renders as the page H1 and the browser tab.',
          fieldComments: const [
            CommentEntry(
              author: 'Lena Fritz',
              initials: 'LF',
              color: Color(0xFFd97706),
              time: '1d',
              body: 'Keep this under 60 characters for SEO.',
            ),
          ],
          commentsByLocale: const {
            'ES': [
              CommentEntry(
                author: 'Lena Fritz',
                initials: 'LF',
                color: Color(0xFFd97706),
                time: '14m',
                body: 'Love this headline — keep the rhythm in ES.',
              ),
              CommentEntry(
                author: 'Diego Ruiz',
                initials: 'DR',
                color: Color(0xFF0f9d8f),
                time: '6m',
                body: 'Agreed. Flagged so MT won’t take it literally.',
              ),
            ],
          },
          published: const {
            'EN': 'A coast that keeps its own time',
            'ES': 'Una costa que marca su tiempo',
            'FR': 'Une côte qui suit son propre rythme',
            'DE': 'Eine Küste mit eigener Zeit',
            'JA': '独自の時を刻む海岸',
          },
          values: const {
            'EN': 'A coast that keeps its own time',
            'ES': 'Una costa que marca su propio tiempo',
            'FR': 'Une côte qui suit son propre rythme',
            'DE': 'Eine Küste, die ihre eigene Zeit behält',
            'JA': '独自の時を刻む海岸',
          },
        ),
        const SizedBox(height: 24),
        TranslatableFieldView(
          translation: _translation,
          label: 'A longer subtitle label that truncates beside its help',
          help: 'Shown under the title.',
          values: const {
            'EN': 'Inland, the cider country',
            'ES': 'Tierra de sidra, hacia el interior',
            'FR': 'À l’intérieur, le pays du cidre',
            'DE': '',
            'JA': '',
          },
        ),
      ],
    );
  }
}
