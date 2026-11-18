# Changelog

## 0.2.0

- A theme says how its switches, checkboxes and radios are drawn, as it
  does its fields, buttons and segmented controls: `AdminTokens.selection`,
  an `AdminSelectionStyle` read through `context.selectionStyle` and given
  to `AdminTheme.from` as `selection`. `toggleWidth`, `toggleHeight` and
  `toggleKnob` size a `Toggle`'s track and knob, and `toggleKnobOn` a knob
  that grows as it turns on. `toggleOff` draws the off track filled
  (`ToggleOffStyle.filled`), as a clear track ringed in `controlBorder`
  around a knob in the same colour (`outlined`), or as that ring over a wash
  of the foreground (`tonal`); `toggleOn` fills the on track with the accent
  or, `ToggleOnColor.success`, with the success colour whatever the brand.
  `checkSize` is a `Check`'s box and `radioSize` a radio's; `radioMark`
  marks the selected radio with a disc around a `radioDot` dot in its
  on-colour (`RadioMark.disc`) or keeps its ring around a dot
  (`RadioMark.dot`). `ink` draws a checked box and a selected radio in the
  accent or in the foreground (`SelectionInk`), and `outline` rings the
  unchecked ones in `controlBorder`, `foregroundSecondary` or the foreground
  (`SelectionOutline`). `AdminRadii` takes a `radiusCheck`, a checkbox's
  corner; left out, it is `radiusSmall` capped at 4, as before. The stock
  Material `Checkbox`, `Radio` and `Switch` under `buildAppTheme` take the
  same ink, outline and on-colour.
- `Check.size` is deprecated: a box's size is the theme's,
  `context.selectionStyle.checkSize`.
- A drag is never the only way to resize a `SplitView`. Each divider is a
  Tab stop, announced as a slider whose value is the share its pane takes
  of the two panes it parts. ← and → move a divider between side-by-side
  panes the way the arrow points, in either reading direction, and ↑ and ↓
  one between stacked panes, 16 logical pixels a press. Home and End take
  its pane to its smallest and its largest, within `minSizes`, and Enter
  collapses the pane to its min size, then restores the size it had. A
  divider's pane is the one before it, or with `initialSizes` the sized
  pane where the other is the free one, so Enter on an inspector's divider
  collapses the inspector. A right-click on a divider, or a long press with
  a finger, opens a menu of the same moves, each beside its key, and a
  screen reader's increase and decrease step the pane too. Each such move
  fires `onWeightsChanged` or `onSizesChanged`, as the end of a drag does.
  A focused divider is lit and ringed inside the view. `DisplayMessages`
  has `resizePanes`, `moveLeft` and `moveRight`, new.
- A `Tree` is operated from the keyboard, and moves a row without a drag.
  It is one Tab stop, the row that held focus last: ↑ and ↓ move between
  the rows on screen, Home and End go to the first and the last, → opens a
  closed parent and then goes to its first child, ← closes an open parent
  and otherwise goes to the row's parent, and Enter or Space opens or
  closes a parent; right to left, → and ← trade places. Tab goes on to the
  controls inside the focused row, then out of the tree. With `onMove`,
  Alt+↑ and Alt+↓ move the focused row among its siblings, Alt+→ nests it
  under the sibling above and Alt+← takes it out beside its parent, as in
  a `TreeEditor`, and each row ends in a ⋯ menu of the same four moves;
  focus stays on the moved row and a screen reader hears where it went. A
  caret is a button named "Expand" or "Collapse" with its row's expanded
  state, in a `TreeEditor` too, where it was a Tab stop with no name.
  `TreeRowInfo.moves` hands a row its moves as a `TreeRowMoves`, new, and
  `rowControls: false` leaves the keys and the menu to rows that are
  controls of their own, which `TreeEditor` passes: its rows work as
  before. `DisplayMessages` has `rowMovedUp`, `rowMovedDown`, `rowIndented`
  and `rowOutdented`, new.
