import 'dart:ui' show SemanticsValidationResult;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = defaultTokens;
final _p = _tokens.palette;

class _Cell<V> extends ValueCell<V> with ChangeNotifier {
  @override
  final String id;
  V _value;

  _Cell(this.id, this._value);

  @override
  V get value => _value;

  @override
  void set(V value) {
    _value = value;
    notifyListeners();
  }
}

class _Parts extends RecordListCell<String> {
  @override
  final String id = 'parts';
  @override
  final List<String> elements = ['Lens hood', 'Strap'];

  @override
  void add() {
    elements.add('Part');
    notifyListeners();
  }

  @override
  void removeAt(int index) {
    elements.removeAt(index);
    notifyListeners();
  }

  @override
  void move(int from, int to) {}
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  ),
);

Widget _input() => Builder(
  builder: (context) => TextField(
    readOnly: FieldStateScope.of(context).readOnly,
    style: fieldTextStyle(context),
    decoration: fieldInputDecoration(context, hint: 'h'),
  ),
);

/// The outline the text field's decoration draws with no interaction.
BorderSide _restingBorder(WidgetTester tester) {
  final d = tester.widget<InputDecorator>(find.byType(InputDecorator));
  return WidgetStateProperty.resolveAs(d.decoration.border, {})!.borderSide;
}

/// Whether some ancestor of the node showing [text] is labelled [label].
bool _groupNamed(WidgetTester tester, String text, String label) {
  SemanticsNode? node = tester.getSemantics(find.text(text)).parent;
  while (node != null) {
    if (node.label == label) return true;
    node = node.parent;
  }
  return false;
}

const _locales = [
  LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
];

