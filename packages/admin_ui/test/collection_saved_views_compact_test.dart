import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:admin_ui/src/collection/ui/saved_views_bar.dart';
import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/tabs.dart';
import 'package:admin_ui/src/l10n/admin_ui_localizations.dart';
import 'package:admin_ui/src/theme/breakpoints.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Under the medium breakpoint the bar is the active view's name over a menu
// of every view, so no name is cut at the edge of a phone.

/// Views whose names run long in each language, the active one last.
final _names = {
  'en': ['All', 'To ship', 'Refund requests waiting on a reply'],
  'fr': ['Toutes', 'À expédier', 'Demandes de remboursement en attente'],
  'ar': ['الكل', 'للشحن', 'طلبات الاسترداد التي تنتظر ردًا من الفريق'],
};

List<SavedView> _views(String locale) {
  final [all, ship, refunds] = _names[locale]!;
  return [
    SavedView(id: 'all', name: all, isDefault: true),
    SavedView(
      id: 'ship',
      name: ship,
      scope: SavedViewScope.shared,
      position: 1,
    ),
    SavedView(id: 'refunds', name: refunds, position: 2),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  SavedViewsBar bar, {
  double width = 360,
  String locale = 'en',
  AdminTokens? tokens,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? irisTheme.tokens),
      locale: Locale(locale),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: bar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SavedViewsBar _bar({
  String locale = 'en',
  String? activeId = 'refunds',
  bool dirty = false,
  SavedViewsLayout layout = SavedViewsLayout.auto,
  ValueChanged<SavedView>? onSelect,
  ValueChanged<SavedView>? onDelete,
  ValueChanged<SavedView>? onSetDefault,
  void Function(SavedView, String)? onDuplicate,
  void Function(SavedView, String)? onRenamed,
  ValueChanged<List<String>>? onReorder,
  VoidCallback? onSaveChanges,
  VoidCallback? onDiscardChanges,
  Object? error,
}) => SavedViewsBar(
  views: _views(locale),
  activeId: activeId,
  dirty: dirty,
  layout: layout,
  onSelect: onSelect ?? (_) {},
  onSaveChanges: onSaveChanges ?? () {},
  onDiscardChanges: onDiscardChanges ?? () {},
  onCreate: (_) {},
  onRenamed: onRenamed ?? (_, _) {},
  onDuplicate: onDuplicate ?? (_, _) {},
  onDelete: onDelete ?? (_) {},
  onSetDefault: onSetDefault ?? (_) {},
  onReorder: onReorder ?? (_) {},
  error: error,
  onRetry: () {},
  onDismissError: () {},
);

final _strip = find.byType(Tabs);

/// The compact form's trigger: the button with the chevron.
final _trigger = find.byWidgetPredicate(
  (w) => w is Button && w.trailingIcon == Icons.expand_more_rounded,
);

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is Button && w.label == label);

/// Every run of text and every glyph drawn inside the bar that crosses its
/// edges: a label cut where the bar ends.
List<String> _cut(WidgetTester tester) {
  final bar = tester.getRect(find.byType(SavedViewsBar)).inflate(0.5);
  return [
    for (final element
        in find
            .descendant(
              of: find.byType(SavedViewsBar),
              matching: find.byType(RichText),
            )
            .evaluate())
      if (element.renderObject case final RenderParagraph p
          when p.attached && p.hasSize)
        if (MatrixUtils.transformRect(
              p.getTransformTo(null),
              Offset.zero & p.size,
            )
            case final rect
            when !bar.contains(rect.topLeft) || !bar.contains(rect.bottomRight))
          p.text.toPlainText(),
  ];
}

RenderParagraph _triggerText(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: _trigger,
            matching: find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().isNotEmpty,
            ),
          )
          .first,
    );

const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