- A `KanbanBoard` moves a card without a drag by a pointer as well as by
  the keyboard. With `onMove`, every card is a Tab stop, whether or not
  `onCardTap` opens it, so Alt+← and Alt+→ reach a card `canOpen` leaves
  out, which no key reached before. A ⋯ in the card's top end corner opens
  a menu with a "Move to …" item per other column: it shows while the
  pointer is over the card or focus is on it, stays up where the pointer is
  a finger, and is the Tab stop after its card. The "Move to …" actions a
  screen reader is offered on the card are as before.
  `CollectionMessages` has `moveCard`, the menu's name, new.

- An app can show on which days someone used something, and how much:
  `CalendarHeatGrid` draws a square per day, a column per week and a row
  per day of the week, over the `weeks` up to today's (26 by default) or
  the weeks of a `CalendarHeatGrid.range`. A day's value in `values` takes
  one of `levels` fills by its share of `max`, from the lightest up to
  `color`, the theme's first chart colour by default; a day without one is
  a faint square that shows on a card and on the page in every theme and
  mode, and `levels: 1` draws days used or not. Days after today are blank.
  The months are named above the weeks, every second weekday at the side,
  and a legend runs from "Less" to "More" under the grid's end. The names,
  the dates and the week's first day follow the app's locale, or `locale`,
  as a `Calendar`'s do, and `firstDayOfWeek` overrides the week's start. A
  day's `Tip` gives its date and value (`formatValue`) on hover, on a long
  press and under keyboard focus: the grid is one Tab stop, the latest day,
  which the arrows move by day and by week, and Home and End to the week's
  ends. Narrower than its weeks, it scrolls sideways under a drag, opening
  on the latest week, with the weekday names kept at its side; right to
  left, it mirrors. `DisplayMessages` has `heatLess` and `heatMore`, new.
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
- A `StatCard` takes a `trend`, a small chart of its figure's recent
  history such as a `Sparkline` or a `BarSparkline` of the last 30 days.
  It stands beside the figure, at the card's end and at its own width,
  while it is no taller than the figure's line and the figure keeps beside
  it its one-line width, and at least `StatCard.minValueWidth` (96): the
  card is then as tall as one without. Otherwise, on a narrow tile such as
  one of two across a phone, or with a figure too wide to share its line,
  it goes under the delta and the caption, across the card, along its
  bottom edge, so the label, figure and delta of the cards in a `StatGrid`
  row stay level, trend or not, and trends under their figures line up
  along the row's bottom. A trend that fills its width, such as
  `Sparkline(width: null)`, always goes under. The chart is left out of
  the card's sentence for assistive technology, where the delta already
  speaks the change. While loading, the card shows a pulsing block of the
  trend's size in its place, for a figure `minValueWidth` wide or as wide
  as its `value` when given one, so a loading card given the trend the
  loaded one will have, with any values, is as tall as it. It mirrors
  right to left.
- `shadcnDarkSidebarPalette` is the palette the shadcn theme's sidebar draws
  with in dark mode, as `antSiderPalette` is Ant's sider: the dark palette
  on the `--sidebar` rail.

### Looks

- Each reference theme draws its switch, checkbox and radio at its design
  system's sizes and with its marks, where every theme drew a 36×20 switch,
  an 18px box and an 18px radio filled around a light dot. Iris keeps those.
  - Material: a 52×32 switch whose off track is outlined in `outline` over a
    wash, around a 16dp handle that grows to 24dp as it turns on; a
    checkbox with a 2dp corner (was 4) outlined in on-surface-variant (was
    `outline`); a 20dp radio button that keeps its 2dp ring around a 10dp
    dot when selected.
  - shadcn: a 32×18 switch around its 16px thumb, and a 16px checkbox and
    radio.
  - Ant: a 44×22 switch around an 18px handle, a 16px checkbox, and a 16px
    radio around a 6px dot (was 8).
  - Fluent: a 40×20 switch, off a clear track ringed in the neutral stroke
    around a 14px thumb of the same grey; a 16px checkbox; a 16px radio
    that keeps its ring around a 10px dot when selected.
  - Carbon: a 48×24 toggle around an 18px knob, `$support-success` green
    when on (was Blue 60); a 16px checkbox with a 2px corner (was square)
    and an 18px radio button, both in `$icon-primary`, near-black on a light
    page and near-white on a dark one (were Blue 60): the outline, the
    checked box's fill, and the selected radio's ring and 8px dot.
