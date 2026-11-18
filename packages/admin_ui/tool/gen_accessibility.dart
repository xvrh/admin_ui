// Generates the tables of ACCESSIBILITY.md from the package itself, so the
// record cannot drift from the code and its tests.
//
//   fvm dart run tool/gen_accessibility.dart           # write the tables
//   fvm dart run tool/gen_accessibility.dart --check    # fail if out of date
//
// Two tables, each between a pair of markers in ACCESSIBILITY.md:
//
// - roles: every `SemanticsRole` a file under lib/src names, and the files
//   that name it;
// - status: one row for each of [components], with the roles its source
//   sets, the test files that build it and press keys, read the semantics
//   tree or measure contrast, where its targets are measured, and what is
//   known to be missing.
//
// A test file is listed for a component when it constructs it and uses the
// API of the column: it is where to look, and no proof that every key or
// state is covered. test/accessibility_status_test.dart runs the check.

import 'dart:io';

/// A component of the status table.
class Component {
  final String name;

  /// The roles of its source file that are its own, where the file holds
  /// more than one component; null is all of them.
  final Set<String>? only;

  /// Roles it carries that its own source does not name.
  final String? inherited;

  /// What is known to be missing, in a sentence; null when nothing is.
  final String? gap;

  const Component(this.name, {this.only, this.inherited, this.gap});
}

/// The components recorded, in the table's order: the kit's controls, its
/// messages and overlays, then the structures that hold them.
const components = [
  Component('Button'),
  Component('IconAction'),
  Component(
    'TextLink',
    gap:
        'As tall as its line of text, 16 to 18px: under 24px where it is '
        'not in a sentence.',
  ),
  Component('Toggle', gap: 'With no label, its target is its 36 by 20 track.'),
  Component('Check', gap: 'With no label, its target is its 18px box.'),
  Component('Choice', gap: 'An option has no name but its visible label.'),
  Component('Segmented', gap: "Fluent's small segment is 22px tall."),
  Component(
    'ValueSlider',
    gap:
        'Takes no label. Announced by Material\'s `Slider`; the `slider` '
        'role is newer than the oldest Flutter the kit builds on.',
  ),
  Component('Tag'),
  Component('Tabs', only: {'tab', 'tabBar'}),
  Component('TabPanel', only: {'tabPanel'}),
  Component('Pagination'),
  Component('Breadcrumbs'),
  Component('Accordion'),
  Component('Menu'),
  Component('MenuButton'),
  Component(
    'Combobox',
    gap:
        'A text field that says whether it is open, with no `comboBox` '
        'role: the framework refuses it. Its options are buttons that say '
        'whether they are selected and where they stand, "2 of 5": the '
        'list box and option roles are newer than the oldest Flutter.',
  ),
  Component('SearchField'),
  Component('Calendar'),
  Component('DateRangePicker'),
  Component(
    'CommandPalette',
    gap:
        'Its results are buttons that say whether they are selected and '
        'where they stand, in no list: see the roles left out.',
  ),
  Component('Tip', gap: 'No `tooltip` role: the framework refuses it.'),
  Component(
    'Alert',
    gap:
        'A danger alert that is read out is an `alert`; a warning is a '
        'live region; info and success are not read out unless asked to '
        'be.',
  ),
  Component('AnnouncementBar'),
  Component(
    'Toast',
    gap: 'A danger toast is an `alert`; the others are live regions.',
  ),
  Component('Modal'),
  Component('SideSheet'),
  Component(
    'Spinner',
    gap:
        'A named live region with no `loadingSpinner` role: see the roles '
        'left out.',
  ),
  Component(
    'ProgressBar',
    inherited: '`progressBar`, from Material\'s indicator',
    gap:
        'With no value it is no progress bar, and its label is read as '
        'text.',
  ),
  Component('Shell'),
  Component('Sidebar'),
  Component('SplitView'),
  Component(
    'Tree',
    gap:
        "Flutter has no tree or tree item role: a row's caret is a button "
        'named Expand or Collapse that says whether it is open. Its drag '
        'handle has no `dragHandle` role: the framework refuses it; a row '
        'moves from its menu and with Alt and the arrows.',
  ),
  Component('TreeEditor'),
  Component('KanbanBoard'),
  Component('CollectionTable'),
  Component('ColumnChooser'),
  Component('NotificationCenter'),
  Component('UploadZone'),
  Component('StatCard'),
  Component('FieldShell'),
  Component(
    'ValidationSummary',
    gap:
        'A live region that waits its turn, not an `alert`: it is read '
        'again as the count changes. Its links are a line of text tall.',
  ),
  Component(
    'SaveCluster',
    gap:
        'Its "fields need attention" link is 16px '
        'tall.',
  ),
  Component('AssetLibrary'),
  Component('CopyButton'),
  Component('JsonView'),
  Component('ZoomView'),
  Component('FormWizard'),
  Component('CommentsButton'),
  Component('HistoryButton'),
];

const _doc = 'ACCESSIBILITY.md';

