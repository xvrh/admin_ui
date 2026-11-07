# Friction log

Every place `admin_ui` (or flutterware) made this app work around it, found
while building an admin on the kit's public barrels only. An entry beats a
silent workaround: each workaround line in the code carries
`// FRICTION(F-NNN): <one line>`, and `test/unit/guards_test.dart` holds the
two together.

<!-- summary:start -->
| Id | Claim | Kind | Severity | Status |
|---|---|---|---|---|
| F-001 | `Shell` has no compact layout, and a drawer built from a side sheet sits outside `AdminScope` | missing-api | S2 | fixed |
| F-002 | No bottom sheet: phone filters use a full-width end side sheet | missing-api | S3 | open |
| F-003 | No appearance model or picker; `ThemableTestApp` and `adminPreviewBrands` are preview-only | missing-api | S2 | fixed |
| F-004 | No public test-support library: font preload, the Segoe UI stand-in and the no-font text check live in the example | test-support | S2 | fixed |
| F-005 | The kit ships no theme font files; every app copies 3.3 MB and must know the file-naming rule | missing-api | S3 | open |
| F-006 | The shipped typography has no Arabic fallback; the app rebuilds every token set through `AdminTypography.from` | i18n | S3 | open |
| F-007 | No routing recipe: one `AdminScope` per pushed page forces a single-frame design; `NavItem.selected` is manual | doc-gap | S2 | fixed |
| F-008 | Kit-owned controls (FormSaveBar save, ErrorState retry, BulkActionBar actions, dialog confirm) take no keys | test-support | S3 | open |
| F-009 | No money or relative-time formatting in `AdminFormats`; `DecimalField` has no currency mode | missing-api | S3 | open |
| F-010 | No documented pattern for app strings; gen-l10n pulls in `flutter_localizations` | doc-gap | S3 | open |
| F-011 | `Collection` does not switch from table to cards by width | missing-api | S3 | open |
| F-012 | `ChartCard` has no error slot | missing-api | S3 | open |
| F-013 | `AdminModule`'s String `route` and `navLabel` do not fit a typed router or a locale change | missing-api | S3 | wontfix |
| F-014 | No permission model beyond `ValueForm(readOnly:)`, and no forbidden-state preset | missing-api | S3 | open |
| F-015 | Frameless kit timers (search debounce, realtime coalesce, `DelayedLoading`) make scenario settling non-obvious | test-support | S3 | open |
| F-016 | `NavItem` takes no key | test-support | S3 | fixed |
| F-017 | `NotificationCenter` bundles its bell with its panel, so the inbox cannot be a sheet on a phone | missing-api | S2 | fixed |
| F-019 | Toasts start at the window's top edge, over the shell's top bar and its actions | awkward-default | S3 | open |
| F-020 | `showSideSheet` draws no surface around a bare builder, and its doc reads as if it did | doc-gap | S3 | fixed |
| F-021 | `CommandSource` lists nothing on an empty query, so a palette opens blank until something is typed | awkward-default | S3 | open |
| F-022 | A remote `SearchSource` is asked on every keystroke; debouncing is the source's job | missing-api | S3 | open |
| F-023 | `Avatar` picks its colour from the ambient palette, so one person has two colours under a top bar with its own | theme | S3 | open |
| F-024 | A theme of your own keeps its base theme's chart series: the README's recipe draws every chart in Iris indigo | theme | S3 | open |
| F-025 | `Asset` has no `copyWith`: changing one field rebuilds eleven | missing-api | S3 | open |
| F-026 | `AssetSource` resolves one id per call: a list of rows either browses the whole library or asks once per row | missing-api | S3 | open |
| F-027 | The kit has no breakpoint vocabulary a host can read | missing-api | S3 | fixed |
| F-028 | `SideSheet` pads the safe area in its own surface colour, and `Shell` pads none: a drawer opens on bands the frame does not have | awkward-default | S3 | fixed |
| F-029 | A click on a submenu row with no level of the menu under it closes the menu and chooses nothing | bug | S2 | fixed |
| F-030 | A script fallback set a field's baseline where the theme's own family is absent, lifting field text | bug | S2 | fixed |
| F-100 | `SignInForm` can say a server refusal only above the form: no per-field error, so `AuthFieldError` has nowhere to go | missing-api | S3 | open |
| F-101 | `StatCard` has no slot for a trend line, though the kit ships `Sparkline` for exactly that dashboard | missing-api | S3 | open |
| F-102 | No rule and no wizard step can name a `RecordListCell`: "at least one row" needs a borrowed cell | missing-api | S2 | fixed |
| F-103 | Server field errors are keyed by cell id, and a record-list row's cell ids are opaque (minted from the wall clock) | doc-gap | S3 | open |
| F-104 | `DecimalField` takes a prefix but no unit, though its `NumberBody` has one | missing-api | S3 | open |
| F-106 | `ValidationSummary` folds to nothing while hidden and brings no spacing, so a host cannot gap it only when it shows | awkward-default | S2 | fixed |
| F-107 | `EmptyState` has no tone: a success end state reads as an empty list | missing-api | S3 | open |
| F-108 | `DonutChart`'s legend overflows a narrow card instead of wrapping or eliding | bug | S3 | open |
| F-109 | `LineChart` thins its category labels greedily by width, so a month's axis is spaced unevenly | awkward-default | S3 | fixed |
| F-110 | `StatCard` has no loading state | missing-api | S2 | fixed |
| F-201 | A saved view's name is stored text, so `SavedViewsBar` cannot show the shop's own views in the page's language | i18n | S3 | open |
| F-202 | A list with saved views is read twice on open | perf | S3 | open |
| F-203 | `CollectionTable` has no row context menu | missing-api | S3 | open |
| F-204 | `SavedViewsBar`'s actions reach every view alike | missing-api | S3 | open |
| F-205 | The kit has mention helpers but no mention composer | missing-api | S2 | fixed |
| F-206 | Anything but a `FormSubmitException` out of `onSubmit` is reported as a Flutter error | awkward-default | S3 | fixed |
| F-207 | A hover card needs a longer rest than any test helper knows | test-support | S3 | open |
| F-208 | `KanbanBoard` pads itself inside the page's gutter, and its padding and gap are not exposed | awkward-default | S3 | open |
| F-209 | `FilterBar` offers "Clear all" for conditions none of its pills shows | awkward-default | S3 | open |
| F-210 | A `PopoverMenuSurface` sized to its content throws around a `Listbox` | bug | S3 | open |
| F-212 | A selectable card's check sits over its content's corner | awkward-default | S3 | open |
| F-213 | `Collection` does not pass `CollectionCards`' padding through | missing-api | S3 | open |
| F-214 | `CollectionRealtime` refreshes the rows on reconnect, but a `SavedViewsController` whose load failed stays failed | awkward-default | S3 | open |
| F-215 | `SavedViewsBar` asks no name or scope for a new view, and cannot rename one | missing-api | S2 | fixed |
| F-216 | `SavedViewsBar` has no compact form: on a phone its strip cuts a view's name mid-word at the edge | missing-api | S2 | fixed |
| F-217 | A page that is not a table has no loader: the customer card reads its customer through `FutureBuilder` | missing-api | S3 | fixed |
| F-300 | A table that opens rows on tap cannot start an inline edit from a pointer | awkward-default | S2 | fixed |
| F-301 | `FormScope` hands out no map cell, which `KeyValueField` needs | missing-api | S2 | fixed |
| F-302 | `TableTextEditor.number` cannot refuse a draft | missing-api | S3 | open |
| F-303 | The kit draws a `VersionDiff` but builds none from two records | missing-api | S2 | fixed |
| F-304 | `ReferenceField` edits a list only; a single reference is a list of one | missing-api | S3 | open |
| F-305 | `PresenceAvatars` takes a fixed list of peers; following a channel is the page's job | awkward-default | S3 | open |
| F-306 | `PageScaffold` has no slot for a tab strip | missing-api | S3 | fixed |
| F-307 | Asset dialogs open on `AdminScope`'s anchor, above a page's `AssetSourceScope`, `LangScope` and keyboard inset | doc-gap | S2 | fixed |
| F-309 | A `FieldValidator` is handed the kit's strings only; an `AsyncFieldValidator` none | awkward-default | S3 | open |
| F-310 | With no default view, `SavedViewsController` applies the first one, and the bar has no "every row" tab | awkward-default | S2 | fixed |
| F-312 | `DiffView` prints each field's internal key beside its label | i18n | S3 | open |
| F-313 | Under `ValidationMode.onEdit` an edit form's `ValidationSummary` never shows | awkward-default | S3 | open |
| F-314 | Revealing the first invalid field leaves its message under the bottom save bar | bug | S2 | fixed |
| F-315 | The kit's own prompts and bars word some buttons through Material, which an `AdminLocalizations` override cannot reach | i18n | S3 | open |
| F-316 | `FormSaveBar.savedLabel` has no doc, and its name reads as the word to show, not a detail after it | doc-gap | S3 | open |
| F-400 | A media page over an `AssetSource` rewrites the picker's private host: paging, search, filters, errors | missing-api | S1 | fixed |
| F-401 | `AssetLibrary`'s toolbar takes no filter of the app's, and `AssetSource.browse` filters by type and text only | missing-api | S2 | fixed |
| F-402 | `showAssetDetail` / `AssetDetailView` take no action but Delete, so Crop cannot sit in the sheet | missing-api | S1 | fixed |
| F-403 | A library asset has no crop: `Asset` carries none and `AssetSource` cannot save one | missing-api | S3 | open |
| F-406 | `onSaveAlt` gets the whole alt text with cleared languages left out, and its doc does not say so | doc-gap | S3 | open |
| F-407 | `AssetLibrary` fixes its tile size, so a phone grid is 3-up, not 2-up | missing-api | S2 | fixed |
| F-408 | `Field` takes no text direction, so an email field reads right to left in Arabic | i18n | S3 | open |
| F-409 | `showCropDialog` takes no size, so on a phone it is not full screen | missing-api | S3 | open |
| F-501 | A `Choice` card cannot show a preview, and `Choice` cannot lay its cards out in a grid | missing-api | S3 | open |
| F-502 | `SwatchRow` is the canvas toolbar's picker: 18px dots, no visible name, no keys, no group semantics | awkward-default | S3 | open |
| F-503 | `SelectField` binds only a form cell, so an instant setting needs a `LocalScope` of its own | awkward-default | S3 | open |
| F-504 | `ChangePasswordForm` shows a server's refusal only as an alert over the form | missing-api | S3 | open |
| F-505 | A `Toggle` with no label stretches its track to a tight width | bug | S3 | open |
| F-506 | `ChangePasswordForm` cannot be cleared after a successful change | missing-api | S3 | open |
| T-001 | No hover, mouse-click, secondary-click or key-chord scenario verbs | test-support | S3 | open |
| T-002 | `shots` has no `brightness` option and there is no app-defined (theme) axis | test-support | S3 | open |
| T-003 | `shots` `file` is documented as repeatable but read as a single string | bug | S3 | open |
| T-004 | Sequential `NN` renumbers every later shot when one is inserted | awkward-default | S3 | open |
| T-005 | Numbered scenario files break the `file_names` lint | awkward-default | S3 | open |
| T-006 | `s.act` always names a step, so a regression walk cannot keep its acts out of `shots` | missing-api | S3 | open |
| T-007 | Awaiting a fake-time future inside `s.act` hangs for minutes, silently | test-support | S2 | open |
| T-008 | `run --matrix=declared` crosses every folder's devices with every file | awkward-default | S3 | open |
| T-009 | `Settle.until(finder.first)` throws "Bad state: No element" while the target is absent | test-support | S3 | open |
| T-010 | Scenario files added or deleted while another run compiles break that run | test-support | S3 | open |
| T-011 | `enterText` sets the whole value in one change, so a debounce is never exercised | test-support | S3 | open |
| T-012 | Taps are touch events on desktop devices, so pointer-adaptive widgets show their touch layout in desktop pictures | test-support | S3 | open |
<!-- summary:end -->

The table is regenerated from the entries by `fvm dart run tool/friction_summary.dart`.

## How to write an entry

Write it at the moment the workaround is written, in its owner's section and
id block. Phrase everything generically: no customer, brand or project names.

