# Changelog

## 0.2.0

- A dashboard can hold its layout while its figures load. `BarList`,
  `LineChart` (and `LineChart.time`) and `BarChart` take `loading`, as
  `StatCard` does: the list keeps its labels, its bars and values pulse,
  and a chart keeps its legend over a skeleton of its plot. Each is exactly
  as tall as it is loaded, so nothing below moves when the values land. A
  `BarList` row with an empty label stands for a row not known yet.
  `SkeletonText` is new: a skeleton exactly one line of a text style tall,
  for a page's own placeholder rows, and the one `StatCard` draws with.
- A click picks a `Combobox` option in an app wrapped in a `SelectionArea`.
  A press held past the tap timeout let the area take focus from the field,
  which closed the list before the release reached the option, so the
  value stayed as it was. Arrows and Enter already worked. A press in the
  list now keeps focus in the field, and a click elsewhere still closes it.
- On the web, a two-finger swipe no longer takes the browser back a page,
  which it often did while scrolling a wide table back to its start.
  Flutter lets the browser have a scroll that no scroll view under the
  pointer uses: one at a view's edge, over a header, or a little off a
  view's axis, and on a Mac the browser takes a sideways one as "back".
  Once one scroll anywhere on the page has reached Chrome, it goes back on
  later swipes even when the app keeps every event of them, so keeping only
  the scrolls over a wide view is not enough. `BrowserSwipeGuard`, which
  `AdminScope` now mounts, keeps every scroll in the app, wherever the
  pointer is. The browser's back button and Cmd+[ still go back.
- The top bar can run over the page alone, beside a sidebar as tall as the
  window, as Ant's side layout does: `AdminShellStyle.topBarSpan` is
  `TopBarSpan.window`, the default and the frame as before, or
  `TopBarSpan.page`. With `page`, the `TopBar`'s `leading` heads the
  sidebar, as tall as the bar and in the sidebar's palette. It heads the
  rail too, centred, where it reads `Sidebar.isCollapsed` to fit. When
  compact, it stays in the bar. The bar's content starts at the page
  gutter, and the sidebar keeps the top inset. The page keeps its state as
  a theme changes the span. The example's shell has two previews of it.
- A failure the app expects shows in its words, and only a bug is reported.
  Anything but a `FormSubmitException` that a `ValueFormController`'s
  `onSubmit` throws is kept as `submitFailure`, a new getter of
  `FormController`. `FormSaveBar` and `FormActions` word it through
  `ErrorTextScope` when the controller has no `submitError`, so an
  unreachable server says so beside Save without a conversion in each
  form. Before, any such failure read as "Couldn’t save" and was reported
  to `FlutterError.onError`, which fails a widget test. Now only an
  `Error` is reported. An async field check that throws still passes, and
  is reported only when it throws an `Error`. `showConfirmDialog`'s
  `errorText` defaults to `ErrorTextScope.describe`, which an app's scope
  words, rather than "Something went wrong. Try again.", and an `Error`
  out of `onConfirm` is now reported too.
- A refresh the user did not ask for can run in the background:
  `AsyncValueController.refresh(background: true)` and
  `CollectionController.refresh(background: true)`. Nothing on screen says it
  runs: `loading` keeps its value and no progress bar shows. The value or the
  rows change in place when the answer lands, and a failure still shows as the
  error. Use it after an edit, on a push or on a timer.
  `CollectionRealtime.bind(background: true)` refetches that way. A local
  change that settles while a background refresh runs is kept on the page it
  lands, as it is for any other load.
- Every control the kit builds can be found by a key the app gives it, so a
  test reaches it without its words, in any language. A data object that
  describes a control takes `key`, put on the control built for it, or on its
  row when a narrow layout folds it into a menu: `NavItem`, `MenuItem`,
  `MenuCheckboxItem`, `MenuSubmenu`, `TabItem`, `SegmentOption`,
  `ChoiceOption`, `SwatchOption`, `AccordionSection`, `StepItem`, `Crumb`,
  `BulkAction`, `SaveBarAction`, `ComboboxOption`, `SelectOption` and
  `FilterOption`. A widget or a function with a control of its own takes
  `<part>Key` for it: `showConfirmDialog(confirmKey:, cancelKey:)`,
  `ErrorState(retryKey:)`, `Modal(closeKey:)`, `SideSheet(closeKey:)`,
  `SaveCluster` and `SaveBar(saveKey:, commitKey:, discardKey:)`,
  `FormSaveBar` and `FormActions(commitKey:, discardKey:)`,
  `FormWizard(backKey:, nextKey:)`, `Pagination` and
  `Pager(previousKey:, nextKey:)`, `Collection(previousPageKey:,
  nextPageKey:)`, `Toast(actionKey:)`, `BulkActionBar(clearKey:)`,
  `SearchField(clearKey:)`, `SignInForm(emailKey:, passwordKey:, submitKey:,
  forgotKey:)`, `SetPasswordForm(newKey:, confirmKey:, submitKey:)`,
  `ChangePasswordForm(currentKey:, newKey:, confirmKey:, submitKey:)` and
  `NewPasswordFields(newKey:, confirmKey:)`. A folded `IconAction` keeps its
  key on its row in the save bar's menu. `FormWizard` keyed its footer by
  `ValueKey('back')` and `ValueKey('next')`, which an app's own `Key('next')`
  equals; it now keys them by a type of its own. The README's API conventions
  say the rule, and *Testing an app on the kit* shows it.
