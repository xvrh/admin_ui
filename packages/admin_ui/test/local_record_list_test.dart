import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Typed handles, hand-written here exactly as codegen would emit them for an
// entity — over the core FormScope/RecordScope types, so the same handles run
// over LocalScope and over an app's own scope (a draft, say).
extension type ContactFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  RecordListCell<PhoneFields> get phones =>
      _s.recordList('phones', build: PhoneFields.new);
}

extension type PhoneFields(RecordScope _e) {
  ValueCell<String> get label => _e.text('label');
  ValueCell<String> get number => _e.text('number');
  ValueCell<bool> get preferred => _e.boolean('preferred');
  SocialFields get social => SocialFields(_e.sub('social'));
  RecordListCell<NoteFields> get notes =>
      _e.recordList('notes', build: NoteFields.new);
  void remove() => _e.remove();
}

extension type SocialFields(FormScope _s) {
  ValueCell<String> get handle => _s.text('handle');
}

extension type NoteFields(RecordScope _e) {
  ValueCell<String> get text => _e.text('text');
}

void main() {
  test('add/remove/removeAt drive elements and notify structurally', () {
    final scope = LocalScope();
    final contact = ContactFields(scope);
    var notified = 0;
    contact.phones.addListener(() => notified++);

    expect(contact.phones.elements, isEmpty);
    contact.phones.add();
    contact.phones.add();
    expect(contact.phones.elements, hasLength(2));
    expect(notified, 2);

    // A value edit must NOT notify the list (structural changes only).
    contact.phones.elements.first.number.set('123');
    expect(notified, 2);

    contact.phones.removeAt(0);
    expect(contact.phones.elements, hasLength(1));
    expect(notified, 3);

    // Element-side remove() (the row's own delete action).
    contact.phones.elements.single.remove();
    expect(contact.phones.elements, isEmpty);
    expect(notified, 4);

    scope.dispose();
  });

  test('cells are stable across elements rebuilds and keyed per element', () {
    final scope = LocalScope();
    final contact = ContactFields(scope);
    contact.phones.add();
    contact.phones.add();

    final a = contact.phones.elements[0];
    final b = contact.phones.elements[1];
    a.number.set('111');
    b.number.set('222');

    // A fresh elements read lands on the same cells.
    final again = contact.phones.elements;
    expect(again[0].number.value, '111');
    expect(again[1].number.value, '222');
    expect(identical(again[0].number, a.number), isTrue);

    // Ids are distinct and namespaced under the list.
    expect(again[0].number.id, isNot(again[1].number.id));
    expect(again[0].number.id, startsWith('phones/'));

    scope.dispose();
  });

  test('move reorders keeping values with their row', () {
    final scope = LocalScope();
    final contact = ContactFields(scope);
    contact.phones.add();
    contact.phones.add();
    contact.phones.add();
    final els = contact.phones.elements;
    els[0].label.set('home');
    els[1].label.set('work');
    els[2].label.set('cell');

    contact.phones.move(0, 2);
    expect(
      [for (final e in contact.phones.elements) e.label.value],
      ['work', 'cell', 'home'],
    );

    scope.dispose();
  });

  test('nested sub-object and nested record list', () {
    final scope = LocalScope();
    final contact = ContactFields(scope);
    contact.phones.add();
    final phone = contact.phones.elements.single;

    phone.social.handle.set('@ada');
    expect(phone.social.handle.value, '@ada');

    phone.notes.add();
    phone.notes.elements.single.text.set('primary line');
    expect(phone.notes.elements.single.text.value, 'primary line');

    // The nested list is its own cell, memoized on the element.
    expect(identical(phone.notes, contact.phones.elements.single.notes), true);

    scope.dispose();
  });

  test('removed rows keep their cells until dispose; dispose cascades', () {
    final scope = LocalScope();
    final contact = ContactFields(scope);
    contact.phones.add();
    final cell = contact.phones.elements.single.number..set('999');
    contact.phones.removeAt(0);

    // Teardown-frame reads on the removed row's cell must not throw.
    expect(cell.value, '999');

    scope.dispose();
    // After scope dispose the cell is disposed — listening now throws.
    expect(() => cell.addListener(() {}), throwsFlutterError);
  });
}
