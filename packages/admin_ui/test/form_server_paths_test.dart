// A server names the field it refuses by where it is in the value it was
// sent: a row of a list by its index, since the row's cell id is the
// form's own. What it says of a list, or of a row the form cannot follow
// to a field, shows under the list until one of its rows is edited. A
// message that names no field of the form does not keep the form from
// being saved again.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

extension type _Shop(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get city => _s.sub('billing').text('city');
  TranslatedCell<String> get tagline => _s.translated('tagline');

  /// A translated field the value does not read: no lane is handed out.
  TranslatedCell<String> get motto => _s.translated('motto');
  AssetRefCell get logo => _s.assetRef('logo');
  RecordListCell<_Zone> get zones => _s.recordList('zones', build: _Zone.new);
  RecordListCell<_Zone> get depots =>
      _s.sub('stock').recordList('depots', build: _Zone.new);
}

extension type _Zone(RecordScope _e) {
  ValueCell<String> get name => _e.text('name');
  ValueCell<double> get rate => _e.decimal('rate');
  ValueCell<String> get street => _e.sub('address').text('street');
  AssetRefCell get photo => _e.assetRef('photo');
  RecordListCell<_Stop> get stops => _e.recordList('stops', build: _Stop.new);
}

extension type _Stop(RecordScope _e) {
  ValueCell<String> get town => _e.text('town');
}

/// What the form sends: every cell is read, as a save reads them.
String _read(FormScope scope) {
  final f = _Shop(scope);
  String zone(_Zone z) => [
    z.name.value,
    z.rate.value,
    z.street.value,
    z.photo.assetId.value,
    for (final s in z.stops.elements) s.town.value,
  ].join(',');
  return [
    f.name.value,
    f.city.value,
    f.tagline.lane('en').value,
    f.logo.assetId.value,
    for (final z in f.zones.elements) zone(z),
    for (final z in f.depots.elements) zone(z),
  ].join(';');
}

/// A form of two zones, the second with two stops, and one depot, whose
/// save is refused with [refusal] while there is one.
({ValueFormController<String> form, _Shop fields, List<String> saved}) _form([
  Map<String, String>? refusal,
]) {
  final saved = <String>[];
  var refuse = refusal;
  final form = ValueFormController<String>(
    read: _read,
    write: (scope, value) => _Shop(scope).name.set(value),
    initial: 'Potting',
    onSubmit: (value) async {
      final errors = refuse;
      refuse = null;
      if (errors != null) {
        throw FormSubmitException(message: 'Refused', fieldErrors: errors);
      }
      saved.add(value);
    },
  );
  addTearDown(form.dispose);
  final fields = _Shop(form.scope);
  fields.zones
    ..add()
    ..add();
  fields.zones.elements[1].stops
    ..add()
    ..add();
  fields.depots.add();
  fields.name.set('Potting shed');
  return (form: form, fields: fields, saved: saved);
}

