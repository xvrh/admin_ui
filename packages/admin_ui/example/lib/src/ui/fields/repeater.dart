import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class RepeaterDemo extends StatelessWidget {
  @Preview(name: 'Repeater / array', wrapper: adminUiPreview)
  const RepeaterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 640,
      children: [
        const DemoSection('Reorder · add · remove'),
        const _EditableList(
          initial: ['Home', 'About us', 'Pricing', 'Contact'],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Inside a boxed FieldGroup'),
        const FieldGroup(
          title: 'FAQ',
          description: 'Questions shown on the help page.',
          boxed: true,
          children: [
            _EditableList(
              initial: ['What is your refund policy?', 'How do I cancel?'],
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Empty → add'),
        const _EditableList(initial: []),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Needs at least one row'),
        const _RequiredList(),
      ],
    );
  }
}

extension type _Menu(FormScope _s) {
  RecordListCell<_Link> get links => _s.recordList('links', build: _Link.new);
}

extension type _Link(RecordScope _e) {
  ValueCell<String> get url => _e.text('url');
}

/// A [RecordListField] whose `ListRules` want a row: empty, it is marked
/// required and says so under the list, and its add button is where a
/// summary's link takes focus.
class _RequiredList extends StatefulWidget {
  const _RequiredList();

  @override
  State<_RequiredList> createState() => _RequiredListState();
}

class _RequiredListState extends State<_RequiredList> {
  late final _form = ValueFormController<int>(
    read: (s) => _Menu(s).links.elements.length,
    write: (s, _) {},
    rules: (s) => [ListRules(_Menu(s).links)],
    mode: ValidationMode.always,
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueForm(
      controller: _form,
      child: RecordListField<_Link>(
        _Menu(_form.scope).links,
        label: 'Footer links',
        description: 'Shown under every page.',
        addLabel: 'Add link',
        item: (link) => Field(link.url, label: 'Address', hint: 'https://…'),
      ),
    );
  }
}

class _EditableList extends StatefulWidget {
  final List<String> initial;

  const _EditableList({required this.initial});

  @override
  State<_EditableList> createState() => _EditableListState();
}

class _EditableListState extends State<_EditableList> {
  late int _nextId = widget.initial.length;
  late final List<({int id, String text})> _items = [
    for (var i = 0; i < widget.initial.length; i++)
      (id: i, text: widget.initial[i]),
  ];

  void _add() => setState(
    () => _items.add((id: _nextId++, text: 'New item ${_items.length + 1}')),
  );

  void _remove(int index) => setState(() => _items.removeAt(index));

  void _reorder(int oldIndex, int newIndex) =>
      setState(() => _items.insert(newIndex, _items.removeAt(oldIndex)));

  @override
  Widget build(BuildContext context) {
    return Repeater(
      itemCount: _items.length,
      keyForItem: (i) => ValueKey(_items[i].id),
      onReorder: _reorder,
      onRemove: _remove,
      onAdd: _add,
      itemBuilder: (context, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_items[i].text, style: context.type.bodyStrong),
          const Gap(AdminSpacing.sm),
          const TextBody(hint: 'https://…'),
        ],
      ),
    );
  }
}
