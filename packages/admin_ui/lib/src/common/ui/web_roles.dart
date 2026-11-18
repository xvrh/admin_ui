import 'package:flutter/foundation.dart';

/// Whether the platform reads the roles only the web has a name for: an
/// alert, a landmark, a tab panel.
///
/// The web does: each becomes the ARIA role of its name. Android, iOS and
/// the desktop embedders read none of them, and announce a node from its
/// flags, its label and its value alone. So what goes with such a role
/// follows the platform:
///
/// - a landmark and a tab panel are named containers, and on a phone a node
///   with a name is a stop of its own, a rectangle the size of the page read
///   before the page's first control. They are given, role and name, only
///   where the role is read;
/// - an alert's words are a live region wherever the role says nothing, and
///   not where it is read out, or the web would read the message twice (the
///   framework refuses the two on one node).
@internal
bool get webRolesAreRead => debugWebRolesAreRead ?? kIsWeb;

/// Stands in for the platform in a test of [webRolesAreRead]; null is the
/// platform's own answer.
@visibleForTesting
bool? debugWebRolesAreRead;
