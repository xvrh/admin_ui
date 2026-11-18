# Changelog

## 0.2.0

- A cohort retention grid, or any matrix read by intensity, is a
  `HeatTable`: a header row over a few leading `labels` columns
  (`HeatTableLabel`: "Week of", "People") and a value column for each of
  its `columns` ("+1", "+2", …). A `HeatTableRow` holds a text per leading
  column and a `HeatTableCell` per value column, whose `share`, 0 to 1,
  sets how strongly it is tinted, under its `text`, by default the share as
  a percentage. A null cell, such as a week not reached yet, is left blank,
  which a 0% is not: it keeps a faint wash. The columns are as wide as their
  text, the value columns sharing the width left over; narrower than that,
  the value columns scroll sideways, with a scroll bar shown, under the
  leading ones, which stay put behind a rule. It mirrors right to left.
- `AdminPalette.heatFill` is a heat map cell's fill at a share of the
  strongest: an accent, by default the first chart colour, at an opacity
  rising with the share from a faint wash to the strongest at which
  `foreground` text still reads at 4.5:1 over `surface` and `background`,
  so a cell's figure stays legible on every step in every theme and mode.

- A `ListboxMenu` takes `optionsWidth`, the width its widest option needs,
  which `ListboxOption.widthOf` measures, and grows past its trigger to
  hold it, up to `ListboxMenu.maxWidth` and the screen's width. `Check.size`
  is the side of a check box.
- A `FilterOption` takes a `description`: a muted line under its label in
  the filter's menu, for what tells apart options whose labels are alike.
  The pill's summary shows the label alone.
- An `InputField` takes a `contextMenuBuilder`: the menu a right-click or a
  long press opens in it, in place of the platform's, such as spellings for
  the word under the pointer above the usual Cut, Copy and Paste. On the web
  the browser's own menu is off while the pointer is over such a field, as
  over a `ContextMenuRegion`, and the field opens its own whether it took
  the focus from a click or from the keyboard.
- A `Shell` can go without a sidebar: a tool of one screen, or an app whose
  navigation sits in its top bar, a switch or a row of tabs. The page then
  takes the width at every size, and the top bar keeps its `leading`, in
  either span, starts its content at the page gutter, in line with the
  page, and has no menu button, unless the shell has a `drawer`, which a
  compact shell still opens from it.
- `ZoomController.show` zooms a `ZoomView` to a region of its content, in
  the content's pixels, such as one the app painted over the picture: as
  large as the view holds it and centred on it, no larger than `maxScale`
  and no smaller than fitted, stopping at the content's edge as a pan
  does, in the same step as the other controls.
- A `SplitView` can keep its side panes at a size of their own, as a
  desktop app keeps its sidebar and inspector: `initialSizes` gives each
  pane its width or height in logical pixels and one pane none, the free
  pane, which takes what the others leave and alone follows the view as it
  resizes. A divider resizes the sized pane beside it, and
  `onSizesChanged` reports the sizes after a drag. Short of room, the sized
  panes give way, down to their `minSizes`, before the free pane goes under
  its own, and take their sizes back as the view widens. `SplitView.two`
  takes `firstSize` or `secondSize` for the same.
- The master list of a master / detail layout has a row of its own:
  `ListRow`, a title with a muted subtitle under it, between a `leading`
  widget (an icon, an `Avatar`, a `StatusDot`) and a `trailing` one (a
  `StatusPill`, a `Tag`, a count, a timestamp). A column of them fills the
  first pane of a `SplitView`, whose next pane shows the detail of the
  `selected` row. The selected row takes a selected table row's fill and is
  announced as selected; hover and press lay the state layer over it, and
  the subtitle stays at 4.5:1 on every fill. The title and the subtitle
  take one line each and end in an ellipsis, so a long title never pushes
  the trailing widget out, and the row mirrors right to left. Without
  `onTap` a row does not open: no hand, no hover, no Tab stop and no
  button, and its text can be selected.
- An app can show a large picture, a photo, a scan or a plan, and let the
  reader look at it closely: `ZoomView` lays its `child` out at
  `contentSize`, the picture's own pixels, so what the app paints over the
  picture is in its coordinates, and opens it fitted, centred, with nothing
  painted in the bands beside it. The wheel zooms about the pointer, a
  trackpad pinches and pans, a drag pans under the open hand, a double click
  goes to actual pixels and back, and with focus `+`, `-`, `0` and `1` zoom,
  fit and show actual pixels, with or without ⌘ or Ctrl, and the arrow keys
  pan. It never shows the picture smaller than fitted or larger than
  `maxScale`, 800% by default, and stops panning at the picture's edges,
  centring it along an axis it does not fill. Fitted, it stays fitted as its
  pane resizes; zoomed in, it keeps the point at its middle. Zooming only
  transforms the child, which is never built again by it. A floating bar in
  the bottom end corner zooms out, shows the percentage, zooms in and fits
  (`showControls`), and a `ZoomController` drives it from the app's own
  controls. Steps take the theme's medium motion. `DisplayMessages` has
  `zoomArea`, `zoomAreaHint`, `zoomIn`, `zoomOut` and `zoomToFit`, new.
- An app can show a job's output, a deploy, an import, a build, as it runs
  or after: `LogView` draws its `LogLine`s, oldest first, in the theme's
  `monoSmall`. A line's `prefix`, a time or an elapsed "12.4 s", sits muted
  in a column as wide as the widest, right-aligned in tabular figures, and
  its `severity` tints it: success, warning and danger in their text-safe
  colours, info plain. It opens on the last line and keeps it in view as
  lines arrive, a burst of them in one frame too, while the reader is at the
  end; a reader who scrolls up stays on what they are reading until they
  scroll back down. With `follow: false` it opens on the first line and
  moves only when scrolled. It fills the height it is given, builds lines
  as they scroll into view, wraps long ones, mirrors right to left, and is
  a read-only place whose selection copies one line per line. With no lines
  it shows `emptyText`, or `DisplayMessages.logEmpty`, new: "No output
  yet".
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
- A screen that owns its `CommandRegistry` can dispose it as it unmounts,
  while the widgets under it withdraw their commands. A command withdrawn
  during a frame notifies after it, and that notify reached the disposed
  registry, an assertion in debug, as did a command withdrawn from one
  already disposed. A disposed registry now notifies nobody.
