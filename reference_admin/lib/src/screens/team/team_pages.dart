import 'package:flutter/widgets.dart';

import '../../keys/media_team_keys.dart';
import '../../routing/routes.dart';
import 'team_screen.dart';

Widget teamPage(BuildContext context, Team route) =>
    const TeamScreen(key: MediaTeamKeys.teamPage);
