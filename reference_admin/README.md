# Potting Shed: the admin_ui reference app

The back office of **Potting Shed**, an invented plant and garden shop that
sells in English, French and Arabic, prices in euros, and has four staff
roles. It is built on `packages/admin_ui` the way an outside team would build
on it, through the kit's public barrels only, and it serves three purposes:

1. It proves the kit can carry a high-quality admin.
2. It records every place the kit made it work around something, in
   [FRICTION.md](FRICTION.md).
3. Its flutterware scenarios are both its regression suite and its
   screenshot export.

There is no server and no network: the app runs on `FakeShopApi`, an
in-memory shop seeded deterministically. All data is invented.

## Run it

From the repository root, with `alias fw='fvm dart run flutterware'`:

```sh
fw run run launch --device=macos --entrypoint='Reference admin' --wait=true
```

The entry point's knobs: `latencyMs` (how long a list takes; other calls
scale with it), `seed` (`demo`, or `empty` for a shop that has setup to do)
and `signedIn` (start as the owner). The sign-in page lists the demo
accounts of `lib/src/fake/seed_accounts.dart`, one per role, because
`AppServices.fake` hands them over as `demoSignIns`; over a real `ShopApi`
that is null and the page shows no hint. No screen imports `lib/src/fake/`
(`guards_test` checks). On the web, the browser's URL is the first page, so
a deep link or a reload lands where it points.

The shop's name and mark sit at the start of the top bar, not in
`Sidebar.header` as the spec drew them: the kit's frame puts the logo in the
top bar, above the sidebar, and a header in the sidebar as well would name
the shop twice. The phone's drawer covers the top bar, so it is the one
sidebar with a header: the same mark, on a row as tall as the bar. A shop
not named yet (the `empty` seed) shows the product's name until setup names
it.

## Layout

| Path | What |
|---|---|
| `lib/src/api/` | `ShopApi`, the models, `Endpoint` (one per call), `ShopError` |
| `lib/src/fake/` | `FakeShopApi` over one `FakeShopDb`: seed, latency, faults and hold gates, the call log, realtime, presence, media and saved views |
| `lib/src/routing/` | Typed routes, the URL parser, the single-page Router 2.0 delegate and its guards |
| `lib/src/frame/` | The frame: sidebar or rail or phone drawer, top bar, palette, inbox, user menu, offline banner, progress bar |
| `lib/src/appearance/` | The seven themes (six kit ones and Greenhouse), accents, the appearance controller |
| `lib/src/session/` | Who is signed in, and the role matrix |
| `lib/src/l10n/` | `RefStrings` (one section per area), the kit-strings override, money and dates |
| `lib/src/keys/` | Scenario keys, one file per area |
| `lib/src/screens/` | One folder per area; `pages.dart` maps a route to its page |
| `lib/src/widgets/` | Shared app widgets |
| `test/scenarios/` | The flutterware scenarios: `story/desktop`, `story/phone`, `themes`, `smoke` |
| `test/support/` | The harness (`openShop`, gestures, settle helpers), profiles, and the fonts, through the kit's `loadAdminFonts` |
| `test/unit/` | Seed digest and counts, routes, faults, permissions; the guards |
| `test/sweep/` | Every page across themes, modes, languages and widths |
| `tool/` | Media generator, kit coverage, friction summary |

Each area's files are owned by one work package: the screens, the
`strings_<area>.dart` section and the `<area>_keys.dart` file. The core owns
everything else, and adds endpoints or seed changes on request.

## Writing a scenario

Build the app inside the body with `openShop`, so every `split` branch gets
a fresh shop, then drive it and assert what no picture shows: the calls that
went out (`shop.calls.countOf(Endpoint.x)`), what the fake database holds,
and the route.

```dart
scenario('Refunding an order', (s) async {
  final shop = await openShop(s, at: const OrderDetail(1042));
  // …
  expect(shop.calls.countOf(Endpoint.refund), 2);
});
```

- Target controls by their `ValueKey('<area>.<thing>')`, never by English
  words. A kit control that takes no key is found by the kit's localized
  word: `s.kit.<section>.<member>`, or the app's: `s.strings.<area>.<member>`.
- Shot names are English, `Area · state`, and unique within a folder
  (`guards_test` checks). About fifteen across the story carry
  `tags: ['tour']`.
- The fake answers in fake time. **Never await a shop call inside
  `s.act`**: start it and let the step settle (T-007).
- Timers draw no frames, so settling on frames stops before a debounce or a
  coalesce fires: use `searchIn`, `realtime`, or `Settle.until`. Calls in
  flight show the frame's progress bar, which keeps frames coming until the
  data lands.
- For a loading picture, arm a hold: `before: (shop) => gate =
  shop.faults.hold(Endpoint.stats)`, pump with `settle: Settle.frames(2)`,
  then `gate.release()`.
- The frame calls `shell.badges` and `notifications.list` as it mounts.

## Export the screens

From the repository root, with `alias fw='fvm dart run flutterware'`. Every
action is also an MCP call (`flutterware_invoke`, plugin `scenarios`).

