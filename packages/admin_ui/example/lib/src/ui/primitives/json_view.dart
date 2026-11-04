import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The [JsonView] primitive — a read-only, collapsible JSON tree for inspecting
/// payloads. Folds objects/arrays, highlights by type, virtualises long
/// documents, and filters live on search. Complements the `CodeBody` editor:
/// that edits raw text, this folds parsed structure.
class JsonViewDemo extends StatelessWidget {
  final bool _rowActions;

  @Preview(name: 'JSON viewer', wrapper: adminUiPreview)
  const JsonViewDemo({super.key}) : _rowActions = false;

  /// A line under the pointer with its copy actions, and a long value
  /// clicked open to show it whole beside one still cut short.
  @Preview(
    name: 'JSON viewer · row actions, a long value shown whole',
    wrapper: adminUiPreview,
  )
  const JsonViewDemo.rowActions({super.key}) : _rowActions = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_rowActions) {
      return DemoPage(
        maxWidth: 560,
        children: [
          DemoVariant(
            'The pointer on "email": copy its value or its path. '
            '"avatar" was clicked to wrap; "token" is still cut short',
            PinnedHover(
              target: (w) =>
                  w is Text &&
                  (w.textSpan?.toPlainText().startsWith('"email"') ?? false),
              child: const _PinnedWrap(child: JsonView(data: _account)),
            ),
          ),
        ],
      );
    }

    return DemoPage(
      maxWidth: 760,
      children: [
        Text(
          'A read-only viewer for decoded JSON — API responses, webhook bodies, '
          'jsonb columns. Click a key, bracket or chevron to fold. Type to filter: '
          'matches stay revealed and highlighted. Rows are virtualised, so large '
          'documents scroll smoothly.',
          style: TextStyle(color: colors.foregroundMuted, height: 1.5),
        ),
        const SizedBox(height: 24),

        const DemoVariant(
          'Nested object — expanded to depth 2',
          JsonView(data: _order),
        ),

        DemoVariant(
          'Large document — virtualised, capped height, scrolls',
          JsonView(data: _bigData, maxHeight: 320),
        ),

        const DemoVariant(
          'Array root',
          JsonView(data: _people, initialExpandDepth: 1),
        ),

        const DemoVariant(
          'Edge cases — empty {} / [], null, unicode, long string (ellipsis; '
          'click it to wrap)',
          JsonView(data: _edges),
        ),

        DemoVariant(
          'From a raw string — invalid, shows the parse error',
          const JsonView.source('{ "tags": ["a" "b"], }'),
        ),

        const DemoVariant(
          'Bare, no toolbar, fully collapsed',
          JsonView(data: _order, showToolbar: false, initialExpandDepth: 0),
        ),
      ],
    );
  }
}

const _order = {
  'id': 'ord_8841',
  'status': 'paid',
  'total': 148.5,
  'currency': 'EUR',
  'paid': true,
  'discount': null,
  'customer': {
    'id': 'cus_204',
    'name': 'Élise Moreau',
    'email': 'elise@example.com',
    'vip': true,
  },
  'items': [
    {'sku': 'CID-12', 'qty': 2, 'price': 14.5},
    {'sku': 'CID-44', 'qty': 1, 'price': 119.5},
  ],
  'tags': ['seasonal', 'estate', 'small-batch'],
};

const _account = {
  'id': 'acc_31',
  'customer': {'email': 'elise@example.com', 'vip': true},
  'avatar':
      'https://cdn.example.com/avatars/2026/06/elise-moreau-portrait-'
      'square-large.webp?width=512&height=512&fit=cover&format=webp',
  'token':
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NfMzEiLCJpYXQiOjE3'
      'MTgwMDAwMDB9.4pcPyMD09olPSyXnrXCjTwXyr4BsezdI1AVTmud2fU4',
};

/// Clicks open the first long value below it once mounted — the one line
/// that announces itself as folded without being a container — so a static
/// preview shows it wrapped.
class _PinnedWrap extends StatefulWidget {
  final Widget child;

  const _PinnedWrap({required this.child});

  @override
  State<_PinnedWrap> createState() => _PinnedWrapState();
}

class _PinnedWrapState extends State<_PinnedWrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Tappable? line;
      void visit(Element element) {
        if (line != null) return;
        if (element.widget case final Tappable t when t.expanded == false) {
          line = t;
          return;
        }
        element.visitChildren(visit);
      }

      context.visitChildElements(visit);
      line?.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const _people = [
  {'name': 'Ada', 'role': 'admin'},
  {'name': 'Linus', 'role': 'editor'},
  {'name': 'Grace', 'role': 'viewer'},
];

const _edges = {
  'emptyObject': <String, dynamic>{},
  'emptyArray': [],
  'nothing': null,
  'unicode': '日本語 · café · 🚀',
  'longString':
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
      'tempor incididunt ut labore et dolore magna aliqua ut enim ad minim.',
  'nested': {
    'deep': {
      'deeper': {'value': 42},
    },
  },
};

/// A synthetic document big enough to exercise virtualisation and collapse-all.
Map<String, dynamic> get _bigData => {
  'generatedAt': '2026-06-21T10:00:00Z',
  'count': 60,
  'records': [
    for (var i = 0; i < 60; i++)
      {
        'id': 'rec_${i.toString().padLeft(4, '0')}',
        'index': i,
        'active': i.isEven,
        'score': (i * 7) % 100 / 10,
        'labels': ['l${i % 5}', 'l${i % 3}'],
      },
  ],
};
