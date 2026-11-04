import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

typedef Page = ({String title, Map<String, String> meta});

extension type PageFields(FormScope _s) {
  ValueCell<String> get title => _s.text('title');
  ValueCell<Map<String, String>> get meta => _s.map('meta');

  Page read() => (title: title.value, meta: meta.value);

  void fill(Page page) {
    title.set(page.title);
    meta.set(page.meta);
  }
}

extension type Section(RecordScope _e) {
  ValueCell<Map<String, String>> get attributes => _e.map('attributes');
}

const _loaded = (title: 'Home', meta: {'og:type': 'website'});

ValueFormController<Page> pageForm({Future<void> Function(Page)? onSubmit}) =>
    ValueFormController<Page>(
      read: (s) => PageFields(s).read(),
      write: (s, page) => PageFields(s).fill(page),
      initial: _loaded,
      onSubmit: onSubmit ?? (_) async {},
    );

void main() {
  group('LocalScope.map', () {
    test('starts empty and holds what it is set to, in order', () {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final meta = scope.map('meta');
      expect(meta.value, isEmpty);
      expect(meta.id, 'meta');
      expect(identical(scope.map('meta'), meta), isTrue);

      var notified = 0;
      meta
        ..addListener(() => notified++)
        ..set({'b': '2', 'a': '1'});
      expect(notified, 1);
      expect(meta.value.keys, ['b', 'a']);
    });

    test('keeps a copy: the map it was given can change, the cell not', () {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final given = {'a': '1'};
      scope.map('meta').set(given);
      given['b'] = '2';
      expect(scope.map('meta').value, {'a': '1'});
      expect(() => scope.map('meta').value['c'] = '3', throwsUnsupportedError);
    });

    test('a sub-scope and a record element hand out their own maps', () {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      expect(scope.sub('seo').map('meta').id, 'seo.meta');
      scope.sub('seo').map('meta').set({'robots': 'noindex'});
      expect(scope.map('seo.meta').value, {'robots': 'noindex'});

      final sections = scope.recordList('sections', build: Section.new)..add();
      final first = sections.elements.single.attributes;
      first.set({'id': 'intro'});
      expect(sections.elements.single.attributes.value, {'id': 'intro'});
      expect(first.id, startsWith('sections/'));
    });
  });

  group('ValueFormController over a map cell', () {
    test('an edit makes the form dirty; the same entries back make it '
        'clean', () {
      final form = pageForm();
      addTearDown(form.dispose);
      final f = PageFields(form.scope);
      expect(form.isDirty, isFalse);

      f.meta.set({...f.meta.value, 'og:title': 'Home'});
      expect(form.isDirty, isTrue);
      expect(form.status, FormStatus.dirty);

      f.meta.set({'og:type': 'website'});
      expect(form.isDirty, isFalse);
    });

    test('discard puts the map back', () {
      final form = pageForm();
      addTearDown(form.dispose);
      final f = PageFields(form.scope);
      f.meta.set({'robots': 'noindex'});

      form.reset();

      expect(f.meta.value, {'og:type': 'website'});
      expect(form.isDirty, isFalse);
      expect(form.status, FormStatus.clean);
    });

    test('save sends the map and makes it the baseline', () async {
      final sent = <Page>[];
      final form = pageForm(onSubmit: (page) async => sent.add(page));
      addTearDown(form.dispose);
      final f = PageFields(form.scope);
      f.meta.set({'og:type': 'article', 'og:title': 'News'});

      await form.submit();

      expect(sent.single.meta, {'og:type': 'article', 'og:title': 'News'});
      expect(form.isDirty, isFalse);
      expect(form.status, FormStatus.submitted);
      f.meta.set({'og:type': 'website'});
      expect(form.isDirty, isTrue, reason: 'the saved map is the baseline');
      form.reset();
      expect(f.meta.value, {'og:type': 'article', 'og:title': 'News'});
    });

    test('a required rule reads the map', () async {
      final form = ValueFormController<Page>(
        read: (s) => PageFields(s).read(),
        write: (s, page) => PageFields(s).fill(page),
        initial: (title: 'Home', meta: const {}),
        rules: (s) => [
          FieldRules(PageFields(s).meta, validators: [Validators.required()]),
        ],
        requireChanges: false,
      );
      addTearDown(form.dispose);
      final f = PageFields(form.scope);
      expect(form.isRequired(f.meta.id), isTrue);
      expect(form.allErrors[f.meta.id], 'Required');
      f.meta.set({'a': '1'});
      expect(form.allErrors, isEmpty);
    });
  });

  testWidgets('KeyValueField edits the map cell it is bound to', (
    tester,
  ) async {
    final form = pageForm();
    addTearDown(form.dispose);
    final f = PageFields(form.scope);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ValueForm(
            controller: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [KeyValueField(f.meta, label: 'Meta tags')],
            ),
          ),
        ),
      ),
    );
    expect(find.text('og:type'), findsOneWidget);
    expect(find.text('website'), findsOneWidget);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(KeyValueField),
            matching: find.byType(EditableText),
          )
          .at(1),
      'article',
    );
    await tester.pump();

    expect(f.meta.value, {'og:type': 'article'});
    expect(form.isDirty, isTrue);

    form.reset();
    await tester.pump();
    expect(find.text('website'), findsOneWidget);
  });
}
