import 'package:admin_ui/history.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = VersionRef(
  id: 'v1',
  label: 'First',
  author: 'Ada',
  initials: 'AD',
  timestamp: 'yesterday',
  status: VersionStatus.published,
  number: 1,
);

const _compare = VersionRef(
  id: 'draft',
  label: 'Draft',
  author: 'Ada',
  initials: 'AD',
  timestamp: 'now',
  status: VersionStatus.draft,
);

/// The single lane's op of a field with no locales.
DiffOp _op(FieldDiff field) => field.locales.single.op;

void main() {
  group('FieldDiff.text', () {
    test('one untranslated text lane per op', () {
      for (final (before, after, op) in [
        ('Hello', 'Hello', DiffOp.unchanged),
        ('Hello', 'Hello there', DiffOp.changed),
        (null, 'Hello', DiffOp.added),
        ('', 'Hello', DiffOp.added),
        ('Hello', null, DiffOp.removed),
        ('Hello', '', DiffOp.removed),
        (null, '', DiffOp.unchanged),
        (null, null, DiffOp.unchanged),
      ]) {
        final field = FieldDiff.text('title', 'Title', before, after);
        expect(_op(field), op, reason: '"$before" → "$after"');
        expect(field.fieldKey, 'title');
        expect(field.label, 'Title');
        expect(field.kind, DiffFieldKind.text);
        expect(field.translatable, isFalse);
        expect(field.locales.single.locale, '');
        expect(field.locales.single.before, before);
        expect(field.locales.single.after, after);
      }
    });
  });

  group('FieldDiff.translated', () {
    test('one lane per language, each with its own op', () {
      final field = FieldDiff.translated(
        'name',
        'Name',
        {'en': 'Fern', 'fr': 'Fougère', 'de': 'Farn'},
        {'en': 'Boston fern', 'fr': 'Fougère', 'ar': 'سرخس'},
      );
      expect(field.kind, DiffFieldKind.text);
      expect(field.translatable, isTrue);
      expect(
        [for (final l in field.locales) (l.locale, l.op)],
        [
          ('en', DiffOp.changed),
          ('fr', DiffOp.unchanged),
          ('de', DiffOp.removed),
          ('ar', DiffOp.added),
        ],
        reason: "before's codes, then after's new ones",
      );
      expect(field.changedLocales, {'en', 'de', 'ar'});
    });

    test('follows the given locales, a lane for each, and drops no other', () {
      final field = FieldDiff.translated(
        'name',
        'Name',
        {'fr': 'Fougère', 'nl': 'Varen'},
        {'en': 'Fern', 'fr': 'Fougère', 'nl': 'Varen'},
        locales: ['en', 'fr', 'ar'],
      );
      expect(
        [for (final l in field.locales) (l.locale, l.op)],
        [
          ('en', DiffOp.added),
          ('fr', DiffOp.unchanged),
          ('ar', DiffOp.unchanged),
          ('nl', DiffOp.unchanged),
        ],
      );
      final ar = field.locales[2];
      expect((ar.before, ar.after), (null, null));
    });
  });

  group('FieldDiff.scalar', () {
    test('compares values by the text they are shown as', () {
      String money(int cents) => '€${(cents / 100).toStringAsFixed(2)}';
      final price = FieldDiff.scalar(
        'price',
        'Price',
        1250,
        1500,
        format: money,
      );
      expect(_op(price), DiffOp.changed);
      expect(
        (price.locales.single.before, price.locales.single.after),
        ('€12.50', '€15.00'),
      );
      expect(price.kind, DiffFieldKind.scalar);
      expect(price.translatable, isFalse);

      // Two lists with the same items, different instances.
      final tags = FieldDiff.scalar(
        'tags',
        'Tags',
        ['green', 'shade'],
        ['green', 'shade'],
        format: (tags) => tags.join(', '),
      );
      expect(_op(tags), DiffOp.unchanged);

      final count = FieldDiff.scalar('stock', 'Stock', 0, 4);
      expect(_op(count), DiffOp.changed, reason: '0 is a value, not absent');
      expect(count.locales.single.before, '0');
    });

    test('a null value, or one shown as nothing, is absent', () {
      expect(_op(FieldDiff.scalar<int>('a', 'A', null, 3)), DiffOp.added);
      expect(_op(FieldDiff.scalar<int>('a', 'A', 3, null)), DiffOp.removed);
      expect(
        _op(FieldDiff.scalar<int>('a', 'A', null, null)),
        DiffOp.unchanged,
      );
      expect(
        _op(
          FieldDiff.scalar('tags', 'Tags', <String>[], [
            'green',
          ], format: (tags) => tags.join(', ')),
        ),
        DiffOp.added,
      );
    });

    test('keeps the kind it is given', () {
      for (final kind in [
        DiffFieldKind.choice,
        DiffFieldKind.media,
        DiffFieldKind.reference,
      ]) {
        expect(FieldDiff.scalar('k', 'K', 1, 2, kind: kind).kind, kind);
      }
      expect(
        () => FieldDiff.scalar('k', 'K', 1, 2, kind: DiffFieldKind.richText),
        throwsAssertionError,
      );
    });
  });

  group('VersionDiff.of', () {
    final fields = [
      FieldDiff.translated(
        'name',
        'Name',
        {'en': 'Fern', 'fr': 'Fougère'},
        {'en': 'Boston fern', 'fr': 'Fougère'},
      ),
      FieldDiff.scalar('sku', 'SKU', 'FERN-01', 'FERN-01'),
      FieldDiff.text('note', 'Note', 'Water weekly', 'Water twice a week'),
      FieldDiff(
        label: 'Sections',
        fieldKey: 'sections',
        kind: DiffFieldKind.recordList,
        locales: const [],
        records: [
          RecordChange(
            id: 's1',
            op: DiffOp.changed,
            label: 'Care',
            fields: [
              FieldDiff.translated(
                'heading',
                'Heading',
                {'en': 'Care', 'ar': 'العناية'},
                {'en': 'Plant care', 'ar': 'العناية'},
              ),
            ],
          ),
        ],
      ),
      FieldDiff.scalar('price', 'Price', 1250, 1250),
    ];

    test('keeps every field, unchanged ones too, in declaration order', () {
      final diff = VersionDiff.of(
        base: _base,
        compare: _compare,
        fields: fields,
      );
      expect(diff.base, same(_base));
      expect(diff.compare, same(_compare));
      expect(
        [for (final f in diff.fields) (f.fieldKey, f.changed)],
        [
          ('name', true),
          ('sku', false),
          ('note', true),
          ('sections', true),
          ('price', false),
        ],
      );
      expect(diff.changedFieldCount, 3);
      expect(diff.hasChanges, isTrue);
    });

    test("gathers the translated fields' languages, records' included", () {
      final diff = VersionDiff.of(
        base: _base,
        compare: _compare,
        fields: fields,
      );
      expect(diff.locales, ['en', 'fr', 'ar']);
    });

    test('with nothing changed, still lists every field', () {
      final diff = VersionDiff.of(
        base: _base,
        compare: _compare,
        fields: [
          FieldDiff.text('a', 'A', 'x', 'x'),
          FieldDiff.scalar('b', 'B', 1, 1),
        ],
      );
      expect(diff.fields, hasLength(2));
      expect(diff.hasChanges, isFalse);
      expect(diff.locales, isEmpty);
    });

    test('refuses two fields under one key', () {
      expect(
        () => VersionDiff.of(
          base: _base,
          compare: _compare,
          fields: [
            FieldDiff.text('a', 'A', 'x', 'y'),
            FieldDiff.text('a', 'A again', 'x', 'y'),
          ],
        ),
        throwsAssertionError,
      );
    });
  });
}
