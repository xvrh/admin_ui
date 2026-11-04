import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Ant, whose field labels keep their case.
final _theme = buildAppTheme(antTheme.tokens);

const _width = 1000.0;
const _height = 600.0;

/// [child] in an Arabic app, laid out right to left, in a window [_width]
/// wide.
Future<void> _pumpRtl(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(_width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      locale: const Locale('ar'),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
  expect(
    Directionality.of(tester.element(find.byWidget(child))),
    TextDirection.rtl,
  );
}

class _Form extends FormController {
  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

Finder _buttonOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Button)).first;

void main() {
  group('Sidebar', () {
    Widget shell() => Shell(
      sidebar: Sidebar(
        entries: [
          NavItem(
            'Pages',
            icon: Icons.description_outlined,
            selected: true,
            onTap: () {},
          ),
          NavItem('Media', icon: Icons.photo_library_outlined, onTap: () {}),
        ],
      ),
      child: const SizedBox.expand(),
    );

    testWidgets('sits at the right edge, its hairline on its left, '
        'against the page', (tester) async {
      await _pumpRtl(tester, shell());

      final rect = tester.getRect(find.byType(Sidebar));
      expect(rect.right, _width);
      expect(rect.width, Sidebar.widthOf(tester.element(find.byType(Sidebar))));

      final decorated = find
          .descendant(
            of: find.byType(Sidebar),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getRect(decorated), rect);
      final box = tester.renderObject<RenderDecoratedBox>(decorated);
      // In the sidebar's own palette: Ant's dark sider in the light theme.
      final line = tester.element(decorated).colors.border;
      expect(line, antSiderPalette.border);
      // In the box's own coordinates: a 1px rule down its left edge, none
      // down its right.
      expect(
        box,
        paints..path(
          color: line,
          includes: const [Offset(0.5, 10), Offset(0.5, _height - 10)],
          excludes: [Offset(rect.width - 0.5, 10)],
        ),
      );
    });

    testWidgets('the selected item is marked, and starts, at the right', (
      tester,
    ) async {
      await _pumpRtl(tester, shell());

      final icon = tester.getRect(find.byIcon(Icons.description_outlined));
      final label = tester.getRect(find.text('Pages'));
      expect(icon.left, greaterThan(label.right), reason: 'icon leads');
      // Ant's item sits itemMarginInline in from the sider's right edge,
      // its glyph an inline indent further in.
      final style = tester.element(find.byType(Sidebar)).shellStyle;
      expect(
        icon.right,
        closeTo(_width - style.itemMarginX! - style.itemPaddingX, 0.5),
      );
    });

    testWidgets('the collapsed rail keeps its hairline against the page', (
      tester,
    ) async {
      await _pumpRtl(
        tester,
        Shell(
          sidebar: Sidebar(
            collapsed: true,
            entries: [
              NavItem('Pages', icon: Icons.description_outlined, onTap: () {}),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      );
      final rect = tester.getRect(find.byType(Sidebar));
      expect(
        rect.left,
        _width -
            Sidebar.widthOf(
              tester.element(find.byType(Sidebar)),
              collapsed: true,
            ),
      );
    });
  });

  group('save controls', () {
    testWidgets('FormActions: the status sits at the right, its gap to the '
        'buttons on its left', (tester) async {
      final form = _Form();
      addTearDown(form.dispose);
      await _pumpRtl(
        tester,
        Scaffold(
          body: Center(child: FormActions(controller: form, showDiscard: true)),
        ),
      );

      const shell = ShellMessagesAr();
      final status = tester.getRect(find.text('تغييرات غير محفوظة'));
      final discard = tester.getRect(_buttonOf(shell.discard));
      final save = tester.getRect(
        _buttonOf(
          MaterialLocalizations.of(tester.element(find.byType(FormActions)))
              .saveButtonLabel,
        ),
      );

      expect(status.left, greaterThan(discard.right));
      expect(discard.left, greaterThan(save.right));
      expect(status.left - discard.right, AdminSpacing.lg);
    });

    testWidgets('SaveBar: the title at the right, the actions at the left', (
      tester,
    ) async {
      await _pumpRtl(
        tester,
        Scaffold(
          body: Column(
            children: [
              SaveBar(
                state: SaveState.unsaved,
                leading: const Text('تعديل الصفحة'),
                onDiscard: () {},
                onCommit: () {},
              ),
            ],
          ),
        ),
      );
      final gutter = PageHeader.gutterOf(tester.element(find.byType(SaveBar)));
      final title = tester.getRect(find.text('تعديل الصفحة'));
      final publish = tester.getRect(
        _buttonOf(const ShellMessagesAr().publish),
      );
      expect(title.right, _width - gutter);
      expect(publish.left, gutter);
    });
  });

  group('auth', () {
    testWidgets('ChangePasswordForm: the submit sits at the start, '
        'on the right', (tester) async {
      await _pumpRtl(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: ChangePasswordForm(onSubmit: (_, _) {}),
            ),
          ),
        ),
      );
      final form = tester.getRect(find.byType(ChangePasswordForm));
      final submit = tester.getRect(
        _buttonOf(const ShellMessagesAr().changePassword),
      );
      expect(submit.right, form.right);
      expect(submit.left, greaterThan(form.left));
    });

    testWidgets('the strength label reads at the end, on the left', (
      tester,
    ) async {
      await _pumpRtl(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: PasswordStrengthMeter(password: r'abcdEf12!xyz'),
            ),
          ),
        ),
      );
      final meter = tester.getRect(find.byType(PasswordStrengthMeter));
      final label = tester.getRect(
        find.text(const ShellMessagesAr().strengthStrong),
      );
      expect(label.left, meter.left);
    });
  });
}
