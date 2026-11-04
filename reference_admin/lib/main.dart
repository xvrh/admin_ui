import 'package:material_ui/material_ui.dart';

import 'src/api/shop_api.dart';
import 'src/app.dart';
import 'src/fake/fake_shop_api.dart';
import 'src/services.dart';

/// Potting Shed over its in-memory fake shop: no server, no network.
///
/// The parameters are flutterware's Run knobs: [latencyMs] is how long a
/// list takes to load (other calls scale with it), [seed] the shop to start
/// with, and [signedIn] skips the sign-in page as the owner.
void main({
  int latencyMs = 350,
  DemoSeed seed = DemoSeed.demo,
  bool signedIn = false,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices.fake(
    latency: Latency.scaled(latencyMs),
    seed: seed,
    signInAs: signedIn ? Role.owner : null,
  );
  // A teammate is in the Boston fern, so the editor's presence shows live.
  if (seed == DemoSeed.demo) services.fake!.simulate.peerJoins('p-12');
  runApp(ReferenceAdminApp(services: services));
}
