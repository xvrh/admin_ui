import 'package:admin_ui/src/common/ui/command_registry.dart';
import 'package:admin_ui/src/common/ui/field_registry.dart';
import 'package:admin_ui/src/fields/ui/field_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap({
  required CommandRegistry commands,
  required FormFieldRegistry fields,
  required Widget child,
}) {
  return MaterialApp(
    home: CommandScope(
      registry: commands,
      child: FormFieldScope(
        registry: fields,
        child: FormFieldCommands(child: Scaffold(body: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('a FieldShell registers itself by fieldId', (tester) async {
    final fields = FormFieldRegistry();
    await tester.pumpWidget(
      _wrap(
        commands: CommandRegistry(),
        fields: fields,
        child: const FieldShell(
          label: 'Title',
          fieldId: 'page.title',
          child: TextField(),
        ),
      ),
    );
    expect(fields.entries.map((e) => e.id), contains('page.title'));
    expect(fields.entries.single.label, 'Title');
  });

  testWidgets('a shell without a fieldId registers under an id of its own', (
    tester,
  ) async {
    final fields = FormFieldRegistry();
    await tester.pumpWidget(
      _wrap(
        commands: CommandRegistry(),
        fields: fields,
        child: const FieldShell(label: 'Summary', child: TextField()),
      ),
    );
    // Not its label, which another field may share and an error key may
    // match.
    final entry = fields.entries.single;
    expect(entry.label, 'Summary');
    expect(entry.id, isNot('Summary'));
  });

  testWidgets('FormFieldCommands surfaces fields as a "Fields" command group', (
    tester,
  ) async {
    final commands = CommandRegistry();
    await tester.pumpWidget(
      _wrap(
        commands: commands,
        fields: FormFieldRegistry(),
        child: const Column(
          children: [
            FieldShell(
              label: 'Title',
              fieldId: 'page.title',
              child: TextField(),
            ),
            FieldShell(label: 'Slug', fieldId: 'page.slug', child: TextField()),
          ],
        ),
      ),
    );
    await tester.pump(); // run the deferred contribute()

    final items = commands.active();
    expect(
      items.where((i) => i.group == 'Fields').map((i) => i.title),
      containsAll(['Title', 'Slug']),
    );
    expect(items.firstWhere((i) => i.title == 'Title').id, 'field:page.title');
  });

  testWidgets('unmounting a field withdraws it from the registry', (
    tester,
  ) async {
    final fields = FormFieldRegistry();
    Widget tree(bool showSlug) => _wrap(
      commands: CommandRegistry(),
      fields: fields,
      child: Column(
        children: [
          const FieldShell(
            label: 'Title',
            fieldId: 'page.title',
            child: TextField(),
          ),
          if (showSlug)
            const FieldShell(
              label: 'Slug',
              fieldId: 'page.slug',
              child: TextField(),
            ),
        ],
      ),
    );
    await tester.pumpWidget(tree(true));
    expect(
      fields.entries.map((e) => e.id),
      containsAll(['page.title', 'page.slug']),
    );
    await tester.pumpWidget(tree(false));
    expect(fields.entries.map((e) => e.id), ['page.title']);
  });
}
