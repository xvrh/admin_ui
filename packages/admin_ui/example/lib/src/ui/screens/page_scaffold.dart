import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// The standard page layout: a [PageScaffold] with a breadcrumb, title, and the
/// save controls living in the header itself ("header with save in it") via
/// [FormActions], over a width-constrained scrolling body of panels. The
/// `maxWidth` column holds the header too, so the title and Save line up with
/// the panels' edges at any window width. This is what every edit screen in
/// the app sits on.
class PageScaffoldDemo extends StatefulWidget {
  /// The window width the page is drawn at, or null for the whole preview.
  final double? windowWidth;

  /// Whether a tab strip under the header switches the body.
  final bool withTabs;

  @Preview(name: 'Page scaffold', wrapper: adminUiPreview)
  const PageScaffoldDemo({super.key}) : windowWidth = null, withTabs = false;

  /// The page in a 420px window: the header actions wrap under the title and
  /// the gutter narrows to 16.
  @Preview(name: 'Page scaffold (narrow window)', wrapper: adminUiPreview)
  const PageScaffoldDemo.narrow({super.key})
    : windowWidth = 420,
      withTabs = false;

  /// The page with a Details / History tab strip in the scaffold's `tabs`
  /// slot: it lines up with the header and stays put while a tab scrolls.
  @Preview(name: 'Page scaffold (tabs)', wrapper: adminUiPreview)
  const PageScaffoldDemo.tabs({super.key})
    : windowWidth = null,
      withTabs = true;

  @override
  State<PageScaffoldDemo> createState() => _PageScaffoldDemoState();
}

class _PageScaffoldDemoState extends State<PageScaffoldDemo> {
  final _form = _MockForm();
  var _tab = 0;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.windowWidth;
    if (width == null) return _page(context);
    return _Window(width: width, child: _page(context));
  }

  Widget _page(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: PageScaffold(
        title: 'Aurora Lamp',
        maxWidth: 860,
        breadcrumb: const Breadcrumbs([
          Crumb('Products'),
          Crumb('Aurora Lamp'),
        ]),
        actions: [
          IconAction(
            Icons.visibility_outlined,
            label: 'Preview',
            onPressed: () {},
          ),
          FormActions(controller: _form, showDiscard: true),
        ],
        tabs: widget.withTabs
            ? Tabs(
                tabs: const [TabItem('Details'), TabItem('History')],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              )
            : null,
        body: _tab == 1
            ? const _History()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Panel(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FieldShell(
                          label: 'Name',
                          child: TextBody(
                            value: 'Aurora Lamp',
                            onChanged: _touch,
                          ),
                        ),
                        const Gap(AdminSpacing.xl),
                        FieldShell(
                          label: 'Slug',
                          child: TextBody(
                            value: 'aurora-lamp',
                            onChanged: _touch,
                          ),
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
              ),
      ),
    );
  }

  void _touch(String _) => _form.markDirty();
}

/// The History tab: who changed the product, newest first.
class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Timeline(
        entries: [
          for (final (who, what, at) in const [
            ('Sam Rivera', 'Changed the price', '2 hours ago'),
            ('Alex Kim', 'Rewrote the description', 'Yesterday'),
            ('Sam Rivera', 'Created the product', 'Mar 3'),
          ])
            TimelineEntry(
              title: what,
              subtitle: who,
              timestamp: at,
              leading: Avatar(name: who, size: 28),
            ),
        ],
      ),
    );
  }
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

/// Draws [child] as a window [width] wide: the width it lays out in and the
/// size [MediaQuery] reports, framed by a hairline.
class _Window extends StatelessWidget {
  final double width;
  final Widget child;

  const _Window({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ColoredBox(
      color: context.colors.surfaceMuted,
      child: Center(
        child: Container(
          width: width,
          foregroundDecoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: context.colors.border),
            ),
          ),
          child: MediaQuery(
            data: media.copyWith(size: Size(width, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
