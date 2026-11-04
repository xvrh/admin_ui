import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// Unsaved edits guarded against leaving the page through the app's
/// navigation: the settings page opens with an edit made, so a sidebar item
/// asks to discard it before it opens its page, and "Filters", which opens
/// a panel rather than a page, does not. Discarding in the prompt, or
/// saving, lets the next item go at once. In a phone-sized window the items
/// are in the shell's drawer, and ask the same.
class LeaveGuardDemo extends StatefulWidget {
  /// Opens with the leave prompt showing.
  final bool prompt;

  @Preview(name: 'Leave guard', wrapper: adminUiPreview)
  const LeaveGuardDemo({super.key}) : prompt = false;

  @Preview(name: 'Leave guard (prompt open)', wrapper: adminUiPreview)
  const LeaveGuardDemo.prompt({super.key}) : prompt = true;

  @override
  State<LeaveGuardDemo> createState() => _LeaveGuardDemoState();
}

class _LeaveGuardDemoState extends State<LeaveGuardDemo> {
  String _page = 'General';
  bool _filters = false;

  static const _nav = [
    ('Workspace', null),
    ('Dashboard', Icons.dashboard_outlined),
    ('Pages', Icons.description_outlined),
    ('Settings', null),
    ('General', Icons.settings_outlined),
    ('Members', Icons.group_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminScope(
      child: Shell(
        // Built below the top bar, in the palette it draws with.
        topBar: TopBar(
          leading: Builder(
            builder: (context) =>
                Text('Acme Admin', style: context.type.bodyStrong),
          ),
        ),
        sidebar: Sidebar(
          entries: [
            for (final (label, icon) in _nav)
              if (icon == null)
                NavSection(label)
              else
                NavItem(
                  label,
                  icon: icon,
                  selected: _page == label,
                  onTap: () => setState(() => _page = label),
                ),
            NavItem(
              'Filters',
              icon: Icons.filter_list_rounded,
              selected: _filters,
              guarded: false,
              onTap: () => setState(() => _filters = !_filters),
            ),
          ],
        ),
        child: _page == 'General'
            ? _GeneralSettings(prompt: widget.prompt)
            : PageScaffold(
                title: _page,
                body: Text(
                  'The settings page was left, and its edits with it.',
                  style: context.type.body.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ),
      ),
    );
  }
}

extension type _Workspace(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<bool> get listed => _s.boolean('listed');
}

typedef _WorkspaceValue = ({String name, String email, bool listed});

/// The settings page, which owns its form: leaving it drops the edits.
class _GeneralSettings extends StatefulWidget {
  final bool prompt;

  const _GeneralSettings({required this.prompt});

  @override
  State<_GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<_GeneralSettings> {
  late final _form = ValueFormController<_WorkspaceValue>(
    read: (s) {
      final w = _Workspace(s);
      return (name: w.name.value, email: w.email.value, listed: w.listed.value);
    },
    write: (s, v) => _Workspace(s)
      ..name.set(v.name)
      ..email.set(v.email)
      ..listed.set(v.listed),
    initial: (name: 'Acme', email: 'hello@acme.test', listed: false),
    rules: (s) {
      final w = _Workspace(s);
      return [
        FieldRules(w.name, validators: [Validators.required()]),
        FieldRules(w.email, validators: [Validators.email()]),
      ];
    },
    onSubmit: (_) async {},
  );

  @override
  void initState() {
    super.initState();
    // The page is pinned with an edit made.
    _Workspace(_form.scope).name.set('Acme Studio');
    if (widget.prompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) LeaveGuardScope.confirmLeave(context);
      });
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = _Workspace(_form.scope);
    return UnsavedChangesGuard(
      controller: _form,
      child: ValueForm(
        controller: _form,
        child: PageScaffold(
          title: 'General',
          subtitle: 'How the workspace appears to members and visitors',
          maxWidth: 560,
          actions: [FormActions(controller: _form, showDiscard: true)],
          body: FieldGroup(
            children: [
              Field(w.name, label: 'Workspace name'),
              Field(w.email, label: 'Contact email'),
              BooleanField(
                w.listed,
                label: 'Listed in the directory',
                description: 'Visitors can find the workspace by name',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
