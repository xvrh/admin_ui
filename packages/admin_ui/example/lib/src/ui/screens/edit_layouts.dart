import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// A bake-off of edit-page layouts so we can pick one. Switch the [_Variant] and
/// toggle the breadcrumb live:
///  - **Header with save** — save controls live in the page header (compact).
///  - **Header + save bar** — page header on top, a dedicated save-bar strip
///    under it (keeps the save bar).
///  - **Sticky bottom bar** — page header on top, save bar pinned at the bottom.
///
/// In all three, Version history hides under the ⋯ "more actions" menu.
class EditLayoutsDemo extends StatefulWidget {
  @Preview(name: 'Edit layouts (compare)', wrapper: adminUiPreview)
  const EditLayoutsDemo({super.key});

  @override
  State<EditLayoutsDemo> createState() => _EditLayoutsDemoState();
}

enum _Variant { headerSave, headerPlusBar, bottomBar }

class _EditLayoutsDemoState extends State<EditLayoutsDemo> {
  final _form = _MockForm();
  _Variant _variant = _Variant.headerSave;
  bool _breadcrumb = true;
  bool _loading = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToastScope(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            _controls(context),
            Expanded(child: _frame(context)),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          Text('Layout', style: context.type.bodyStrong),
          const Gap(AdminSpacing.lg),
          Segmented<_Variant>(
            value: _variant,
            onChanged: (v) => setState(() => _variant = v),
            segments: const [
              SegmentOption(_Variant.headerSave, 'Header with save'),
              SegmentOption(_Variant.headerPlusBar, 'Header + save bar'),
              SegmentOption(_Variant.bottomBar, 'Sticky bottom bar'),
            ],
          ),
          const Spacer(),
          Toggle(
            value: _loading,
            label: 'Loading',
            onChanged: (v) => setState(() => _loading = v),
          ),
          const Gap(AdminSpacing.lg),
          Toggle(
            value: _breadcrumb,
            label: 'Breadcrumb',
            onChanged: (v) => setState(() => _breadcrumb = v),
          ),
        ],
      ),
    );
  }

  /// The simulated shell content area, so each variant is judged in context.
  Widget _frame(BuildContext context) {
    switch (_variant) {
      case _Variant.headerSave:
        return PageScaffold(
          title: _loading ? '' : 'Aurora Lamp',
          titleLoading: _loading,
          breadcrumb: _crumbs(),
          maxWidth: _maxWidth,
          actions: [
            _previewButton(context),
            FormActions(
              controller: _form,
              showDiscard: true,
              overflowActions: _overflow(context),
            ),
          ],
          body: _fields(context),
        );
      case _Variant.headerPlusBar:
        return Column(
          children: [
            PageHeader(
              _loading ? '' : 'Aurora Lamp',
              titleLoading: _loading,
              breadcrumb: _crumbs(),
              actions: [_previewButton(context)],
            ),
            FormSaveBar(
              controller: _form,
              showDiscard: true,
              overflowActions: _overflow(context),
            ),
            _scrollArea(context),
          ],
        );
      case _Variant.bottomBar:
        return Column(
          children: [
            PageHeader(
              _loading ? '' : 'Aurora Lamp',
              titleLoading: _loading,
              breadcrumb: _crumbs(),
              actions: [_previewButton(context)],
            ),
            _scrollArea(context),
            FormSaveBar(
              controller: _form,
              showDiscard: true,
              overflowActions: _overflow(context),
              placement: SaveBarPlacement.bottom,
            ),
          ],
        );
    }
  }

  static const _maxWidth = 860.0;

  Widget? _crumbs() => _breadcrumb
      ? Breadcrumbs([
          const Crumb('Products'),
          Crumb(_loading ? '' : 'Aurora Lamp', loading: _loading),
        ])
      : null;

  List<SaveBarAction> _overflow(BuildContext context) => [
    SaveBarAction(
      label: 'Version history',
      icon: Icons.history,
      onPressed: () => _toast(context, 'Open version history'),
    ),
    SaveBarAction(
      label: 'Duplicate',
      icon: Icons.copy_all_outlined,
      onPressed: () => _toast(context, 'Duplicate'),
    ),
    SaveBarAction(
      label: 'Delete',
      icon: Icons.delete_outline,
      danger: true,
      onPressed: () => _toast(context, 'Delete'),
    ),
  ];

  Widget _previewButton(BuildContext context) => IconAction(
    Icons.visibility_outlined,
    label: 'Preview',
    onPressed: () => _toast(context, 'Preview'),
  );

  void _toast(BuildContext context, String msg) =>
      ToastScope.of(context).show(Toast(msg));

  Widget _scrollArea(BuildContext context) {
    final gutter = PageHeader.gutterOf(context);
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          gutter,
          AdminSpacing.xxl,
          gutter,
          AdminSpacing.xxl,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: _fields(context),
          ),
        ),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldShell(
                label: 'Name',
                child: TextBody(value: 'Aurora Lamp', onChanged: _touch),
              ),
              const Gap(AdminSpacing.xl),
              FieldShell(
                label: 'Slug',
                child: TextBody(value: 'aurora-lamp', onChanged: _touch),
              ),
              const Gap(AdminSpacing.xl),
              FieldShell(
                label: 'Description',
                child: TextBody(
                  hint: 'A warm bedside glow…',
                  onChanged: _touch,
                ),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        Panel(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldShell(
                label: 'Price',
                child: TextBody(value: '€ 49.00', onChanged: _touch),
              ),
              const Gap(AdminSpacing.xl),
              FieldShell(
                label: 'SKU',
                child: TextBody(value: 'AUR-001', onChanged: _touch),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _touch(String _) => _form.markDirty();
}

/// A throwaway [FormController] so the demo's Save/Discard come alive.
class _MockForm extends FormController {
  FormStatus _status = FormStatus.dirty;

  @override
  FormStatus get status => _status;

  @override
  Map<String, String?> get errors => const {};

  void markDirty() {
    if (_status == FormStatus.clean || _status == FormStatus.submitted) {
      _status = FormStatus.dirty;
      notifyListeners();
    }
  }

  @override
  Future<void> submit() async {
    _status = FormStatus.submitting;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _status = FormStatus.submitted;
    notifyListeners();
  }

  @override
  void reset() {
    _status = FormStatus.clean;
    notifyListeners();
  }
}
