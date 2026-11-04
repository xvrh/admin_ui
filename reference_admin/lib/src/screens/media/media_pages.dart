import 'package:flutter/widgets.dart';

import '../../keys/media_team_keys.dart';
import '../../routing/routes.dart';
import 'media_screen.dart';

Widget mediaPage(BuildContext context, Media route) =>
    const MediaScreen(key: MediaTeamKeys.mediaPage);