- A theme says how its segmented controls are drawn, as it does its fields
  and buttons: `AdminTokens.segmented`, an `AdminSegmentedStyle` read
  through `context.segmentedStyle` and given to `AdminTheme.from` as
  `segmented`. Its `variant` is a `SegmentedVariant.track`, a recessed
  track whose selected segment is a raised knob that slides between them,
  or `SegmentedVariant.joined`, segments in one outline with the selected
  one filled. `inset` is the gap between a track and its knob,
  `trackOutline` and `knobOutline` ring them in a hairline, `indicator`
  adds an accent pill at the knob's foot, `checkmark` a check before the
  selected label, `inverse` fills a joined selection with the foreground
  inside a foreground outline, `radius` gives the control a corner of its
  own, and `labelWeight` weighs every label alike.
- A `BarListItem` takes a `detail`, a second figure after its value, muted,
  as the app formats it: a funnel step's share of the first ("84%") beside
  its count, or a second count ("4,120 times") beside the number of people.
  The details stand in a column of their own after the values, each at its
  end edge, so they read down the rows; baked into the label, a figure was
  the first thing a narrow card cut and lined up with nothing. While the
  list loads, a row given a detail shows a pulsing bar in its place.

### Looks

- A `BarList`'s values stand in a column as wide as the widest, each at its
  end edge, and every row's bar runs along the same track. Each row's track
  ended where its own value began, so a row with a short value had a longer
  track, and its bar drew longer than its share beside a row with a long
  one. The bar of a row whose value is narrower than the widest is now
  shorter by the difference, and the figures are measured again when a
  font loads.
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
- A `MaskedBody` with `ghostMask`, and so a `MaskedDateField` and the
  `inline` and `masked` editors of a `DateBody`, draws the field's outline
  alone. The decorator that lays the ghost over the field drew an outline of
  its own, which Material coloured for the state: the colour scheme's
  `outline` at rest and its `primary`, 2px wide, under focus, with a 4px
  corner inside the field's own.
- The menu of a `SelectBody`, a `MultiSelectBody` and a `FilterBar`'s
  choices grows to its longest option, from the trigger's width up to
  480px and the screen's width, so options that differ only near their end
  can be told apart. It stayed the trigger's width, at least 200px, and cut
  every option to one line. An option's label and description now take up
  to two lines before the ellipsis, in every listbox: one longer than the
  widest menu wraps, as does one in a combobox's or a mention's list, which
  keep their field's width.

- A `Segmented` is drawn as each theme's reference system draws one. It was
  an outlined strip in every theme, its dividers the field outline at full
  height and its selection the soft primary tint, which read as a row of
  cells rather than a choice. Iris, shadcn and Ant now draw a track, the
  hover wash over what lies beneath, with the selected segment a raised knob
  in the surface that slides to the next selection over the theme's medium
  duration, its label in the foreground and the others in the muted shade
  that holds 4.5:1 on the track: Iris rings its knob in a hairline 3 in,
  shadcn lifts it on its small shadow 3 in, as its tabs list does, and Ant 2
  in, as its `Segmented` does, with regular labels. Fluent rings the track
  too and sets a 16px accent pill on the knob's foot, its labels lifted half
  the pill's height, as its `Segmented` does. Material keeps the outlined
  segments, the selection now in `softFill`, M3's secondaryContainer, under
  `onSoft`, with a check before its label or in its icon's place, and room
  kept for the check either side of every other label so the segments never
  move. Carbon draws its high-contrast content switcher: a foreground
  outline, hairline dividers, and the selection filled in the foreground
  under the surface's colour, the dividers beside it swallowed, rounded 4
  where its buttons are square, with regular labels. On a track each
  segment's tap target runs the control's full height, its wash and the
  knob drawn the inset in from the edge; a dark track rings its knob, a step
  lighter than the surface, where a shadow does not read. Disabled, a knob
  rests flat. A `DiffView`'s locale and unchanged toggles are drawn as lone
  segments of the `Segmented` beside them, in each theme's look.
- A `ChartCard`'s `trailing` widget goes under the title, above the chart,
  when beside it the title would keep less than `ChartCard.minTitleWidth`,
  200, or its one-line width where that is less. A control as wide as a
  four-option `Segmented`, on a card in a column of two, left the title a
  sliver at the header's start: the title broke word by word and a one-line
  subtitle ran to five lines. Under the title it starts at the title's
  edge, and one wider than the card is laid out at the card's width, where
  a `Segmented` shortens its widest labels. With room it stays beside the
  title, now 12 from it where nothing kept them apart. It stays in the
  header while the card is `loading` or `isEmpty`, which replace the chart
  alone, so a control that picks what the chart shows can move off a
  selection that has no data. The catalog's Primitives / Chart card page
  shows the card in a column of two, at the page's width and at a phone's.

## 0.1.0

The first release. [README.md](README.md) describes the kit: the app frame,
collections and data tables, forms and field bodies, overlays, media and
asset pickers, comments and mentions, version history, charts and sign-in
screens, themed from one set of design tokens in six themes with a light and
a dark mode each. [`api.txt`](api.txt) lists its public surface and
[`looks.txt`](looks.txt) every theme's resolved tokens.
