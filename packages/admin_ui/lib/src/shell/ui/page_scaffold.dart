/// @docImport '../../common/ui/tabs.dart';
/// @docImport 'shell.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import 'page_header.dart';

/// The standard layout for a page inside the [Shell]'s content area: a
/// [PageHeader] over a body with the one canonical content gutter.
///
/// This is the single source of a page's title + padding — screens should not
/// add their own outer [Padding] or re-roll a title. The header owns the top
/// padding; the body adds the matching left/right/bottom gutter, which narrows
/// in a compact window ([PageHeader.gutterOf]).
///
/// [maxWidth] constrains and centers the content column — the header's title
/// and actions and the body together, so they line up at every width, with
/// the gutter outside it. Use it for forms and detail views (e.g. ~860) so
/// lines stay readable; leave null for tables/collections that want the full
/// width. [headerMaxWidth] sets the header's column apart, e.g.
/// `double.infinity` for a header spanning the page over a narrower body.
///
/// [scrollable] wraps the body in a scroll view (the default). Set it false when
/// the [body] manages its own scrolling (e.g. a `Collection`); the body then
/// fills the remaining height inside the gutter.
///
/// [tabs] puts a tab strip under the header, typically a [Tabs] whose
/// selection picks the [body]. It stays put while the body scrolls.
///
/// [bottomBar] docks a full-width bar under the body (outside the gutter, so it
/// owns its own padding) — for a detail editor's save/publish controls.
class PageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? breadcrumb;
  final Widget? leading;

  /// Inline widget shown right of the title — e.g. a status pill.
  final Widget? titleTrailing;
  final bool titleLoading;
  final List<Widget> actions;
  final double? maxWidth;

  /// The header's content width, when it should differ from [maxWidth].
  final double? headerMaxWidth;

  /// A tab strip under the header, in the header's column and gutter; the
  /// body starts a gap below it, and scrolls under it.
  final Widget? tabs;

  final bool scrollable;
  final Widget body;
  final Widget? bottomBar;

  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb,
    this.leading,
    this.titleTrailing,
    this.titleLoading = false,
    this.actions = const [],
    this.maxWidth,
    this.headerMaxWidth,
    this.tabs,
    this.scrollable = true,
    required this.body,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    // The content gutter: [PageHeader]'s side gutter, with no top (the header
    // owns it, or a gap under the tabs) and a bottom breather.
    final side = PageHeader.gutterOf(context);
    final tabs = this.tabs;
    final gutter = EdgeInsets.fromLTRB(
      side,
      tabs == null ? 0 : AdminSpacing.xl,
      side,
      AdminSpacing.xxl,
    );

    Widget content = body;
    if (maxWidth != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    final Widget bodyArea;
    if (scrollable) {
      bodyArea = Expanded(
        child: SingleChildScrollView(padding: gutter, child: content),
      );
    } else {
      bodyArea = Expanded(
        child: Padding(padding: gutter, child: content),
      );
    }

    // The header and the tabs keep their gutter inside their box, so their
    // column is the body's plus a gutter each side.
    final headerWidth = headerMaxWidth ?? maxWidth;
    Widget column(Widget child) => headerWidth == null || !headerWidth.isFinite
        ? child
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: headerWidth + 2 * side),
              child: child,
            ),
          );

    final header = PageHeader(
      title,
      subtitle: subtitle,
      breadcrumb: breadcrumb,
      leading: leading,
      titleTrailing: titleTrailing,
      titleLoading: titleLoading,
      actions: actions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        column(header),
        if (tabs != null)
          column(
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: tabs,
              ),
            ),
          ),
        bodyArea,
        ?bottomBar,
      ],
    );
  }
}
