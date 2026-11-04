import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/field_registry.dart';
import 'package:admin_ui/src/common/ui/spinner.dart';
import 'package:admin_ui/src/common/ui/tappable.dart';
import 'package:admin_ui/src/common/ui/tip.dart';
import 'package:admin_ui/src/forms/form_actions.dart';
import 'package:admin_ui/src/forms/form_controller.dart';
import 'package:admin_ui/src/forms/form_save_bar.dart';
import 'package:admin_ui/src/forms/form_shortcuts.dart';
import 'package:admin_ui/src/shell/ui/save_bar.dart';
import 'package:admin_ui/src/shell/ui/save_cluster.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  _Form({this._status = FormStatus.clean});

  FormStatus _status;
  Map<String, String?> _errors = const {};
  String? failure;
  var submits = 0;
  var resets = 0;

  /// Makes [submit] fail as a backing does: status error, then a rethrow.
  bool throwOnSubmit = false;

  @override
  FormStatus get status => _status;
  set status(FormStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  Map<String, String?> get errors => _errors;
  set errors(Map<String, String?> e) {
    _errors = e;
    notifyListeners();
  }

  @override
  String? get submitError => failure;

  @override
  Future<void> submit() async {
    submits++;
    if (throwOnSubmit) {
      status = FormStatus.error;
      throw StateError('offline');
    }
  }

  @override
  void reset() => resets++;
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: child),
);

Widget _bar(FormController form, {FormFieldRegistry? fields}) => _host(
  Align(
    alignment: Alignment.topCenter,
    child: FormSaveBar(
      controller: form,
      commitLabel: 'Save',
      showDiscard: true,
      fields: fields,
    ),
  ),
);

Button _button(WidgetTester tester, String label) => tester.widget<Button>(
  find.ancestor(of: find.text(label), matching: find.byType(Button)).first,
);

String? _tipOn(WidgetTester tester, String label) => tester
    .widgetList<Tip>(
      find.ancestor(of: find.text(label), matching: find.byType(Tip)),
    )
    .map((t) => t.message)
    .firstOrNull;