```sh
# 1. The screenshot set: desktop story, phone story, theme gallery and smoke walk, in three languages
fw run scenarios shots --package=reference_admin --languages=en,fr,ar \
  --output=build/reference_admin/screens
#   -> build/reference_admin/screens/{en,fr,ar}/{window,iphone-16,window-wide,window-small}/NN-<slug>.png

# 2. Highlights only (shots tagged 'tour')
fw run scenarios shots --package=reference_admin --languages=en,fr,ar \
  --tag=tour --output=build/reference_admin/tour

# 3. One set (shots takes one --file, T-003)
fw run scenarios shots --package=reference_admin --file=test/scenarios/themes \
  --languages=en,ar --output=build/reference_admin/themes

# 4. A browsable page (flow canvas, step pages, trees, each step's fake calls);
#    serve it as the result's `serve` field says
fw run scenarios export --package=reference_admin --languages=en,ar \
  --capture-scale=2 --output=build/reference_admin/web
fw run scenarios export --package=reference_admin --languages=en \
  --brightness=dark --output=build/reference_admin/web-dark

# 5. Debug lane: one file, one step, two runs compared
fw run scenarios run --package=reference_admin \
  --file=test/scenarios/story/desktop/03_orders_test.dart
fw run scenarios read --step=<fw:// address from the result>
fw run scenarios diff --before=<run dir> --after=<run dir>

# 6. A video of one branch (ffmpeg from mise)
fw run scenarios video --package=reference_admin \
  --file=test/scenarios/story/desktop/03_orders_test.dart \
  --scenario='Working the order queue' --branch='let it commit' --device=window --language=en
```

Each folder's profile has its own head device, so one `shots` command
writes one numbered set per folder: `<language>/window` (the desktop story),
`<language>/iphone-16` (the phone story), `<language>/window-wide` (the theme
gallery) and `<language>/window-small` (the smoke walk: a regression set,
not part of the story, kept apart by its own head device, T-006). `NN` follows the
story (files `01_`…`07_`, then declaration order, then split branch), so the
same `NN` and slug is the same screen in every language. `build/` is ignored;
no picture is committed.

Measured again on the kit with #99 (a 20-core Mac, warm build, other work
running), command 1:

| Set | Shots per language | en + fr + ar |
|---|---|---|
| `window` (desktop story, 7 files, 36 scenarios) | 124 | 372 PNGs, 80 MB |
| `window-wide` (theme gallery, 8 scenarios) | 74 | 222 PNGs, 62 MB |
| `window-small` (smoke walk, 4 scenarios) | 24 | 72 PNGs, 11 MB |
| `iphone-16` (phone story, 7 scenarios) | 15 | 45 PNGs, 6.9 MB |
| **All** | **237** | **711 PNGs, 161 MB, 10 min 28 s** |

The other commands, measured the same way (4 on the kit with #99; 2 and 6
after the review fixes, neither changed since):

| Command | Result | Time |
|---|---|---|
| 2 (`--tag=tour`) | 13 tour shots per language (11 `window`, 2 `iphone-16`), 39 PNGs | 8 min 48 s |
| 4, en + ar at capture scale 2 | 110 scenarios, 1,096 steps, 1.8 GB | 7 min 59 s |
| 4, en in dark | 55 scenarios, 548 steps, 0.8 GB | 3 min 8 s |
| 6 (the video) | `build/flutterware/video/working-the-order-queue.mp4`, 1.5 MB | 26 s |

`shots` and `export` run every scenario whatever they keep, so the tour set
costs almost what the whole set does.

Two consecutive `fw run scenarios run --package=reference_admin`
passes (55 scenarios at the folder heads, 2 min 39 s and 2 min 37 s) report
nothing changed, and `scenarios diff` between them is empty: 555 steps
compared, 239 matched by name.

## Checks

```sh
fvm flutter test                         # unit, guards, sweep, scenarios (heads only)
fvm dart run tool/kit_coverage.dart      # regenerate KIT_COVERAGE.md
fvm dart run tool/friction_summary.dart  # regenerate FRICTION.md's table
fvm flutter test test/sweep --dart-define=reference_admin.sweep=full
```

Measured on the kit with #99: `fvm flutter test` runs 171
tests (the unit and guard files, the sweep's 76 pumps across eight language
and width combinations, and every scenario at its folder's head device and
language) in 59 s wall on a 20-core Mac with other work running; after the
review fixes it took 84 s with `-j 2`, which is what `tool/src/ci_jobs.dart`
weighs it at. The spec's budget is 90 s, with a ceiling of 150 s.

The guards fail on: an import across the kit boundary, or a screen that
imports the fake; `DateTime.now()` or
an unseeded `Random()` in `lib/`; a friction marker naming no entry, an open
S1/S2 entry with no marker, an entry without kind, severity, status or
evidence, a `suspected` entry, a status the process does not name, or a
stale summary table; a shot name used
twice in a folder; a stale KIT_COVERAGE.md, or an unused kit symbol with no
reason in `coverage_exclusions.yaml`.
