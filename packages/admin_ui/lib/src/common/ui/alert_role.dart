import 'package:flutter/foundation.dart';

/// Whether the platform reads a node with `SemanticsRole.alert` out by
/// itself, at once and over what it was saying.
///
/// The web does: the role becomes ARIA's `alert`, an assertive live region
/// whose words are read as it arrives and as they change. Android, iOS and
/// the desktop embedders have no such role, and read a message out only from
/// a live region. The framework refuses the two on one node, and the two
/// around one message would have the web read it twice, so an urgent message
/// is an alert whose words are a live region wherever the role says nothing.
@internal
bool get alertRoleAnnounces => debugAlertRoleAnnounces ?? kIsWeb;

/// Stands in for the platform in a test of [alertRoleAnnounces]; null is the
/// platform's own answer.
@visibleForTesting
bool? debugAlertRoleAnnounces;
