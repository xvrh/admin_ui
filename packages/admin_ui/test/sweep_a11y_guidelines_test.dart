import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.2 SC 2.5.8: a pointer target of at least 24 by 24 CSS pixels.
const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

/// One kit surface on a page of its own.
class _Exhibit {
  final String name;
  final Widget Function() build;

  /// Brings the surface into the state under test — opens a menu, shows a
  /// toast — once the page is up.
  final Future<void> Function(WidgetTester tester)? setUp;

  /// Winds down whatever [setUp] left running.
  final Future<void> Function(WidgetTester tester)? tearDown;

  const _Exhibit(this.name, this.build, {this.setUp, this.tearDown});
}

void _noop() {}

final _exhibits = <_Exhibit>[
  _Exhibit(
    'Button and IconAction',
    () => const Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Button('Save', onPressed: _noop),
        Button.primary('Publish', onPressed: _noop),
        Button.ghost('Cancel', onPressed: _noop),
        Button.danger('Delete', onPressed: _noop),
        IconAction(Icons.edit_outlined, label: 'Edit', onPressed: _noop),
        IconAction.close(onPressed: _noop),
      ],
    ),
  ),
  _Exhibit(
    'Toggle',
    () => Toggle(value: true, onChanged: (_) {}, label: 'Allow comments'),
  ),
  _Exhibit(
    'Check',
    () => Check(value: false, onChanged: (_) {}, label: 'Notify followers'),
  ),
  _Exhibit(
    'Choice',
    () => Choice<String>(
      options: const [
        ChoiceOption('draft', 'Draft'),
        ChoiceOption('live', 'Live'),
      ],
      value: 'draft',
      onChanged: (_) {},
    ),
  ),
  _Exhibit(
    'Segmented',
    () => Segmented<String>(
      segments: const [
        SegmentOption('grid', 'Grid'),
        SegmentOption('list', 'List'),
      ],
      value: 'grid',
      onChanged: (_) {},
    ),
  ),
  _Exhibit(
    'Tag',
    () => const Wrap(
      spacing: 8,
      children: [
        Tag('News'),
        Tag('Removable', onRemove: _noop),
      ],
    ),
  ),
  _Exhibit(
    'Tabs',
    () => Tabs(
      tabs: const [TabItem('Content'), TabItem('SEO'), TabItem('Settings')],
      selected: 0,
      onChanged: (_) {},
    ),
  ),
  _Exhibit(
    'Breadcrumbs',
    () => const Breadcrumbs([
      Crumb('Home', onTap: _noop),
      Crumb('Pages', onTap: _noop),
      Crumb('About us'),
    ]),
  ),
  _Exhibit(
    'Pagination',
    () => Pagination(page: 3, pageCount: 9, onChanged: (_) {}),
  ),
  _Exhibit(
    'Sidebar',
    () => const SizedBox(
      width: Sidebar.expandedWidth,
      height: 320,
      child: Sidebar(
        entries: [
          NavItem(
            'Pages',
            icon: Icons.description_outlined,
            selected: true,
            onTap: _noop,
          ),
          NavItem('Media', icon: Icons.image_outlined, onTap: _noop),
        ],
      ),
    ),
  ),
  _Exhibit(
    'Menu, open',
    () => Menu(
      entries: const [
        MenuItem('Edit', icon: Icons.edit_outlined, onSelect: _noop),
        MenuItem(
          'Delete',
          icon: Icons.delete_outline,
          danger: true,
          onSelect: _noop,
        ),
      ],
      builder: (context, controller) =>
          Button('Actions', onPressed: controller.toggle),
    ),
    setUp: (tester) async {
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'Modal',
    () => const Modal(
      title: 'Delete page?',
      message: 'This cannot be undone.',
      onDismiss: _noop,
      actions: [
        Button.ghost('Cancel', onPressed: _noop),
        Button.danger('Delete', onPressed: _noop),
      ],
    ),
  ),
  _Exhibit(
    'Toast',
    () => Builder(
      builder: (context) => Button(
        'Notify',
        onPressed: () => ToastScope.of(
          context,
        ).show(const Toast('Page saved', actionLabel: 'Undo', onAction: _noop)),
      ),
    ),
    setUp: (tester) async {
      await tester.tap(find.text('Notify'));
      await tester.pumpAndSettle();
    },
    tearDown: (tester) async {
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'UploadZone',
    () => const SizedBox(
      width: 420,
      child: UploadZone(onBrowse: _noop, accept: 'PNG, JPG up to 10 MB'),
    ),
  ),
  _Exhibit(
    'Accordion',
    () => const SizedBox(
      width: 480,
      child: Accordion(
        initiallyOpen: {0},
        sections: [
          AccordionSection(
            title: 'General',
            icon: Icons.tune_rounded,
            child: Text('Title, slug and summary.'),
          ),
          AccordionSection(
            title: 'Search appearance',
            subtitle: 'How the page shows in results',
            child: Text('Meta title and description.'),
          ),
        ],
      ),
    ),
  ),
  _Exhibit(
    'StatGrid, tappable',
    () => const SizedBox(
      width: 560,
      child: StatGrid(
        children: [
          StatCard(
            label: 'Visitors',
            value: '12,480',
            icon: Icons.people_outline,
            delta: StatDelta('8%'),
            caption: 'vs last week',
            onTap: _noop,
          ),
          StatCard(
            label: 'Bounce rate',
            value: '41%',
            delta: StatDelta('3%', direction: TrendDirection.down),
            onTap: _noop,
          ),
        ],
      ),
    ),
  ),
  _Exhibit(
    'DescriptionList',
    () => const SizedBox(
      width: 520,
      child: DescriptionList(
        items: [
          DescriptionItem('Status', value: 'Published'),
          DescriptionItem('Author', value: 'Alex Morgan'),
          DescriptionItem('Updated', value: 'Jun 12, 2026'),
        ],
      ),
    ),
  ),
  _Exhibit(
    'Alert and AnnouncementBar',
    () => SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Alert('Draft saved.', onDismiss: _noop),
          const SizedBox(height: 12),
          const Alert(
            'A newer version exists.',
            severity: Severity.warning,
            action: Button.ghost(
              'Review',
              size: ControlSize.small,
              onPressed: _noop,
            ),
          ),
          const SizedBox(height: 12),
          AnnouncementBar(
            'Scheduled maintenance tonight.',
            action: Button(
              'Details',
              size: ControlSize.small,
              onPressed: () {},
            ),
            onDismiss: _noop,
          ),
        ],
      ),
    ),
  ),
  _Exhibit(
    'AnnouncementBar, clipped to a line',
    () => const SizedBox(
      width: 360,
      child: AnnouncementBar(
        'Scheduled maintenance tonight from 22:00 to 23:30 UTC: publishing '
        'and uploads pause while the database is upgraded.',
        maxLines: 1,
        onDismiss: _noop,
      ),
    ),
  ),
  _Exhibit(
    'SearchField, with text',
    () => const SearchField(value: 'lamp', width: 280),
  ),
  _Exhibit(
    'SideSheet',
    () => const SizedBox(
      width: 420,
      height: 480,
      child: SideSheet(
        title: 'Edit details',
        onDismiss: _noop,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button.ghost('Cancel', onPressed: _noop),
            SizedBox(width: 8),
            Button.primary('Save', onPressed: _noop),
          ],
        ),
        child: Text('The page’s title, slug and summary.'),
      ),
    ),
  ),
  _Exhibit(
    'NotificationCenter, open',
    () => const NotificationCenter(
      onMarkAllRead: _noop,
      items: [
        NotificationItem(
          title: 'Alex mentioned you',
          body: 'On “Pricing”: can you check the table?',
          timestamp: '2m',
          unread: true,
          onTap: _noop,
        ),
        NotificationItem(title: 'Export ready', timestamp: '1h', onTap: _noop),
      ],
    ),
    setUp: (tester) async {
      await tester.tap(find.byType(NotificationCenter));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'DateRangePicker, open',
    () => DateRangePicker(
      value: DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 7),
      ),
      today: DateTime(2026, 6, 12),
      onChanged: (_) {},
    ),
    setUp: (tester) async {
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'CommandPalette',
    () => const SizedBox(
      width: 600,
      height: 420,
      child: CommandPalette(
        items: [
          PaletteItem(
            id: 'pages',
            title: 'Pages',
            icon: Icons.description_outlined,
            group: 'Go to',
            shortcut: 'G P',
            onSelect: _noop,
          ),
          PaletteItem(
            id: 'new',
            title: 'New page',
            subtitle: 'Create a blank page',
            icon: Icons.add_rounded,
            group: 'Commands',
            onSelect: _noop,
          ),
        ],
      ),
    ),
  ),
  _Exhibit(
    'CommentsButton, open',
    () => CommentsButton(
      count: 2,
      anchor: 'its own time',
      messages: const [
        CommentEntry(
          author: 'Lena Fritz',
          initials: 'LF',
          color: Color(0xFFD97706),
          time: '14m',
          body: 'Love this headline.',
        ),
        CommentEntry(
          author: 'Diego Ruiz',
          initials: 'DR',
          color: Color(0xFF0F9D8F),
          time: '6m',
          body: 'Agreed.',
        ),
      ],
      onReply: (_) {},
      onResolve: _noop,
    ),
    setUp: (tester) async {
      await tester.tap(find.byType(CommentsButton));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'HistoryButton, open',
    () => const HistoryButton(
      draft: 'A coast that marks its own time',
      baseline: 'A coast that keeps its own time',
      versions: [
        FieldVersion(
          label: 'Published v3',
          author: 'Marina Cole',
          initials: 'MC',
          color: Color(0xFF9333A8),
          time: 'Yesterday',
        ),
      ],
      onRevert: _noop,
    ),
    setUp: (tester) async {
      await tester.tap(find.byType(HistoryButton));
      await tester.pumpAndSettle();
    },
  ),
  _Exhibit(
    'Select field',
    () => SizedBox(
      width: 360,
      child: FieldShell(
        label: 'Status',
        help: const HelpButton(text: 'Where the page stands.'),
        child: SelectBody(
          options: const [
            SelectOption(value: 'draft', label: 'Draft'),
            SelectOption(value: 'live', label: 'Live'),
          ],
          value: 'draft',
          onChanged: (_) {},
        ),
      ),
    ),
  ),
];