- In the shadcn, Ant and Carbon themes `AdminStroke.controlStrong` is 1 (was
  1.5), each system's own border width. Beside the outline of an unchecked
  box and radio, what else is drawn with it is as much thinner there: the
  edge of a selected choice card, of a selected option in a `SelectBody` and
  a `MultiSelectBody` drawn as pills or cards and of a selected import
  source, the ring of an outlined `StatusPill`, of the current `Steps`
  marker, of a field's help button and of a `MediaTile`'s check, and a
  `Tree`'s landing slot. A selected edge there is told from a resting one by
  its colour, no longer by its width as well.
- A `Check`'s glyph is never larger than its box less 2, so it keeps a pixel
  clear of the edge of a box smaller than the theme's small icon.
- A knob in an outlined `Toggle` track casts no shadow.
- A `Tree` with `onMove` ends each row in a ⋯ button, after the row's own
  content, which is narrower by its 28px and a 4px margin. A tree whose
  rows carry their own menu passes `rowControls: false` to go without it,
  as `TreeEditor` does. The Tab stop of a tree that keeps `rowControls` is
  a row, ringed inside its edge, where it was each caret.
- A `KanbanBoard` with `onMove` draws a ⋯ on a chip of its own over the top
  end corner of a card, 28px square and 6px in: under the pointer and on
  focus, and for good on a touch screen. A card keeps what must stay
  readable out of that corner.
- A loading `StatCard`'s delta bar is as wide as the chip of a short delta,
  "12%": the chip's padding, its arrow and its words, measured as the chip
  lays them out. It was three times as wide as it is tall, about 7 wider
  than that chip at the normal size, 21 in Ant. Only the chip's words grow
  with the text size, not its padding or its arrow, so at twice the size
  the bar stood up to 80% wider than the chip, and a loading card two
  across a phone (165.5 wide) overflowed in Ant. The bar is narrower at
  every size, and a loading card fits wherever the card it becomes does.
  The catalog's stat card page has a phone-width preview, its tiles two
  across.
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

- The five themes drawn after a design system were checked against its
  published tokens on 18 November 2026, and their values moved where the two
  differed. Each theme's file now names the version it was checked against
  and the contrast rules of the kit that take it away from that system. A
  value the kit's contrast, hue or ordering rules refuse is the nearest one
  they accept, and the file says so beside it.
- Material sets its titles and labels at weight 500, Material 3's Medium:
  `heading` and `strong` were 600. That is the page title, a heading, a
  section label, a table's header, a tab, the selected sidebar item,
  `bodyStrong`, `micro`, `button`, and the title and label styles of the
  Material text theme. A filled button lightens under the pointer by its
  content's state layer, 8% and 10% pressed, as M3's does: `primaryHover`
  #735EAB and `primaryActive` #7662AD, the danger pair #B93730 and #BB3C35,
  and in dark mode a pressed #C1ACF1, 10% where it was 12%. It darkened to
  `primaryStrong`, #4F378B. The light surfaces are current roles: cards and
  inputs are `surface`, #FEF8FF, one step from M3's #FEF7FF so that a
  brand's selected table row keeps its hue (was #FFFBFE), and the wells and
  a table's header `surfaceContainerLow`, #F7F2FA (was #FEF7FF). A sidebar
  item under the pointer is on-surface at just under 6%, #E6E1EA: as far
  toward M3's 8% as leaves it no stronger than the selection (was 5%). A
  field's icons are 20 (were 16), the largest the kit's fields hold of M3's
  24, and the outline of an unchecked checkbox or radio is 2 wide (was
  1.5).
