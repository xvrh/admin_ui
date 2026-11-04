import 'package:flutterware/flutter_test.dart';

// One folder per form factor, each with its own head device, so one `shots`
// command with no --devices writes one coherent, separately numbered set
// per folder: <language>/window, <language>/iphone-16, <language>/window-wide.

/// The desktop story: `test/scenarios/story/desktop`.
const desktopStory = ScenarioProfile(
  'desktop',
  devices: [Devices.window, Devices.smallWindow, Devices.wideWindow],
  languages: ['en', 'fr', 'ar'],
);

/// The phone story: `test/scenarios/story/phone`.
const phoneStory = ScenarioProfile(
  'phone',
  devices: [
    Devices.iphone16,
    Devices.iphoneSe,
    Devices.androidMedium,
    Devices.iPad,
  ],
  languages: ['en', 'fr', 'ar'],
);

/// The theme gallery: `test/scenarios/themes`.
const themeGallery = ScenarioProfile(
  'themes',
  devices: [Devices.wideWindow],
  languages: ['en', 'ar'],
);

// FRICTION(T-006): a folder cannot be kept out of the shots export, so the
// smoke walk gets a head of its own.
/// The smoke walk: `test/scenarios/smoke`. Headed by the small window, the
/// medium layout nothing else leads with, so its set stays apart from the
/// story's.
const smokeWalk = ScenarioProfile(
  'smoke',
  devices: [Devices.smallWindow, Devices.window, Devices.iphone16],
  languages: ['en', 'ar'],
);
