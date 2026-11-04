import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Global ⌘K search: commands + content in one palette, recents on focus.
class CommandPaletteDemo extends StatelessWidget {
  @Preview(name: 'Command palette (⌘K)', wrapper: adminUiPreview)
  const CommandPaletteDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalAnchor(
      child: Builder(
        builder: (context) => CallbackShortcuts(
          bindings: {
            primaryModifierActivator(LogicalKeyboardKey.keyK): () =>
                _open(context),
          },
          child: Focus(
            autofocus: true,
            child: DemoPage(
              maxWidth: 460,
              children: [
                const DemoSection('Trigger'),
                Text(
                  'Press ${shortcutLabel(context, primaryModifierActivator(LogicalKeyboardKey.keyK))}, '
                  'or click the search box. Local commands match '
                  'instantly; content (pages, products, people) loads async — watch the '
                  'progress line under the field. Type a broad query like “a” to overflow '
                  'the height cap and scroll inside the fixed-size palette; the field '
                  'never jumps as results stream in.',
                  style: context.type.bodyMuted,
                ),
                const SizedBox(height: 20),
                CommandTrigger(
                  hint: context.adminL10n.inputs.searchOrJumpTo,
                  onTap: () => _open(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    // ⌘K toggles — the palette sits below this shortcut, so the binding
    // still fires while it's open.
    final modals = ModalAnchor.of(context);
    if (modals.isOpen) {
      modals.close();
      return;
    }
    void go(String what) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('→ $what (demo)')));
    }

    String shortcut(LogicalKeyboardKey key) =>
        shortcutLabel(context, primaryModifierActivator(key));

    PaletteItem cmd(
      String id,
      String title,
      IconData icon, {
      String? shortcut,
      List<String> keywords = const [],
    }) => PaletteItem(
      id: id,
      title: title,
      icon: icon,
      group: 'Commands',
      shortcut: shortcut,
      keywords: keywords,
      onSelect: () => go(title),
    );

    PaletteItem page(String id, String title, String url) => PaletteItem(
      id: id,
      title: title,
      icon: Icons.description_outlined,
      group: 'Pages',
      subtitle: url,
      keywords: const ['page'],
      onSelect: () => go(title),
    );

    PaletteItem product(String id, String title, String sku) => PaletteItem(
      id: id,
      title: title,
      icon: Icons.inventory_2_outlined,
      group: 'Products',
      subtitle: sku,
      onSelect: () => go(title),
    );

    PaletteItem person(String id, String title, String email) => PaletteItem(
      id: id,
      title: title,
      icon: Icons.person_outline_rounded,
      group: 'People',
      subtitle: email,
      onSelect: () => go(title),
    );

    final commands = [
      cmd(
        'c-newpage',
        'New page',
        Icons.note_add_outlined,
        shortcut: shortcut(LogicalKeyboardKey.keyN),
        keywords: ['create', 'add'],
      ),
      cmd(
        'c-newproduct',
        'New product',
        Icons.add_box_outlined,
        keywords: ['create', 'add'],
      ),
      cmd(
        'c-menus',
        'Manage menus',
        Icons.account_tree_outlined,
        keywords: ['navigation', 'tree'],
      ),
      cmd(
        'c-settings',
        'Open settings',
        Icons.settings_outlined,
        shortcut: shortcut(LogicalKeyboardKey.comma),
      ),
      cmd(
        'c-theme',
        'Toggle dark theme',
        Icons.dark_mode_outlined,
        keywords: ['appearance'],
      ),
      cmd(
        'c-publish',
        'Publish changes',
        Icons.cloud_upload_outlined,
        keywords: ['deploy', 'live'],
      ),
    ];
    // Enough pages that a broad query overflows the height cap and scrolls.
    final pages = [
      for (final name in _samplePages)
        page(
          'pg-${name.toLowerCase().replaceAll(' ', '-')}',
          name,
          '/${name.toLowerCase().replaceAll(' ', '-')}',
        ),
    ];
    final products = [
      product('pr-widget', 'Acme Widget', 'SKU-1024'),
      product('pr-gadget', 'Acme Gadget Pro', 'SKU-2048'),
      product('pr-gizmo', 'Gizmo Mini', 'SKU-4096'),
      product('pr-anvil', 'Acme Anvil', 'SKU-8192'),
    ];
    final people = [
      person('u-marina', 'Marina Cole', 'marina@acme.com'),
      person('u-diego', 'Diego Ruiz', 'diego@acme.com'),
      person('u-aisha', 'Aisha Khan', 'aisha@acme.com'),
    ];

    showCommandPalette(
      context,
      groupOrder: const ['Commands', 'Pages', 'Products', 'People', 'Recent'],
      sources: [
        // Local commands — match instantly, no spinner.
        CommandSource(() => commands),
        // Content — simulated server latency so the progress line shows.
        _DelayedSource([...pages, ...products, ...people]),
        RecentsSource(
          () => [
            page('pg-about-us', 'About us', '/about-us'),
            product('pr-widget', 'Acme Widget', 'SKU-1024'),
            cmd('c-menus', 'Manage menus', Icons.account_tree_outlined),
          ],
        ),
      ],
    );
  }
}

const _samplePages = [
  'Home',
  'About us',
  'Pricing',
  'Contact',
  'Blog',
  'Careers',
  'Press',
  'Partners',
  'Privacy policy',
  'Terms of service',
  'Support',
  'Changelog',
  'Roadmap',
  'Status',
  'Security',
  'Accessibility',
  'Cookie policy',
  'Affiliates',
  'Community',
  'Newsletter',
  'Case studies',
  'Integrations',
];

/// A fuzzy-matching content source with simulated network latency, so the
/// palette's async loading affordance (progress line + merge-in) is visible.
class _DelayedSource implements SearchSource {
  final List<PaletteItem> all;
  _DelayedSource(this.all);

  @override
  Future<List<PaletteSection>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final q = query.trim();
    if (q.isEmpty) return const [];
    final byGroup = <String, List<ScoredItem>>{};
    for (final it in all) {
      final m = fuzzyMatch(q, it.title);
      if (m != null) {
        (byGroup[it.group] ??= []).add(ScoredItem(it, m.matched, m.score));
      }
    }
    return [for (final e in byGroup.entries) PaletteSection(e.key, e.value)];
  }
}

/// The palette as it rests open on 40 results in four sections, with the
/// preview pane beside them — dropped once the palette is under 640px wide
/// (render this at a phone width to see it go).
class CommandPaletteResultsDemo extends StatefulWidget {
  @Preview(name: 'Command palette — 40 results', wrapper: adminUiPreview)
  const CommandPaletteResultsDemo({super.key});

  @override
  State<CommandPaletteResultsDemo> createState() =>
      _CommandPaletteResultsDemoState();
}

class _CommandPaletteResultsDemoState extends State<CommandPaletteResultsDemo> {
  late final _controller = CommandPaletteController(
    sources: [
      _Suggestions(
        (key) => shortcutLabel(context, primaryModifierActivator(key)),
      ),
    ],
    groupOrder: const ['Commands', 'Pages', 'Products', 'People'],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 520),
            child: CommandPalette.controller(
              _controller,
              preview: true,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything on an empty query, and fuzzy matches on a typed one.
class _Suggestions implements SearchSource {
  _Suggestions(this.shortcut);

  /// A command's shortcut with the platform's modifier, as it writes it.
  final String Function(LogicalKeyboardKey key) shortcut;

  late final _all = [
    for (final (title, icon, key) in const [
      ('New page', Icons.note_add_outlined, LogicalKeyboardKey.keyN),
      ('New product', Icons.add_box_outlined, null),
      ('Manage menus', Icons.account_tree_outlined, null),
      ('Open settings', Icons.settings_outlined, LogicalKeyboardKey.comma),
      ('Toggle dark theme', Icons.dark_mode_outlined, null),
      ('Publish changes', Icons.cloud_upload_outlined, null),
    ])
      _item(
        title,
        'Commands',
        icon,
        shortcut: key == null ? null : shortcut(key),
      ),
    for (final name in _samplePages.take(22))
      _item(
        name,
        'Pages',
        Icons.description_outlined,
        subtitle: '/${name.toLowerCase().replaceAll(' ', '-')}',
      ),
    for (final (name, sku) in const [
      ('Acme Widget', 'SKU-1024'),
      ('Acme Gadget Pro', 'SKU-2048'),
      ('Gizmo Mini', 'SKU-4096'),
      ('Acme Anvil', 'SKU-8192'),
      ('Rocket Skates', 'SKU-1638'),
      ('Portable Hole', 'SKU-3276'),
    ])
      _item(name, 'Products', Icons.inventory_2_outlined, subtitle: sku),
    for (final (name, email) in const [
      ('Marina Cole', 'marina@example.com'),
      ('Diego Ruiz', 'diego@example.com'),
      ('Aisha Khan', 'aisha@example.com'),
      ('Tom Lee', 'tom@example.com'),
      ('Maya Patel', 'maya@example.com'),
      ('Noah Smith', 'noah@example.com'),
    ])
      _item(name, 'People', Icons.person_outline_rounded, subtitle: email),
  ];

  static PaletteItem _item(
    String title,
    String group,
    IconData icon, {
    String? subtitle,
    String? shortcut,
  }) => PaletteItem(
    id: '$group/$title',
    title: title,
    icon: icon,
    group: group,
    subtitle: subtitle,
    shortcut: shortcut,
    onSelect: () {},
  );

  @override
  List<PaletteSection> search(String query) {
    final q = query.trim();
    final byGroup = <String, List<ScoredItem>>{};
    for (final it in _all) {
      final m = q.isEmpty ? null : fuzzyMatch(q, it.title);
      if (q.isNotEmpty && m == null) continue;
      (byGroup[it.group] ??= []).add(
        ScoredItem(it, m?.matched ?? const [], m?.score ?? 0),
      );
    }
    return [for (final e in byGroup.entries) PaletteSection(e.key, e.value)];
  }
}

/// The selected row's secondary line on its tinted fill: a page's path, and a
/// content hit's snippet beside its reason chip, each held selected so a
/// static render shows the muted text on the selection.
class CommandPaletteSelectionDemo extends StatefulWidget {
  @Preview(name: 'Command palette — selected hits', wrapper: adminUiPreview)
  const CommandPaletteSelectionDemo({super.key});

  @override
  State<CommandPaletteSelectionDemo> createState() =>
      _CommandPaletteSelectionDemoState();
}

class _CommandPaletteSelectionDemoState
    extends State<CommandPaletteSelectionDemo> {
  late final _subtitle = _pinned(0);
  late final _snippet = _pinned(1);

  static final _hits = [
    PaletteItem(
      id: 'pg-pricing',
      title: 'Pricing',
      subtitle: '/pricing',
      icon: Icons.description_outlined,
      group: 'Pages',
      onSelect: () {},
    ),
    PaletteItem(
      id: 'pg-returns',
      title: 'Returns policy',
      snippet: 'Items can be returned within 30 days of delivery.',
      snippetHighlights: const [13, 21],
      reason: 'Body',
      reasonIcon: Icons.notes_rounded,
      icon: Icons.description_outlined,
      group: 'Pages',
      onSelect: () {},
    ),
    PaletteItem(
      id: 'c-newpage',
      title: 'New page',
      shortcut: 'Ctrl+N',
      icon: Icons.note_add_outlined,
      group: 'Commands',
      onSelect: () {},
    ),
  ];

  static CommandPaletteController _pinned(int selected) =>
      CommandPaletteController(
        sources: [RecentsSource(() => _hits, title: 'Pages')],
      )..setSelected(selected);

  @override
  void dispose() {
    _subtitle.dispose();
    _snippet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget palette(CommandPaletteController controller) => ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: CommandPalette.controller(controller, onDismiss: () {}),
    );
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('A page selected: its path'),
        palette(_subtitle),
        const Gap(AdminSpacing.xl),
        const DemoSection('A content hit selected: its snippet'),
        palette(_snippet),
      ],
    );
  }
}
