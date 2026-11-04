import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/ui/screens/customer_form.dart';
import 'package:admin_ui_example/src/ui/screens/record_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpDemo(
  WidgetTester t, {
  Widget demo = const CustomerFormDemo(),
}) async {
  // Tall enough for the whole form and the demo's controls under it.
  await t.binding.setSurfaceSize(const Size(900, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(theme: buildAppTheme(defaultTokens), home: demo),
  );
  // The fake RPC load takes 400ms.
  await t.pump(const Duration(milliseconds: 500));
  await t.pumpAndSettle();
}

Future<void> save(WidgetTester t) async {
  await t.tap(find.text('Save'));
  await t.pump(const Duration(milliseconds: 500));
  await t.pumpAndSettle();
}

AdminLocalizations l10nOf(WidgetTester t) =>
    t.element(find.byType(ContactFormScreen)).adminL10n;

/// The field labelled [label]; its label shows in the theme's casing.
Finder shellOf(String label) =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == label);

/// The text input of the field labelled [label].
Finder inputOf(String label) =>
    find.descendant(of: shellOf(label), matching: find.byType(EditableText));

bool hasFocus(WidgetTester t, Finder input) =>
    t.widget<EditableText>(input).focusNode.hasFocus;

Future<void> pressSaveShortcut(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(LogicalKeyboardKey.keyS);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('loads the DTO, edits mark dirty, save rebases clean', (t) async {
    await pumpDemo(t);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Unsaved changes'), findsNothing);

    await t.enterText(find.text('Ada Lovelace'), 'Ada L.');
    await t.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await save(t);
    expect(find.text('Saved'), findsOneWidget);

    // Editing back to the saved value returns to clean, not dirty.
    await t.enterText(find.text('Ada L.'), 'Ada');
    await t.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await t.enterText(find.text('Ada'), 'Ada L.');
    await t.pump();
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('repeater add/remove flows through the record list', (t) async {
    await pumpDemo(t);
    expect(find.text('+32 2 555 01 23'), findsOneWidget);
    final numbers = find.descendant(
      of: find.byType(RecordListField<PhoneFields>),
      matching: find.byType(EditableText),
    );
    expect(numbers, findsNWidgets(2));

    await t.tap(find.text('Add phone'));
    await t.pumpAndSettle();
    expect(numbers, findsNWidgets(4));
    expect(find.text('Unsaved changes'), findsOneWidget);

    // Removing the row added is back to the baseline.
    await t.tap(
      find.byWidgetPredicate(
        (w) => w is IconAction && w.label == l10nOf(t).fields.removeItemAt(2),
      ),
    );
    await t.pumpAndSettle();
    expect(numbers, findsNWidgets(2));
    expect(find.text('Unsaved changes'), findsNothing);

    await t.tap(find.text('Add phone'));
    await t.pumpAndSettle();
    await t.enterText(numbers.at(3), '+32 2 555 04 56');
    await save(t);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('+32 2 555 04 56'), findsOneWidget);
  });

  testWidgets('a failing save shows the server’s reason and can be retried', (
    t,
  ) async {
    await pumpDemo(t);

    // Arm the failure via the demo toggle.
    await t.tap(find.text('Fail next save'));
    await t.pump();

    await t.enterText(find.text('Ada Lovelace'), 'Grace');
    await t.pump();
    await save(t);
    expect(find.text(FakeContactApi.busyMessage), findsOneWidget);

    // Retry succeeds (the fake API fails once).
    await save(t);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('discard resets fields and repeater to the baseline', (t) async {
    await pumpDemo(t);
    await t.enterText(find.text('Ada Lovelace'), 'Someone Else');
    await t.tap(find.text('Add phone'));
    await t.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('a cleared name says it is required, and nothing moves', (
    t,
  ) async {
    await pumpDemo(t);
    final email = t.getTopLeft(shellOf('Email'));
    final required = l10nOf(t).fields.valueRequired;
    expect(find.text(required), findsNothing);

    await t.enterText(inputOf('Name'), '');
    await t.pump();
    expect(find.text(required), findsOneWidget);
    expect(t.getTopLeft(shellOf('Email')), email);
    expect(find.text(l10nOf(t).shell.fieldsNeedAttention(1)), findsOneWidget);

    await t.enterText(inputOf('Name'), 'Ada');
    await t.pump();
    expect(find.text(required), findsNothing);
  });

  testWidgets('the email is checked with the server as it is typed', (t) async {
    await pumpDemo(t);
    final l10n = l10nOf(t);
    final vip = t.getTopLeft(shellOf('VIP'));

    await t.enterText(inputOf('Email'), FakeContactApi.takenEmail);
    await t.pump();
    expect(find.text(l10n.fields.checking), findsOneWidget);
    expect(t.getTopLeft(shellOf('VIP')), vip);

    // The 300ms debounce, then the fake server's 400ms.
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.fields.checking), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.fields.checking), findsNothing);
    expect(find.text('Already used by another contact'), findsOneWidget);
    expect(t.getTopLeft(shellOf('VIP')), vip);

    await t.enterText(inputOf('Email'), 'ada.king@example.com');
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('Already used by another contact'), findsNothing);
    expect(find.text('Unsaved changes'), findsOneWidget);
  });

  testWidgets('saving an invalid form takes focus to the name', (t) async {
    await pumpDemo(t);
    await t.enterText(inputOf('Name'), '');
    await t.tap(inputOf('Email'));
    await t.pump();
    expect(hasFocus(t, inputOf('Email')), isTrue);

    await pressSaveShortcut(t);
    expect(hasFocus(t, inputOf('Name')), isTrue);
    expect(find.text('Saved'), findsNothing);

    // The save bar's "1 field needs attention" does the same.
    await t.tap(inputOf('Email'));
    await t.pump();
    await t.tap(find.text(l10nOf(t).shell.fieldsNeedAttention(1)));
    await t.pumpAndSettle();
    expect(hasFocus(t, inputOf('Name')), isTrue);
  });

  testWidgets('a save waits for the email check, and a refusal focuses it', (
    t,
  ) async {
    await pumpDemo(t);
    await t.enterText(inputOf('Email'), FakeContactApi.takenEmail);
    await t.pump();
    await t.tap(inputOf('Name'));
    await t.pump();

    // Save is live while the check is pending: it runs the check at once.
    await t.tap(find.text('Save'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(find.text('Already used by another contact'), findsOneWidget);
    expect(hasFocus(t, inputOf('Email')), isTrue);
    expect(find.text('Saved'), findsNothing);
  });

  group('record dialog', () {
    Future<void> pumpDialog(WidgetTester t, Widget demo) async {
      await pumpDemo(t, demo: demo);
      expect(find.text('New contact'), findsWidgets);
    }

    Finder create() => find.widgetWithText(Button, 'Create');

    testWidgets('Create on a blank form shows each message in place and '
        'focuses the first', (t) async {
      await pumpDialog(t, const RecordDialogDemo());
      final l10n = t.element(find.byType(NewContactDialog)).adminL10n;
      final email = t.getTopLeft(shellOf('Email'));
      expect(t.widget<Button>(create()).onPressed, isNotNull);

      await t.tap(create());
      await t.pumpAndSettle();
      expect(find.text(l10n.fields.valueRequired), findsNWidgets(2));
      expect(hasFocus(t, inputOf('Name')), isTrue);
      expect(t.getTopLeft(shellOf('Email')), email);
      final button = t.widget<Button>(create());
      expect(button.onPressed, isNull);
      expect(button.disabledHint, l10n.shell.fieldsNeedAttention(2));
      expect(find.byType(NewContactDialog), findsOneWidget);
    });

    testWidgets('the invalid variant pins that refusal', (t) async {
      await pumpDialog(t, const RecordDialogDemo.invalid());
      final l10n = t.element(find.byType(NewContactDialog)).adminL10n;
      expect(find.text(l10n.fields.valueRequired), findsNWidgets(2));
      expect(hasFocus(t, inputOf('Name')), isTrue);
    });

    testWidgets('a valid contact is created and the dialog closes with it', (
      t,
    ) async {
      await pumpDialog(t, const RecordDialogDemo());
      await t.enterText(inputOf('Name'), 'Ada King');
      await t.enterText(inputOf('Email'), 'ada.king@example.com');
      // Past the email check's debounce and the fake server.
      await t.pump(const Duration(milliseconds: 700));

      await t.tap(create());
      await t.pump(const Duration(milliseconds: 400));
      await t.pumpAndSettle();
      expect(find.byType(NewContactDialog), findsNothing);
      expect(find.text('Created Ada King'), findsOneWidget);
    });
  });

  for (final (platform, label) in const [
    (TargetPlatform.macOS, '⌘S'),
    (TargetPlatform.linux, 'Ctrl+S'),
  ]) {
    testWidgets('the save hint writes the shortcut as ${platform.name} does', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      await pumpDemo(t);
      expect(find.textContaining('the checks. $label saves;'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
