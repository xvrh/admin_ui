import 'package:material_ui/material_ui.dart';

import '../../routing/routes.dart';
import 'dashboard_screen.dart';

Widget dashboardPage(BuildContext context, Dashboard route) =>
    const DashboardScreen(key: ValueKey('access.dashboardScreen'));