- A tap target leaves its text out of any `SelectionArea` above it: `Tappable`,
  `CursorRegion`, `Button`, a `CollectionTable` row that opens, a cell edited
  on a double tap and a column header (both under the arrow), a field's label
  (which focuses the field, under the arrow cursor a browser gives a label),
  a tags field's box, a collapsible field group's header, a reference field's
  result rows and load-more, and the image cropper's aspect chips. Before, a
  drag across their labels selected them and only the cursor changed, or the
  I-beam showed. `MentionText` under a tap target stays
  plain rather than opening a selection area of its own, which also put a
  second Tab stop inside the target. The example's selection sweep pumps every
  demo under a `SelectionArea` and fails on selectable text under a target.
- Every control shows the hand off the web too, so a development build on the
  desktop looks like the shipped web app. `Button`, the tree's caret, a
  collapsible field group's header, a reference field's rows and load-more and
  the image cropper's aspect chips took Material's platform-adaptive default,
  the arrow off the web, while `Tappable` showed the hand. A selected option,
  a selected swatch and the current page number show the hand like a selected
  tab (they showed the arrow), and a kanban card that opens shows the hand
  even when it can also be moved (it showed the open hand).
- A collapsed `Sidebar` rail opens over the page, expanded, so its labels
  are within reach: when the pointer rests on it for
  `Sidebar.railOpenDelay`, and when focus moves into or within it by a key.
  The page does not move. It closes as the pointer or focus leaves, on
  Escape, and as an item opens; a menu opened from it, such as a
  `SidebarAccount`'s, keeps it open. A click on the shut rail opens the item
  and keeps the rail shut until the pointer leaves. The column moves to the
  overlay while it is open, keeping its scroll, focus and keys, so a test
  finds one row per item, open or shut.
- `Shell.hasDrawer(context)` says whether the frame opens its navigation as
  a drawer from the top bar's menu button: compact, and now also between
  the breakpoints beside a collapsed rail. `Shell.openDrawer` opens it in
  both. A top bar of the app's own shows its menu button by it.
- A list can hold rows that open and rows that do not, such as an upload
  still on its way among the files that have arrived: `canOpen` on
  `CollectionTable`, `CollectionCards`, `KanbanBoard` and `Collection` says
  which rows `onRowTap` or `onCardTap` opens, and null opens them all. A row
  it leaves out is content, not a control: it shows no hand, is no Tab stop
  as a card, opens on no Enter and announces no open action. A table cell of
  such a row edits on a double tap, as in a table with no row tap. A card
  under a selection still selects on a tap, and a board's card still moves.

### Looks

- A loading `StatCard` keeps room for the delta and the caption it is given,
  and for no other. It kept room for both whatever it was given, so a card
  that loads into one with a caption alone stood taller by the height of
  the delta's chip, and one with neither by a whole row, and the page moved
  up when the figures landed. Their words are not shown while it loads, so
  a page gives the loading card the delta and caption the loaded one will
  have, with any words. A loading card given neither is a row shorter than
  before.
- Stock Material widgets under `buildAppTheme` draw the accent the way the
  kit's own controls do, at its contrast target. The label of an
  `OutlinedButton` or an `ElevatedButton`, and a selected `ListTile`, take
  `primaryText`; a checked `Checkbox`, a selected `Radio`, a `Switch` that is
  on and a `TabBar`'s indicator take `controlAccent`, their check and thumb
  `onControlAccent`. They took `primary`, which a light brand accent leaves
  under 4.5:1 as text and under 3:1 as a control. Among the shipped themes,
  the labels move in Iris Dark, Ant, Fluent Dark and Carbon Dark, and the
  controls in Fluent Dark only. The catalog's Foundations / Stock Material
  page shows them under the theme's accent and under a light one.
- Between the breakpoints, beside a collapsed rail, the `TopBar` leads with
  its menu button, as it does when compact, and its `leading` moves after
  it. The rail opened over the page carries the theme's medium shadow on its
  edge. A section label is laid out at the sidebar's width and revealed as
  the sidebar widens, as an item's row is, rather than wrapped to the
  widening width. The catalog's shell demo folds to the rail between the
  breakpoints, and has a tablet-width preview.
- A `CollectionTable` flex column whose share of the width would fall under
  its `minWidth` keeps that minimum, and the other flex columns share what is
  left. It used to keep its minimum on top of their full shares, so a table
  whose columns fit scrolled sideways by the difference, with an edge shadow
  saying there was more. A table now scrolls only when its columns' minimum
  widths outgrow it, and the flex columns beside a held one are narrower by
  what it took.
- A `CollectionCards` card lifts under the pointer only when a tap on it
  does something: it opens, or it selects. A card with neither, in a grid
  with no `onCardTap` and no selection or left out by `canOpen`, keeps its
  resting border and no shadow. Every card used to lift.

## 0.1.0

The first release. [README.md](README.md) describes the kit: the app frame,
collections and data tables, forms and field bodies, overlays, media and
asset pickers, comments and mentions, version history, charts and sign-in
screens, themed from one set of design tokens in six themes with a light and
a dark mode each. [`api.txt`](api.txt) lists its public surface and
[`looks.txt`](looks.txt) every theme's resolved tokens.