/// The catalog's brand accents, re-checked for text contrast: a brand
/// re-derives the primary fills and their text.
const _brands = <String, Color>{
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      if (dark && !theme.hasDark) continue;
      final mode = dark ? 'Dark' : 'Light';
      // The theme's palette, radii and focus ring, without its font.
      final tokens = dark ? theme.dark! : theme.tokens;
      ThemeData themed(AdminPalette palette) => buildAppTheme(
        AdminTokens.from(
          palette: palette,
          radii: tokens.radii,
          focus: tokens.focus,
        ),
      );

      group('${theme.name} $mode', () {
        _checkExhibits(themed(tokens.palette), const [
          (labeledTapTargetGuideline, 'labelled targets'),
          (_targetSize, '24px targets'),
          (textContrastGuideline, 'text contrast'),
        ]);
      });
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        group('${theme.name} $mode + $brand', () {
          _checkExhibits(themed(tokens.palette.branded(seed)), const [
            (textContrastGuideline, 'text contrast'),
          ]);
        });
      }
    }
  }

  // Mirrored, with the kit's Arabic strings: a label that went missing in
  // translation, or a target the mirrored layout clipped.
  group('Iris Light · ar, RTL', () {
    _checkExhibits(buildAppTheme(defaultTokens), const [
      (labeledTapTargetGuideline, 'labelled targets'),
      (_targetSize, '24px targets'),
    ], locale: const Locale('ar'));
  });
}

/// One test per exhibit and guideline, under [theme], in [locale] (the
/// platform's, English, when null).
void _checkExhibits(
  ThemeData theme,
  List<(AccessibilityGuideline, String)> guidelines, {
  Locale? locale,
}) {
  for (final exhibit in _exhibits) {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: locale,
          supportedLocales: AdminLocalizations.supportedLocales,
          localizationsDelegates: AdminLocalizations.localizationsDelegates,
          builder: (context, child) => ToastScope(child: child!),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: exhibit.build(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await exhibit.setUp?.call(tester);
    }

    for (final (guideline, name) in guidelines) {
      testWidgets('${exhibit.name}: $name', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester);
        await expectLater(tester, meetsGuideline(guideline));
        await exhibit.tearDown?.call(tester);
        handle.dispose();
      });
    }
  }
}
