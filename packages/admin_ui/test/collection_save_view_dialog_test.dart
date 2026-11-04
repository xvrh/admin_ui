import 'dart:ui' show SemanticsValidationResult;

import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:admin_ui/src/collection/ui/save_view_dialog.dart';
import 'package:admin_ui/src/collection/ui/saved_views_bar.dart';
import 'package:admin_ui/src/common/ui/choice.dart';
import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/l10n/admin_ui_localizations.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The kit names a new view and renames one.

typedef _Answer = ({String name, SavedViewScope scope});

/// An app in [locale] whose one button opens the dialog with [open], and
/// the dialog's answers, in order.
Future<List<_Answer?>> _pumpOpener(
  WidgetTester tester,
  Future<_Answer?> Function(BuildContext context) open, {
  String locale = 'en',
}) async {
  final answers = <_Answer?>[];
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: Locale(locale),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answers.add(await open(context)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return answers;
}

Future<void> _pumpBar(WidgetTester tester, SavedViewsBar bar) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 900, child: bar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _views = [
  SavedView(id: 'all', name: 'All', isDefault: true),
  SavedView(id: 'pub', name: 'Published', scope: SavedViewScope.shared),
];

Finder get _field => find.byType(EditableText);

void main() {
  group('showSaveViewDialog', () {
    testWidgets('asks for a name and who sees the view', (tester) async {
      final semantics = tester.ensureSemantics();
      final answers = await _pumpOpener(tester, showSaveViewDialog);
      expect(find.text('Save view'), findsOneWidget);
      expect(
        find.text('Keeps the current filters and sort one click away.'),
        findsOneWidget,
      );
      // Iris sets its labels in capitals: they are read as written.
      expect(find.bySemanticsLabel(RegExp('^Name')), findsOneWidget);
      expect(find.bySemanticsLabel('Who sees it'), findsOneWidget);
      expect(find.byType(Choice<SavedViewScope>), findsOneWidget);
      // The name field has the focus, so typing goes straight in.
      expect(tester.widget<EditableText>(_field).focusNode.hasFocus, isTrue);

      await tester.enterText(_field, '  Bank transfers  ');
      await tester.tap(find.text('Shared'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(answers, [(name: 'Bank transfers', scope: SavedViewScope.shared)]);
      expect(find.text('Save view'), findsNothing);
      semantics.dispose();
    });

    testWidgets('refuses an empty name with an error, not a closed dialog', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final answers = await _pumpOpener(tester, showSaveViewDialog);
      await tester.enterText(_field, '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(answers, isEmpty);
      expect(find.text('Give the view a name.'), findsOneWidget);
      expect(
        tester.getSemantics(_field),
        isSemantics(
          isTextField: true,
          hint: 'Give the view a name.',
          validationResult: SemanticsValidationResult.invalid,
        ),
      );

      // Typing a name takes the error away.
      await tester.enterText(_field, 'Late');
      await tester.pumpAndSettle();
      expect(find.text('Give the view a name.'), findsNothing);
      semantics.dispose();
    });

    testWidgets('Enter in the field saves', (tester) async {
      final answers = await _pumpOpener(tester, showSaveViewDialog);
      await tester.enterText(_field, 'Late');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(answers, [(name: 'Late', scope: SavedViewScope.personal)]);
    });

    testWidgets('Escape and Cancel close it with no answer', (tester) async {
      final answers = await _pumpOpener(tester, showSaveViewDialog);
      await tester.enterText(_field, 'Late');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(answers, [null]);
      expect(find.text('Save view'), findsNothing);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answers, [null, null]);
    });

    testWidgets('without askScope, keeps the scope it was given', (
      tester,
    ) async {
      final answers = await _pumpOpener(
        tester,
        (context) => showSaveViewDialog(
          context,
          askScope: false,
          initialScope: SavedViewScope.shared,
        ),
      );
      expect(find.byType(Choice<SavedViewScope>), findsNothing);
      await tester.enterText(_field, 'Team');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(answers, [(name: 'Team', scope: SavedViewScope.shared)]);
    });

    testWidgets('rename starts from the name, selected, and confirms with '
        'Rename', (tester) async {
      final answers = await _pumpOpener(
        tester,
        (context) => showSaveViewDialog(
          context,
          initialName: 'Published',
          askScope: false,
          rename: true,
        ),
      );
      expect(find.text('Rename view'), findsOneWidget);
      expect(
        find.text('Keeps the current filters and sort one click away.'),
        findsNothing,
      );
      final editable = tester.widget<EditableText>(_field);
      expect(editable.controller.text, 'Published');
      expect(
        editable.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 9),
      );
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(answers, [(name: 'Published', scope: SavedViewScope.personal)]);
    });

    for (final (locale, title, required) in [
      ('fr', 'Enregistrer la vue', 'Donnez un nom à la vue.'),
      ('ar', 'حفظ طريقة العرض', 'أدخل اسمًا لطريقة العرض.'),
    ]) {
      testWidgets('speaks $locale', (tester) async {
        await _pumpOpener(tester, showSaveViewDialog, locale: locale);
        expect(find.text(title), findsOneWidget);
        final material = MaterialLocalizations.of(
          tester.element(find.text(title)),
        );
        await tester.tap(find.text(material.saveButtonLabel));
        await tester.pumpAndSettle();
        expect(find.text(required), findsOneWidget);
      });
    }

    testWidgets('right to left, Save sits left of Cancel and the field '
        'reads from the right', (tester) async {
      await _pumpOpener(tester, showSaveViewDialog, locale: 'ar');
      final material = MaterialLocalizations.of(
        tester.element(find.text('حفظ طريقة العرض')),
      );
      expect(
        tester.getCenter(find.text(material.saveButtonLabel)).dx,
        lessThan(tester.getCenter(find.text(material.cancelButtonLabel)).dx),
      );
      expect(
        tester.getTopLeft(find.text('الاسم')).dx,
        greaterThan(tester.getCenter(_field).dx),
        reason: 'the label starts on the right',
      );
    });
  });

  group('SavedViewsBar asks itself', () {
    testWidgets('the "+" names a new view for onCreate', (tester) async {
      final created = <_Answer>[];
      await _pumpBar(
        tester,
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
          onCreate: created.add,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Save current as a new view'));
      await tester.pumpAndSettle();
      await tester.enterText(_field, 'Refunds');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(created, [(name: 'Refunds', scope: SavedViewScope.personal)]);
    });

    testWidgets('askScope false leaves the question out', (tester) async {
      await _pumpBar(
        tester,
        SavedViewsBar(
          views: _views,
          activeId: 'all',
          dirty: false,
          onSelect: (_) {},
          onCreate: (_) {},
          askScope: false,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Save current as a new view'));
      await tester.pumpAndSettle();
      expect(find.byType(Choice<SavedViewScope>), findsNothing);
    });

    testWidgets('a tab\'s Rename renames it through onRenamed, and not to '
        'its own name', (tester) async {
      final renamed = <(String, String)>[];
      await _pumpBar(
        tester,
        SavedViewsBar(
          views: _views,
          activeId: 'pub',
          dirty: false,
          onSelect: (_) {},
          onRenamed: (v, name) => renamed.add((v.id, name)),
        ),
      );
      Future<void> rename(String to) async {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is IconAction && w.label == 'Published options',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();
        expect(find.text('Rename view'), findsOneWidget);
        expect(find.byType(Choice<SavedViewScope>), findsNothing);
        await tester.enterText(_field, to);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      await rename('Live');
      expect(renamed, [('pub', 'Live')]);
      await rename(' Published ');
      expect(renamed, [('pub', 'Live')]);
    });
  });
}