void main(List<String> arguments) {
  final root = Directory.current.path;
  final file = File('$root/$_doc');
  if (!file.existsSync()) {
    stderr.writeln('No $_doc: run this from packages/admin_ui.');
    exit(2);
  }
  final current = file.readAsStringSync();
  final next = render(root, current);
  if (arguments.contains('--check')) {
    if (next != current) {
      stderr.writeln(
        '$_doc is out of date: fvm dart run tool/gen_accessibility.dart',
      );
      exit(1);
    }
    return;
  }
  file.writeAsStringSync(next);
  stdout.writeln('wrote $_doc');
}

/// [document] with its two tables written afresh from the package at [root].
String render(String root, String document) {
  final sources = _read('$root/lib/src');
  final tests = _read('$root/test');
  final demos = _read('$root/example/lib');
  var result = _between(document, 'roles', rolesTable(sources));
  result = _between(result, 'status', statusTable(sources, tests, demos));
  return result;
}

final _role = RegExp(r'SemanticsRole\.(\w+)');

/// The roles the files of [sources] name, each with those files.
Map<String, List<String>> rolesInUse(Map<String, String> sources) {
  final roles = <String, List<String>>{};
  for (final MapEntry(key: path, value: text) in sources.entries) {
    for (final role in {for (final m in _role.allMatches(text)) m.group(1)!}) {
      if (role == 'none') continue;
      (roles[role] ??= []).add(path);
    }
  }
  return {
    for (final role in roles.keys.toList()..sort()) role: roles[role]!..sort(),
  };
}

String rolesTable(Map<String, String> sources) {
  final rows = [
    '| Role | Set in |',
    '|---|---|',
    for (final MapEntry(key: role, value: files) in rolesInUse(sources).entries)
      '| `$role` | ${files.map((f) => '`$f`').join(', ')} |',
  ];
  return rows.join('\n');
}

String statusTable(
  Map<String, String> sources,
  Map<String, String> tests,
  Map<String, String> demos,
) {
  final rows = [
    '| Component | Roles it sets | Keyboard | Name, role and state '
        '| Contrast | Targets | Known gaps |',
    '|---|---|---|---|---|---|---|',
  ];
  for (final component in components) {
    final declared = RegExp(
      '^class ${component.name}(<[^>]*>)? ',
      multiLine: true,
    );
    final source = sources.entries
        .where((entry) => declared.hasMatch(entry.value))
        .firstOrNull;
    if (source == null) {
      throw StateError('No class ${component.name} under lib/src');
    }
    final built = RegExp('\\b${component.name}(<[^>]*>)?(\\.\\w+)?\\(');
    List<String> using(RegExp api) => [
      for (final MapEntry(key: path, value: text) in tests.entries)
        if (built.hasMatch(text) && api.hasMatch(text)) path,
    ]..sort();
    final named = {for (final m in _role.allMatches(source.value)) m.group(1)!}
      ..remove('none');
    final only = component.only;
    if (only != null && !named.containsAll(only)) {
      throw StateError('${source.key} does not name ${only.difference(named)}');
    }
    final roles = [
      for (final role in (only ?? named).toList()..sort()) '`$role`',
      ?component.inherited,
    ];
    final exhibit = built.hasMatch(
      tests['sweep_a11y_guidelines_test.dart'] ?? '',
    );
    final inDemo = demos.values.any(built.hasMatch);
    rows.add(
      [
        '',
        '`${component.name}`',
        roles.isEmpty ? '' : roles.join(', '),
        _files(using(_keys)),
        _files(using(_semantics)),
        _files(using(_contrast)),
        exhibit || inDemo
            ? [if (exhibit) 'exhibits', if (inDemo) 'demos'].join(', ')
            : 'none',
        component.gap ?? '',
        '',
      ].join(' | ').trim(),
    );
  }
  return rows.join('\n');
}

final _keys = RegExp('LogicalKeyboardKey|sendKeyEvent');
final _semantics = RegExp(
  'isSemantics|getSemantics|bySemanticsLabel|SemanticsRole|find\\.semantics',
);
final _contrast = RegExp('contrastRatio|textContrastGuideline');

/// Up to three test files by name, then how many more.
String _files(List<String> files) {
  if (files.isEmpty) return 'none';
  final names = [
    for (final file in files.take(3))
      '`${file.replaceFirst(RegExp(r'_test\.dart$'), '')}`',
  ];
  final more = files.length - names.length;
  return '${names.join(', ')}${more > 0 ? ' and $more more' : ''}';
}

/// The Dart files under [directory], by path relative to it.
Map<String, String> _read(String directory) => {
  for (final file
      in Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
    file.path.substring(directory.length + 1): file.readAsStringSync(),
};

/// [document] with what lies between the `name` markers replaced by [table].
String _between(String document, String name, String table) {
  final begin = '<!-- $name:begin -->';
  final end = '<!-- $name:end -->';
  final from = document.indexOf(begin);
  final to = document.indexOf(end);
  if (from < 0 || to < from) {
    throw StateError('$_doc has no $begin … $end');
  }
  return '${document.substring(0, from + begin.length)}\n'
      '$table\n'
      '${document.substring(to)}';
}
