import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class BreadcrumbsDemo extends StatefulWidget {
  @Preview(name: 'Breadcrumbs', wrapper: adminUiPreview)
  const BreadcrumbsDemo({super.key});

  @override
  State<BreadcrumbsDemo> createState() => _BreadcrumbsDemoState();
}

class _BreadcrumbsDemoState extends State<BreadcrumbsDemo> {
  String _last = '—';

  void _go(String where) => setState(() => _last = where);

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection('Single item'),
        Breadcrumbs([Crumb('Dashboard', onTap: () => _go('Dashboard'))]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Basic trail'),
        Breadcrumbs([
          Crumb('Home', onTap: () => _go('Home')),
          Crumb('Articles', onTap: () => _go('Articles')),
          Crumb('Editing'),
        ]),
        const Gap(AdminSpacing.lg),
        Text('Navigated to: $_last', style: context.type.bodyMuted),
        const Gap(AdminSpacing.xxl),

        const DemoSection('With leading icons'),
        Breadcrumbs([
          Crumb('Home', icon: Icons.home_outlined, onTap: () => _go('Home')),
          Crumb(
            'Media',
            icon: Icons.perm_media_outlined,
            onTap: () => _go('Media'),
          ),
          Crumb('Spring campaign', icon: Icons.image_outlined),
        ]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Long labels — truncate + tooltip'),
        Breadcrumbs(itemMaxWidth: 140, [
          Crumb('Home', onTap: () => _go('Home')),
          Crumb(
            'Quarterly marketing initiatives',
            onTap: () => _go('Initiatives'),
          ),
          Crumb('Draft: 2026 spring product launch announcement'),
        ]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Overflow — collapse the middle'),
        Breadcrumbs(maxItems: 4, [
          Crumb('Home', onTap: () => _go('Home')),
          Crumb('Workspace', onTap: () => _go('Workspace')),
          Crumb('Content', onTap: () => _go('Content')),
          Crumb('Collections', onTap: () => _go('Collections')),
          Crumb('Blog', onTap: () => _go('Blog')),
          Crumb('Hello world'),
        ]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Narrow — collapses by width'),
        _Frame(
          width: 420,
          child: Breadcrumbs(maxItems: null, [
            Crumb('Home', onTap: () => _go('Home')),
            Crumb('Workspace', onTap: () => _go('Workspace')),
            Crumb('Marketing', onTap: () => _go('Marketing')),
            Crumb('Campaigns', onTap: () => _go('Campaigns')),
            Crumb('Spring launch', onTap: () => _go('Spring launch')),
            Crumb('Landing page draft'),
          ]),
        ),
        const Gap(AdminSpacing.md),
        _Frame(
          width: 240,
          child: Breadcrumbs([
            Crumb('Home', onTap: () => _go('Home')),
            Crumb('Articles', onTap: () => _go('Articles')),
            Crumb('A very long article title that has to ellipsise'),
          ]),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Sibling dropdown — jump laterally'),
        Breadcrumbs([
          Crumb('Home', onTap: () => _go('Home')),
          Crumb(
            'Blog',
            onTap: () => _go('Blog'),
            siblings: [
              Crumb(
                'Pages',
                icon: Icons.description_outlined,
                onTap: () => _go('Pages'),
              ),
              Crumb(
                'Products',
                icon: Icons.sell_outlined,
                onTap: () => _go('Products'),
              ),
              Crumb(
                'Authors',
                icon: Icons.person_outline,
                onTap: () => _go('Authors'),
              ),
            ],
          ),
          Crumb(
            'Hello world',
            siblings: [
              Crumb('Getting started', onTap: () => _go('Getting started')),
              Crumb('Release notes', onTap: () => _go('Release notes')),
            ],
          ),
        ]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Loading — async labels'),
        Breadcrumbs([
          Crumb('Home', onTap: () => _go('Home')),
          const Crumb('', loading: true),
          const Crumb('', loading: true),
        ]),
        const Gap(AdminSpacing.xxl),

        const DemoSection('RTL'),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Breadcrumbs([
            Crumb('الرئيسية', onTap: () => _go('الرئيسية')),
            Crumb('المقالات', onTap: () => _go('المقالات')),
            Crumb('تحرير'),
          ]),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('In a page header'),
        PageHeader(
          'Hello world',
          subtitle: 'Draft · last edited 2h ago',
          breadcrumb: Breadcrumbs([
            Crumb('Home', onTap: () => _go('Home')),
            Crumb('Blog', onTap: () => _go('Blog')),
            Crumb('Hello world'),
          ]),
          actions: [Button.primary('Publish', onPressed: () {})],
        ),
      ],
    );
  }
}

/// A box [width] wide at most, its edges drawn just outside the trail and its
/// actual width captioned under it — the page may clamp it narrower.
class _Frame extends StatelessWidget {
  final double width;
  final Widget child;

  const _Frame({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    const inset = AdminSpacing.sm;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width + 2 * inset),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: context.colors.border),
                  ),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: child,
                ),
              ),
              const Gap(AdminSpacing.xxs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                child: Text(
                  '${(constraints.maxWidth - 2 * inset).round()}px',
                  style: context.type.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