```
### F-NNN · <the claim, one line>

- **Kind:** missing-api | awkward-default | doc-gap | bug | a11y | i18n | theme | perf | test-support
- **Severity:** S1 blocker (a feature dropped, or kit code copied) | S2 workaround (non-obvious, or 20+ lines) | S3 papercut
- **Status:** suspected | open | kit PR #NN | fixed (#NN, workaround removed) | not reproduced | wontfix (why)
- **Kit:** `barrel › Symbol`, kit file:line
- **App:** the workaround's file:line, and the lines it cost
- **Evidence:** scenario › shot, or a `fw://` step address, plus a minimal snippet
- **Workaround:** what the app does instead
- **Proposal:** an API sketch
```

A `suspected` entry is a hypothesis: the owning work package confirms it
with evidence, or sets it to `not reproduced`, which is a finding too.

## Core (F-001–F-099)

### F-001 · `Shell` has no compact layout, and a drawer built from a side sheet sits outside `AdminScope`

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `shell.dart › Shell` (`lib/src/shell/ui/shell.dart:32`): `sidebar` is required and the frame is a fixed Column/Row; `widgets.dart › showSideSheet` (`lib/src/common/ui/side_sheet.dart:29`) pushes a `showGeneralDialog` route.
- **App:** `lib/src/frame/app_frame.dart` (the compact branch passes `SizedBox.shrink()` as the sidebar and puts a menu button in `TopBar.leading`); `lib/src/frame/navigation.dart` `openNavigationDrawer` (~30 lines).
- **Evidence:** a phone-width frame has nowhere to put the navigation; the sheet's `Sidebar` calls `LeaveGuardScope.confirmLeave`, which with no scope above answers "leave", so a dirty form is dropped without asking unless the registry is re-provided. `test/scenarios/story/phone` (WP-E) photographs "Phone · leave without saving?".
- **Workaround:** the drawer is `showSideSheet(side: start)` whose builder returns a `SideSheet` (F-020) holding a `Sidebar`, wrapped in `LeaveGuardScope(registry: services.leaveGuards)`; navigating pops the sheet first. Signing out, which leaves every page at once, asks the same guards through `AppRouterDelegate.signOut`.
- **Proposal:** done: the kit's compact `Shell` (`shell.dart`): below `context.breakpoints.medium` the navigation is a modal drawer on `AdminScope`'s anchor, opened by the top bar's `ShellMenuButton`, so it sees the page's leave guards. The frame passes its sidebar (and a keyed `drawer:`) and `TopBar(menuButton: ShellMenuButton(key: ShellKeys.menu))`; `openNavigationDrawer`, its `SizedBox.shrink()` sidebar and the re-provided leave-guard registry are gone.

### F-002 · No bottom sheet: phone filters use a full-width end side sheet

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified in source)
- **Kit:** `widgets.dart › SideSheetSide` (`lib/src/common/ui/side_sheet.dart:11`) is `{start, end}` only.
- **App:** `lib/src/screens/orders/orders_screen.dart` (the phone filters) and `lib/src/screens/customers/customers_screen.dart` (the phone quick view), each a full-width `end` sheet (~10 lines each).
- **Evidence:** "Phone · filters" (phone story) and "Customer · quick view" on `iphone-16` (04_customers): both sheets slide in from the side, where a phone expects them from the bottom.
- **Workaround:** `showSideSheet(side: end, width: screen width)`.
- **Proposal:** `SideSheetSide.bottom`, or `showBottomSheet` with the kit's chrome and a drag handle.

### F-003 · No appearance model or picker; `ThemableTestApp` and `adminPreviewBrands` are preview-only

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `theme.dart › adminThemes`, `AdminTheme.branded`; nothing holds the choice.
- **App:** `lib/src/appearance/appearance_controller.dart` (~110 lines: theme, mode, accent, density, locale, motion, cached token sets, persistence); the picker is `lib/src/screens/settings/appearance/appearance_view.dart` and `appearance_pages.dart` (~330 lines, of which F-501 to F-503 and F-505 are the rough edges).
- **Evidence:** "Appearance and language" › "Appearance", "Appearance · Carbon dark", "Appearance · Teal accent" (desktop story, 07); "Appearance follows me" › "Dashboard · my appearance back": the kit has the parts (`Choice`, `Segmented`, `SwatchRow`, `Toggle`, `branded`), but holding, persisting and re-deriving the token sets per (theme, accent, brightness), and the page that edits them, are all the app's.
- **Workaround:** the app's own `AppearanceController`.
- **Proposal:** done: `theme.dart › AdminAppearance` (theme, mode, accent, density; `tokens(brightness)`, `themeData`, `toJson`/`fromJson`) and `shell.dart › AppearancePicker`. The app's `AppearanceController` holds an `AdminAppearance` (plus language and motion), derives its token sets from `tokens(brightness)` and persists through `AdminAppearance.fromJson`; the appearance page is the kit's picker beside the app's own language and motion rows.

### F-004 · No public test-support library: font preload, the Segoe UI stand-in and the no-font text check live in the example

- **Kind:** test-support
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `admin_ui_example/testing/fonts.dart:39` (`loadTestFonts`, private `_preloadGoogleFonts`), which an app may not depend on.
- **App:** `test/support/fonts.dart` (~75 lines).
- **Evidence:** without the preload, a bare `flutter test` draws Inter and IBM Plex Sans themes in the fallback face and measures text wrong.
- **Workaround:** a copy of the preload, run before `runScenarios` in each folder's config.
- **Proposal:** done: `package:admin_ui/testing.dart` (`loadAdminFonts`, `withTestFontFallback`, `textWithoutFont`, `loadTestFontFamily`), which the example's harness now builds on too. `test/support/fonts.dart` is one `loadAdminFonts` call per lane, and its preload, stand-in and message are the kit's.

### F-005 · The kit ships no theme font files; every app copies 3.3 MB and must know the file-naming rule

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** the README's "Fonts" section; the files live under `example/assets/google_fonts/`.
- **App:** `assets/google_fonts/` (17 TTFs and their licences, byte-identical copies), `pubspec.yaml`.
- **Evidence:** `GoogleFonts.config.allowRuntimeFetching = false` with no bundled files logs a missing-file error per weight and draws the platform font.
- **Workaround:** copy the example's files.
- **Proposal:** ship the weights the themes name as the kit's own assets, loaded under `packages/admin_ui/`, so an app bundles nothing.

### F-006 · The shipped typography has no Arabic fallback; the app rebuilds every token set through `AdminTypography.from`

- **Kind:** i18n
- **Severity:** S3
- **Status:** open (verified in source; narrowed at integration: with the fallback switched off, the runner still draws Arabic, in the platform's own face, because the engine falls back to system fonts on macOS. What the app's fallback buys is one bundled face on every platform and in both test lanes, not legibility)
- **Kit:** `theme.dart › AdminTypography.from` (`lib/src/theme/typography.dart:655`); no theme sets `fontFamilyFallback`.
- **App:** `lib/src/appearance/themes.dart` `withArabicFallback` (~15 lines), applied to every token set.
- **Evidence:** "shadcn" (theme gallery, `window-wide`, ar) › "shadcn · light · dashboard" run twice, with and without `withArabicFallback`: Noto Naskh Arabic with it, the system Arabic face without it, and line heights that differ between the two, so the pictures depend on the machine that draws them.
- **Workaround:** append `Noto Naskh Arabic` to every spec's fallback. The kit now puts the platform's UI fonts before it, so where a theme's own family is absent (on the web) the fallback no longer sets the baseline of Latin text or draws its spaces and digits (F-030); the gap here, no Arabic fallback in the shipped typography, stands.
- **Proposal:** `AdminTypeSpec.fontFamilyFallback` defaulting to a script-aware list, or `AdminTheme.withFallback([...])`.

### F-007 · No routing recipe: one `AdminScope` per pushed page forces a single-frame design; `NavItem.selected` is manual

- **Kind:** doc-gap
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › AdminScope` (`lib/src/common/ui/admin_scope.dart:54`) and the README's "A minimal app"; `shell.dart › NavItem.selected`.
- **App:** `lib/src/routing/router_delegate.dart` (~150 lines), `lib/src/routing/routes.dart`, `route_parser.dart`.
- **Evidence:** every route is one Navigator page whose body swaps; the leave guard needs a context below the frame's scope (`frameKey`).
- **Workaround:** a Router 2.0 delegate holding one page (auth page or frame); routes carry their `Nav` so the sidebar derives `selected`.
- **Proposal:** done: the README's "Routing" section describes the single-frame Router 2.0 design this app uses, and `Sidebar(selected:)` with `NavItem(value:)` lights an item: the frame passes `route.nav`, in place of `selected:` set by hand on each item.

