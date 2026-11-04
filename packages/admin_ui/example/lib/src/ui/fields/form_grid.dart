import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// One contact form on a `FormGrid` of one, two or three columns, in three
/// frames whose widths fall in each width class: the grid counts its
/// columns from its own width, not the window's. A street address spans two
/// columns and the notes the whole row; each frame's caption gives the
/// grid's width and column count.
///
/// The last name holds focus in the widest frame, so its halo shows whole
/// between its neighbours: the grid never clips.
///
/// In a window narrower than the frames, they stack and narrow with it, and
/// each grid takes the columns of the width it is left.
class FormGridDemo extends StatelessWidget {
  @Preview(name: 'Form grid', wrapper: adminUiPreview)
  const FormGridDemo({super.key});

  @override
  Widget build(BuildContext context) => const DemoPage(
    // The expanded frame, then the compact and medium ones side by side.
    maxWidth: 360 + AdminSpacing.xxl + 720 + 2 * 32,
    children: [
      DemoSection('Width classes — the grid’s own width sets its columns'),
      Wrap(
        spacing: AdminSpacing.xxl,
        runSpacing: AdminSpacing.xxl,
        children: [
          // First, so the field holding focus is near the top of the page
          // and opening it scrolls nowhere.
          _Frame(width: 1000, focused: true),
          _Frame(width: 360),
          _Frame(width: 720),
        ],
      ),
    ],
  );
}

extension type _Contact(FormScope _s) {
  static const ids = [
    'firstName',
    'lastName',
    'email',
    'country',
    'street',
    'notes',
  ];

  ValueCell<String> get firstName => _s.text('firstName');
  ValueCell<String> get lastName => _s.text('lastName');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get country => _s.text('country');
  ValueCell<String> get street => _s.text('street');
  ValueCell<String> get notes => _s.text('notes');
}

/// A card at most [width] wide holding the form.
class _Frame extends StatefulWidget {
  final double width;

  /// Pins focus on the last name.
  final bool focused;

  const _Frame({required this.width, this.focused = false});

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  static const _columns = FormColumns(compact: 1, medium: 2, expanded: 3);

  static const _countries = [
    SelectOption(value: 'ca', label: 'Canada'),
    SelectOption(value: 'fr', label: 'France'),
    SelectOption(value: 'jp', label: 'Japan'),
  ];

  final _form = ValueFormController<Map<String, String>>(
    read: (s) => {for (final id in _Contact.ids) id: s.text(id).value},
    write: (s, value) => value.forEach((id, v) => s.text(id).set(v)),
    initial: const {
      'firstName': 'Ada',
      'lastName': '',
      'email': 'ada@example.com',
      'country': 'fr',
      'street': '12 Rue des Lilas',
      'notes': '',
    },
    rules: (s) {
      final f = _Contact(s);
      return [
        FieldRules(f.firstName, validators: [Validators.required()]),
        FieldRules(
          f.email,
          validators: [Validators.required(), Validators.email()],
        ),
      ];
    },
  );

  final _focus = FocusScopeNode(debugLabel: 'Form grid pinned focus');

  @override
  void initState() {
    super.initState();
    if (!widget.focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.traversalDescendants.firstOrNull?.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _form.dispose();
    super.dispose();
  }

  static String _widthClass(double width) {
    if (width < FormGrid.compactMaxWidth) return 'Compact';
    if (width < FormGrid.mediumMaxWidth) return 'Medium';
    return 'Expanded';
  }

  @override
  Widget build(BuildContext context) {
    final f = _Contact(_form.scope);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: Panel(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final count = _columns.resolve(width);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_widthClass(width)} · ${width.round()} wide · '
                  '$count ${count == 1 ? 'column' : 'columns'}',
                  style: context.type.caption.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
                const Gap(AdminSpacing.lg),
                ValueForm(
                  controller: _form,
                  child: FormGrid(
                    columns: _columns,
                    children: [
                      Field(f.firstName, label: 'First name'),
                      FocusScope(
                        node: _focus,
                        child: Field(
                          f.lastName,
                          label: 'Last name',
                          hint: 'Lovelace',
                        ),
                      ),
                      Field(
                        f.email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SelectField(
                        f.country,
                        label: 'Country',
                        options: _countries,
                      ),
                      FormGridItem(
                        span: 2,
                        child: Field(f.street, label: 'Street address'),
                      ),
                      FormGridItem(
                        fullWidth: true,
                        child: Field(
                          f.notes,
                          label: 'Notes',
                          hint: 'Delivery instructions, a gate code…',
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
