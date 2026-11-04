import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:flutter/widgets.dart';

import '../api/shop_api.dart';
import '../l10n/ref_strings.dart';

/// How each status reads in a `StatusPill`, in the page's language and the
/// theme's status colours: one place, so a status looks the same on the
/// dashboard, the list and the detail page.
extension StatusMetas on BuildContext {
  StatusMeta orderStatusMeta(OrderStatus status) {
    final c = colors;
    final label = strings.shell.orderStatus(status);
    return switch (status) {
      OrderStatus.pending => StatusMeta(label, c.foregroundSubtle, ring: true),
      OrderStatus.paid => StatusMeta(label, c.info),
      OrderStatus.picking || OrderStatus.packed => StatusMeta(label, c.warning),
      OrderStatus.shipped => StatusMeta(label, c.primary),
      OrderStatus.delivered => StatusMeta(label, c.success),
      OrderStatus.cancelled => StatusMeta(label, c.danger),
    };
  }

  StatusMeta productStatusMeta(ProductStatus status) {
    final c = colors;
    final label = strings.shell.productStatus(status);
    return switch (status) {
      ProductStatus.draft => StatusMeta(label, c.foregroundSubtle, ring: true),
      ProductStatus.active => StatusMeta(label, c.success),
      ProductStatus.archived => StatusMeta(label, c.foregroundMuted),
    };
  }

  StatusMeta staffStatusMeta(StaffStatus status) {
    final c = colors;
    final label = strings.shell.staffStatus(status);
    return switch (status) {
      StaffStatus.active => StatusMeta(label, c.success),
      StaffStatus.invited => StatusMeta(label, c.info, ring: true),
      StaffStatus.deactivated => StatusMeta(label, c.foregroundMuted),
    };
  }
}