### F-008 · Kit-owned controls (FormSaveBar save, ErrorState retry, BulkActionBar actions, dialog confirm) take no keys

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (confirmed by WP-A, WP-B, WP-C and WP-E)
- **Kit:** `forms.dart › FormSaveBar` (`lib/src/forms/form_save_bar.dart:27`), `widgets.dart › ErrorState` (`lib/src/common/ui/error_state.dart:13`), `collection.dart › BulkAction` (`lib/src/collection/ui/bulk_action_bar.dart:15`), `showConfirmDialog`; `auth.dart › SignInForm` (`lib/src/auth/ui/sign_in_form.dart:30`) and `SetPasswordForm` (`lib/src/auth/ui/set_password_form.dart:18`), whose inputs and submit are built inside; `assets.dart › AssetLibrary` (the grid/list `Segmented`, the type `FilterMenuButton`) and `forms.dart › AssetDetailView` (the alt `Field`'s lanes).
- **App:** every scenario file; the kit's words are read through `s.kit`, and Material's through `MaterialLocalizations.of` where the kit borrows them (F-315). The auth forms are keyed from outside and their fields found as the n-th `EditableText` under the key (`01_access_test.dart` `_inputs`); the library's view switch by its icon under the library's key and an alt lane by its place in `LangScope.locales` (`06_media_team_test.dart`).
- **Evidence:** 02_home "The dashboard when stats fail" finds Retry by `s.kit.retry`; "Setting up a brand-new shop" finds Next by `s.kit.fields.wizardNext`; "Changing the shop's settings" finds Save by `MaterialLocalizations.saveButtonLabel`. 03_orders "Orders · shipping undone" (the toast's Undo), "Orders · shipped, undo offered" (a `BulkAction` by its text), "Orders · nothing matches" (Clear filters), "Saving a view of my own" (the `SavedViewsBar` "+" by its icon). 05_catalogue "Product · leave without saving?" (`FormSaveBar`, `FormActions`, the guard's Cancel, the picker's Select). 01_access "Signing in" and "An invited teammate sets a password" (the auth forms, formerly F-105). 06_media_team "Media · list" and "Media · alt text saved" (the library toolbar and the alt lanes, formerly F-405). 07_settings and the phone story: `Choice` options, `Segmented` segments, `SwatchRow` swatches and `ChangePasswordForm` fields by index.
- **Workaround:** `find.text(s.kit.…)`.
- **Proposal:** a `key` (or `saveKey`, `retryKey`, `confirmKey`) on each; `emailFieldKey`, `passwordFieldKey`, `submitKey` (or one `keyPrefix`) on the auth forms; keys derived from a parent key on the library's toolbar (`ValueKey('$key.view.list')`) and lane keys from the locale code. One kit PR.
- **Progress:** the kit now keys every control it builds from the app's data (`MenuItem`, `BulkAction`, `SegmentOption`, `ChoiceOption`, `SwatchOption` and the rest take `key`), and the controls of its own named here: `showConfirmDialog(confirmKey:, cancelKey:)`, `ErrorState(retryKey:)`, `FormSaveBar` and `FormActions(commitKey:, discardKey:)`, `FormWizard(backKey:, nextKey:)`, `Toast(actionKey:)`, and the auth forms' inputs and submit (`SignInForm(emailKey:, passwordKey:, submitKey:)`, `SetPasswordForm(newKey:, confirmKey:, submitKey:)`, `ChangePasswordForm(currentKey:, …)`). `01_access_test.dart` signs in and sets a password by those keys. Still open: the asset library's view switch and type filter, an alt field's language lanes, and the `AppearancePicker`'s options, which the kit builds from data of its own; the scenarios that find the rest by `s.kit` words can move to keys one by one.

### F-009 · No money or relative-time formatting in `AdminFormats`; `DecimalField` has no currency mode

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `l10n.dart › AdminFormats` (`lib/src/l10n/formats.dart:18`): decimal, integer, compact, percent, bytes, dateFormat; `forms.dart › DecimalField` (`lib/src/forms/value_fields.dart:934`).
- **App:** `lib/src/l10n/money.dart` (`formatMoney`, `formatAgo`, ~50 lines).
- **Evidence:** every price and total in the app, and the inbox's timestamps.
- **Workaround:** `intl` `NumberFormat.currency` per locale; a hand-rolled "5 min / 3 h / 2 d".
- **Proposal:** `AdminFormats.money(int minorUnits, String currency)` and `AdminFormats.ago(DateTime, {DateTime now})`; `DecimalField(currency: 'EUR')`.

### F-010 · No documented pattern for app strings; gen-l10n pulls in `flutter_localizations`

- **Kind:** doc-gap
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** the README's "Localisation and right-to-left" covers the kit's strings only.
- **App:** `lib/src/l10n/ref_strings.dart` and one `strings_<area>.dart` per area (hand-written, ~100 lines of scaffolding).
- **Evidence:** `lib/src/l10n/ref_strings.dart` and six `strings_<area>.dart` files, about 4,100 lines in all, written in the kit's own style; gen-l10n was not an option because its generated `localizationsDelegates` lists `GlobalMaterialLocalizations` from `flutter_localizations`, which `test/unit/guards_test.dart` forbids.
- **Workaround:** the kit's own style, copied.
- **Proposal:** a README recipe for app strings beside the kit's, and a note on gen-l10n's delegate list.

### F-011 · `Collection` does not switch from table to cards by width

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (confirmed by WP-B, WP-C and WP-D)
- **Kit:** `collection.dart › Collection`, `CollectionViewMode`.
- **App:** `lib/src/screens/orders/orders_screen.dart`, `lib/src/screens/customers/customers_screen.dart`, `lib/src/screens/products/product_list.dart` and `lib/src/screens/team/team_screen.dart` each pick `CollectionViewMode.cards` from `Breakpoint.of(context)` (~5 lines each).
- **Evidence:** "Phone · orders as cards" (phone story), and orders, customers, products and team on `iphone-16`: without the switch, `Collection` lays its table out at 393 px.
- **Workaround:** the screen picks `CollectionViewMode.cards` below 600.
- **Proposal:** `Collection(compactViewMode: CollectionViewMode.cards, compactBreakpoint: 600)`.

### F-012 · `ChartCard` has no error slot

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified in source; the app's design does not need the slot)
- **Kit:** `widgets.dart › ChartCard` (`lib/src/common/ui/chart.dart:463`): `loading`, `isEmpty`, no error.
- **App:** none: the spec asked for a per-card error, and the dashboard shows one `ErrorState` for the page instead, by design: it reads one `stats` call for every card, so every card fails together (`lib/src/screens/dashboard/dashboard_view.dart`).
- **Evidence:** "The dashboard when stats fail" › "Dashboard · could not load" (02_home). A dashboard whose cards load separately would need the slot.
- **Workaround:** none needed here.
- **Proposal:** `ChartCard(error: Object?, onRetry:)`.

### F-013 · `AdminModule`'s String `route` and `navLabel` do not fit a typed router or a locale change

- **Kind:** missing-api
- **Severity:** S3
- **Status:** wontfix (not exercised: v1 registers no `AdminModule`, spec §13; to be judged with the module PR)
- **Kit:** `shell.dart › AdminModule` (`lib/src/shell/ui/admin_module.dart:15`).
- **App:** not used in v1.
- **Evidence:** none: `AdminModule` is listed as deferred in `coverage_exclusions.yaml`.
- **Workaround:** none needed yet.
- **Proposal:** `navLabel` as `String Function(BuildContext)`, and a route that is an app value rather than a String.

### F-014 · No permission model beyond `ValueForm(readOnly:)`, and no forbidden-state preset

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (confirmed by WP-C and WP-D)
- **Kit:** `forms.dart › ValueForm.readOnly` (`lib/src/forms/value_form.dart:52`).
- **App:** `lib/src/session/session_controller.dart` (`can`), `lib/src/screens/stubs.dart` `ForbiddenPage` (~25 lines).
- **Evidence:** "A viewer can look but not edit" › "Product · read-only" (05_catalogue: no save bar and zero write calls, from the app's role check), "Staff cannot manage the team" › "Team · not allowed" (06_media_team: the app's forbidden page, and a forced `staff.invite` refused by the fake), and "A viewer is turned away from the team page" (smoke).
- **Workaround:** the app's role matrix; the forbidden page from `EmptyState`.
- **Proposal:** `EmptyState.forbidden(onBack:)` (icon, title and message from `AdminLocalizations`), and an `AdminScope(can: bool Function(Object permission))` that kit actions taking a `permission:` (`BulkAction`, `MenuItem`, `FormSaveBar`) consult to hide themselves, so a screen stops repeating the role check next to every action.

### F-015 · Frameless kit timers (search debounce, realtime coalesce, `DelayedLoading`) make scenario settling non-obvious

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (confirmed by WP-A, WP-B, WP-C and WP-E)
- **Kit:** `collection.dart › CollectionController.searchDebounce` (`lib/src/collection/collection_controller.dart:109`), `CollectionRealtime`, `widgets.dart › DelayedLoading` (`lib/src/common/ui/delayed_loading.dart:13`).
- **App:** `lib/src/frame/app_frame.dart` `_InFlightBar` shows `TopProgressBar` at once instead of through `DelayedLoading`; `test/support/harness.dart` `searchIn` and `realtime` settle `until` a target.
- **Evidence:** 02_home "Jumping with the command palette" and 03/04 "Finding an order" and "Looking a customer up" wait on `searchIn` (`Settle.until`); 05_catalogue "Product · checking SKU" waits out the `AsyncFieldValidator` debounce; 07_settings "Working offline" › "Orders · back online" waits on the realtime coalesce. Each of them photographed the screen before the timer fired when settled on frames alone.
- **Workaround:** frame-driven loading, and `Settle.until` for timers.
- **Proposal:** a debug hook the kit's timers report through (e.g. a `ValueListenable<int> pendingTimers`), which a harness can wait on.

### F-016 · `NavItem` takes no key

- **Kind:** test-support
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `shell.dart › NavItem` (`lib/src/shell/ui/sidebar.dart:24`) was a data class with no key; `Sidebar` built the rows, and wrapped a collapsed rail's row in `Tip(message: label)`, which `find.byTooltip` does not see.
- **App:** `lib/src/keys/shell_keys.dart` had no nav keys; `test/support/harness.dart` `navTo` found a row by its localized label, on the rail by `find.byWidgetPredicate((w) => w is Tip && w.message == label)`; the same in the phone story's `_railItem`.
- **Evidence:** "Signing in and opening every page" (smoke), `Smoke · orders` … `Smoke · settings`, on `window-small`, where the sidebar is a rail (formerly F-018).
- **Workaround:** `find.text(label)` under the `Sidebar`, or the rail's `Tip`.
- **Proposal:** done: `NavItem(key:)` goes on the row the sidebar builds, in the rail and the phone's drawer too. `ShellKeys.nav(nav)` keys each row, and `navTo` and the phone story tap it by its key at every width.

### F-017 · `NotificationCenter` bundles its bell with its panel, so the inbox cannot be a sheet on a phone

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › NotificationCenter` (`lib/src/common/ui/notification_center.dart:116`): the bell, its badge and the popover in one widget.
- **App:** `lib/src/frame/inbox.dart` shows the popover at every width.
- **Evidence:** "Notifications on a phone" › "Phone · notifications": the spec's full-width inbox sheet was not built; the inbox itself works (the popover fits the phone's width, asserted), so the feature stands and its phone form was dropped.
- **Workaround:** the popover, clamped to the phone's width.
- **Proposal:** done: `widgets.dart › NotificationInbox` and `NotificationBell`, split out of `NotificationCenter`. On a phone the frame's bell opens the inbox in a full-width `SideSheet`; wider windows keep the popover.

### F-019 · Toasts start at the window's top edge, over the shell's top bar and its actions

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › ToastScope` (`lib/src/common/ui/toast.dart:229`): `position: topEnd`, `margin: EdgeInsets.zero`; the README places the scope in `MaterialApp.builder`, above any `Shell`.
- **App:** `lib/src/app.dart` passes `margin: EdgeInsetsDirectional.only(top: context.shellStyle.topBarHeight)` (4 lines).
- **Evidence:** "The palette and the shop push reach the frame" (smoke) › "Smoke · new order toast": before the margin, the toast covered the bell and the user menu.
- **Workaround:** the margin, read from the theme's shell style.
- **Proposal:** `ToastScope` defaulting its top inset to `shellStyle.topBarHeight` when a `Shell` is mounted, or a `ToastScope.belowTopBar` constructor.

### F-020 · `showSideSheet` draws no surface around a bare builder, and its doc reads as if it did

- **Kind:** doc-gap
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › showSideSheet` (`lib/src/common/ui/side_sheet.dart:22`): "the surface is a [SideSheet]", but `_SideSheetHost` only sizes and aligns the builder's widget; nothing provides a `Material` or a `DefaultTextStyle`.
- **App:** `lib/src/frame/navigation.dart` `openNavigationDrawer` (the builder returned a `SideSheet` with no title, 3 lines); removed with F-001, and the app's other sheets return a `SideSheet`.
- **Evidence:** "Getting around on a phone" › "Phone · navigation" and "A dirty form survives the drawer" › "Phone · leave without saving?": with the `Sidebar` returned bare, every label drew in Flutter's yellow double-underline "no text style" debug style, in en, fr and ar.
- **Workaround:** wrap the builder's content in `SideSheet(side: SideSheetSide.start, child: …)`.
- **Proposal:** done: `showSideSheet`'s doc says the builder returns the surface, a `SideSheet`, and that the host gives it no `Material` or text style. The app's drawer is now the kit's (F-001), and its other sheets (the orders filters, the customer quick view, the phone inbox) return a `SideSheet`.

### F-021 · `CommandSource` lists nothing on an empty query, so a palette opens blank until something is typed

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › CommandSource.search` (`lib/src/common/ui/command_palette.dart:104`) returns `[]` for an empty query; only `RecentsSource` answers one.
- **App:** `lib/src/frame/palette.dart` `openCommandPalette` (two `RecentsSource`s over the pages and the commands, ~10 lines).
- **Evidence:** "Jumping with the command palette" › "Command palette": before the workaround the panel held "Type to search" and nothing else, although every page and command was registered.
- **Workaround:** `RecentsSource(() => pages, title: groupPages)` and one for the commands: `RecentsSource` shows a fixed list only while the query is empty, which is the behaviour wanted.
- **Proposal:** `CommandSource(items, showWhenEmpty: true)`, or a `SuggestedSource` named for what it is.

### F-022 · A remote `SearchSource` is asked on every keystroke; debouncing is the source's job

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › SearchSource`, `CommandPaletteController._run` (`lib/src/common/ui/command_palette.dart:207`): each `setQuery` calls every source at once; a later query's token drops an earlier answer, but the request has gone out.
- **App:** `lib/src/frame/palette.dart` `_ShopSearch` (a 200 ms delay and a latest-query check, ~8 lines).
- **Evidence:** "Jumping with the command palette" › "Command palette · results": typing "fe", "fer", "fern" in turn makes one `search.query` call with the workaround, three without it.
- **Workaround:** the source waits out a pause and answers `[]` for a query that was overtaken.
- **Proposal:** `SearchSource.debounce` (a `Duration?` the controller honours), or `DebouncedSource(source, delay)`.

### F-023 · `Avatar` picks its colour from the ambient palette, so one person has two colours under a top bar with its own

- **Kind:** theme
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › Avatar` (`lib/src/common/ui/avatar.dart:55`, the private `_autoColor` over `context.colors.chart`); Carbon's dark header re-provides a palette of its own around the top bar.
- **App:** `lib/src/frame/navigation.dart` `pageTokens` and `staffAvatarColor` (~30 lines: the kit's pick, repeated over the page's palette and passed as `Avatar.color` in the top bar and the sidebar foot).
- **Evidence:** theme gallery "Carbon" › "Carbon · dark · orders": the signed-in "NL" was teal in the top bar and pink in the sidebar foot; the same in "Appearance · Carbon dark".
- **Workaround:** pin the colour, computed against the page's palette.
- **Proposal:** make the auto colour public (`Avatar.colorFor(name, palette)`), or have `Avatar` hash against the page palette (`AdminScope`'s tokens) rather than a chrome's.

### F-024 · A theme of your own keeps its base theme's chart series: the README's recipe draws every chart in Iris indigo

- **Kind:** theme
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `theme.dart › AdminPalette.copyWith` and `AdminPalette.branded` (`lib/src/theme/palette.dart:940`, "[chart] is kept: charts don't follow the brand"); the README's "A theme of your own" copies `irisPalette` with a new primary and says nothing about `chart`.
- **App:** `lib/src/appearance/themes.dart` `greenhouseTheme` (two 8-colour series, ~25 lines).
- **Evidence:** theme gallery "Greenhouse (a theme of our own)" › "Greenhouse · light · dashboard": the revenue line, its area, the four sparklines and the best-seller bars were Iris indigo on a green interface.
- **Workaround:** `copyWith(chart: …)` on both palettes, leading with the house green.
- **Proposal:** a line in the README recipe (set `chart`, or derive it), or `AdminPalette.branded(seed, chartLead: true)` that rotates the series to the seed's nearest hue.

### F-025 · `Asset` has no `copyWith`: changing one field rebuilds eleven

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `assets.dart › Asset` (`lib/src/assets/ui/asset_library.dart:33`): an immutable value with eleven fields and no `copyWith`.
- **App:** `lib/src/fake/fake_media.dart` `FakeAssetSource.updateAlt` (13 lines), and the seed's usage counts (`lib/src/fake/seed.dart` `_seedProducts`).
- **Evidence:** "The media library" › "Media · alt text saved": the saved asset is the old one field by field with a new `alt`; a field added to `Asset` later would be dropped silently.
- **Workaround:** every field carried over by hand.
- **Proposal:** `Asset.copyWith({...})`.

### F-026 · `AssetSource` resolves one id per call: a list of rows either browses the whole library or asks once per row

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `assets.dart › AssetSource.resolve(String id)` (`lib/src/assets/asset_source.dart:25`); no batch form.
- **App:** `lib/src/screens/products/catalogue_widgets.dart` `CatalogueLookups.load` pages through the whole library once for the product list's thumbnails (it used to take one page of 200, so a photo past it showed none); `lib/src/screens/orders/order_detail_screen.dart` `_loadPhotos` resolves each line's photo in its own call.
- **Evidence:** "Browsing the catalogue" › "Products" (one `media.browse` for 40 assets) and "Refunding an order" › "Order" (three `media.resolve` calls for three lines).
- **Workaround:** browse every page for a list; one call per id for a handful.
- **Proposal:** `Future<Map<String, Asset>> resolveAll(Iterable<String> ids)` on `AssetSource`, with a default that calls `resolve` per id.

### F-027 · The kit has no breakpoint vocabulary a host can read

- **Kind:** missing-api
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** scattered per-widget constants: `shell.dart › TopBar.compactWidth` (600), `PageHeader.compactWindowWidth`, `SaveBar.compactWidth` and `phoneWidth` (480, `lib/src/shell/ui/save_bar.dart:236`, `:241`); nothing exported says "compact", "medium", "expanded".
- **App:** `lib/src/frame/breakpoints.dart` (the whole file, ~30 lines): the app's own `Breakpoint` enum (under 600, 600–1199, 1200 up), which every screen reads for cards or table, fullscreen modals and the frame's rail. F-001 and F-011 lean on it.
- **Evidence:** "Phone · orders as cards" and the `window-small` smoke walk (the rail): the app's 600 happens to match `TopBar.compactWidth`, and the save bar folds at 480 on its own.
- **Workaround:** the app's enum.
- **Proposal:** done: `theme.dart › AdminBreakpoints` (600 and 1200 by default, on `AdminTokens.breakpoints`, set per theme through `AdminTheme.from(breakpoints:)`, read as `context.breakpoints`) and `AdminBreakpoint.of(context)` / `forWidth`. The screens read `AdminBreakpoint`, and the app's enum is gone.

### F-028 · `SideSheet` pads the safe area in its own surface colour, and `Shell` pads none: a drawer opens on bands the frame does not have

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › SideSheet` (`lib/src/common/ui/side_sheet.dart:163`): a `SafeArea` around the whole surface, painted in `colors.surface` whatever the child paints; `shell.dart › Shell` (`lib/src/shell/ui/shell.dart:50`) and `TopBar` (`lib/src/shell/ui/top_bar.dart:78`) take no inset at all, so the top bar starts at the window's top edge.
- **App:** `lib/src/frame/navigation.dart` `openNavigationDrawer` (the sheet's top and bottom padding removed, the bottom inset handed to `FrameSidebar.bottomInset`, ~8 lines) and `_DrawerHeader` (the shop's mark on a row as tall as the top bar, ~20 lines).
- **Evidence:** "Getting around on a phone" › "Phone · navigation" on `iphone-16` (insets 59 and 34): before, the drawer began with a 59 px band in the sheet's white above "SALES" and ended with a 34 px one under the footer, both lighter than the sidebar, beside a top bar that starts at the top edge. Under Ant's dark sider the same bands are the page's white against a dark column.
- **Workaround:** `MediaQuery.removePadding(removeTop: true, removeBottom: true)` around the `SideSheet`; the sidebar's footer keeps the bottom inset in the sidebar's colour, and a header as tall as the top bar carries the shop's mark where the bar has it, so the drawer lines up with the frame it covers.
- **Proposal:** done: `TopBar` runs under the status bar in its own colour, `Shell` takes that inset out of the row below it, and `Sidebar` paints the top and bottom insets in its own colour; `SideSheet(safeArea:)` keeps each part clear at its own edges. `MediaQuery.removePadding`, `FrameSidebar.bottomInset` and `_DrawerHeader` are gone: the kit's drawer head is as tall as the top bar and carries its `leading`.

### F-029 · A click on a submenu row with no level of the menu under it closes the menu and chooses nothing

- **Kind:** bug
- **Severity:** S2
- **Status:** fixed (in the kit; the app had no workaround)
- **Kit:** `widgets.dart › MenuSubmenu` (`lib/src/common/ui/menu.dart:959`, `_MenuPanelState.build`): before the fix, a submenu's panel sat in a `MouseRegion(opaque: false)`, which kept it out of its popover's tap region, so a press on a row that lay over no other level of the menu counted as a tap outside and closed every level before the release could choose. A press and release in one frame, as a test's tap makes them, still chose. The fix makes the region opaque, and `test/menus_submenu_test.dart` clicks rows beside the menu, past it and over it.
- **App:** none: `lib/src/frame/user_menu.dart` is plain `MenuSubmenu`s (Appearance › Theme, Mode, Language).
- **Evidence:** the owner's report, from using the app on a desktop: avatar › Appearance › Theme. The avatar sits in the window's end corner, so Appearance opens toward the start and Theme, the third level, over the top-level menu and past its last row; a click on any theme below Material closed the menu and left the theme as it was. No scenario showed it: taps press and release in one frame (T-012). "Picking a theme from the user menu" (07_settings, `window`) › "User menu · themes" and "Dashboard · Greenhouse, from the user menu" now click with a mouse, frames apart, on the last theme, asserted to lie over neither other level; on the kit before the fix that click unmounts the pressed row and the scenario fails. "Smoke · user menu" (smoke) shows the top level.
- **Workaround:** none.
- **Proposal:** done.

### F-030 · A script fallback set a field's baseline where the theme's own family is absent, lifting field text

- **Kind:** bug
- **Severity:** S2
- **Status:** fixed (in the kit; the app had no workaround)
- **Kit:** `theme.dart › AdminTypeSpec.fontFamilyFallback` (`lib/src/theme/typography.dart:496`, `_withFallback`): before the fix, a spec's fallback came straight after the style's own family. On the web Iris, Ant and Fluent name platform families that do not exist there, so the first family the engine had was the app's `Noto Naskh Arabic` (F-006): a `TextField`'s forced strut took Naskh's ascent and descent, and a trigger's value drew its spaces and digits in Naskh. The fix puts the platform's UI fonts (the Material typography's family for the platform, and Roboto on the web) before a spec's fallback; `test/field_text_centring_test.dart` measures every theme's fields.
- **App:** none for the lift; `lib/src/appearance/themes.dart` `withArabicFallback` (F-006) is what puts Naskh on every spec.
- **Evidence:** the owner's report, on the web: `#/settings/shop`, "Shop name" in Iris, measured on a 2× screenshot: the box spans device rows 256–327 and the "P" rows 279–297, 3.5 device px (1.75 logical) above centre; after the fix, 1.5 (the remaining ~0.75 logical px is the engine's baseline rounding, shared with buttons, and left as is). In the scenarios the same field is "Shop settings" (02_home, `window`), and it did not move with the fix: the lanes run `flutter_tester` on macOS, where Iris's and Ant's platform family resolves and Fluent's `Segoe UI` is a loaded stand-in (F-004), so Naskh was never first there. Re-exported in en, fr and ar, 36 shots per language changed and no field among them: only the ⌘ of the search field's ⌘K hint in Carbon, Material and Fluent, whose fonts lack the glyph, which now comes from the platform's UI font instead of the engine's own fallback past Naskh (a box of at most 24×20 logical px, e.g. theme gallery › "Carbon · light · orders" and "Appearance · Carbon dark").
- **Workaround:** none.
- **Proposal:** done.

## A · Access & home (F-100–F-199)

Owned by WP-A.

### F-100 · `SignInForm` can say a server refusal only above the form: no per-field error, so `AuthFieldError` has nowhere to go

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `auth.dart › SignInForm` (`lib/src/auth/ui/sign_in_form.dart:30`) takes one `errorText`, shown as an `Alert`; `auth.dart › AuthFieldError` (`lib/src/auth/ui/auth_field.dart:28`) exists but the form builds its own fields.
- **App:** `lib/src/screens/access/sign_in_page.dart` (`_errorText`, ~10 lines): wrong password, locked account and inactive account all go into the one alert.
- **Evidence:** `01_access` "Signing in" › "Sign in · wrong password": the message sits above the email field although only the password was wrong.
- **Workaround:** the form-level alert, worded per `ShopError` case.
- **Proposal:** `SignInForm(emailError:, passwordError:)`, each shown under its field through `AuthFieldError`, beside the existing `errorText`. `ChangePasswordForm` has the same gap (F-504).

### F-101 · `StatCard` has no slot for a trend line, though the kit ships `Sparkline` for exactly that dashboard

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › StatCard` (`lib/src/common/ui/stat_card.dart:37`): label, value, icon, delta and a `String` caption only.
- **App:** `lib/src/screens/dashboard/dashboard_view.dart` `_Kpi` (~20 lines): a `Stack` lays the `Sparkline` over the card's delta row with `PositionedDirectional`, guessing the card's padding (`AdminSpacing.xl`).
- **Evidence:** `02_home` "The dashboard at a glance" › "Dashboard": the four KPI tiles. The overlay only holds while the delta chip and the sparkline both fit on the row (≥150 px tiles).
- **Workaround:** the overlay, with the caption dropped (the period moved to the page subtitle) so nothing runs under the sparkline.
- **Proposal:** `StatCard(trend: Widget?)` (or `sparkline: List<double>`), laid out at the end of the delta row.

### F-102 · No rule and no wizard step can name a `RecordListCell`: "at least one row" needs a borrowed cell

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `forms.dart › FieldRules` (`lib/src/forms/validation.dart:164`) and `FormRule` take a `Cell`; `FormWizardStep.fields` (`lib/src/forms/form_wizard.dart:22`) is a `List<Cell>`; `RecordListCell` (`lib/src/forms/record_list_cell.dart:11`) is not a `Cell`, yet `RecordListField` shows a required mark and a message filed under the list's id (`lib/src/forms/value_fields.dart:1876`).
- **App:** `lib/src/screens/setup/shop_form.dart`: `RecordListId` (a fake `Cell` carrying the list's id, for the step's fields) and a `FieldRules` on the shop-name cell with `id: zones.id` whose validator reads the list (~20 lines, non-obvious).
- **Evidence:** `02_home` "Setting up a brand-new shop": the shipping step refuses Next with no zone ("Add at least one shipping zone." under the list), checked by hand with the only row removed.
- **Workaround:** as above.
- **Proposal:** done: `forms.dart › ListRules(cell, minItems:, maxItems:, message:)`, and `RecordListCell` is a `Cell<List<H>>`. `ListRules(zones, message: …)` replaces the rule borrowed from the shop-name cell, and the shipping step names `f.zones` itself: `RecordListId` is gone.

### F-103 · Server field errors are keyed by cell id, and a record-list row's cell ids are opaque (minted from the wall clock)

- **Kind:** doc-gap
- **Severity:** S3
- **Status:** open
- **Kit:** `forms.dart › FormSubmitException.fieldErrors` (`lib/src/forms/validation.dart:277`) is keyed by field id; a local row's id is `r${DateTime.now().microsecondsSinceEpoch}-n` (`lib/src/forms/cell.dart:565`). The controller itself tracks rows by index path (`phones[0].label`) but does not accept one in `fieldErrors`.
- **App:** `lib/src/screens/setup/shop_form.dart` `shopSubmitError` (~40 lines): maps a server path such as `shippingZones.1.name` to the cell by walking the handles.
- **Evidence:** the cell-id scheme was guessable for top-level cells (the id is the field name passed to `FormScope.text('name')`), not for rows: nothing documents how a row's id is formed, and it changes every run, so a server cannot name it.
- **Workaround:** the path-to-cell mapping.
- **Proposal:** `FormSubmitException.fieldErrors` accepting index paths (`shippingZones[1].name`), resolved by the controller the way its baseline already is.

### F-104 · `DecimalField` takes a prefix but no unit, though its `NumberBody` has one

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `forms.dart › DecimalField` (`lib/src/forms/value_fields.dart:934`) passes `prefix` only; `fields.dart › NumberBody.unit` (`lib/src/fields/ui/number_body.dart:87`) draws a trailing `%`, `px`, `kg`.
- **App:** `lib/src/screens/setup/shop_form.dart` `PercentField` (~35 lines): the field bound by hand with `bind` over a `NumberBody(unit: '%')`, re-reading `FieldStateScope` for read-only.
- **Evidence:** `02_home` "Setting up a brand-new shop" › "Setup · shop details": the VAT rate with its `%`.
- **Workaround:** the hand-bound field.
- **Proposal:** `unit:` on `DecimalField` and `NumberField`, passed through.

### F-106 · `ValidationSummary` folds to nothing while hidden and brings no spacing, so a host cannot gap it only when it shows

- **Kind:** awkward-default
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `forms.dart › ValidationSummary` (`lib/src/forms/validation_summary.dart:30`); what shows it after a refused wizard step (`revealedByCheck`) is not public, so the host cannot know either.
- **App:** `lib/src/screens/setup/setup_screen.dart` `_GapBelow` (~35 lines): a render box that adds its gap only when its child lays out taller than zero; `lib/src/screens/products/catalogue_widgets.dart` `FormSummary` (~20 lines), which repeats the summary's show rule to put a gap below it (formerly F-311). Two work packages, two workarounds for one gap.
- **Evidence:** `02_home` "Setting up a brand-new shop" › "Setup · fix the highlighted fields": without it the alert touched the steps indicator; with a plain `Gap` the page carried an empty band whenever the form was valid. `05_catalogue` "Adding a product" › "New product · fix the highlighted fields": the same against the field group.
- **Workaround:** `_GapBelow`.
- **Proposal:** done: `ValidationSummary(margin:)`, applied only while it shows, `ValidationSummary.showsFor(controller)`, and `FormWizard(summary:)`. `FormWizard(summary: ValidationSummary())` replaces `_GapBelow` on the setup page, and `ValidationSummary(margin: EdgeInsets.only(bottom: lg))` replaces `FormSummary` on the product and new-product pages.

### F-107 · `EmptyState` has no tone: a success end state reads as an empty list

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › EmptyState` (`lib/src/common/ui/empty_state.dart:9`): the icon is always muted.
- **App:** `lib/src/screens/setup/setup_screen.dart` `_Ready`: accepted as is (no workaround).
- **Evidence:** `02_home` "Setting up a brand-new shop" › "Shop ready": the check mark is the grey of "No sales yet".
- **Workaround:** none; accepted as is.
- **Proposal:** `EmptyState(tone: Severity?)`, colouring the icon (and its halo, where a theme draws one) from `severityStyleOf`.

### F-108 · `DonutChart`'s legend overflows a narrow card instead of wrapping or eliding

- **Kind:** bug
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › DonutChart` (`lib/src/common/ui/chart.dart:282`): the ring and a `Flexible` legend in a `Row`, but each legend item (`:592`) is a `Row` holding an unflexed `Text`, so a label longer than the room left overflows.
- **App:** `lib/src/screens/dashboard/dashboard_view.dart` (the best-sellers and channels cards stack below 880 px of content, ~15 lines).
- **Evidence:** the phone story on `ipad` (en) › "Phone · dashboard": "A RenderFlex overflowed by 5.9 pixels on the right" (and 1.2 px), the channels card 270 px wide with "Market stall" cut at the stripe. Found at integration; the desktop widths and the phone's single column never gave the card so little room.
- **Workaround:** stack the two chart cards at medium widths.
- **Proposal:** give each legend item's label `Flexible` with an ellipsis, and put the legend under the ring when the row is narrower than ring + legend.

### F-109 · `LineChart` thins its category labels greedily by width, so a month's axis is spaced unevenly

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › LineChart` (`lib/src/common/ui/chart.dart:836`, `_AxisLayout.measure`): the first label always shows, then each next one that clears its shown neighbour; there is no interval or label-count parameter.
- **App:** `lib/src/screens/dashboard/dashboard_view.dart` `_RevenueChart` (~10 lines): over 30 days only every 7th day gets a label, counted back from the last; the others are empty strings. Over 90 days every day is labelled and the chart's own thinning is kept, because a blank label counts as shown: with days about 10 px apart the blanks crowded out every date but the last.
- **Evidence:** "The dashboard at a glance" › "Dashboard" on `window-wide`: the labels ran daily from Dec 3 to Dec 9, about 60 px apart, then every other day, about 120 px apart, because "Dec 9" is narrower than "Dec 10"; in Fluent every day was labelled in small type. "Dashboard · last 90 days" with a label every 14th day: the axis read "Dec 31" and nothing else.
- **Workaround:** blank labels between the ones to show, up to a month; past it, none.
- **Proposal:** `LineChart(labelEvery: 7)` or `maxLabels:`, spacing the shown labels evenly from the last point; and leave an empty label out of the thinning. Done, two ways. A crowded category axis now names every k-th label counted back from the last, evenly spaced, and an empty label is neither shown nor counted. And a series of dates no longer needs categories: `LineChart.time` takes `ChartTimeSeries` of `(DateTime, double)` points on a time axis ticked on the calendar, in the locale's words and from its first day of the week. `_RevenueChart` passes its days as points; the blank labels and their arithmetic are gone, and the axis reads a date a week (or a month, over 90 days) at even steps.

### F-110 · `StatCard` has no loading state

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `widgets.dart › StatCard` (`lib/src/common/ui/stat.dart`): label, value, delta and footer, no `loading`; `ChartCard(loading:)` and `AttentionGrid` have one.
- **App:** `lib/src/screens/dashboard/dashboard_view.dart` `_SkeletonKpi` (~35 lines): a `Panel` of `Skeleton` rows that repeats the card's padding, row heights and pill radius.
- **Evidence:** "The dashboard at a glance" › "Dashboard · loading": the KPI row is the app's skeleton, the charts' are the kit's.
- **Workaround:** the hand-built skeleton, which drifts when the card's anatomy changes.
- **Proposal:** done: `StatCard(loading: true)`, as tall as a loaded card in every theme and at any text size, and a `StatGrid` that pulses its loading cards from one `SkeletonGroup`. The dashboard's loading tiles are `StatCard(label:, icon:, loading: true)`; `_SkeletonKpi` is gone.

## B · Orders & customers (F-200–F-299)

Owned by WP-B.

### F-201 · A saved view's name is stored text, so `SavedViewsBar` cannot show the shop's own views in the page's language

- **Kind:** i18n
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › SavedViewsBar` (`lib/src/collection/ui/saved_views_bar.dart:229`, `TabItem(v.name, …)`), `SavedView.name` (`lib/src/collection/saved_view.dart:103`).
- **App:** `lib/src/screens/orders/order_widgets.dart` `localizedView` (~15 lines) and `lib/src/screens/products/product_list.dart` (`CatalogueStrings.savedViewName`, formerly F-308): each seeded shared view is renamed by id before the bar sees it.
- **Evidence:** "Working the order queue" › "Orders · to ship" and "Browsing the catalogue" › "Products · low stock" in fr and ar: before the workaround the tabs read "All · To ship · Refund requests" on a French page.
- **Workaround:** the screen copies each seeded shared view with its name in the page's language (`view.copyWith(name: …)`), keyed by the view's id.
- **Proposal:** `SavedViewsBar(labelOf: String Function(SavedView))`, or a `SavedView.labels` map by language for views a shop ships.

### F-202 · A list with saved views is read twice on open

- **Kind:** perf
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › CollectionController` loads in its constructor (`lib/src/collection/collection_controller.dart:153`); `SavedViewsController` then applies the default view (`lib/src/collection/saved_views_controller.dart:63`), which loads again.
- **App:** `lib/src/screens/orders/orders_screen.dart` (`_list`, `_views`); no workaround, the first answer is dropped.
- **Evidence:** "Working the order queue" asserts `orders.list` ×2 before anything is touched; the run report shows both calls on the first step.
- **Workaround:** none; the controller's latest-wins rule keeps the picture right.
- **Proposal:** `CollectionController(autoLoad: false)` (or `load: false`), with `SavedViewsController` making the first load once the default view is known.

### F-203 · `CollectionTable` has no row context menu

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › CollectionTable`, `TableColumn` (`lib/src/collection/ui/collection_table.dart:46`): no row menu; `widgets.dart › ContextMenuRegion` wraps one widget.
- **App:** `lib/src/screens/orders/orders_screen.dart` `_columns` › `cell()` (~15 lines): every cell is wrapped in a `ContextMenuRegion` stretched to the cell's padding box.
- **Evidence:** "Right-click and hover" › "Orders · row menu". A right-click on a cell's padding opens nothing, and the row is not marked while its menu is open (the kit's own guidance for `onOpenChanged`).
- **Workaround:** a region per cell, entries built per row.
- **Proposal:** `CollectionTable(rowMenu: List<MenuEntry> Function(T row))` (and on `Collection`), tinting the row as selected while its menu is open; Shift+F10 on the focused row.

### F-204 · `SavedViewsBar`'s actions reach every view alike

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › SavedViewsBar` (`lib/src/collection/ui/saved_views_bar.dart:43`): one `onDelete`, `onRename`, `onSetDefault` for all views.
- **App:** `lib/src/screens/orders/orders_screen.dart` (`onDelete` and `onSaveChanges`): shop managers get them for every view, everyone else for none.
- **Evidence:** a staff member cannot delete a personal view they saved without also being offered delete on the shop's shared views, so they get neither.
- **Workaround:** gate the callbacks on the role.
- **Proposal:** `SavedViewsBar(canEdit: bool Function(SavedView))`, or the actions taking `SavedView → VoidCallback?`.

### F-205 · The kit has mention helpers but no mention composer

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `comments.dart › mentionQueryAt`, `matchMentionCandidates`, `tokenizeMentions`, `mentionRuns` (`lib/src/comments/mentions.dart:56-80`); nothing that puts them behind a text field.
- **App:** `lib/src/screens/orders/note_composer.dart` (~200 lines): the `@` query at the caret, a `Popover` opened and closed from the text's listener, a `Listbox` of teammates, ↑/↓/Enter/Tab/Escape, replacing the query with the name, tokenizing on send, and `NoteText` rendering the runs.
- **Evidence:** "A note that mentions a teammate" › "Order · mention a teammate", "Order · note added".
- **Workaround:** the composer above. `ListboxMenu` could not be used: it takes focus as it opens, which the text field must keep.
- **Proposal:** done: `comments.dart › MentionField` and `MentionText`. The note composer is the kit's `MentionField` (the app keeps its teammates, keys and the Add note button around it) and notes draw with `MentionText`; the app's `@` query, popover, listbox and keys are gone.

### F-206 · Anything but a `FormSubmitException` out of `onSubmit` is reported as a Flutter error

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `forms.dart › ValueFormController` (`lib/src/forms/value_form_controller.dart:306`, `FlutterError.reportError` on any other error).
- **App:** `lib/src/screens/orders/refund_dialog.dart` `_refund`: every `ShopError` is caught and rethrown as `FormSubmitException(message: ErrorTextScope.describe(…))`.
- **Evidence:** an offline refund would fail a scenario (`FlutterError`) instead of showing "You're offline" in the dialog.
- **Workaround:** the conversion, in each form's submit.
- **Proposal:** done: anything else `onSubmit` throws is the controller's `submitFailure`, which `FormSaveBar` and `FormActions` word through `ErrorTextScope`. Only an `Error`, a bug in the save, is still reported. The same rule now holds for an async field check and for `showConfirmDialog(onConfirm:)`, whose `errorText` defaults to `ErrorTextScope.describe`. The refund and invite dialogs, the product forms and the shop forms convert only what they word themselves, a refused field or an edit conflict; the deactivate and restore confirms pass no `errorText`.

### F-207 · A hover card needs a longer rest than any test helper knows

- **Kind:** test-support
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › HoverCard.openDelay` defaults to 700 ms (`lib/src/common/ui/hover_card.dart:62`), a literal no test can read.
- **App:** `test/support/harness.dart` `hover` rests 1.5 s (it rested 600 ms, and photographed the row without its card).
- **Evidence:** "Right-click and hover" › "Orders · customer card".
- **Workaround:** the harness's hover rests `Settle.elapse(1500 ms)`, past the delay and the card's own read.
- **Proposal:** `HoverCard.defaultOpenDelay` (and the tip's) as public constants, which the harness's `hover` waits out.

### F-208 · `KanbanBoard` pads itself inside the page's gutter, and its padding and gap are not exposed

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › KanbanBoard` (`lib/src/collection/ui/kanban_board.dart:127`, a fixed `EdgeInsets.all(AdminSpacing.xl)` and a fixed `AdminSpacing.lg` gap between columns; only `columnWidth` is a parameter).
- **App:** `lib/src/screens/orders/order_board.dart` `boardColumnWidth` (~15 lines, repeating the padding and the gap).
- **Evidence:** "The order board" › "Order board": the columns start 16 px inside the title's line, where the list's panel lines up with it; at 1024 and 1280 the viewport's edge cut the last visible column through its cards ("€23.1", "#12"), which read as an overflow, not a scroller.
- **Workaround:** a `LayoutBuilder` shares the width out so a whole number of columns fits; the others scroll in.
- **Proposal:** `KanbanBoard(padding:, gap:)`, and a `fitColumns: true` (or `minColumnWidth`) that does the sharing out.

### F-209 · `FilterBar` offers "Clear all" for conditions none of its pills shows

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › FilterBar` (`lib/src/collection/ui/filter_bar.dart:132`): a pill per field, Clear all for any active condition.
- **App:** `lib/src/screens/orders/orders_screen.dart` `_filterFields`: a `BoolFilterField` for a saved view's own condition (To ship, Refund requested) while it is set (~10 lines).
- **Evidence:** "Working the order queue" › "Orders · to ship" (first run): the bar showed only "Clear all", with nothing saying what it would clear.
- **Workaround:** the extra fields, present only while their condition is.
- **Proposal:** a pill for any active condition whose field is not listed, labelled by `FilterCondition.label`.

### F-210 · A `PopoverMenuSurface` sized to its content throws around a `Listbox`

- **Kind:** bug
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › PopoverMenuSurface` (`lib/src/common/ui/popover_menu.dart:92`, `IntrinsicWidth`), `Listbox` (a lazy list).
- **App:** none: the note composer is the kit's `MentionField` (F-205), which gives its suggestion list a fixed width itself. Before, `lib/src/screens/orders/note_composer.dart` gave the surface `width: 280`.
- **Evidence:** "A note that mentions a teammate", first run: "RenderShrinkWrappingViewport does not support returning intrinsic dimensions", then a null check in `_ListboxState._reveal`.
- **Workaround:** a fixed width.
- **Proposal:** say so in `PopoverMenuSurface`'s docs, or have `Listbox` answer intrinsics from its rows' labels.

### F-212 · A selectable card's check sits over its content's corner

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › CollectionCards` (`lib/src/collection/ui/collection_cards.dart:442`, a 24 px check chip at `top: md, start: md`, always shown under touch).
- **App:** `lib/src/screens/orders/order_widgets.dart` `OrderCard(checkRoom:)`: the first line starts 28 px in when the card is selectable.
- **Evidence:** the orders list as cards on `iphone-16`: before the workaround the check covered "#1240".
- **Workaround:** an indent, guessed from the chip's size and inset.
- **Proposal:** `CollectionCards.checkInset` (or the builder given `EdgeInsets` to keep clear), or a card header slot the check sits beside.

### F-213 · `Collection` does not pass `CollectionCards`' padding through

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `collection.dart › Collection` (`lib/src/collection/collection.dart:185`): `CollectionCards(padding:, minTileWidth:, tileHeight:)` are not parameters of `Collection`.
- **App:** `lib/src/screens/orders/orders_screen.dart`, `lib/src/screens/customers/customers_screen.dart`; no workaround.
- **Evidence:** orders and customers as cards on `iphone-16`: the cards sit 16 px inside the page's gutter, off the line of the search box and the saved views above them.
- **Workaround:** none; dropping to `CollectionCards` would mean re-threading loading, empty, error and the pager by hand.
- **Proposal:** `Collection(cardPadding:, minTileWidth:, tileHeight:)`.

### F-214 · `CollectionRealtime` refreshes the rows on reconnect, but a `SavedViewsController` whose load failed stays failed

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `collection.dart › SavedViewsController.lastError` / `retry` (`lib/src/collection/saved_views_controller.dart:21`), `CollectionRealtime.bind(onConnected:)` (`lib/src/collection/realtime_binding.dart:46`).
- **App:** `lib/src/screens/orders/orders_screen.dart` (`_reconnected`, ~15 lines): the connection stream goes through the screen, which retries the views first (their retry applies the default view and reads the rows itself) and only otherwise passes the reconnect on to the list's binding.
- **Evidence:** 07_settings "Working offline" › "Orders · back online": before the fix, the rows had reloaded while the saved views bar still said "You're offline. Try again once you're back." above them; with it, the note is gone and the list is read once (both asserted).
- **Workaround:** the screen's own reconnect listener.
- **Proposal:** `SavedViewsController(onConnected: Stream<bool>)` that retries a failed load, or `CollectionRealtime.bind(savedViews:)` that reconnects both in the right order.

### F-215 · `SavedViewsBar` asks no name or scope for a new view, and cannot rename one

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `collection.dart › SavedViewsBar` (`lib/src/collection/ui/saved_views_bar.dart:34`): `onSaveAsNew` is a `VoidCallback` and `onRename` a `ValueChanged<SavedView>`; neither prompts. The example's own prompt (`_promptView`, `example/lib/src/ui/collection/saved_views.dart:173`) is private.
- **App:** `lib/src/screens/orders/orders_screen.dart` `SaveViewDialog` (~90 lines: a `Modal`, an `InputField`, a scope choice and the Cancel/Save row); `onRename` is left null, so renaming was dropped.
- **Evidence:** "Saving a view of my own" › "Orders · save view": the dialog is the app's; the bar's "Rename" never shows.
- **Workaround:** the app's dialog for a new view; no rename.
- **Proposal:** done: `collection.dart › showSaveViewDialog` and `SavedViewsBar(onCreate:, onRenamed:, askScope:)`, which open it. `SaveViewDialog` is gone: the orders page names a new view and renames one through the bar.

### F-216 · `SavedViewsBar` has no compact form: on a phone its strip cuts a view's name mid-word at the edge

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `collection.dart › SavedViewsBar` (`lib/src/collection/ui/saved_views_bar.dart:185`): always a `Tabs` strip, with no layout parameter; `widgets.dart › Tabs` (`lib/src/common/ui/tabs.dart:529`): an overflowing strip scrolls behind an edge fade and adds a menu of *every* tab, so the tab at the edge stays half drawn. `TabsAlignment.fill` would ellipsize every label instead, and the bar does not pass an alignment through.
- **App:** `lib/src/widgets/saved_views_switcher.dart` `SavedViewsSwitcher` (~245 lines): the kit's bar from 600 up; below, the active view as a ghost `Button` opening a `Menu` of every view (the active one checked, the default one captioned) and the active view's set-as-default, duplicate and delete, beside the bar's own Reset, Save and "+" and a copy of its error row. Orders and products both use it.
- **Evidence:** "Getting around on a phone" › "Phone · orders as cards" on `iphone-16`: before, the strip read "All ★ ⌄ · To ship · Refund r…" with the fade over "requests"; in French the third tab showed one letter, and in Arabic the fade crossed its middle. After, "Phone · saved views" shows the menu.
- **Workaround:** the switcher; moving a view left or right is left to the wide strip.
- **Proposal:** done: `SavedViewsBar(layout:)` (`SavedViewsLayout.auto` by default), the active view's name over a menu of every view below `context.breakpoints.medium` of the bar's own width. `SavedViewsSwitcher` is gone: orders and products use `SavedViewsBar`.

### F-217 · A page that is not a table has no loader: the customer card reads its customer through `FutureBuilder`

- **Kind:** missing-api
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `collection.dart › CollectionController` (`lib/src/collection/collection_controller.dart:107`) gives a table loading, an error with a retry, a refresh that keeps the rows and the latest request winning; nothing gives one value the same.
- **App:** `lib/src/screens/orders/order_widgets.dart` `CustomerCard` (~30 lines): a `FutureBuilder` over a future made once in `initState`, its skeleton and its error text by hand. A refresh would have to make a new future in `setState`, which the builder listens to only at the next frame, so a future that fails first is reported as uncaught.
- **Evidence:** "Right-click and hover" › "Orders · customer card" (03_orders).
- **Workaround:** the `FutureBuilder`, with no refresh and no retry.
- **Proposal:** done: `AsyncValueController` and `AsyncValueBuilder`, the collection's load states for one value. `CustomerCard` holds a controller over `api.customer` and draws it with the builder, its skeleton the placeholder and its caption the `errorBuilder`; the `FutureBuilder` is gone.

## C · Catalogue (F-300–F-399)

Owned by WP-C. Every entry was met building `/products`, `/products/new` and `/products/:id` (Details and History); the scenarios are `test/scenarios/story/desktop/05_catalogue_test.dart`.

### F-300 · A table that opens rows on tap cannot start an inline edit from a pointer

- **Kind:** awkward-default
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `collection.dart › TableColumn.editBuilder`; `lib/src/collection/ui/collection_table.dart:1205` wires the double-tap edit only `when widget.onRowTap == null`, and a single tap on a cell opens the row.
- **App:** `lib/src/screens/products/product_list.dart:297` passes no `onRowTap` in table view and makes the identity cell a `Tappable(link: true)` that opens the product (~15 lines).
- **Evidence:** "Browsing the catalogue" › "Products · editing stock": the stock cell opens its editor on a double tap only because rows no longer open on tap. With `onRowTap` set, the only way in is keyboard focus plus Enter/F2.
- **Workaround:** rows open from their name; the rest of the row edits or selects.
- **Proposal:** done: `CollectionTable(editTrigger: TableEditTrigger.doubleTap)`, passed through `Collection(editTrigger:)`: a single tap on an editable cell waits out the double-tap window before opening its row. Products opens rows on a tap in the table too and edits stock on a double tap; the name's `Tappable` link is gone.

### F-301 · `FormScope` hands out no map cell, which `KeyValueField` needs

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `forms.dart › KeyValueField` (`lib/src/forms/value_fields.dart:1446`) takes a `Cell<Map<String, String>>`; `forms.dart › FormScope` (`lib/src/forms/cell.dart:82`) has text, number, list, relation, record-list and asset cells, but no map.
- **App:** `lib/src/screens/products/product_form.dart` `JsonMapCell` and `ProductCells.care` (25 lines): a `ValueCell<Map<String, String>>` stored as JSON in a text cell, so `ValueFormController` still tracks it.
- **Evidence:** "Editing a product" › "Product" (the Care group); discarding or saving the care advice works only because the controller sees the underlying text cell.
- **Workaround:** the JSON adapter.
- **Proposal:** done: `FormScope.map(field)`, a `ValueCell<Map<String, String>>` that `ValueFormController` tracks like any cell. `ProductCells.care` is `_s.map('care')`: `JsonMapCell` is gone.

### F-302 · `TableTextEditor.number` cannot refuse a draft

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `collection.dart › TableTextEditor.number` (`lib/src/collection/ui/table_edit_session.dart:112`): it stays open only on text that does not parse; `onCommit` is a `ValueChanged<num>`, with no integer mode, minimum or validator.
- **App:** `lib/src/screens/products/product_list.dart:140` (`_commitStock`, ~25 lines): a fraction is refused after the editor closed, a negative count is sent and rolled back when the shop refuses it.
- **Evidence:** "Browsing the catalogue", the unnamed steps after "Products · editing stock": `-3` closes the editor, one refused `products.patchStock`, the row goes back to 42 and a "Stock not saved" toast explains.
- **Workaround:** optimistic update, rollback and a toast.
- **Proposal:** `TableTextEditor.number(integer: true, min: 0, validate: (num) => String?)`, keeping the editor open and marked invalid with the message as its tooltip.

### F-303 · The kit draws a `VersionDiff` but builds none from two records

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `history.dart › VersionDiff`, `FieldDiff`, `LocaleDiff` (`lib/src/history/diff_model.dart:148`, `:239`) are plain data; only `InlineDiff.words` computes anything, and the example builds its diffs by hand (`mock_diff.dart`).
- **App:** `lib/src/screens/products/product_diff.dart:49` (`productDiff`, `_op`, `withFieldOf`, ~170 lines): a field-by-field comparison of two product snapshots, ops worked out per locale, plus the per-field restore.
- **Evidence:** "What changed, and undoing it" › "Product history · diff".
- **Workaround:** the hand-written comparison.
- **Proposal:** done: `history.dart › FieldDiff.text`, `FieldDiff.translated`, `FieldDiff.scalar` and `VersionDiff.of`. `productDiff` declares its fields with `FieldDiff.translated` and `FieldDiff.scalar` over `VersionDiff.of`; the hand-written comparison and its `_op` are gone, and the per-field restore (`DiffKeys`, `withFieldOf`) stays.

### F-304 · `ReferenceField` edits a list only; a single reference is a list of one

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › ReferenceField` (`lib/src/forms/value_fields.dart:1753`) takes a `Cell<List<K>>` and always shows its "Link…" trigger; `ReferenceResolver` asks for entities by id, which a search-only backend does not have.
- **App:** `lib/src/screens/products/product_form.dart:27` (the supplier as a one-element `list` cell, read with `firstOrNull`); `lib/src/screens/products/product_editor.dart:523` resolves ids through a supplier search.
- **Evidence:** "Editing a product" › "Product · checking SKU": the supplier card still has "Choose a supplier" under it, which would add a second supplier.
- **Workaround:** the list of one; nothing stops a second pick.
- **Proposal:** `ReferenceField.single(Cell<K?> …)` (or `maxItems: 1`, which hides the trigger once full and turns it into Replace).

### F-305 · `PresenceAvatars` takes a fixed list of peers; following a channel is the page's job

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `widgets.dart › PresenceAvatars` (`lib/src/common/ui/field_presence.dart:339`) takes `peers`; `presentPeers(channel)` and `PresenceChannel.onChange` are separate, while `FieldShell` follows a `FieldPresenceScope` by itself.
- **App:** `lib/src/screens/products/product_editor.dart:631` (`_PresencePile`, ~30 lines).
- **Evidence:** "Photos and variants" › "Product · someone else is here".
- **Workaround:** a small stateful wrapper that subscribes and rebuilds.
- **Proposal:** `PresenceAvatars.of(PresenceChannel channel)` or `PresenceAvatars.scope()` reading the ambient `FieldPresenceScope`, as the field ring does.

### F-306 · `PageScaffold` has no slot for a tab strip

- **Kind:** missing-api
- **Severity:** S3
- **Status:** fixed (kit)
- **Kit:** `shell.dart › PageScaffold` (`lib/src/shell/ui/page_scaffold.dart:29`): header, body, bottom bar.
- **App:** `lib/src/screens/products/product_editor.dart:255`: the `Tabs` strip is the body's first row, and the Details tab scrolls under it itself (`scrollable: false` plus a `SingleChildScrollView`).
- **Evidence:** "Editing a product" › "Product"; "What changed, and undoing it" › "Product history".
- **Workaround:** as above; the header and the strip stay put while the tab scrolls.
- **Proposal:** `PageScaffold(tabs: …)`, laid out under the header inside the same column width. Done: the strip sits in the header's column and gutter and stays put while the body scrolls under it. The product editor passes its Details / History strip there, Details scrolls in the scaffold (its own `SingleChildScrollView` is gone) and History, which fills the page, keeps `scrollable: false`; `SettingsScaffold` passes its strip of settings pages there too, where it had been the body's first row as well.

### F-307 · Asset dialogs open on `AdminScope`'s anchor, above a page's `AssetSourceScope`, `LangScope` and keyboard inset

- **Kind:** doc-gap
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `forms.dart › showAssetEditor` (`lib/src/forms/asset_editor.dart:45`, `ModalAnchor.of(context)`), which `AssetListField` opens on a tile tap, and `showAssetDetail` / `AssetDetailView` (`lib/src/forms/asset_detail.dart:19`: "mount the anchor below the host's language scope"); the README's scope table says a modal sees the scopes above the anchor, while `AdminScope` puts the anchor around the whole frame.
- **App:** `lib/src/screens/products/product_editor.dart` (a `ModalAnchor` inside the page, below its `AssetSourceScope`, `LangScope` and `FieldPresenceScope`); `lib/src/screens/media/media_screen.dart` `build` (a `LangScope` and a second `ModalAnchor` around the library, ~20 lines) and `lib/src/screens/media/asset_sheet.dart` (the keyboard inset read from the `View`, 4 lines). Formerly also F-404.
- **Evidence:** "Photos and variants" › "Product · crop photo" passes with the page anchor; with it removed, tapping a photo throws `LangScope.of() was called with a context that has no LangScope above it` from the asset editor's alt-text field. "The media library" › "Media · details": on `iphone-16` the page's anchor sits inside the shell's `Scaffold`, whose `MediaQuery` has the keyboard taken out, so the sheet ran under the keyboard and the Arabic lane could not be reached (`fw://…/The media library/8?device=iphone-16&language=ar`) until the sheet read the inset from the `View`. While the sheet is open, only the library is hidden from assistive technology, not the frame.
- **Workaround:** a page-level `ModalAnchor` (and `LangScope` on the media page), and the view's keyboard inset.
- **Proposal:** done: `showAssetEditor` (and the picker its Replace opens) takes the opener's `AssetSourceScope`, `ExternalProviderScope`, `LangScope`, `FieldPresenceScope` and `FieldBinderScope`, and `showAssetDetail(context:)` the page's `LangScope` and `AssetSourceScope`; `ModalAnchor` lays its modals out above the keyboard, read from the window. The product editor's and the media page's own anchors are gone, and so is the sheet's `View` inset; the media page's `LangScope` only names the shop's languages.

### F-309 · A `FieldValidator` is handed the kit's strings only; an `AsyncFieldValidator` none

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › FieldValidator` and `AsyncFieldValidator` (`lib/src/forms/validation.dart:8`, `:13`).
- **App:** `lib/src/screens/products/product_form.dart` `_stringsOf` (app messages looked up again from `AdminLocalizations.localeName`) and `productRules`' `strings` getter for the async SKU check.
- **Evidence:** "Editing a product" › "Product · two fields need attention" and "Product · SKU already used", worded in fr and ar too.
- **Workaround:** `RefStrings.lookup(Locale(l10n.localeName))`.
- **Proposal:** pass the validators a `BuildContext`-free `Locale`, or let `ValueForm` carry an app `messages` object the validators receive.

### F-310 · With no default view, `SavedViewsController` applies the first one, and the bar has no "every row" tab

- **Kind:** awkward-default
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `collection.dart › SavedViewsController.load` (`lib/src/collection/saved_views_controller.dart:141`: `isDefault ?? firstOrNull`); `SavedViewsBar` cannot show "no view".
- **App:** `lib/src/screens/products/product_list.dart:50`: `applyDefaultOnLoad: false`, an app-made "All products" view first in the bar, and the route mapping for it (~25 lines).
- **Evidence:** the first run of "Browsing the catalogue" opened on "Low stock" with 9 of 60 products; "Products" now shows all 60 under "All products".
- **Workaround:** the synthetic view.
- **Proposal:** done: `SavedViewsController` applies only a view marked default, `SavedViewsController.clearView()`, and `SavedViewsBar(onSelectAll:, allLabel:)`. The synthetic "All products" view and `applyDefaultOnLoad: false` are gone: products passes `onSelectAll: clearView` with `allLabel`.

### F-312 · `DiffView` prints each field's internal key beside its label

- **Kind:** i18n
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `history.dart › DiffView` (`lib/src/history/ui/diff_view.dart:458`, `text: field.fieldKey` after the label).
- **App:** none possible: `fieldKey` is also what `onRestorePart` hands back.
- **Evidence:** "What changed, and undoing it" › "Product history · diff": "Price  price", and in Arabic "السعر  price".
- **Workaround:** none.
- **Proposal:** `DiffView(showFieldKeys: false)`, or show the key only in a debug build.

### F-313 · Under `ValidationMode.onEdit` an edit form's `ValidationSummary` never shows

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › ValueFormController.canSubmit` (`lib/src/forms/value_form_controller.dart:225`) is false while any message shows, so Save is disabled before a submit is ever attempted, and the summary waits for a submit attempt.
- **App:** none; the editor's save bar says "2 fields need attention" instead, and the summary shows on `/products/new` only, whose blank fields are not revealed before Create.
- **Evidence:** "Editing a product" › "Product · two fields need attention" (no summary) against "Adding a product" › "New product · fix the highlighted fields" (summary).
- **Workaround:** none needed; recorded because the README presents the summary as part of every form.
- **Proposal:** let a disabled Save still count as a submit attempt on tap (reveal and summarise), or document that the summary belongs to create forms.

### F-314 · Revealing the first invalid field leaves its message under the bottom save bar

- **Kind:** bug
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `forms.dart › FormShortcuts.revealFirstInvalid` (`lib/src/forms/form_shortcuts.dart:58`), used by `ValueForm` after a refused submit: it only calls the field's `focus()`, so the input's caret is scrolled into view with `EditableText`'s 20 px padding, and the message line below it is not.
- **App:** `lib/src/screens/products/product_editor.dart` `_onFormChanged` / `_revealFocusedField` (~40 lines): it follows `ValueFormController.revealRequest` as `ValueForm` does, waits three frames for the focus scroll, then `Scrollable.ensureVisible` the focused field's keyed wrapper with `keepVisibleAtEnd`.
- **Evidence:** "Editing a product" › "Product · SKU already used": before the workaround the SKU field sat at the viewport's bottom edge and "Another product already uses this SKU" was cut in half by the page's `FormSaveBar(placement: bottom)`.
- **Workaround:** the second reveal, on the whole field.
- **Proposal:** done: `FormFieldEntry.reveal()`, which every kit jump to a field now uses: the whole refused field shows, its message 12 above the bottom save bar. The product editor's `_onFormChanged` / `_revealFocusedField` are gone.

### F-315 · The kit's own prompts and bars word some buttons through Material, which an `AdminLocalizations` override cannot reach

- **Kind:** i18n
- **Severity:** S3
- **Status:** open (verified; evidence for F-008 too)
- **Kit:** `FormSaveBar`'s default commit label (`lib/src/forms/form_save_bar.dart:169`, `saveButtonLabel`), `showConfirmDialog`'s cancel (`lib/src/common/ui/modal.dart:250`) and `UnsavedChangesGuard`'s cancel (`lib/src/forms/unsaved_changes_guard.dart:171`) are `MaterialLocalizations`; Discard, Select, Apply and Done are the kit's.
- **App:** `test/scenarios/story/desktop/05_catalogue_test.dart:23` (`_material`); the editor passes its own `commitLabel`, so its Save is found by the app's word.
- **Evidence:** "Editing a product" › "Product · leave without saving?": "Stay" is Material's Cancel, found through `MaterialLocalizations.of`, while the confirm is `s.kit`'s.
- **Workaround:** a Material lookup in the scenario beside `s.kit`.
- **Proposal:** word `FormSaveBar`'s Save and the Cancel of `showConfirmDialog` and `UnsavedChangesGuard` from `AdminLocalizations` (a `save` and a `cancel` in its shell section), so the documented override path (the app's `PottingShedKitStrings`) reaches every word the kit shows; keys as F-008 proposes for tests.

### F-316 · `FormSaveBar.savedLabel` has no doc, and its name reads as the word to show, not a detail after it

- **Kind:** doc-gap
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › FormSaveBar.savedLabel` (`lib/src/forms/form_save_bar.dart:40`, no doc comment); `SaveCluster.savedLabel` and `SaveBar.savedLabel` document it as "appended to the Saved message", and `_SaveStatus` builds it through `ShellMessages.statusWithDetail`.
- **App:** none now: the editor and the new-product page passed their own "Saved", and dropped it.
- **Evidence:** "Editing a product" › "Product · saved": the bar read "Saved · Saved" (fr "Enregistré · Enregistré").
- **Workaround:** pass nothing.
- **Proposal:** copy `SaveCluster`'s doc onto `FormSaveBar.savedLabel` and `FormActions.savedLabel`, or rename it `savedDetail`.

## D · Media & team (F-400–F-499)

Owned by WP-D.

### F-400 · A media page over an `AssetSource` rewrites the picker's private host: paging, search, filters, errors

- **Kind:** missing-api
- **Severity:** S1
- **Status:** fixed (kit)
- **Kit:** `assets.dart › AssetLibrary` (`lib/src/assets/ui/asset_library.dart:109`) is view-pure; the host that feeds it from an `AssetSource` is `_LibraryPane` (`lib/src/assets/ui/asset_picker.dart:427`), private to `showAssetPicker`.
- **App:** `lib/src/screens/media/media_screen.dart` `_MediaScreenState` `_load` / `_loadMore` and the state fields (~90 lines).
- **Evidence:** "The media library" › "Media library": the page state is the picker's pane line for line (request counter against stale answers, first page, next page, short page ends the library, error with retry).
- **Workaround:** the same state machine, written again in the screen.
- **Proposal:** done: `assets.dart › AssetLibraryController` and `AssetLibrary.connected(controller:)`, which `showAssetPicker` runs on too. The media page is `AssetLibrary.connected` over the kit's controller; its paging state machine (~90 lines) is gone.

### F-401 · `AssetLibrary`'s toolbar takes no filter of the app's, and `AssetSource.browse` filters by type and text only

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `assets.dart › AssetLibrary` builds a private `_Toolbar` (`lib/src/assets/ui/asset_library.dart:407`: search, type, view) with no slot; `AssetSource.browse({index, size, query, filter})` (`lib/src/assets/asset_source.dart:28`).
- **App:** `lib/src/screens/media/media_screen.dart` puts a `FilterMenuButton` for usage in `PageScaffold.actions` (~25 lines) and `_browseAll` reads every page to filter by `usageCount` (~15 lines).
- **Evidence:** "The media library" › "Media · unused": the usage filter sits in the page header, away from the search and type filter it belongs with; with the filter on, the library is read whole (40 assets, one call of 100) and the grid loses its paging.
- **Workaround:** a header filter, and client-side filtering of the whole library.
- **Proposal:** done: `AssetLibrary(toolbarActions:)` and `AssetSource.browse(where:)`. The usage filter is a `FilterMenuButton` in the library's toolbar, its choice set on `controller.where` and answered by the shop's browse: "Media · unused" is one paged call, not the whole library read and filtered in the page.

### F-402 · `showAssetDetail` / `AssetDetailView` take no action but Delete, so Crop cannot sit in the sheet

- **Kind:** missing-api
- **Severity:** S1
- **Status:** fixed (kit)
- **Kit:** `forms.dart › AssetDetailView` (`lib/src/forms/asset_detail.dart:54`) builds a `SideSheet` whose footer holds only `onDelete` (`:87`) and whose header `actions` it does not expose; `showAssetDetail` (`:26`) wraps it with nothing to add.
- **App:** `lib/src/screens/media/asset_sheet.dart` (~70 lines): `AssetDetailView` stacked over an app footer drawn as `SideSheet` draws its own (surface, inner edge, hairline, 12px padding); `media_screen.dart` `_openAsset` opens it with `ModalAnchorController.showSheet(width: 460)` instead of `showAssetDetail`.
- **Evidence:** "The media library" › "Media · details" and "Media · crop": the footer reads as the sheet's own only because its colours, edge and padding are the kit's `SideSheet` footer, copied.
- **Workaround:** the stacked footer.
- **Proposal:** done: `AssetDetailView(actions:, footerActions:)` and the same on `showAssetDetail`. The details sheet is `showAssetDetail(footerActions: [Crop, where it is used])`; `asset_sheet.dart` and its copied `SideSheet` footer are deleted.

### F-403 · A library asset has no crop: `Asset` carries none and `AssetSource` cannot save one

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `assets.dart › Asset` (`lib/src/assets/ui/asset_library.dart:33`), `AssetSource` (`lib/src/assets/asset_source.dart`); `forms.dart › showCropDialog` (`lib/src/forms/asset_editor.dart:423`) returns a `CropValue` that the kit only stores on a usage (the asset reference's cell).
- **App:** `lib/src/screens/media/media_screen.dart` `_crops` and `_crop` (~20 lines): the crop is kept for as long as the page.
- **Evidence:** "The media library" › "Media · crop": Apply closes the dialog and raises a toast, and no call goes out (the scenario asserts the call log still holds only `media.updateAlt`).
- **Workaround:** a crop per asset in page state, reopened from where it was left; nothing persists.
- **Proposal:** `Asset.crop` (a default `CropValue` a new usage starts from) and `AssetSource.updateCrop(id, CropValue)`, or a documented statement that crops are per usage only, so a library page does not offer one. (A product's photos keep their crop through the app's own model, `Product.photoCrops`, because the crop lives on the usage there.)

### F-406 · `onSaveAlt` gets the whole alt text with cleared languages left out, and its doc does not say so

- **Kind:** doc-gap
- **Severity:** S3
- **Status:** open (verified in source)
- **Kit:** `forms.dart › AssetDetailView.onSaveAlt` (`lib/src/forms/asset_detail.dart:64`); `_AltEditor._save` (`:227`) sends every non-empty lane.
- **App:** `lib/src/fake/fake_media.dart` `updateAlt` replaces the stored alt text (it merged, so a cleared language came back).
- **Evidence:** "The media library" › "Media · alt text saved": one Arabic lane typed, and `media.updateAlt` carries en, fr and ar. A server that merges (as the fake does, `{...old, ...alt}`) never removes a language the user cleared.
- **Workaround:** the fake replaces the map; `test/unit/model_test.dart` "saving alt text replaces it, so a language can be cleared".
- **Proposal:** say "the complete alt text; a language missing from the map has none" on `onSaveAlt` and `AssetSource.updateAlt`, or pass the changed languages beside it.

### F-407 · `AssetLibrary` fixes its tile size, so a phone grid is 3-up, not 2-up

- **Kind:** missing-api
- **Severity:** S2
- **Status:** fixed (kit)
- **Kit:** `assets.dart › AssetLibrary` builds `MediaGrid` with the default `maxTileExtent: 150` (`lib/src/assets/ui/asset_library.dart:323`) and takes no size of its own; `MediaGrid.maxTileExtent` is public but unreachable through the library.
- **App:** `lib/src/screens/media/media_screen.dart` (the library as the kit lays it out; no workaround).
- **Evidence:** "The media library" › "Media library" on `iphone-16`: three 110px tiles whose names ellipsize; the spec's 2-up phone grid was dropped, since only a copy of the library's toolbar and states (F-400) could change it.
- **Workaround:** none; replacing the library with a hand-built `MediaGrid` would mean copying its toolbar and states too (F-400).
- **Proposal:** done: `AssetLibrary(maxTileExtent:)`, and a two-up grid below `context.breakpoints.medium` by default. On `iphone-16` the grid is two 158.5px tiles whose names show whole (it was three of 101.7).

### F-408 · `Field` takes no text direction, so an email field reads right to left in Arabic

- **Kind:** i18n
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › Field` (`lib/src/forms/value_fields.dart:524`): `keyboardType` and `autofillHints`, no `textDirection`.
- **App:** none; `lib/src/screens/team/invite_dialog.dart` keeps the email `Field` as is.
- **Evidence:** "Inviting a teammate" › "Invite · invalid email" in `ar`: the address and its `name@example.com` hint sit against the right edge, the caret on the left of what was typed.
- **Workaround:** none; a `Directionality` around the field would flip its label and message too.
- **Proposal:** `Field(textDirection:)` for the input alone, or LTR by default when `keyboardType` is `emailAddress` or `url`.

### F-409 · `showCropDialog` takes no size, so on a phone it is not full screen

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** `forms.dart › showCropDialog` (`lib/src/forms/asset_editor.dart:423`) builds its `Modal` at `ModalSize.large`.
- **App:** none; the app's other dialogs use `ModalSize.fullscreen` below 600.
- **Evidence:** "The media library" › "Media · crop" on `iphone-16`: the dialog floats with a margin, its presets wrapped on two rows, and the page's toast lands over its title.
- **Workaround:** none.
- **Proposal:** `showCropDialog(size:)`, or `ModalSize.large` falling back to full screen under a compact width.

## E · Settings, phone, themes (F-500–F-599)

Owned by WP-E.

### F-501 · A `Choice` card cannot show a preview, and `Choice` cannot lay its cards out in a grid

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › ChoiceOption` (`lib/src/common/ui/choice.dart:15`) carries `label`, `description` and an `IconData icon`, no widget; `Choice` (`choice.dart:61`) lays out one `Column`, or one unwrapped `Row` for `Axis.horizontal`.
- **App:** none: the app's theme cards went with its hand-built picker (F-003), and the kit's `AppearancePicker` lists the themes as radios. The app keeps its `ThemePreview` (`lib/src/screens/settings/appearance/appearance_view.dart`), in a card of its own.
- **Evidence:** "Appearance and language" › "Appearance": seven full-width cards stacked in one column take the whole first screen, and none can show its theme's colours, the one thing that tells themes apart at a glance. `Choice(direction: Axis.horizontal)` with seven cards overflows the row.
- **Workaround:** each card names the theme and says what sets it apart in its description; one preview under the list draws the chosen theme's buttons, a status and palette roles with the kit's own widgets.
- **Proposal:** `ChoiceOption.leading` (or `preview`) as a `Widget`, and `Choice.columns` (or a `minCardWidth`) that wraps cards into a grid while keeping one radio group and its arrow-key order.

### F-502 · `SwatchRow` is the canvas toolbar's picker: 18px dots, no visible name, no keys, no group semantics

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › SwatchRow`, `SwatchOption` (`lib/src/common/ui/block_canvas_chrome.dart:278`, `:288`): fixed `_dot = 18`, `_box = 24`; each swatch is a `Tip` around a `Tappable`, with no key and no radio-group semantics; the file is the block-canvas chrome.
- **App:** `test/scenarios/story/desktop/07_settings_test.dart` and `test/scenarios/themes/themes_test.dart` `_swatch`, which find a swatch by its `Tip.message`. The kit's `AppearancePicker` writes the picked accent's name after the swatches, the caption the app wrote by hand; the swatches are still 18px, keyless and in no group of their own.
- **Evidence:** "Appearance and language" › "Appearance · Teal accent": the dots read small next to the 36–40px `Segmented` rows above and below them, and nothing on screen says which accent is on until the app writes it. A scenario can only reach a swatch through `find.byWidgetPredicate((w) => w is Tip && w.message == label)`.
- **Workaround:** the chosen accent's name as a caption after the row; scenarios find swatches by their localized tip.
- **Proposal:** a `SwatchPicker` in the form-control family (a `ControlSize size`, radio-group semantics named by `semanticLabel`, arrow keys like `Choice`), or `SwatchRow(size:, semanticLabel:)` with `SwatchOption.key`.

### F-503 · `SelectField` binds only a form cell, so an instant setting needs a `LocalScope` of its own

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** `forms.dart › SelectField` (`lib/src/forms/value_fields.dart:1262`) takes a `Cell<String>`; the bare `fields.dart › SelectBody` has no label chrome.
- **App:** `lib/src/screens/settings/appearance/appearance_view.dart:232`, `appearance_pages.dart` (`LocalScope`, the cell, two listeners that keep it and the appearance controller in step, ~20 lines).
- **Evidence:** "Appearance and language" › "Appearance · Arabic": the language is a setting that applies on pick, like the `Segmented` and `SwatchRow` beside it, which take `value`/`onChanged`; the select alone wants a cell.
- **Workaround:** a `LocalScope().text('language')` cell, set from the controller and listened to; `SelectBody` inside a `LabeledField` would do too, but the README steers settings pages to the presets.
- **Proposal:** `SelectField.value(value:, onChanged:, …)` (and the same for the other presets), or a documented "instant setting" recipe with `LabeledField` + `SelectBody`.

### F-504 · `ChangePasswordForm` shows a server's refusal only as an alert over the form

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `auth.dart › ChangePasswordForm` (`lib/src/auth/ui/change_password_form.dart:21`): one `errorText`, drawn as an `Alert` above the fields; no per-field error.
- **App:** `lib/src/screens/settings/profile/profile_pages.dart:55` (the shop's `validation({'current': …})` / `{'next': …}` mapped to one sentence).
- **Evidence:** "Changing my password" › "Password · current is wrong": the message sits above the form while the field it concerns is not marked, unlike the kit's own mismatch message, which sits under the confirmation field.
- **Workaround:** the sentence names the field ("That is not your current password…").
- **Proposal:** `currentErrorText` and `newErrorText`, or taking a `FormSubmitException`-style map keyed `current` / `new`.

### F-505 · A `Toggle` with no label stretches its track to a tight width

- **Kind:** bug
- **Severity:** S3
- **Status:** open
- **Kit:** `widgets.dart › Toggle` (`lib/src/common/ui/toggle.dart:23`): with a `label` the control is wrapped in `Align(widthFactor: 1)`; without one the bare track is returned and fills a tight constraint, although it is meant to be 36×20 (`toggle.dart:49`).
- **App:** `lib/src/screens/settings/appearance/appearance_view.dart:252` (`Align` around the toggle, 4 lines).
- **Evidence:** "Appearance and language" (run `e-07a`, step "Appearance · Carbon dark"): under a `LabeledField`, whose control is stretched, the "Reduce motion" switch drew a 425px-wide track with its knob at the start.
- **Workaround:** `Align(alignment: AlignmentDirectional.centerStart, child: Toggle(…))`.
- **Proposal:** always return the aligned, intrinsically sized toggle.

### F-506 · `ChangePasswordForm` cannot be cleared after a successful change

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open
- **Kit:** `auth.dart › ChangePasswordForm` (`lib/src/auth/ui/change_password_form.dart:21`): its controllers are private state; there is no controller, `reset()` or `onSuccess` hook.
- **App:** `lib/src/screens/settings/profile/profile_pages.dart:80` (a generation counter in the key).
- **Evidence:** "Changing my password" › "Password · changed": without a new key the three fields keep the old and new passwords after the success toast.
- **Workaround:** `ChangePasswordForm(key: ValueKey(_generation))`, bumped on success.
- **Proposal:** a `clearOnSuccess` flag with `onSubmit` returning a `Future<bool>`, or a `ChangePasswordFormState.reset()`.

## Tooling: flutterware (T-001–T-099)

### T-001 · No hover, mouse-click, secondary-click or key-chord scenario verbs

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `lib/src/scenarios/scenario.dart` (`ScenarioTester`'s verbs).
- **App:** `test/support/harness.dart` `hover`, `click`, `rightClick`, `pressShortcut` (~70 lines) over `s.act` and the raw tester.
- **Evidence:** WP-A's "Command palette" (⌘K), WP-B's "Orders · row menu" and "Orders · customer card", the user menu's "User menu · themes" (07_settings, a mouse click, F-029); also no submit (Enter) verb (02_home, a `TagsField` tag) and no double-tap verb (05_catalogue, the inline stock edit). `s.act` always names a step, so a gesture the verbs lack cannot be an unnamed one: the route is raw `s.tester` work, then `s.settle()`.
- **Workaround:** named `s.act` steps around raw `WidgetTester` gestures.
- **Proposal:** `s.hover(target)`, `s.click(target)`, `s.tap(target, buttons: secondary)`, `s.keys(primaryModifierActivator(K))`.

### T-002 · `shots` has no `brightness` option and there is no app-defined (theme) axis

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `scenarios_core.dart` `_shots`.
- **App:** the theme gallery walks themes through the real UI (WP-E).
- **Evidence:** `fw actions scenarios shots` lists no `brightness`.
- **Workaround:** `export --brightness=dark` for the story; the gallery for themes.
- **Proposal:** `brightness` on `shots`, and a project-declared axis (`fw.axis('theme', values: [...])`) an app reads.

### T-003 · `shots` `file` is documented as repeatable but read as a single string

- **Kind:** bug
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `scenarios_core.dart` `_shots` (`arguments['file'] as String?`).
- **App:** the README's export commands pass one `--file` each.
- **Evidence:** the action's own parameter doc says "repeatable".
- **Workaround:** one command per file or folder.
- **Proposal:** read it as a list, as `run` does.

### T-004 · Sequential `NN` renumbers every later shot when one is inserted

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (by design, noted)
- **Kit:** flutterware `scenarios_core.dart` `_shotSlug`.
- **App:** none.
- **Evidence:** inserting one shot early in the story renames every file after it.
- **Workaround:** compare with `scenarios diff` (name-matched), not by file name.
- **Proposal:** an opt-in slug-only naming.

### T-005 · Numbered scenario files break the `file_names` lint

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware orders `shots` by file path, so the story is numbered `01_access_test.dart` …; `flutter_lints` wants `lower_case_with_underscores` identifiers.
- **App:** `analysis_options.yaml` turns `file_names` off for the package (marked `# FRICTION(T-005)`).
- **Evidence:** `fvm flutter analyze` reports one `file_names` info per story file.
- **Workaround:** the lint is off.
- **Proposal:** an explicit order in the folder config (`runScenarios(order: [...])`), or document the lint.

### T-006 · `s.act` always names a step, so a regression walk cannot keep its acts out of `shots`

- **Kind:** missing-api
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `ScenariosPackage(directory:)` and `shots`, which walk every folder under it.
- **App:** `test/scenarios/smoke` gets a head device of its own (`window-small`) in `test/support/profiles.dart`, so its shots land in a set apart from the story's.
- **Evidence:** the smoke walk's own steps could stay unnamed and out of the export, but a walk that drives the app through `s.act` (a push, a key chord, T-001) names a shot every time; sharing the story's head, those would interleave into `<lang>/window`'s numbering.
- **Workaround:** a distinct head device per folder (`window-small` for the smoke walk), so its pictures are a set apart; the README says it is a regression set, not part of the story.
- **Proposal:** `s.act(..., shot: Shot.skip)`, or `runScenarios(export: false)` for a folder that is a regression walk.

### T-007 · Awaiting a fake-time future inside `s.act` hangs for minutes, silently

- **Kind:** test-support
- **Severity:** S2
- **Status:** open (verified)
- **Kit:** flutterware `ScenarioTester.act` awaits its body before settling; the body runs under fake time.
- **App:** `test/scenarios/smoke/smoke_test.dart` fires the sign-in inside `act` without awaiting it.
- **Evidence:** `s.act('…', () => session.signIn(...))`, where the fake's latency is a `Future.delayed`, hung until the test's timeout (3 min in the bare lane, no message) — the watchdog `runAsync` has is not on `act`.
- **Workaround:** start the work in the body and let the step's settle move time: `() { signIn(...).ignore(); }`.
- **Proposal:** the `runAsync` watchdog on `act`, naming the pending fake timer, or `act` pumping while its body's future is pending.

### T-008 · `run --matrix=declared` crosses every folder's devices with every file

- **Kind:** awkward-default
- **Severity:** S3
- **Status:** open
- **Kit:** flutterware `scenarios run` › `matrix: declared` ("the union of their devices, languages and orientations").
- **App:** none; each folder is run with its own `--devices` / `--languages` instead.
- **Evidence:** `run --file=test/scenarios/story/phone/01_phone_test.dart --matrix=declared` ran the phone story on `window`, `window-wide` and `window-small` too (the desktop and theme folders' devices), where "Phone · navigation" has no menu button: 30 failures that are not bugs. The desktop story likewise ran on `iphone-se` and `ipad`.
- **Workaround:** name the folder's own devices on the command line, repeating what its `flutter_test_config.dart` profile already declares.
- **Proposal:** `matrix: declared` runs each file on its own folder profile's points (the union only across folders), or a `matrix: profile` that does.

### T-009 · `Settle.until(finder.first)` throws "Bad state: No element" while the target is absent

- **Kind:** test-support
- **Severity:** S3
- **Status:** open
- **Kit:** flutterware `Settle.until` (`lib/src/scenarios/settle.dart:302`) calls `isEmpty` on the finder's results; a `.first` finder's `filter` throws on an empty candidate list (flutter_test's `_FirstFinderMixin`).
- **App:** `test/scenarios/story/desktop/07_settings_test.dart` ("Working offline") waits on the unrefined finder instead (marked).
- **Evidence:** "Working offline" › "Orders · back online" with `until: _orderRows.first` failed at once with `Bad state: No element` and a stack inside `_Until.apply`, not with "never appeared" — the rows were not there yet, which is exactly what `until` waits for.
- **Workaround:** `until: _orderRows` (any match).
- **Proposal:** treat a `StateError` from the finder as "not yet", or evaluate the parent finder and take its first element in `until`.

### T-010 · Scenario files added or deleted while another run compiles break that run

- **Kind:** test-support
- **Severity:** S3
- **Status:** open
- **Kit:** flutterware's scenarios harness: one generated `build/flutterware/scenarios_harness.dart` per package imports every scenario file found when a run starts.
- **App:** none.
- **Evidence:** while five work packages ran their own files side by side, a scratch scenario file deleted by one agent made every other agent's next run fail to compile with a missing import, whichever file it had asked for.
- **Workaround:** no scratch files in the scenario tree while others run; a failed run is retried.
- **Proposal:** a harness per run (or per `--file` set), in the run's own output directory, importing only the files that run needs.

### T-011 · `enterText` sets the whole value in one change, so a debounce is never exercised

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `ScenarioTester.enterText` (`lib/src/scenarios/scenario.dart:1394`): "a run sets the value" through `tester.enterText`, one editing update however long the text.
- **App:** `test/support/harness.dart` `typeInto` / `typeValues` (~40 lines): one `enterText` per keystroke, 90 ms of fake time apart and unnamed, the last one settled as asked; `searchIn` types through it.
- **Evidence:** "Finding an order", "Looking a customer up", "Jumping with the command palette" and "Product · checking SKU" asserted one read per settled search, which held whether or not anything debounced: removing `CollectionController.searchDebounce` left them green. Typed a keystroke at a time they fail without the debounce.
- **Workaround:** the typing helpers.
- **Proposal:** `s.type(target, text, {Duration perKey})` (or `enterText(..., typing: true)`), which a film already does.

### T-012 · Taps are touch events on desktop devices, so pointer-adaptive widgets show their touch layout in desktop pictures

- **Kind:** test-support
- **Severity:** S3
- **Status:** open (verified)
- **Kit:** flutterware `tap` (`lib/src/scenarios/scenario.dart:1305`, `tester.tapAt`, a touch pointer) on `window`, `window-small` and `window-wide`; admin_ui's `CollectionTable` header keeps its ⋮ column menu showing after a coarse (touch) pointer (`lib/src/collection/ui/collection_table.dart:2221`, `slotted`).
- **App:** none.
- **Evidence:** "Working the order queue" › "Orders · three selected" and "Orders · shipped, undo offered": after the check boxes were tapped, every column header showed its ⋮, which a mouse user never sees at rest; the same in "Products · editing stock". A tap also presses and releases in one frame, which is why every scenario that tapped the user menu's themes chose them while a person's click lost them (F-029).
- **Workaround:** none; the pictures show the touch layout. Where a click's timing matters, `click` in `test/support/harness.dart` presses with a mouse, frames apart (T-001).
- **Proposal:** a device's pointer kind in `Devices` (mouse for the windows), used by every gesture verb.

## Worked first time

| Area | What | Note |
|---|---|---|
| Core | `buildAppTheme` + `AdminLocalizations.localizationsDelegates` under `MaterialApp.router` | The README's minimal app carried over to a Router 2.0 app unchanged. |
| Core | `AdminTheme.from` (Greenhouse) | The README's own snippet built a working house theme, dark set included. |
| Core | Overriding one kit phrase | Subclassing `AdminLocalizationsEn/Fr/Ar` and listing a delegate first worked exactly as documented. |
| Core | `LocalCollectionSource` behind a fake server | Search, every filter variant, sort and paging with no extra code; `matching` gave the CSV export for free. |
| Core | `CommandTrigger` + `showCommandPalette(sources:)` | Pages, commands, an async shop search and recents in ~150 lines; only the empty query (F-021) and the remote source's debounce (F-022) needed help. |
| Core | `ErrorTextScope(describe:)` | One place words every `ShopError` in the app's language. |
| A | `SetPasswordForm` + `NewPasswordFields` + `PasswordStrengthMeter` | Too short, mismatch and the strength ramp with no app code; only the server's refusal is the app's. |
| A | `AttentionGrid` / `AttentionItem` | Tones, counts, captions and the drill-in taps, including its own loading tiles and all-clear line. |
| A | `ChartCard(loading:)` + `LineChart` / `BarList` / `DonutChart` | Loading skeletons, empty state, RTL mirroring and locale-aware axes came free. |
| A | `FormWizard` over one `ValueFormController` | Per-step validation, the step marked in error, focus on the first field and Back/Next in 3 steps of ~60 lines; a `FormSubmitException` on Finish lands on its step. |
| A | Sharing sections between the wizard and a settings page | The same `ShopFields` handles and field widgets under a `FormWizard` and under a `ValueForm` + `FormSaveBar` (⌘S included). |
| A | `ToastScope` above the Navigator | A toast raised by a page that the next frame unmounts (sign-up, then the frame) still shows. |
| B | `CollectionController.undoable` + `ToastHandle.dismissed` | The bulk "mark shipped" with Undo, commit on timeout and rollback on refusal in ~30 lines, exactly as the doc's snippet. |
| B | `CollectionRealtime.bind` | One line per list; a bulk change or a board move refreshes the list and the board. |
| B | `CollectionController.optimistic` on a `KanbanBoard` | A drag moves the card at once and puts it back when the shop refuses. |
| B | `SavedViewsController` + `SavedViewsBar` over the fake's `SavedViewsStore` | Select, dirty, save changes, set default, reorder, and a personal view that survives leaving the page; naming a new view needed the app's own dialog (F-215), and shared names the app's words (F-201). |
| B | `FormSubmitException` keyed by field name | A `ValueFormController`'s own scope names a cell by its field, so the shop's `amount` refusal lands under the amount field with no mapping. |
| B | `SplitButton`, `Menu` + `MenuSubmenu`, `ContextMenuRegion` | Status submenus, checked current status, danger item, all keyboard-reachable. |
| B | `showSideSheet` + a nested `Collection` | The customer quick view and its orders list needed nothing but a bounded height. |
| B | `bidiIsolate` | An Arabic-script name inside an English sentence reads right with one call. |
| C | `LangScope` + `LocaleTabs` + a translated `Field` | One lane at a time; the Arabic lane lays out right to left inside an English page, and the tabs' amber dot follows the edits. |
| C | `AsyncFieldValidator` | Debounced to one `products.skuAvailable` per settled edit, "Checking…" under the field, and a seeded value is not checked again. |
| C | `FormSubmitException(fieldErrors:)` | The server's `sku` landed under the SKU field: the cell ids are the field names given to the scope, so the mapping was guessable. |
| C | `CollectionController.optimistic` | Stock and bulk status change at once and roll back on a refusal with no bookkeeping in the screen. |
| C | `AssetListField` + `showAssetPicker` + the crop dialog | Pick, reorder, remove and crop from one field once a page anchor sits below the page's scopes (F-307); read-only in a read-only `ValueForm`, where a tap opens nothing. |
| C | `FieldPresenceScope` + a scripted `PresenceChannel` | The field ring and badge came from four lines. |
| C | `VersionTimeline` + `DiffView` + `showConfirmDialog(onConfirm:)` | Timeline, per-locale diff, whole and per-field restore; the dialog kept itself open with a spinner while the restore ran. |
| C | `ColumnChooserButton` + `ColumnLayout.apply` | Hidden-by-default column, reset and header-menu hide with no glue. |
| C | `RecordListField` in `ValueFormController` | Rows added through the field are tracked for dirty and saved in order. |
| C | `UnsavedChangesGuard` with an app router | The sidebar and `router.go` both asked before leaving a dirty product. |
| D | `Collection` over a plain list endpoint | `LocalCollectionSource(await api.staff()).fetch(query)` as the fetcher: sort, paging and the empty state for free. |
| D | `MenuButton` + `MenuSubmenu` + `MenuItem(description:, checked:)` | The role submenu, with each role's reach and the current one checked, in ~30 lines. |
| D | `showConfirmDialog(onConfirm:, danger: true)` | Deactivation runs inside the dialog, with the shop's error inline, with no state of the app's. |
| D | `ValueForm` in a `Modal`, `FormActions` as its footer | The example's record dialog carried over; `Validators.email` and the "1 field needs attention" hint worked as is. |
| D | `FormSubmitException(fieldErrors: {'email': …})` | The cell id is the name given to `FormScope.text('email')`, so the server's field lands under its field on the first try. |
| D | `showCropDialog` over an anchor sheet | The dialog, a Navigator route, stacks above a `ModalAnchor` sheet and returns to it. |
| E | `AdminTokens.branded` + `==` | "The page is drawn with Carbon dark, branded teal" is one `expect` against `carbonTheme.dark!.branded(teal)`: token sets compare by value, and the animated theme lands exactly on its end value. |
| E | `Segmented` for mode and density, `Tabs` for the settings pages | Keyed once per group, localized labels, RTL and all seven themes with no adjustment. |
| E | `FieldGroup(boxed: true)` + `LabeledField` | A settings card per section, label and description over each control, in every theme's own label style (uppercase where the theme wants it). |
| E | `ChangePasswordForm` | Current, new and confirm with strength and mismatch messages in three languages, from one widget and an `onSubmit`; only the server-refusal and reset paths needed help (F-504, F-506). |
| E | `DescriptionList` + `StatusPill` + `Avatar` | The profile's read-only account card, unchanged from phone to wide window. |
| Tooling | flutterware's tap under the soft keyboard | A tap on something the keyboard covers fails naming the cover and `s.keyboard.dismiss()`, which fixed it first time (06_media_team on `iphone-16`). |
