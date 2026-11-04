import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class PaginationDemo extends StatelessWidget {
  @Preview(name: 'Pagination', wrapper: adminUiPreview)
  const PaginationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 600,
      children: [
        const DemoSection('Short range'),
        LiveValue<int>(
          initial: 2,
          builder: (page, set) =>
              Pagination(page: page, pageCount: 5, onChanged: set),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Long range (ellipsis)'),
        LiveValue<int>(
          initial: 8,
          builder: (page, set) =>
              Pagination(page: page, pageCount: 42, onChanged: set),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Near the start'),
        LiveValue<int>(
          initial: 1,
          builder: (page, set) =>
              Pagination(page: page, pageCount: 42, onChanged: set),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Sizes — small, medium, large'),
        for (final size in ControlSize.values) ...[
          LiveValue<int>(
            initial: 12,
            builder: (page, set) => Pagination(
              page: page,
              pageCount: 120,
              size: size,
              onChanged: set,
            ),
          ),
          const Gap(AdminSpacing.md),
        ],
        const Gap(AdminSpacing.lg),

        const DemoSection('Unknown page count (arrows only)'),
        LiveValue<int>(
          initial: 3,
          builder: (page, set) => Pagination(
            page: page,
            pageCount: null,
            hasNext: page < 6,
            onChanged: set,
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Single page (static)'),
        const Pagination(page: 1, pageCount: 1, onChanged: null),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Pager — a collection footer'),
        LiveValue<int>(
          initial: 3,
          builder: (page, set) => LiveValue<int>(
            initial: 25,
            builder: (size, setSize) => Pager(
              from: (page - 1) * size + 1,
              to: page * size > 1234 ? 1234 : page * size,
              total: 1234,
              hasPrev: page > 1,
              hasNext: page * size < 1234,
              page: page,
              onPage: set,
              pageSize: size,
              pageSizes: const [10, 25, 50, 100],
              onPageSize: (s) {
                setSize(s);
                set(1);
              },
            ),
          ),
        ),
        const Gap(AdminSpacing.lg),
        const Pager(
          from: 51,
          to: 75,
          total: null,
          hasPrev: true,
          hasNext: true,
          page: 3,
          onPage: _noop,
        ),
      ],
    );
  }
}

void _noop(int _) {}
