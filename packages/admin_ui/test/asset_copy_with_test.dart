// An asset is copied with the fields given changed and every other carried
// over, so that changing one does not mean naming eleven, and a field
// added to Asset later is not dropped by a copy written before it.

import 'dart:io';

import 'package:admin_ui/assets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _thumbnail = AssetImage('fern.png');
const _other = AssetImage('moss.png');

/// An asset none of whose fields is at its default.
const _fern = Asset(
  id: 'm-1',
  name: 'fern.png',
  type: AssetType.document,
  bytes: 4096,
  thumbnail: _thumbnail,
  url: 'https://example.com/fern.png',
  swatch: Color(0xFF2E7D32),
  width: 480,
  height: 360,
  usageCount: 3,
  alt: {'en': 'A fern'},
);

/// Every field of [asset], by name.
Map<String, Object?> _fields(Asset asset) => {
  'id': asset.id,
  'name': asset.name,
  'type': asset.type,
  'bytes': asset.bytes,
  'thumbnail': asset.thumbnail,
  'url': asset.url,
  'swatch': asset.swatch,
  'width': asset.width,
  'height': asset.height,
  'usageCount': asset.usageCount,
  'alt': asset.alt,
};

/// One copy per field, changing that field alone to the value beside it.
final _changes = <String, (Asset, Object?)>{
  'id': (_fern.copyWith(id: 'm-2'), 'm-2'),
  'name': (_fern.copyWith(name: 'moss.png'), 'moss.png'),
  'type': (_fern.copyWith(type: AssetType.video), AssetType.video),
  'bytes': (_fern.copyWith(bytes: 1), 1),
  'thumbnail': (_fern.copyWith(thumbnail: () => _other), _other),
  'url': (
    _fern.copyWith(url: () => 'https://example.com/moss.png'),
    'https://example.com/moss.png',
  ),
  'swatch': (
    _fern.copyWith(swatch: () => const Color(0xFF000000)),
    const Color(0xFF000000),
  ),
  'width': (_fern.copyWith(width: () => 1), 1),
  'height': (_fern.copyWith(height: () => 2), 2),
  'usageCount': (_fern.copyWith(usageCount: 0), 0),
  'alt': (
    _fern.copyWith(alt: const {'fr': 'Une fougère'}),
    {'fr': 'Une fougère'},
  ),
};

/// One copy per field that can be null, making it so.
final _cleared = <String, Asset>{
  'thumbnail': _fern.copyWith(thumbnail: () => null),
  'url': _fern.copyWith(url: () => null),
  'swatch': _fern.copyWith(swatch: () => null),
  'width': _fern.copyWith(width: () => null),
  'height': _fern.copyWith(height: () => null),
};

void main() {
  test('a copy with nothing given is the asset, field by field', () {
    expect(_fields(_fern.copyWith()), _fields(_fern));
  });

  for (final MapEntry(key: field, value: (copy, value)) in _changes.entries) {
    test('$field alone changes when it is the one given', () {
      expect(_fields(copy), {..._fields(_fern), field: value});
    });
  }

  for (final MapEntry(key: field, value: copy) in _cleared.entries) {
    test('$field is made null by a function that answers null', () {
      expect(_fields(copy), {..._fields(_fern), field: null});
    });
  }

  test('several fields change together', () {
    final copy = _fern.copyWith(
      usageCount: 0,
      alt: const {},
      thumbnail: () => null,
    );
    expect(_fields(copy), {
      ..._fields(_fern),
      'usageCount': 0,
      'alt': <String, String>{},
      'thumbnail': null,
    });
  });

  test('these tests, and copyWith, name every field Asset declares', () {
    final source = File('lib/src/assets/ui/asset_library.dart')
        .readAsStringSync();
    final start = source.indexOf('class Asset {');
    expect(start, isNot(-1));
    final body = source.substring(start, source.indexOf('\n}\n', start));
    final declared = [
      for (final m in RegExp(
        r'^  final [^;=(]+ (\w+);$',
        multiLine: true,
      ).allMatches(body))
        m[1]!,
    ];
    expect(declared, _fields(_fern).keys, reason: 'a field these tests miss');
    expect(_changes.keys, declared);

    final copyWith = body.substring(body.indexOf('Asset copyWith({'));
    final copy = copyWith.substring(0, copyWith.indexOf(');') + 2);
    for (final field in declared) {
      expect(
        RegExp('\\b$field,\\n').hasMatch(copy),
        isTrue,
        reason: 'copyWith takes no $field',
      );
      expect(
        copy,
        contains('    $field: '),
        reason: 'copyWith does not carry $field over',
      );
    }
  });
}
