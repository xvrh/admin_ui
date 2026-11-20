import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The catalog is where a widget is looked at and where the sweeps pump it:
// in every theme, at twice the text size, under reduced motion, right to
// left. A public widget no page builds gets none of that.
//
// This holds the line: every public widget of the kit is built by a page of
// the catalog, or is on the list below of those that are not yet. The list
// only shrinks. A new public widget comes with its page.

/// Public widgets that no catalog page builds yet. Take a name off when a
/// demo builds the widget; do not add one.
const _noPageYet = <String>{
  'AddRowButton',
  'AssetDropTarget',
  'AssetListField',
  'AssetMediaCanvas',
  'AttentionTile',
  'AuthField',
  'AuthFieldError',
  'BrowserSwipeGuard',
  'ChangeScopeHost',
  'CircleButton',
  'CollectionCards',
  'ColorField',
  'CommentAnnotationPin',
  'CursorRegion',
  'DashedBorder',
  'DateField',
  'DelayedLoading',
  'DiffMoveHint',
  'DiffRestoreButton',
  'DocumentPresenceRoster',
  'EnumSelectField',
  'FieldBodyScope',
  'FieldDescription',
  'FieldErrorText',
  'FieldMessage',
  'FieldPresenceRing',
  'FieldRequiredMarker',
  'FieldToken',
  'FocusRing',
  'FormErrorsScope',
  'FormFieldCommands',
  'FormShortcuts',
  'Glyph',
  'HighlightedText',
  'LaneLanguage',
  'LaneStack',
  'Listbox',
  'ListboxMenu',
  'ListboxOption',
  'LocaleTabs',
  'MaskedDateField',
  'MaskedField',
  'MatchCell',
  'MultiSelectField',
  'NewPasswordFields',
  'NotchedLabelBox',
  'NotificationBell',
  'OptionalBooleanField',
  'OptionalDateField',
  'OptionalDecimalField',
  'OptionalNumberField',
  'PresenceAvatars',
  'ReferenceField',
  'SaveCluster',
  'SelectionFooter',
  'ShellMenuButton',
  'SingleReferenceField',
  'SkeletonText',
  'StillLinearProgress',
  'SwatchRow',
  'TabPanel',
  'TagsField',
  'TextCellBody',
  'TopProgressBar',
};

/// The names `api.txt` exports, each once.
Set<String> _publicNames() => {
  for (final line in File('../api.txt').readAsLinesSync())
    if (line.trim().split(RegExp(r'\s+')) case [final barrel, final name]
        when barrel.endsWith('.dart'))
      name,
};

/// The Dart under [dir], comments left out, as one text.
String _code(String dir) => [
  for (final file in Directory(dir).listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      for (final line in file.readAsLinesSync()) line.split('//').first,
].join('\n');

void main() {
  final kit = _code('../lib/src');
  final catalog = _code('lib');
  // A widget a page can build: a class of the kit's public surface that
  // extends StatelessWidget or StatefulWidget.
  final widgets = [
    for (final name in _publicNames().toList()..sort())
      if (RegExp(
        'class ${RegExp.escape(name)}(?:<[^>{]*>)?\\s+extends\\s+'
        r'(?:StatelessWidget|StatefulWidget)\b',
      ).hasMatch(kit))
        name,
  ];
  // Built by a page: constructed, plainly or with type arguments, or
  // reached through a named constructor or a static.
  bool built(String name) =>
      RegExp('\\b${RegExp.escape(name)}\\s*(?:<[^>()]*>)?\\s*[(.]')
          .hasMatch(catalog);

  test('the kit has public widgets to hold to this', () {
    expect(widgets.length, greaterThan(200));
    expect(widgets, containsAll(['Button', 'Collection', 'Tabs']));
    expect(built('Button'), isTrue);
  });

  test('every public widget is built by a catalog page', () {
    final missing = [
      for (final name in widgets)
        if (!built(name) && !_noPageYet.contains(name)) name,
    ];
    expect(
      missing,
      isEmpty,
      reason:
          'No page of the catalog builds these public widgets. Give each a '
          'demo under example/lib, with its states, so the sweeps pump it.',
    );
  });

  test('the list of widgets with no page only shrinks', () {
    final shown = [
      for (final name in _noPageYet)
        if (built(name)) name,
    ];
    expect(
      shown,
      isEmpty,
      reason:
          'A page builds these now: take them off _noPageYet in '
          'example/test/catalog_coverage_test.dart.',
    );
    final gone = [
      for (final name in _noPageYet)
        if (!widgets.contains(name)) name,
    ];
    expect(
      gone,
      isEmpty,
      reason: 'These are no longer public widgets: take them off _noPageYet.',
    );
  });
}