void main() {
  group('FormSaveBar maps each FormStatus', () {
    testWidgets('clean: no status, Discard and Save shown disabled', (
      tester,
    ) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));

      expect(find.text('Unsaved changes'), findsNothing);
      expect(_button(tester, 'Discard').onPressed, isNull);
      expect(_button(tester, 'Save').onPressed, isNull);
      // A label of the caller's own gets a hint that fits any submit.
      expect(_tipOn(tester, 'Save'), 'No changes');
    });

    testWidgets('clean, default label of an autosaving document: Publish '
        'says there is nothing to publish', (tester) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          FormSaveBar(
            controller: form,
            showDiscard: true,
            flow: SaveFlow.publish,
          ),
        ),
      );

      expect(_button(tester, 'Publish').onPressed, isNull);
      expect(_tipOn(tester, 'Publish'), 'No changes to publish');
    });

    testWidgets('clean, default label of an explicit-save form: Save, with '
        'nothing to save', (tester) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(FormSaveBar(controller: form, showDiscard: true)),
      );

      expect(find.text('Publish'), findsNothing);
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(_tipOn(tester, 'Save'), 'No changes');
    });

    testWidgets('dirty: status, Discard and Save live', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));

      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(_button(tester, 'Discard').onPressed, isNotNull);
      expect(_button(tester, 'Save').onPressed, isNotNull);
      await tester.tap(find.text('Discard'));
      await tester.tap(find.text('Save'));
      expect(form.resets, 1);
      expect(form.submits, 1);
    });

    testWidgets('submitting: "Saving…" and one spinner, in the button', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.submitting);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));

      expect(find.text('Saving…'), findsOneWidget);
      expect(find.byType(Spinner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Button),
          matching: find.byType(Spinner),
        ),
        findsOneWidget,
      );
      final save = _button(tester, 'Save');
      expect(save.loading, isTrue);
      expect(save.onPressed, isNotNull, reason: 'keeps its tone');
      expect(_button(tester, 'Discard').onPressed, isNull);
    });

    testWidgets('submitted: "Saved"', (tester) async {
      final form = _Form(status: FormStatus.submitted);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));

      expect(find.text('Saved'), findsOneWidget);
      expect(_button(tester, 'Save').onPressed, isNull);
    });

    testWidgets('error: the controller’s message, else the generic one', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.error);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));
      expect(find.text('Couldn’t save'), findsOneWidget);
      expect(_button(tester, 'Save').onPressed, isNotNull, reason: 'retry');

      form.failure = 'The slug is already taken';
      form.status = FormStatus.error;
      await tester.pump();
      expect(find.text('The slug is already taken'), findsOneWidget);
    });

    testWidgets('dirty and invalid: the fields that need attention', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.dirty)
        ..errors = {'name': 'Required', 'email': 'Invalid', 'phone': null};
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));

      final status = find.text('2 fields need attention');
      expect(status, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(status).text.style!.color,
        irisPalette.dangerText,
      );
      expect(find.textContaining('No changes'), findsNothing);
      expect(
        find.ancestor(of: status, matching: find.byType(Tappable)),
        findsNothing,
        reason: 'no fields to reveal, so no dead button',
      );
      expect(_button(tester, 'Save').onPressed, isNull);
      expect(_tipOn(tester, 'Save'), '2 fields need attention');
      expect(_button(tester, 'Discard').onPressed, isNotNull);

      form.errors = {'name': 'Required'};
      await tester.pump();
      expect(find.text('1 field needs attention'), findsOneWidget);
    });
  });

  group('focus the first invalid field', () {
    late FormFieldRegistry fields;
    late List<FocusNode> nodes;

    Widget page(FormController form) => _host(
      FormFieldScope(
        registry: fields,
        child: Column(
          children: [
            FormSaveBar(controller: form, commitLabel: 'Save'),
            for (final (i, id) in ['name', 'email', 'phone'].indexed)
              TextField(key: ValueKey(id), focusNode: nodes[i]),
          ],
        ),
      ),
    );

    setUp(() {
      nodes = [for (var i = 0; i < 3; i++) FocusNode()];
      fields = FormFieldRegistry();
      for (final (i, id) in ['name', 'email', 'phone'].indexed) {
        fields.register(
          FormFieldEntry(id: id, label: id, focus: nodes[i].requestFocus),
        );
      }
    });

    tearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });

    testWidgets('from the status', (tester) async {
      final form = _Form(status: FormStatus.dirty)
        ..errors = {'email': 'Invalid', 'phone': 'Required'};
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));

      await tester.tap(find.text('2 fields need attention'));
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue, reason: 'email is first');
      expect(form.submits, 0);
    });

    testWidgets('from Cmd+S', (tester) async {
      final form = _Form(status: FormStatus.dirty)..errors = {'phone': 'Req'};
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));
      nodes[0].requestFocus();
      await tester.pump();

      await _pressSave(tester, meta: true);
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue);
      expect(form.submits, 0);
    });

    testWidgets('FormActions in a header, given the body’s registry', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.dirty)..errors = {'name': 'Req'};
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FormActions(controller: form, fields: fields),
              FormFieldScope(
                registry: fields,
                child: TextField(focusNode: nodes[0]),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('1 field needs attention'));
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);
    });
  });

  group('Discard', () {
    testWidgets('is present but disabled while clean, not inserted on the '
        'first edit', (tester) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));
      final clean = tester.getRect(find.text('Discard'));
      expect(_button(tester, 'Discard').onPressed, isNull);

      form.status = FormStatus.dirty;
      await tester.pump();
      expect(tester.getRect(find.text('Discard')), clean);
      expect(_button(tester, 'Discard').onPressed, isNotNull);
    });

    testWidgets('FormActions too', (tester) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          Center(
            child: FormActions(
              controller: form,
              commitLabel: 'Save',
              showDiscard: true,
            ),
          ),
        ),
      );
      expect(find.text('Discard'), findsOneWidget);
      expect(_button(tester, 'Discard').onPressed, isNull);
    });
  });

  group('no shift while saving', () {
    Future<Map<String, Rect>> rects(
      WidgetTester tester,
      List<String> labels,
    ) async => {
      for (final label in labels)
        label: tester.getRect(
          find.ancestor(of: find.text(label), matching: find.byType(Button)),
        ),
    };

    testWidgets('FormSaveBar: unsaved → saving → saved', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form));
      final unsaved = await rects(tester, ['Discard', 'Save']);
      final statusEnd = tester.getRect(find.text('Unsaved changes')).right;

      form.status = FormStatus.submitting;
      await tester.pump();
      expect(await rects(tester, ['Discard', 'Save']), unsaved);
      expect(tester.getRect(find.text('Saving…')).right, statusEnd);

      form.status = FormStatus.submitted;
      await tester.pump();
      expect(await rects(tester, ['Discard', 'Save']), unsaved);
    });

    testWidgets('SaveBar with Save and a split Publish', (tester) async {
      Widget bar(SaveState state, {bool publishing = false}) => _host(
        SaveBar(
          state: state,
          committing: publishing,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
          overflowActions: [
            SaveBarAction(label: 'Duplicate', onPressed: () {}),
          ],
          commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
        ),
      );
      const labels = ['Discard', 'Save', 'Publish'];
      await tester.pumpWidget(bar(SaveState.unsaved));
      final unsaved = await rects(tester, labels);
      final more = tester.getRect(find.byIcon(Icons.more_horiz));

      await tester.pumpWidget(bar(SaveState.saving));
      expect(await rects(tester, labels), unsaved);
      expect(tester.getRect(find.byIcon(Icons.more_horiz)), more);
      expect(find.byType(Spinner), findsOneWidget);

      await tester.pumpWidget(bar(SaveState.unsaved, publishing: true));
      expect(await rects(tester, labels), unsaved);
      expect(find.byType(Spinner), findsOneWidget);
    });
  });

  group('Cmd+S / Ctrl+S', () {
    Widget page(FormController form) => _host(
      Column(
        children: [
          FormSaveBar(controller: form, commitLabel: 'Save'),
          const TextField(key: ValueKey('field')),
        ],
      ),
    );

    for (final meta in [true, false]) {
      final name = meta ? 'Cmd+S' : 'Ctrl+S';
      testWidgets('$name saves from a field and is consumed', (tester) async {
        final form = _Form(status: FormStatus.dirty);
        addTearDown(form.dispose);
        await tester.pumpWidget(page(form));
        await tester.tap(find.byKey(const ValueKey('field')));
        await tester.pump();

        final handled = await _pressSave(tester, meta: meta);
        expect(form.submits, 1);
        expect(handled, isTrue, reason: 'kept from the browser');
      });
    }

    testWidgets('a save that fails shows in the status, not the zone', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.dirty)..throwOnSubmit = true;
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));

      await _pressSave(tester, meta: true);
      await tester.pump();
      expect(form.submits, 1);
      expect(form.status, FormStatus.error);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(Button, 'Save'));
      await tester.pump();
      expect(form.submits, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a clean form swallows the key and does nothing', (
      tester,
    ) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));

      expect(await _pressSave(tester, meta: true), isTrue);
      expect(form.submits, 0);
    });

    testWidgets('Shift or Alt with it is not the shortcut', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(form.submits, 0);
    });

    testWidgets('only while its route is on top', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('over'))),
      );
      await tester.pumpAndSettle();

      expect(await _pressSave(tester, meta: true), isFalse);
      expect(form.submits, 0);

      navigator.pop();
      await tester.pumpAndSettle();
      await _pressSave(tester, meta: true);
      expect(form.submits, 1);
    });

    testWidgets('unmounted, it is gone', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(page(form));
      await tester.pumpWidget(_host(const SizedBox()));

      expect(await _pressSave(tester, meta: true), isFalse);
      expect(form.submits, 0);
    });

    testWidgets('FormShortcuts wraps a custom surface; one controller in '
        'two places acts once', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          FormShortcuts(
            controller: form,
            child: Column(
              children: [
                FormActions(controller: form),
                const TextField(key: ValueKey('field')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('field')));
      await _pressSave(tester, meta: false);
      expect(form.submits, 1);
    });

    testWidgets('of two forms, the one holding focus saves', (tester) async {
      final a = _Form(status: FormStatus.dirty);
      final b = _Form(status: FormStatus.dirty);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FormShortcuts(
                controller: a,
                child: const TextField(key: ValueKey('a')),
              ),
              FormShortcuts(controller: b, child: const SizedBox()),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('a')));
      await _pressSave(tester, meta: true);
      expect(a.submits, 1);
      expect(b.submits, 0);
    });

    testWidgets(
      'under SaveFlow.publish the key is consumed, never publishing',
      (tester) async {
        final form = _Form(status: FormStatus.dirty);
        addTearDown(form.dispose);
        await tester.pumpWidget(
          _host(
            Center(
              child: FormActions(controller: form, flow: SaveFlow.publish),
            ),
          ),
        );
        expect(await _pressSave(tester, meta: true), isTrue);
        expect(form.submits, 0);
      },
    );

    testWidgets('saveShortcut: false opts out', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(FormSaveBar(controller: form, saveShortcut: false)),
      );
      expect(await _pressSave(tester, meta: true), isFalse);
      expect(form.submits, 0);
    });
  });

  group('semantics', () {
    testWidgets('the status is a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(_bar(form, fields: FormFieldRegistry()));

      bool live(String text) => tester
          .getSemantics(find.text(text))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion;
      expect(live('Unsaved changes'), isTrue);

      form.status = FormStatus.submitting;
      await tester.pump();
      expect(live('Saving…'), isTrue);

      form.errors = {'name': 'Required'};
      form.status = FormStatus.dirty;
      await tester.pump();
      // One node: a button named by the message, which is the live region.
      final invalid = tester
          .getSemantics(find.text('1 field needs attention'))
          .getSemanticsData();
      expect(invalid.flagsCollection.isLiveRegion, isTrue);
      expect(invalid.flagsCollection.isButton, isTrue);
      expect(invalid.label, '1 field needs attention');
      semantics.dispose();
    });

    testWidgets('the compact status names itself', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: const AdminBreakpoints().medium - 1,
              child: SaveBar(state: SaveState.unsaved, onSave: () {}),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Unsaved changes'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel('Unsaved changes'),
      );
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    });

    testWidgets('the split caret is named and the overflow is "More actions"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          Center(
            child: FormActions(
              controller: form,
              overflowActions: [
                SaveBarAction(label: 'Duplicate', onPressed: () {}),
              ],
              commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
            ),
          ),
        ),
      );
      expect(find.byType(SplitButton), findsOneWidget);
      expect(
        tester.widget<SplitButton>(find.byType(SplitButton)).menuSemanticLabel,
        'More publish options',
      );
      expect(find.bySemanticsLabel('More publish options'), findsOneWidget);
      expect(find.bySemanticsLabel('More actions'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('the default submit label follows the flow', () {
    for (final flow in SaveFlow.values) {
      final publish = flow == SaveFlow.publish;
      final label = publish ? 'Publish' : 'Save';
      final saving = publish ? 'Publishing…' : 'Saving…';
      testWidgets('FormActions, ${flow.name} → "$label"', (tester) async {
        final form = _Form(status: FormStatus.dirty);
        addTearDown(form.dispose);
        await tester.pumpWidget(
          _host(
            Center(
              child: FormActions(controller: form, flow: flow),
            ),
          ),
        );
        expect(find.widgetWithText(Button, label), findsOneWidget);
        await tester.tap(find.text(label));
        expect(form.submits, 1);

        form.status = FormStatus.submitting;
        await tester.pump();
        expect(find.text(saving), findsOneWidget);
      });

      testWidgets('FormSaveBar, ${flow.name} → "$label"', (tester) async {
        final form = _Form(status: FormStatus.dirty);
        addTearDown(form.dispose);
        await tester.pumpWidget(
          _host(FormSaveBar(controller: form, flow: flow)),
        );
        expect(find.widgetWithText(Button, label), findsOneWidget);
      });
    }

    testWidgets('a label of the caller’s own still wins', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FormSaveBar(controller: form, commitLabel: 'Go live'),
              FormActions(
                controller: form,
                flow: SaveFlow.publish,
                commitLabel: 'Update',
                saveShortcut: false,
              ),
            ],
          ),
        ),
      );
      expect(find.widgetWithText(Button, 'Go live'), findsOneWidget);
      expect(find.widgetWithText(Button, 'Update'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Publish'), findsNothing);
    });
  });

  testWidgets('SaveCluster alone keeps its buttons in one row', (tester) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: SaveCluster(
            state: SaveState.unsaved,
            onDiscard: () {},
            onSave: () {},
          ),
        ),
      ),
    );
    final discard = tester.getRect(find.text('Discard'));
    final save = tester.getRect(find.text('Save'));
    expect(discard.center.dy, save.center.dy);
    expect(discard.right, lessThan(save.left));
  });
}

/// Presses S with Cmd ([meta]) or Ctrl held; returns whether the press was
/// handled.
Future<bool> _pressSave(WidgetTester tester, {required bool meta}) async {
  final modifier = meta
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(modifier);
  return handled;
}
