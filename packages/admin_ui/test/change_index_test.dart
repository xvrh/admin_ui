import 'package:admin_ui/history.dart';
import 'package:flutter_test/flutter_test.dart';

LocaleDiff _lane(
  String locale,
  DiffOp op, {
  List<BlockChange> blocks = const [],
}) => LocaleDiff(locale: locale, op: op, before: '', after: '', blocks: blocks);

void main() {
  final index = FieldChangeIndex([
    const FieldDiff(
      label: 'Title',
      fieldKey: 'title',
      kind: DiffFieldKind.text,
      translatable: true,
      locales: [
        LocaleDiff(locale: 'en', op: DiffOp.unchanged),
        LocaleDiff(locale: 'fr', op: DiffOp.changed),
      ],
    ),
    const FieldDiff(
      label: 'Price',
      fieldKey: 'price',
      kind: DiffFieldKind.scalar,
      locales: [LocaleDiff(locale: '', op: DiffOp.unchanged)],
    ),
    // An asset ref: unchanged binding ('' lane), changed English alt.
    const FieldDiff(
      label: 'Hero',
      fieldKey: 'hero',
      kind: DiffFieldKind.media,
      translatable: true,
      locales: [
        LocaleDiff(locale: 'en', op: DiffOp.changed),
        LocaleDiff(locale: '', op: DiffOp.unchanged),
      ],
    ),
    FieldDiff(
      label: 'Body',
      fieldKey: 'body',
      kind: DiffFieldKind.richText,
      translatable: true,
      locales: [
        _lane(
          'en',
          DiffOp.changed,
          blocks: const [
            BlockChange(id: 'b1', type: 'paragraph', op: DiffOp.changed),
            BlockChange(id: 'b2', type: 'paragraph', op: DiffOp.unchanged),
            BlockChange(id: 'b3', type: 'image', op: DiffOp.added),
          ],
        ),
      ],
    ),
    const FieldDiff(
      label: 'Specs',
      fieldKey: 'specs',
      kind: DiffFieldKind.recordList,
      locales: [],
      records: [
        RecordChange(
          id: 'r1',
          op: DiffOp.changed,
          label: 'One',
          fields: [
            FieldDiff(
              label: 'Name',
              fieldKey: 'name',
              kind: DiffFieldKind.text,
              translatable: true,
              locales: [LocaleDiff(locale: 'en', op: DiffOp.changed)],
            ),
          ],
        ),
        RecordChange(id: 'r2', op: DiffOp.unchanged, label: 'Two', fields: []),
        RecordChange(id: 'r3', op: DiffOp.added, label: 'Three', fields: []),
      ],
    ),
  ]);

  test('scalar and lane summaries', () {
    expect(index.summaryOf('title').modified, isTrue);
    expect(index.summaryOf('title').lanes, {'fr'});
    expect(index.summaryOf('title').shared, isFalse);
    expect(index.summaryOf('price').modified, isFalse);
    expect(index.summaryOf('missing'), FieldChangeSummary.none);
  });

  test('asset alt edit lands in its language lane, not shared', () {
    final hero = index.summaryOf('hero');
    expect(hero.modified, isTrue);
    expect(hero.lanes, {'en'});
    expect(hero.shared, isFalse);
    // A nested cell path that names no diff node resolves to none, not a crash.
    expect(index.summaryOf('hero/alt'), FieldChangeSummary.none);
  });

  test('rich body exposes per-block ops', () {
    final body = index.summaryOf('body');
    expect(body.modified, isTrue);
    expect(body.blocks['en'], {'b1': DiffOp.changed, 'b3': DiffOp.added});
  });

  test('record list aggregates records and languages', () {
    final specs = index.summaryOf('specs');
    expect(specs.modified, isTrue);
    expect(specs.lanes, {'en'});
    expect(specs.shared, isTrue); // r3 was added — structural.
    expect(specs.records, {'r1': DiffOp.changed, 'r3': DiffOp.added});
  });

  test('record and record-child paths resolve', () {
    expect(index.summaryOf('specs/r1').modified, isTrue);
    expect(index.summaryOf('specs/r1').lanes, {'en'});
    expect(index.summaryOf('specs/r1/name').modified, isTrue);
    expect(index.summaryOf('specs/r2'), FieldChangeSummary.none);
    expect(index.summaryOf('specs/r1/other'), FieldChangeSummary.none);
    expect(index.summaryOf('specs/nope/name'), FieldChangeSummary.none);
  });

  test('summaries are value-equal across index generations', () {
    final other = FieldChangeIndex(index.fields);
    expect(other.summaryOf('specs'), index.summaryOf('specs'));
    expect(other.summaryOf('body'), index.summaryOf('body'));
    expect(
      FieldChangeIndex(const []).summaryOf('specs'),
      isNot(index.summaryOf('specs')),
    );
  });
}
