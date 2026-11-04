import 'package:flutter/foundation.dart';

/// Keys of this area's controls, as `ValueKey('<area>.<thing>')`.
abstract final class MediaTeamKeys {
  static const mediaPage = ValueKey('media_team.mediaPage');
  static const teamPage = ValueKey('media_team.teamPage');

  // media
  static const library = ValueKey('media.library');
  static const usageFilter = ValueKey('media.usageFilter');
  static const crop = ValueKey('media.crop');

  // team
  static const staffList = ValueKey('team.staffList');
  static const invite = ValueKey('team.invite');
  static const inviteDialog = ValueKey('team.inviteDialog');
  static const inviteEmail = ValueKey('team.inviteEmail');
  static const inviteRole = ValueKey('team.inviteRole');

  /// The actions menu on [staffId]'s row or card.
  static ValueKey<String> memberMenu(String staffId) =>
      ValueKey('team.memberMenu.$staffId');
}
