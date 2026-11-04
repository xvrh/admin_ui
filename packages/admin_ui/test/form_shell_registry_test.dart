import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _form(
  FormFieldRegistry fields,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  PresenceChannel? presence,
  void Function(String? fieldId)? onFocus,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: FieldFocusScope(
        onFocus: onFocus ?? (_) {},
        child: FieldPresenceScope(
          channel: presence,
          child: FormFieldScope(registry: fields, child: child),
        ),
      ),
    ),
  ),
);

Widget _field(String label, {String? id, Key? key}) => FieldShell(
  key: key,
  label: label,
  fieldId: id,
  child: InputField(value: label),
);

List<String> _ids(FormFieldRegistry fields) => [
  for (final entry in fields.entries) entry.id,
];

/// Records what a shell publishes; no peers.
class _Presence implements PresenceChannel {
  final published = <String>[];

  @override
  int get clientId => 1;

  @override
  Map<int, Map<String, Object?>> get states => {};

  @override
  void Function() onChange(void Function() cb) => () {};

  @override
  void setLocalField(String fieldId) => published.add(fieldId);
}

void main() {
  group('a field without an id', () {
    testWidgets('registers under a key of its own, never its label', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      await tester.pumpWidget(
        _form(fields, Column(children: [_field('Title'), _field('Title')])),
      );
      final entries = fields.entries.toList();
      expect(entries, hasLength(2), reason: 'both are listed');
      expect(entries.map((e) => e.label), ['Title', 'Title']);
      expect(entries.map((e) => e.id).toSet(), hasLength(2));
      expect(entries.map((e) => e.id), isNot(contains('Title')));
    });

    testWidgets('two with one label survive each other going away', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      Widget tree({bool first = true, bool second = true}) => _form(
        fields,
        Column(
          children: [
            if (first) _field('Title', key: const Key('first')),
            if (second) _field('Title', key: const Key('second')),
          ],
        ),
      );
      await tester.pumpWidget(tree());
      final [firstId, secondId] = _ids(fields);

      await tester.pumpWidget(tree(first: false));
      expect(_ids(fields), [secondId]);

      await tester.pumpWidget(tree());
      await tester.pumpWidget(tree(second: false));
      expect(_ids(fields), hasLength(1));
      expect(_ids(fields), isNot(contains(secondId)));
      expect(_ids(fields).single, isNot(firstId), reason: 'a new state');
    });

    testWidgets('reports neither focus nor presence', (tester) async {
      final fields = FormFieldRegistry();
      final presence = _Presence();
      final focused = <String?>[];
      await tester.pumpWidget(
        _form(
          fields,
          Column(
            children: [
              _field('Title'),
              _field('Slug', id: 'slug'),
            ],
          ),
          presence: presence,
          onFocus: focused.add,
        ),
      );
      expect(
        find.byType(FieldPresenceRing),
        findsOneWidget,
        reason: 'only the field with an id is framed',
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      expect(focused, isEmpty);
      expect(presence.published, isEmpty);

      await tester.tap(find.byType(EditableText).last);
      await tester.pump();
      expect(focused, ['slug']);
      expect(presence.published, ['slug']);

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      expect(focused, ['slug'], reason: 'losing focus reports nothing');
    });
  });

  group('re-registering', () {
    testWidgets('a changed fieldId replaces the old entry', (tester) async {
      final fields = FormFieldRegistry();
      await tester.pumpWidget(_form(fields, _field('Title', id: 'a')));
      expect(_ids(fields), ['a']);
      await tester.pumpWidget(_form(fields, _field('Title', id: 'b')));
      expect(_ids(fields), ['b']);
    });

    testWidgets('a changed label is listed as it now reads', (tester) async {
      final fields = FormFieldRegistry();
      await tester.pumpWidget(_form(fields, _field('Title', id: 'a')));
      await tester.pumpWidget(_form(fields, _field('Headline', id: 'a')));
      expect(fields.entries.single.label, 'Headline');
    });

    testWidgets('an unlabelled field keeps its own key across a new label', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      await tester.pumpWidget(_form(fields, _field('Title')));
      final id = _ids(fields).single;
      await tester.pumpWidget(_form(fields, _field('Headline')));
      expect(_ids(fields), [id]);
      expect(fields.entries.single.label, 'Headline');
    });

    testWidgets('disposing a duplicate leaves the field that replaced it', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      Widget tree({bool first = true}) => _form(
        fields,
        Column(
          children: [
            if (first) _field('Title', id: 'title', key: const Key('first')),
            _field('Title (copy)', id: 'title', key: const Key('second')),
          ],
        ),
      );
      await tester.pumpWidget(tree());
      await tester.pumpWidget(tree(first: false));
      expect(_ids(fields), ['title']);
      expect(fields.entries.single.label, 'Title (copy)');
    });
  });

  group('FormFieldRegistry', () {
    test('unregister by id alone still removes the field', () {
      final fields = FormFieldRegistry()
        ..register(FormFieldEntry(id: 'a', label: 'A', focus: () {}));
      fields.unregister('a');
      expect(fields.entries, isEmpty);
    });

    test('unregister with a stale entry keeps the current one', () {
      final stale = FormFieldEntry(id: 'a', label: 'A', focus: () {});
      final current = FormFieldEntry(id: 'a', label: 'A2', focus: () {});
      final fields = FormFieldRegistry()
        ..register(stale)
        ..register(current);
      fields.unregister('a', stale);
      expect(fields.entries.single, same(current));
      fields.unregister('a', current);
      expect(fields.entries, isEmpty);
    });

    test(
      'lists fields without bounds after those on screen, as registered',
      () {
        FormFieldEntry entry(String id, [Rect? rect]) =>
            FormFieldEntry(id: id, label: id, focus: () {}, bounds: () => rect);
        final fields = FormFieldRegistry()
          ..register(entry('off-1'))
          ..register(entry('low', const Rect.fromLTWH(0, 200, 100, 40)))
          ..register(entry('off-2'))
          ..register(entry('high', const Rect.fromLTWH(0, 100, 100, 40)));
        expect(_ids(fields), ['high', 'low', 'off-1', 'off-2']);
      },
    );
  });

  group('reading order', () {
    testWidgets('a field shown late takes its place on screen', (tester) async {
      final fields = FormFieldRegistry();
      Widget tree({required bool vat}) => _form(
        fields,
        Column(
          children: [
            _field('Name', id: 'name'),
            if (vat) _field('VAT number', id: 'vat'),
            _field('Email', id: 'email'),
          ],
        ),
      );
      await tester.pumpWidget(tree(vat: false));
      await tester.pumpWidget(tree(vat: true));
      expect(_ids(fields), ['name', 'vat', 'email']);
    });

    testWidgets('a grid reads row by row, from the start edge', (tester) async {
      for (final direction in TextDirection.values) {
        final fields = FormFieldRegistry();
        Widget tree({required bool city}) => _form(
          fields,
          direction: direction,
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _field('Street', id: 'street')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: city
                        ? _field('City', id: 'city')
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Postcode', id: 'postcode')),
                  const SizedBox(width: 16),
                  Expanded(child: _field('Country', id: 'country')),
                ],
              ),
            ],
          ),
        );
        await tester.pumpWidget(tree(city: false));
        await tester.pumpWidget(tree(city: true));
        expect(_ids(fields), [
          'street',
          'city',
          'postcode',
          'country',
        ], reason: direction.name);
      }
    });

    testWidgets('fields on a tab in the background follow those shown', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      final selection = TabSelection('seo');
      addTearDown(selection.dispose);
      await tester.pumpWidget(
        _form(
          fields,
          IndexedStack(
            index: 1,
            children: [
              TabScope(
                tabId: 'content',
                selection: selection,
                child: _field('Title', id: 'title'),
              ),
              TabScope(
                tabId: 'seo',
                selection: selection,
                child: Column(
                  children: [
                    const SizedBox(height: 200),
                    _field('Meta title', id: 'meta'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(_ids(fields), ['meta', 'title']);
      selection.select('content');
      expect(_ids(fields), ['title', 'meta']);
    });

    testWidgets('a refused submit reveals the topmost invalid field', (
      tester,
    ) async {
      final fields = FormFieldRegistry();
      Widget tree({required bool vat}) => _form(
        fields,
        Column(
          children: [
            _field('Name', id: 'name'),
            if (vat) _field('VAT number', id: 'vat'),
            _field('Email', id: 'email'),
          ],
        ),
      );
      await tester.pumpWidget(tree(vat: false));
      await tester.pumpWidget(tree(vat: true));
      final form = _Invalid({'email': 'Required', 'vat': 'Required'});
      addTearDown(form.dispose);
      expect(FormShortcuts.revealFirstInvalid(form, fields), isTrue);
      await tester.pumpAndSettle();
      final vat = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(FieldShell, 'VAT number'),
          matching: find.byType(EditableText),
        ),
      );
      expect(vat.focusNode.hasFocus, isTrue);
    });
  });
}

/// A form whose fields hold [errors].
class _Invalid extends FormController {
  _Invalid(this.errors);

  @override
  final Map<String, String> errors;

  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}