void main() {
  group('FieldShell', () {
    testWidgets('a required field stars its label and announces itself '
        'required', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Title',
            required: true,
            mergeSemantics: false,
            child: _input(),
          ),
        ),
      );
      final label = tester.getRect(find.text('TITLE'));
      final star = tester.getRect(find.text('*'));
      expect(star.left, greaterThanOrEqualTo(label.right));
      expect(
        tester.widget<Text>(find.text('*')).style?.color ??
            tester
                .widget<RichText>(
                  find.descendant(
                    of: find.text('*'),
                    matching: find.byType(RichText),
                  ),
                )
                .text
                .style!
                .color,
        _p.dangerText,
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: 'Title\nh', isTextField: true, isRequired: true),
      );
      expect(find.bySemanticsLabel('*'), findsNothing);
      handle.dispose();
    });

    testWidgets('the description is a caption 4 under the label row, the body '
        '8 under it, and the body\'s hint', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Handle',
            description: 'Used in the page address.',
            mergeSemantics: false,
            child: _input(),
          ),
        ),
      );
      final top = tester.getTopLeft(find.byType(FieldShell)).dy;
      final description = tester.getRect(
        find.text('Used in the page address.'),
      );
      final control = tester.getRect(find.byType(TextField));
      expect(description.top, top + 24 + 4);
      expect(control.top, description.bottom + 8);
      expect(
        tester.widget<Text>(find.text('Used in the page address.')).style,
        _tokens.typography.fieldDescription,
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(hint: 'Used in the page address.'),
      );
      handle.dispose();
    });

    testWidgets('an error reddens the body, sits 8 under it, its glyph flush '
        'with the label, and is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Slug',
            errorText: 'Already taken',
            mergeSemantics: false,
            child: _input(),
          ),
        ),
      );
      expect(_restingBorder(tester), BorderSide(color: _p.danger, width: 1.5));
      final label = tester.getRect(find.text('SLUG'));
      final control = tester.getRect(find.byType(TextField));
      final message = tester.getRect(find.text('Already taken'));
      expect(message.top, control.bottom + 8);
      final glyph = tester.getRect(find.byIcon(Icons.error_outline_rounded));
      expect(glyph.left, label.left);
      expect(message.left, glyph.right + 6);
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(
          hint: 'Already taken',
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
      expect(
        tester.getSemantics(find.text('Already taken')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('enabled, read-only and the error reach the body through the '
        'FieldStateScope', (tester) async {
      Future<FieldState> stateOf(FieldShell Function(Widget) shell) async {
        late FieldState state;
        await tester.pumpWidget(
          _host(
            shell(
              Builder(
                builder: (context) {
                  state = FieldStateScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        return state;
      }

      expect(
        await stateOf((c) => FieldShell(label: 'A', child: c)),
        const FieldState(),
      );
      expect(
        await stateOf((c) => FieldShell(label: 'A', errorText: 'x', child: c)),
        const FieldState(invalid: true),
      );
      expect(
        await stateOf((c) => FieldShell(label: 'A', enabled: false, child: c)),
        const FieldState(enabled: false),
      );
      expect(
        await stateOf((c) => FieldShell(label: 'A', readOnly: true, child: c)),
        const FieldState(readOnly: true),
      );
    });

    testWidgets('the label dims with a disabled field', (tester) async {
      await tester.pumpWidget(
        _host(FieldShell(label: 'Handle', enabled: false, child: _input())),
      );
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.text('HANDLE'),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        _p.foregroundSubtle,
      );
    });

    testWidgets('the label row is the 24px slot with or without capabilities', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldShell(
                  key: const Key('bare'),
                  label: 'SKU',
                  child: _input(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                // Room for the label beside every capability.
                flex: 2,
                child: FieldShell(
                  key: const Key('full'),
                  label: 'Title',
                  help: const HelpButton(text: 'Shown as the heading.'),
                  language: LanguagePill(
                    value: const {'en'},
                    activeLocale: 'en',
                    locales: _locales,
                    sourceLocale: 'en',
                    onChanged: (_) {},
                  ),
                  comments: const CommentsButton(count: 3),
                  history: const HistoryButton(draft: 'a', baseline: 'b'),
                  child: _input(),
                ),
              ),
            ],
          ),
        ),
      );
      Rect controlOf(String key) => tester.getRect(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      );
      final top = tester.getTopLeft(find.byKey(const Key('bare'))).dy;
      expect(controlOf('bare').top, top + 24 + 8);
      expect(controlOf('full').top, controlOf('bare').top);
      // Every capability is centred in the row, the comment count too.
      for (final capability in [
        find.byType(HelpButton),
        find.byType(LanguagePill),
        find.byType(CommentsButton),
        find.byType(HistoryButton),
      ]) {
        final rect = tester.getRect(capability);
        expect(rect.height, 24, reason: '$capability');
        expect(rect.top, top, reason: '$capability');
      }
      final count = tester.getRect(find.text('3'));
      expect(count.top, greaterThanOrEqualTo(top));
      expect(count.bottom, lessThanOrEqualTo(top + 24));
    });

    testWidgets('a narrow field wraps its capabilities under the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: FieldShell(
                label: 'Title',
                help: const HelpButton(text: 'Shown as the heading.'),
                language: LanguagePill(
                  value: const {'en'},
                  activeLocale: 'en',
                  locales: _locales,
                  sourceLocale: 'en',
                  onChanged: (_) {},
                ),
                comments: const CommentsButton(count: 3),
                history: const HistoryButton(draft: 'a', baseline: 'b'),
                modified: true,
                child: _input(),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final shell = tester.getRect(find.byType(FieldShell));
      final label = tester.getRect(find.text('TITLE'));
      // The label keeps its line, whole, with its help dot beside it.
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('TITLE'))
            .didExceedMaxLines,
        isFalse,
      );
      expect(label.center.dy, shell.top + 12);
      expect(tester.getRect(find.byType(HelpButton)).top, shell.top);
      // The capabilities wrap under it, still at the end, all inside.
      for (final capability in [
        find.byType(LanguagePill),
        find.byType(CommentsButton),
        find.byType(HistoryButton),
      ]) {
        final rect = tester.getRect(capability);
        expect(rect.top, greaterThanOrEqualTo(shell.top + 24 + 4));
        expect(rect.right, lessThanOrEqualTo(shell.right));
        expect(rect.left, greaterThanOrEqualTo(shell.left));
      }
      expect(tester.getRect(find.byType(HistoryButton)).right, shell.right);
    });

    testWidgets('a history button showing "Edited" replaces the label marker', (
      tester,
    ) async {
      Future<void> pump(Widget? history) => tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Title',
            modified: true,
            history: history,
            child: _input(),
          ),
        ),
      );
      await pump(null);
      expect(find.text('Edited'), findsOneWidget);
      await pump(const HistoryButton(draft: 'a', baseline: 'b'));
      expect(find.text('Edited'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HistoryButton),
          matching: find.text('Edited'),
        ),
        findsOneWidget,
      );
      await pump(const HistoryButton(draft: 'a', baseline: 'a'));
      expect(find.text('Edited'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HistoryButton),
          matching: find.text('Edited'),
        ),
        findsNothing,
      );
    });

    testWidgets('a body of several controls keeps each its own node, in a '
        'group the label names', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Visibility',
            mergeSemantics: false,
            child: Choice<String>(
              options: const [
                ChoiceOption('public', 'Public'),
                ChoiceOption('private', 'Private'),
              ],
              value: 'public',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final public = tester.getSemantics(find.text('Public'));
      final private = tester.getSemantics(find.text('Private'));
      expect(public, isNot(same(private)));
      expect(
        public,
        isSemantics(label: 'Public', isInMutuallyExclusiveGroup: true),
      );
      expect(private, isSemantics(label: 'Private'));
      expect(_groupNamed(tester, 'Public', 'Visibility'), isTrue);
      handle.dispose();
    });

    testWidgets('a lone trigger merges with the label into one button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SelectField(
            _Cell('status', 'review'),
            label: 'Status',
            options: const [
              SelectOption(value: 'draft', label: 'Draft'),
              SelectOption(value: 'review', label: 'In review'),
            ],
          ),
        ),
      );
      final data = tester
          .getSemantics(find.text('In review'))
          .getSemanticsData();
      expect(data.label, 'Status\nIn review');
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('Presets', () {
    testWidgets('a preset reads its message from the FieldErrorsScope, and '
        'its own error wins', (tester) async {
      Future<void> pump(Map<String, String?> errors) => tester.pumpWidget(
        _host(
          FieldErrorsScope(
            errors: errors,
            child: Column(
              children: [
                Field(_Cell('slug', 'about us'), label: 'Slug'),
                Field(_Cell('title', 'About'), label: 'Title'),
                Field(_Cell('name', ''), label: 'Name', errorText: 'Own'),
              ],
            ),
          ),
        ),
      );
      await pump({'slug': 'Use dashes, not spaces.', 'name': 'From scope'});
      expect(find.text('Use dashes, not spaces.'), findsOneWidget);
      expect(find.text('Own'), findsOneWidget);
      expect(find.text('From scope'), findsNothing);
      final slug = tester.widget<InputDecorator>(
        find.descendant(
          of: find.widgetWithText(FieldShell, 'SLUG'),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(
        WidgetStateProperty.resolveAs(slug.decoration.border, {})!.borderSide,
        BorderSide(color: _p.danger, width: 1.5),
      );

      await pump({'slug': null});
      expect(find.text('Use dashes, not spaces.'), findsNothing);
    });

    testWidgets('a FormErrorsScope shows what its controller reports, as it '
        'changes', (tester) async {
      final form = _Errors();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(
          FormErrorsScope(
            controller: form,
            child: Field(_Cell('slug', 'about us'), label: 'Slug'),
          ),
        ),
      );
      expect(find.byType(FieldMessage), findsNothing);
      form.errors = {'slug': 'Use dashes, not spaces.'};
      await tester.pump();
      expect(find.text('Use dashes, not spaces.'), findsOneWidget);
      form.errors = const {};
      await tester.pump();
      expect(find.text('Use dashes, not spaces.'), findsNothing);
    });

    testWidgets('a text field takes its text-area, limit, keyboard and affix '
        'options, and turns read-only or disabled', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Field(
                _Cell('notes', ''),
                label: 'Notes',
                minLines: 3,
                maxLines: 6,
                maxLength: 280,
              ),
              Field(
                _Cell('weight', '1.2'),
                label: 'Weight',
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.transactionAmount],
                prefix: '≈',
                suffix: 'kg',
              ),
              Field(_Cell('sku', 'A-1'), label: 'SKU', readOnly: true),
              Field(_Cell('handle', 'a'), label: 'Handle', enabled: false),
            ],
          ),
        ),
      );
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final [notes, weight, sku, handle] = fields.toList();
      expect(notes.minLines, 3);
      expect(notes.maxLines, 6);
      expect(notes.maxLength, 280);
      expect(notes.keyboardType, TextInputType.multiline);
      expect(find.text('0/280'), findsOneWidget);
      expect(weight.keyboardType, TextInputType.number);
      expect(weight.autofillHints, [AutofillHints.transactionAmount]);
      expect(find.text('≈'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(sku.readOnly, isTrue);
      expect(handle.decoration!.enabled, isFalse);
    });

    testWidgets('a required number can be emptied to retype it; an optional '
        'one empties to null', (tester) async {
      final count = _Cell<int>('count', 5);
      final limit = _Cell<int?>('limit', 5);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              NumberField(count, label: 'Count'),
              OptionalNumberField(limit, label: 'Limit'),
            ],
          ),
        ),
      );
      Future<void> blur() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
      }

      final inputs = find.byType(EditableText);
      await tester.enterText(inputs.at(0), '');
      await blur();
      expect(count.value, 5);
      await tester.enterText(inputs.at(0), '12');
      await blur();
      expect(count.value, 12);

      await tester.enterText(inputs.at(1), '');
      await blur();
      expect(limit.value, isNull);
    });
  });

  group('RecordListField', () {
    testWidgets('names each remove by its item, and drops add and remove '
        'while read-only', (tester) async {
      final handle = tester.ensureSemantics();
      final parts = _Parts();
      Future<void> pump({bool readOnly = false}) => tester.pumpWidget(
        _host(
          RecordListField<String>(
            parts,
            label: 'Parts',
            readOnly: readOnly,
            itemLabel: (part, _) => part,
            item: Text.new,
          ),
        ),
      );
      await pump();
      await tester.tap(find.bySemanticsLabel('Remove Strap'));
      await tester.pump();
      expect(parts.elements, ['Lens hood']);
      expect(find.bySemanticsLabel('Remove Lens hood'), findsOneWidget);
      expect(find.text('Add item'), findsOneWidget);

      await pump(readOnly: true);
      expect(find.bySemanticsLabel('Remove Lens hood'), findsNothing);
      expect(find.text('Add item'), findsNothing);
      handle.dispose();
    });
  });

  group('FieldGroup', () {
    testWidgets('the title is a heading above a smaller description', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const FieldGroup(
            title: 'Pricing',
            description: 'What customers pay.',
            children: [Text('field')],
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Pricing'));
      final description = tester.widget<Text>(find.text('What customers pay.'));
      expect(title.style, _tokens.typography.heading);
      expect(description.style!.fontSize, lessThan(title.style!.fontSize!));
      expect(
        description.style!.fontSize,
        greaterThan(_tokens.typography.fieldLabel.fontSize!),
      );
      expect(
        tester.getRect(find.text('What customers pay.')).top,
        tester.getRect(find.text('Pricing')).bottom + 4,
      );
      expect(
        tester.getSemantics(find.text('Pricing')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });

  group('Capabilities', () {
    testWidgets('comments and history sit in the 24px inline slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              CommentsButton(count: 0),
              CommentsButton(count: 12),
              HistoryButton(draft: 'a', baseline: 'a'),
              HistoryButton(draft: 'a', baseline: 'b'),
            ],
          ),
        ),
      );
      for (final element in [
        ...find.byType(CommentsButton).evaluate(),
        ...find.byType(HistoryButton).evaluate(),
      ]) {
        expect(tester.getSize(find.byWidget(element.widget)).height, 24);
      }
    });
  });
}

/// A form whose only state is the errors a test sets.
class _Errors extends FormController {
  Map<String, String?> _errors = const {};

  @override
  Map<String, String?> get errors => _errors;
  set errors(Map<String, String?> value) {
    _errors = value;
    notifyListeners();
  }

  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}