void main() {
  group('a refused save names a field by its path', () {
    test('a row of a list by its index, in brackets or after a dot', () async {
      for (final path in ['zones[1].name', 'zones.1.name']) {
        final (:form, :fields, saved: _) = _form({path: 'Taken'});
        await form.submit();
        final second = fields.zones.elements[1].name.id;
        expect(form.errors, {second: 'Taken'}, reason: path);
        expect(
          form.errors.keys.single,
          isNot(fields.zones.elements[0].name.id),
        );
      }
    });

    test('a top-level field, one under a sub-scope, and the list', () async {
      final (:form, :fields, saved: _) = _form({
        'name': 'Too long',
        'billing.city': 'Unknown',
        'zones': 'Two zones overlap',
      });
      await form.submit();
      expect(form.errors, {
        fields.name.id: 'Too long',
        fields.city.id: 'Unknown',
        fields.zones.id: 'Two zones overlap',
      });
    });

    test('in a row: a field under its sub-scope, its asset reference, its '
        'own list and a row of that', () async {
      final (:form, :fields, saved: _) = _form({
        'zones[0].address.street': 'Missing',
        'zones[0].photo': 'Too large',
        'zones[1].stops': 'Too many stops',
        'zones[1].stops[1].town': 'Unknown',
        'stock.depots[0].rate': 'Too high',
      });
      await form.submit();
      final [first, second] = fields.zones.elements;
      expect(form.errors, {
        first.street.id: 'Missing',
        first.photo.id: 'Too large',
        second.stops.id: 'Too many stops',
        second.stops.elements[1].town.id: 'Unknown',
        fields.depots.elements[0].rate.id: 'Too high',
      });
      expect(first.photo.id, isNot('zones[0].photo'));
      expect(second.stops.id, isNot('zones[1].stops'));
    });

    test('a lane of a translated field names the field, handed out or '
        'not; an asset reference is named by its own path', () async {
      final (:form, :fields, saved: _) = _form({
        'tagline/en': 'Too long',
        'logo': 'Too large',
      });
      await form.submit();
      expect(form.errors, {
        fields.tagline.id: 'Too long',
        fields.logo.id: 'Too large',
      });

      final other = _form({'tagline/fr': 'Trop long'});
      await other.form.submit();
      expect(other.form.errors, {other.fields.tagline.id: 'Trop long'});
    });

    test('the index counts the rows as they stand', () async {
      final (:form, :fields, saved: _) = _form({'zones[0].name': 'Taken'});
      final first = fields.zones.elements[0].name.id;
      final second = fields.zones.elements[1].name.id;
      fields.zones.move(1, 0);
      await form.submit();
      expect(form.errors.keys, [second]);
      expect(form.errors.keys, isNot(contains(first)));
    });

    test('a field id still names its field, a row\'s too', () async {
      final probe = _form();
      final (:form, :fields, saved: _) = _form();
      final row = fields.zones.elements[1].rate.id;
      form.setErrors({'name': 'Too long', row: 'Too high'});
      expect(form.errors, {'name': 'Too long', row: 'Too high'});
      expect(probe.form.errors, isEmpty);
    });

    test('an id wins over a path spelled the same', () async {
      // Under a scope of the app's own the ids are prefixed and the paths
      // are not: the cell handed out as `b` has the id `billing.b`, which
      // is also the path of the cell `b` under `sub('billing')`.
      final local = LocalScope();
      addTearDown(local.dispose);
      var refuse = true;
      final form = ValueFormController<String>(
        scope: local.sub('billing'),
        read: (s) => s.text('b').value + s.sub('billing').text('b').value,
        write: (s, value) => s.text('b').set(value),
        initial: 'a',
        onSubmit: (_) async {
          if (!refuse) return;
          refuse = false;
          throw const FormSubmitException(fieldErrors: {'billing.b': 'No'});
        },
      );
      addTearDown(form.dispose);
      final byId = form.scope.text('b');
      final byPath = form.scope.sub('billing').text('b');
      expect(byId.id, 'billing.b');
      expect(byPath.id, isNot('billing.b'));
      byId.set('c');
      await form.submit();
      expect(form.errors, {byId.id: 'No'});
    });

    test(
      'its message shows until that field is edited, and no longer',
      () async {
        final (:form, :fields, :saved) = _form({
          'zones[1].name': 'Taken',
          'zones[0].rate': 'Too high',
        });
        await form.submit();
        expect(form.errors, hasLength(2));
        expect(form.canSubmit, isFalse);

        fields.zones.elements[1].name.set('North');
        expect(form.errors, {fields.zones.elements[0].rate.id: 'Too high'});
        fields.zones.elements[0].rate.set(4);
        expect(form.errors, isEmpty);
        expect(form.canSubmit, isTrue);
        await form.submit();
        expect(saved, hasLength(1));
      },
    );

    test('setErrors takes paths too, and clears by one', () {
      final (:form, :fields, saved: _) = _form();
      // Every cell handed out, as a seed, a save or the fields would.
      form.value;
      form.setErrors({'zones[1].name': 'Taken', 'billing.city': 'Unknown'});
      expect(form.errors, {
        fields.zones.elements[1].name.id: 'Taken',
        fields.city.id: 'Unknown',
      });
      form.setErrors({'zones.1.name': null});
      expect(form.errors, {fields.city.id: 'Unknown'});
    });
  });

  group('a path into a list that leads to no field names the list', () {
    for (final (what, path) in [
      ('a row the list has not', 'zones[5].name'),
      ('an index no list could hold', 'zones[99999999999999999999].name'),
      ('a field its row has not', 'zones[0].rateCents'),
      ('a row with no field', 'zones[1]'),
      ('a row of a list that a missing row would hold', 'zones[5].stops[0]'),
    ]) {
      test(what, () async {
        final (:form, :fields, :saved) = _form({path: 'Refused here'});
        await form.submit();
        expect(form.errors, {fields.zones.id: 'Refused here'});

        fields.name.set('Potting shed 2');
        expect(form.errors, hasLength(1), reason: 'not an edit of the list');
        fields.zones.elements[0].name.set('North');
        expect(form.errors, isEmpty);
        await form.submit();
        expect(saved, hasLength(1), reason: 'the form saves again');
      });
    }

    test('a row\'s own list, for a row of it the form has not', () async {
      final (:form, :fields, saved: _) = _form({
        'zones[1].stops[9].town': 'Unknown',
      });
      await form.submit();
      expect(form.errors, {fields.zones.elements[1].stops.id: 'Unknown'});
    });
  });

  group('what the server says of a list', () {
    test('an edit in one of its rows answers, and the form saves', () async {
      final (:form, :fields, :saved) = _form({'zones': 'Two zones overlap'});
      await form.submit();
      expect(form.errors, {fields.zones.id: 'Two zones overlap'});
      expect(form.canSubmit, isFalse);

      fields.zones.elements[1].rate.set(4);
      expect(form.errors, isEmpty);
      expect(form.canSubmit, isTrue);
      await form.submit();
      expect(saved, hasLength(1));
    });

    test('an edit under a row\'s sub-scope and in its asset reference '
        'do too', () async {
      for (final edit in <void Function(_Zone)>[
        (zone) => zone.street.set('1 Quay'),
        (zone) => zone.photo.assetId.set('m-1'),
      ]) {
        final (:form, :fields, saved: _) = _form({'zones': 'Refused'});
        await form.submit();
        edit(fields.zones.elements[0]);
        expect(form.errors, isEmpty);
      }
    });

    test('an edit in a row of a row answers both lists', () async {
      final (:form, :fields, saved: _) = _form({
        'zones': 'Two zones overlap',
        'zones[1].stops': 'Too many stops',
        'stock.depots': 'No depot is open',
      });
      await form.submit();
      expect(form.errors, hasLength(3));

      fields.zones.elements[1].stops.elements[0].town.set('Ghent');
      expect(form.errors, {fields.depots.id: 'No depot is open'});
    });

    test('a row added to a row\'s list answers the list around it', () async {
      final (:form, :fields, saved: _) = _form({'zones': 'Two zones overlap'});
      await form.submit();
      fields.zones.elements[1].stops.add();
      expect(form.errors, isEmpty);
    });

    test('an edit in a row leaves the list within it, and another '
        'list', () async {
      final (:form, :fields, saved: _) = _form({
        'zones[1].stops': 'Too many stops',
        'stock.depots': 'No depot is open',
      });
      await form.submit();
      fields.zones.elements[1].name.set('North');
      expect(form.errors, {
        fields.zones.elements[1].stops.id: 'Too many stops',
        fields.depots.id: 'No depot is open',
      });
    });

    test('an edit in one row leaves what was said of another', () async {
      final (:form, :fields, saved: _) = _form({'zones[1].name': 'Taken'});
      await form.submit();
      fields.zones.elements[0].name.set('South');
      expect(form.errors, {fields.zones.elements[1].name.id: 'Taken'});
    });

    test('an edit outside the list leaves it', () async {
      final (:form, :fields, saved: _) = _form({'zones': 'Two zones overlap'});
      await form.submit();
      fields.name.set('Potting shed 2');
      fields.city.set('Ghent');
      expect(form.errors, {fields.zones.id: 'Two zones overlap'});
    });
  });

  group('a message that names no field of the form', () {
    for (final (what, path) in [
      ('a field the form has not', 'vatNumber'),
      ('a list the form has not', 'warehouses[0].name'),
    ]) {
      test('$what: it shows under its key, and the next edit of any field '
          'takes it', () async {
        final (:form, :fields, :saved) = _form({path: 'Refused here'});
        await form.submit();
        expect(form.errors, {path: 'Refused here'});
        expect(form.submitError, 'Refused');
        expect(form.canSubmit, isFalse);

        fields.name.set('Potting shed 2');
        expect(form.errors, isEmpty);
        expect(form.canSubmit, isTrue);
        await form.submit();
        expect(saved, hasLength(1), reason: 'the form saves again');
      });
    }

    test('adding or removing a row takes it too', () async {
      final (:form, :fields, saved: _) = _form({'vatNumber': 'Unknown'});
      await form.submit();
      expect(form.errors, {'vatNumber': 'Unknown'});
      fields.zones.add();
      expect(form.errors, isEmpty);
    });

    test('every named field\'s message beside it stays until its own '
        'edit', () async {
      final refusal = {
        'vatNumber': 'Unknown',
        'zones[1].name': 'Taken',
        'zones': 'Two zones overlap',
        'tagline/fr': 'Trop long',
        'motto/fr': 'Trop court',
        'logo': 'Too large',
      };
      final (:form, :fields, saved: _) = _form(refusal);
      // Handed out, as its field would, with no lane read.
      fields.motto;
      // A row's field by its id, as an app that has the handle names it.
      final rate = fields.zones.elements[0].rate.id;
      refusal[rate] = 'Too high';
      await form.submit();
      expect(form.errors, hasLength(7));

      fields.name.set('Potting shed 2');
      expect(form.errors, {
        fields.zones.elements[1].name.id: 'Taken',
        fields.zones.id: 'Two zones overlap',
        fields.tagline.id: 'Trop long',
        fields.motto.id: 'Trop court',
        fields.logo.id: 'Too large',
        rate: 'Too high',
      });
    });

    test('a path to a row\'s cell the scope has not handed out names the '
        'list until it has', () {
      final (:form, :fields, saved: _) = _form();
      form.setErrors({'zones[1].name': 'Taken'});
      expect(form.errors, {fields.zones.id: 'Taken'});
      form.setErrors({'zones[1].name': null});
      expect(form.errors, isEmpty);

      fields.zones.elements[1].name;
      form.setErrors({'zones[1].name': 'Taken'});
      expect(form.errors, {fields.zones.elements[1].name.id: 'Taken'});
    });

    test('one the app sets itself stays until the app clears it', () {
      final (:form, :fields, saved: _) = _form();
      form.setErrors({'vatNumber': 'Unknown'});
      fields.name.set('Potting shed 2');
      expect(form.errors, {'vatNumber': 'Unknown'});
      form.setErrors({'vatNumber': null});
      expect(form.errors, isEmpty);
    });

    test('a reset forgets it', () async {
      final (:form, fields: _, saved: _) = _form({'vatNumber': 'Unknown'});
      await form.submit();
      form.reset();
      expect(form.errors, isEmpty);
    });
  });
}