- shadcn draws Tailwind's `shadow-sm`, `shadow-md` and `shadow-lg` in light
  mode, under the selected segment, a menu or popover, and a dialog; it drew
  the kit's own softer shadows. Dark mode keeps the kit's dark set. Its
  corners follow `--radius` at 0.625rem: a card, `radiusLarge`, is 14 (was
  12), a dialog 10 (was 12), a small button 8 as the others are (was 6), the
  segmented track 10 around a knob of 7 (were 8 and 5), and a sidebar item 8
  (was 6). The sidebar is 256 wide over 32px items and folds to a 48px rail
  (were 240, 36 and 64). In dark mode it is `--sidebar`, #18181B, a step
  above the page, where it was the page's #09090B. A button pads 12, 16 and
  24 at its three sizes, and 10, 12 and 16 on the side of a leading icon
  (was 12, 14 and 16 either side). Dark `primary` is #E4E4E7 (was #FAFAFA)
  and dark `border` #2F2F32 (was #27272A).
- Ant's page is `colorBgLayout`, #F5F5F5, and its wells and table header
  #FAFAFA; the two were the other way round. On the darker page five of the
  light chart colours and `warningText`, now #A26100, deepen by a step or
  two to keep their 3:1 and 4.5:1. The rule under a row of tabs is
  `colorBorderSecondary`, #F0F0F0 and in dark mode #303030 (were #D9D9D9 and
  #424242). The dark selection tint, `primarySubtle`, is #15325B, the dark
  algorithm's `colorPrimaryBg` (was #112545). `elevation.sm`, under the
  selected segment, takes the alphas of Ant 6.4.4: 5%, 3% and 3% (were 3%,
  2% and 2%). The focus ring is 3 wide, 1 from the control (was 2 and 2). In
  the sider a group's title is white at 65%, #A6ADB4 (was 55%), and an
  item's icon 14 (was 16).
- Fluent takes Fluent 2's neutral greys where it had the warm ones of
  Fluent UI v8: the page #FAFAFA, the wells #F5F5F5, `border` #D1D1D1,
  `borderSubtle` #E0E0E0, `foregroundSubtle` #707070 and `foregroundFaint`
  #BDBDBD, and in dark mode `border` #666666 and `borderSubtle` #525252. An
  input, a secondary button and a divider are framed a step stronger for
  it. The icon in a button, a menu item or a tab, `iconSizes.md`, is 20
  (was 16), and a field's icon 20, 6 from its text (were 16 and 8). A tab's
  indicator and the segmented control's pill are 3 thick (were 2), the
  outline of an unchecked checkbox or radio 1 wide (was 1.5), and a card's
  corner, `radiusLarge`, 4 (was 8). A primary button hovers and presses to
  the brand ramp, #115EA3 and #0C3B5E. The warning is Fluent 2's orange
  where it was v8's yellow: #F7820C under `warningText` #AA5908 (were
  #FFB900 and #8A5300), each 8° of hue from Fluent's own #F7630C and
  #BC4B09, which stand too near the danger for a changed line to be told
  from a removed one. In dark mode `success` is #54B054, `warning` and
  `warningText` #FAB16B and `danger` #DC626D (were #6BB700, #FCE100, #D9B400
  and #F1707B).
- Carbon's field labels, section labels and sidebar items are
  `$text-secondary`, #525252 (was #393939), and its helper text, captions
  and placeholders `$text-helper`, #6F6F6F (was #525252). A field's text
  starts 16 from its edge (was 12). Dark `border` is #525252, the present
  `$border-subtle-01` (was #393939). The scrim behind a modal in light mode
  is `$overlay`, black at 60% (was 45%). A danger button hovers and presses
  to `$button-danger-hover` and `-active`, #B81921 and #750E13. A selected
  table row is `$layer-selected-01` with 5% of the primary in it, #D5D9E2
  and in dark mode #373B42; it was the primary at 10% in the surface. Code
  is set in IBM Plex Mono where the app bundles the family.

## 0.1.0

The first release. [README.md](README.md) describes the kit: the app frame,
collections and data tables, forms and field bodies, overlays, media and
asset pickers, comments and mentions, version history, charts and sign-in
screens, themed from one set of design tokens in six themes with a light and
a dark mode each. [`api.txt`](api.txt) lists its public surface and
[`looks.txt`](looks.txt) every theme's resolved tokens.