void main() {
  group('layout', () {
    testWidgets('auto is a menu under the medium breakpoint and a strip '
        'from it', (tester) async {
      await _pump(tester, _bar(), width: 599);
      expect(_trigger, findsOneWidget);
      expect(_strip, findsNothing);

      await _pump(tester, _bar(), width: 600);
      expect(_strip, findsOneWidget);
      expect(_trigger, findsNothing);
    });

    testWidgets('auto goes by the bar\'s own width, not the window\'s', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 700),
                Expanded(child: _bar()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_trigger, findsOneWidget);
    });

    testWidgets('auto follows the theme\'s breakpoints', (tester) async {
      final tokens = irisTheme.tokens.copyWith(
        breakpoints: const AdminBreakpoints(medium: 480),
      );
      await _pump(tester, _bar(), width: 500, tokens: tokens);
      expect(_strip, findsOneWidget);
      await _pump(tester, _bar(), width: 470, tokens: tokens);
      expect(_trigger, findsOneWidget);
    });

    testWidgets('strip and menu are kept at any width', (tester) async {
      await _pump(tester, _bar(layout: SavedViewsLayout.strip), width: 360);
      expect(_strip, findsOneWidget);
      await _pump(tester, _bar(layout: SavedViewsLayout.menu), width: 900);
      expect(_trigger, findsOneWidget);
    });

    testWidgets('the menu row\'s controls take a finger: the theme\'s '
        'medium size, as the top bar\'s are', (tester) async {
      for (final theme in adminThemes) {
        final tokens = theme.tokens;
        await _pump(tester, _bar(dirty: true), tokens: tokens);
        final medium = tokens.sizes.medium;
        expect(tester.getSize(_trigger).height, medium, reason: theme.name);
        expect(
          tester.getSize(_button('Save')).height,
          medium,
          reason: theme.name,
        );
        for (final label in ['Reset', 'Save current as a new view']) {
          expect(
            tester.getSize(_button(label)),
            Size.square(medium),
            reason: '${theme.name} $label',
          );
        }
      }
    });
  });

  group('the menu', () {
    testWidgets('names the active view, and lists every view with it '
        'checked and the default captioned', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _bar(activeId: 'ship'));
      expect(
        find.descendant(of: _trigger, matching: find.text('To ship')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(_trigger),
        isSemantics(label: 'View: To ship', isButton: true),
      );

      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('To ship').last),
        isSemantics(
          label: 'To ship',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('All').last),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      expect(find.text('Default'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('ends in the active view\'s actions, with no moves', (
      tester,
    ) async {
      SavedView? deleted, defaulted;
      (SavedView, String)? duplicated;
      await _pump(
        tester,
        _bar(
          activeId: 'ship',
          onDelete: (v) => deleted = v,
          onSetDefault: (v) => defaulted = v,
          onDuplicate: (v, name) => duplicated = (v, name),
        ),
      );
      Future<void> pick(String entry) async {
        await tester.tap(_trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry));
        await tester.pumpAndSettle();
      }

      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(find.text('Move left'), findsNothing);
      expect(find.text('Move right'), findsNothing);
      for (final entry in ['Set as default', 'Duplicate', 'Rename']) {
        expect(find.text(entry), findsOneWidget, reason: entry);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await pick('Set as default');
      expect(defaulted?.id, 'ship');
      await pick('Duplicate');
      expect(duplicated?.$1.id, 'ship');
      expect(duplicated?.$2, 'To ship copy');
      await pick('Delete');
      expect(deleted?.id, 'ship');
    });

    testWidgets('renames the active view through the bar\'s dialog', (
      tester,
    ) async {
      (SavedView, String)? renamed;
      await _pump(
        tester,
        _bar(activeId: 'ship', onRenamed: (v, name) => renamed = (v, name)),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(find.text('Rename view'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Ready to ship');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(renamed?.$1.id, 'ship');
      expect(renamed?.$2, 'Ready to ship');
    });

    testWidgets('with no actions, lists the views alone', (tester) async {
      await _pump(
        tester,
        SavedViewsBar(
          views: _views('en'),
          activeId: 'ship',
          dirty: false,
          onSelect: (_) {},
        ),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(find.text('Refund requests waiting on a reply'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_MenuDividerRow',
        ),
        findsNothing,
      );
    });

    testWidgets('picks another view', (tester) async {
      SavedView? picked;
      await _pump(tester, _bar(onSelect: (v) => picked = v));
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      await tester.tap(find.text('To ship'));
      await tester.pumpAndSettle();
      expect(picked?.id, 'ship');
    });

    testWidgets('keeps Reset, as an icon, Save, "+" and the error row', (
      tester,
    ) async {
      var saved = 0, reset = 0;
      await _pump(
        tester,
        _bar(
          dirty: true,
          onSaveChanges: () => saved++,
          onDiscardChanges: () => reset++,
          error: Exception('Request failed with status 503'),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.tap(find.bySemanticsLabel('Reset'));
      expect((saved, reset), (1, 1));
      expect(find.bySemanticsLabel('Save current as a new view'), findsOne);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('opens from the keyboard', (tester) async {
      await _pump(tester, _bar(activeId: 'ship'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Set as default'), findsOneWidget);
    });
  });

  group('no name is cut at the edge', () {
    for (final locale in ['en', 'fr', 'ar']) {
      testWidgets('$locale, at 360 with Save and Reset showing', (
        tester,
      ) async {
        await _pump(tester, _bar(locale: locale, dirty: true), locale: locale);
        expect(_cut(tester), isEmpty);
        // The long name gives way with an ellipsis, not a cut, and is read
        // whole.
        final name = _names[locale]!.last;
        expect(_triggerText(tester).didExceedMaxLines, isTrue);
        final strings = AdminLocalizations.lookup(Locale(locale)).collection;
        expect(find.bySemanticsLabel(strings.currentView(name)), findsOne);
      });
    }

    testWidgets('the strip, by contrast, cuts a tab at 360', (tester) async {
      await _pump(
        tester,
        _bar(locale: 'fr', activeId: 'all', layout: SavedViewsLayout.strip),
        locale: 'fr',
      );
      expect(_cut(tester), isNotEmpty);
    });
  });

  group('right to left', () {
    testWidgets('the trigger leads on the right and the "+" ends on the '
        'left', (tester) async {
      await _pump(
        tester,
        _bar(locale: 'ar', activeId: 'ship'),
        locale: 'ar',
      );
      final bar = tester.getRect(find.byType(SavedViewsBar));
      final trigger = tester.getRect(_trigger);
      final plus = tester.getRect(
        find.bySemanticsLabel('حفظ الحالي كطريقة عرض جديدة'),
      );
      expect(bar.right - trigger.right, lessThan(bar.width / 4));
      expect(plus.left - bar.left, lessThan(bar.width / 4));
      final chevron = tester.getCenter(
        find.descendant(
          of: _trigger,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
      );
      expect(
        chevron.dx,
        lessThan(tester.getCenter(find.text('للشحن')).dx),
        reason: 'the chevron follows the name, to its left',
      );
    });
  });

  group('accessible in every theme', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        if (dark && !theme.hasDark) continue;
        final mode = dark ? 'Dark' : 'Light';
        testWidgets('${theme.name} $mode', (tester) async {
          final semantics = tester.ensureSemantics();
          final source = dark ? theme.dark! : theme.tokens;
          final tokens = AdminTokens.from(
            palette: source.palette,
            radii: source.radii,
            focus: source.focus,
            sizes: source.sizes,
          );
          await _pump(
            tester,
            _bar(dirty: true, error: Exception('status 503')),
            tokens: tokens,
          );
          expect(_trigger, findsOneWidget);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(_targetSize));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }
    }
  });
}
