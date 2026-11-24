# Changelog

## 0.2.0

- A table cell's editor can refuse a draft, and says why.
  `TableTextEditor.number` takes `integer`, `min`, `max` and `validate`,
  and `TableTextEditor` takes `validate`. A number editor refused only
  text that was no number: a fraction typed into a count, or a count
  below zero, closed the editor and was the app's to undo. Now a draft
  that has a fraction where `integer` is set, that is outside `min` to
  `max`, or that `validate` gives a message for, is not saved: the editor
  stays open, marked invalid, with the message on a card under the cell,
  or over it where it does not fit below. The card follows the cell as
  the table scrolls, takes no pointer and no focus, and goes once the
  draft is edited; a screen reader hears it, and reads it as the editor's
  hint. With `integer`, `onCommit` receives an `int`, and the keyboard has
  no decimal key; with a `min` of zero or more it has no minus. An editor
  given none of them saves what it saved.
- `KanbanBoard` takes `padding`, `columnSpacing` and `fitColumns`. Its
  padding, 16px on every side, and the 12px between its columns were
  fixed: a board in a page that has its own gutter started 16px inside
  the page's line, and an app that shared the width out among the columns
  repeated both numbers to do it. With `fitColumns` the board does the
  sharing, each column `columnWidth` wide or wider: all of them where
  they fit, filling the board, and where they do not, as many whole ones
  as do, so that the board's edge falls after a column rather than
  through its cards. Each defaults to what the board did, so nothing
  moves.
- `ComboboxOption` takes a `group`: the heading it is listed under, for a
  long list of options of a few kinds. Options sharing a group are listed
  together under one heading, after the options with no group, the groups
  in the order they first appear. Typed into, a group keeps its heading
  while it has a match, and the groups follow their best match, as cmdk
  orders them. A heading is not an option: the arrow keys pass over it, a
  click on it picks nothing, and screen readers hear it as a heading. It
  is drawn as a `MenuHeader` is. Options with no group list as before.
- `Listbox` takes `groupOf`, which draws those headings over any list of
  options: one above each option whose group is not the one before it's.
  The `ListboxController` counts and moves through the options alone, so
  "n of m" and the keys are the options', as they were.
- A `LocalCollectionSource` field may read several values, as an
  `Iterable`: the teams a member belongs to, the tags on a ticket. A
  filter keeps a row when one of its values matches, `options` offers
  each value once, the search looks in all of them, and the row sorts by
  the first of them in the field's order, a row with none last. A list
  read before was one value, its `toString`, so no option matched it.
- `ThumbnailImage` takes an `alignment`, as `Image` does: where the image
  sits in its box, and so the part a cropping `fit` keeps. A portrait
  cropped to a square lost as much at its top as at its bottom, whatever
  it showed. It is still centred by default.
- `CommandSource` takes `listOnEmptyQuery`: on an empty query it lists
  every item, under its group and in the order given, where it lists
  none. A palette over one opened on "Type to search" with every page and
  command registered, and an app that wanted them listed gave each group
  a `RecentsSource` of its own. Off by default, and a typed query matches
  as it does without.
- `EmptyState` takes a `tone`: a `Severity` that draws its icon in the
  tone's text-safe colour, where the icon was always the muted grey of an
  empty list, so the last step of a setup read as "nothing here". With no
  `icon` given the tone picks its own glyph too, so the colour is not
  alone in saying it. `icon` is nullable for this, and is the inbox still
  when neither is given. The title and the message keep their colours,
  and a state with no tone draws what it drew.
- A `Collection` back from a row's page stands where it stood: the row
  that was opened is where it was on screen, and holds the focus, ringed
  to say where the user came from until their next click. With
  `ringOnReturn: false` the ring shows only when the keyboard opened the
  row, as a browser shows focus. The list kept its page, sort and
  search across the visit, but its view was built again at the top, a
  row in the lower half of a page out of sight. The view says where it
  stands as it leaves (`onLeave`), its `CollectionController` keeps that
  as `position`, and the next view starts from it (`initialPosition`).
  A table puts the opened row back at its height, so rows a refresh or a
  realtime update put above it do not move it; a card view is scrolled
  as it was. A row scrolled out of sight before the list left takes no
  focus, the focus another control holds stays there — not that of a
  `SelectionArea` around the list, which a click anywhere under it
  takes — and a query changed meanwhile starts the list at the top.
  `CollectionTable` and `CollectionCards` take the two on their own, for
  a list that is not a `Collection`, and `CollectionTable` takes
  `ringOnReturn` too.
- A `Collection` given a new page, page size, sort, search, filters or
  saved view starts its rows at the top. It stayed where it was
  scrolled, so the next page opened at its bottom; a refresh or a
  realtime update still keeps the place. `CollectionTable` and
  `CollectionCards` take `scrollToTopOn`: what names the rows asked
  for, whose change scrolls them back to the top.
- A table cell a click focused stays without a ring when the window or
  the page loses focus and gets it back. Flutter takes the focus away
  then and gives it back, and the table took its return for the
  keyboard's, so the ring showed on a cell nobody had moved to.
- `SignInForm` takes `emailErrorText` and `passwordErrorText`, as
  `ChangePasswordForm` takes its two: a server's refusal of one field,
  under that field, where the one `errorText` put a wrong password in an
  alert above the email. A field's message is about what the field held
  when it came, the form's own "is required" shows in its place, and the
  submit that brings one takes focus to its field. `errorText` is
  unchanged, for what is no field's.
- A `Choice` lays its cards side by side. `style: ChoiceStyle.card` with
  `direction: Axis.horizontal` threw in any parent, a form field's or a
  modal's included: the row gave each card an unbounded width, which a
  card's text cannot fill, and Flutter reported "RenderFlex children have
  non-zero flex but incoming width constraints are unbounded". The cards
  now share the width they are given evenly and stand as tall as the
  tallest, so their edges line up. With no width to share, in a horizontal
  scroll view, each is as wide as the widest card's content on one line.
  Plain options side by side, and cards in a column, are unchanged.
- `Collection` takes the sizing of its card grid: `minTileWidth`,
  `tileHeight`, `tileSpacing` and `gridPadding`, handed to its
  `CollectionCards` as `minTileWidth`, `tileHeight`, `spacing` and
  `padding`. Its cards could not be made wider than the grid's 240px
  minimum allowed, nor given one height, so an app that wanted either
  built a `CollectionCards` itself and wired the controller's loading,
  error, empty result and pager to it by hand. Each defaults to what
  `CollectionCards` takes, so nothing moves.
- `ChangePasswordFormState.reset()` empties a `ChangePasswordForm`: its
  three fields, and what a submit showed under them. The form kept both
  passwords in its fields after the host changed the password, and the
  only way to empty it was to give it a new key. Its state is public for
  this, as `NewPasswordFieldsState` is, which gains the same `reset()`.
- `ChangePasswordForm` takes `currentErrorText` and `newErrorText`: a
  server's refusal of one password, under that password's field, where
  its one `errorText` drew every refusal as an alert above the form and
  marked no field. A field's message is about what the field held when it
  came: it shows while that is unchanged, and the form's own "is
  required" or length rule shows in its place. The submit that brings one
  takes focus to its field. `NewPasswordFields` takes the same as
  `errorText`. `errorText` on the form is unchanged, for what is no
  field's.
- `Asset.copyWith`: an asset with the fields given changed and every other
  carried over, where changing its alt text or its usage count meant
  naming all eleven fields, and a field added later was dropped by a copy
  written before it. A field that can be null (`thumbnail`, `url`,
  `swatch`, `width`, `height`) takes a function, so that it can be made
  null: `copyWith(thumbnail: () => null)`.
- `NumberField`, `OptionalNumberField`, `DecimalField` and
  `OptionalDecimalField` take a `unit`, as their `NumberBody` does: what
  the number counts, drawn after it in the field and read with it (`%`,
  `kg`, `px`). They took a `prefix` only, so a percentage with its sign
  meant binding a `NumberBody` by hand.
- What a server says of a record list, an edit in one of its rows
  answers. A message under the list (`zones`: "Two zones overlap") stayed
  until a row was added, removed or moved, so one that editing a row
  answers kept the form from being saved again. An edit of any field in
  the list's rows now takes it, a row of a row's own list included. And a
  path into a list that leads to no field names the list, where it named
  nothing: a row or a field the form has not (`zones[7].name`,
  `zones[0].vat`), or the row itself (`zones[1]`).
- A server names the field it refuses by where it is in the value. A key
  of `FormSubmitException.fieldErrors`, and of
  `ValueFormController.setErrors`, is a field's id, as before, or its path
  in the form's value: `name`, `billing.city` under a `sub('billing')`,
  and for a row of a record list `zones[1].name` or `zones.1.name`. A
  row's cell id is the form's own and changes every run, so a server
  could not name a row's field, and an app mapped each path to its cell
  by hand. `title/fr` names its translated field, and `zones` the list.
- A refused save's message that names no field of the form no longer
  keeps the form from being saved again. It showed in `errors` under its
  key, as it still does, and no edit was its own, so `canSubmit` stayed
  false until a reset. The next edit of any field now takes it. A message
  an app sets itself with `setErrors` stays until the app clears it.
- `DiffView` takes `showFieldKeys`: whether each card names its field's
  key after its label. False by default, where the view always did: the
  key is the app's name for the field, in no reader's language, and a
  translated page read "السعر  price". A restore names the field by its
  key either way. `FieldDiff.label` and `FieldDiff.fieldKey` say which is
  which.
- `Field`, `OptionalField`, `TextBody` and `TextCellBody` take a
  `textDirection`, as `InputField` does: the direction the value is typed
  and shown in when it is not the page's. Left null, an email or URL
  `keyboardType` reads left to right, since an address reads so in every
  language, and anything else follows the page. The hint and the fixed
  `prefix` and `suffix` read with the value, a prefix standing before it in
  its own direction; the label, the message and the counter stay on the
  page's side.
- Two docs say what they carry. `savedLabel` on `SaveBar`, `SaveCluster`,
  `FormSaveBar` and `FormActions`, which had none on the last two, is a
  detail after the status's own word: `'2m ago'` reads "Saved · 2m ago", and
  `'Saved'` reads "Saved · Saved". `AssetDetailView.onSaveAlt` and
  `AssetSource.updateAlt` are handed the whole alt text, with a language
  the person cleared left out: store it in place of the old map, since
  merged into it a cleared language comes back. Nothing behaves
  differently.
- A `Listbox` asked how wide it would like to be says that it cannot, and
  what to pass. It builds its rows as they scroll into view, so a
  `PopoverMenuSurface` with no width, which sizes itself to its content,
  cannot hold one: that threw Flutter's "RenderShrinkWrappingViewport does
  not support returning intrinsic dimensions", which names neither widget,
  and then a null check from the list's own scroll into view. The error
  now names the `Listbox` and the surface and says to give the surface a
  width, its trigger's or the widest row's from `ListboxOption.widthOf`, as
  `ListboxMenu` does, and nothing follows it from the list. The docs of
  `PopoverMenuSurface` and `Listbox` say the same. A list that had a width
  is unchanged.
- A `Toggle` or a `Check` with no label keeps its own size in a box that
  stretches it, where it filled the box: under a `LabeledField` a switch
  drew its track the field's width, 425px in one form, and a checkbox its
  box. It stands at the start, centred in the height, as one with a label
  does, and only the control takes the tap, where the whole row did. With
  room of its own, and with a label, nothing moves.
- A `DonutChart` with no room for its legend beside the ring puts it under
  the ring, where its row overflowed: in a card 270px wide, a 148px ring
  left the legend 6px less than its longest label needs. The legend stands
  beside the ring while every label fits there whole, and otherwise under
  it, centred and wrapping. Under the ring a label longer than the chart is
  cut with an ellipsis, and in a height the chart is given the legend takes
  what it needs and the ring draws in the rest. A chart whose legend fitted
  does not move. The legend of a `LineChart` or a `BarChart` cuts a series
  name longer than the chart the same way, where it overflowed too.
- A finger's near miss presses the small control it was meant for.
  `TouchTargetAdjustment` gives each control under it a touch area of at
  least 48px, centred on the control, with nothing laid out larger: a
  finger that comes down on no control, inside that area of one, presses
  it. An `AdminScope` holds one around its page
  (`AdminScope(adjustTouchTargets: false)` turns it off), and the kit's
  popovers, modals and side sheets hold one around their content and
  follow the page that opened them. Every enabled `Tappable` is a target;
  `TouchTarget` marks a tap target of the app's own.
  What is under the finger keeps its claim: a finger on a control presses
  that one, a row that opens or a text field takes its own tap, a finger
  that moves still scrolls or drags, and of two controls the one whose
  edge is nearer is pressed. A mouse presses what it points at. So the
  size is not guaranteed: in a tight row each control grows by half the
  gap to its neighbour, and a small button inside a row that opens gains
  nothing.
- The catalog is held to the kit's public widgets:
  `example/test/catalog_coverage_test.dart` fails when a public widget is
  built by no page of the catalog, and so is pumped by no sweep. 64 of the
  245 are in that case today, the form-bound fields among them
  (`DateField`, `ReferenceField`, `TagsField`), whose bodies the catalog
  shows. They are listed in the test, and the list only shrinks. The
  README said the catalog showed every widget.
- A `TopBar` that runs out of room gives its `leading` the width that is
  left, where the bar's own row overflowed: on a 360px phone at twice the
  text size, a logo with its name and one action left the search icon
  6px. The actions and the menu button keep their size, the search icon
  keeps its place, the title ellipsizes, and then `leading` is laid out
  in what remains, so a logo whose name is in a `Flexible` and ellipsized
  folds toward its mark. With room to spare `leading` is as wide as it
  asks to be, as before, and nothing moves.
- `ForbiddenState` is the placeholder of a page or a panel the signed-in
  user may not open: a muted lock, "You don't have access to this" over
  "Ask an administrator if you need it.", and a Go back button where
  `onBack` is given (`backKey` finds it in a test). The words are the
  kit's, in English, French and Arabic (`AdminLocalizations.notAllowed`,
  `notAllowedAskAdministrator`, `goBack`), until the app passes its own
  `title`, `message` or `backLabel`. Beside `EmptyState` and `ErrorState`,
  which it is drawn as.
- A table row has a context menu: `CollectionTable(rowMenu:)`, and
  `Collection(rowMenu:)` for its table view, builds a row's entries. A
  right-click anywhere on the row, its padding included, or a finger's
  long press opens the menu at the pointer; Shift+F10 or the context-menu
  key opens it under the focused cell, on its first item. The row is drawn
  as a selected one while its menu is open, and Escape or a choice hands
  focus back to the table. A row that gives no entry opens none, and
  neither does a row dimmed under a reload. A menu follows its record
  through a sort and closes when the record leaves the page. Wrapping
  every cell in a `ContextMenuRegion` did none of the last four.
- `Collection` takes `compactViewMode`, the layout that takes `viewMode`'s
  place while the window is compact (`AdminBreakpoint.of`: narrower than
  the theme's `breakpoints.medium`, a phone). With
  `compactViewMode: CollectionViewMode.cards` a table becomes cards on a
  phone, which each screen had to decide for itself. The page, the query
  and the selection are the controller's and carry across. Null, the
  default, keeps `viewMode` at every width.
- `Tabs` takes `activation`. `TabsActivation.manual` has the arrow keys,
  Home and End move focus along the strip and select nothing, and Enter or
  Space select the focused tab; focus that leaves the strip comes back to
  the selected tab. For tabs whose content takes time to show, such as a
  tab that loads from a server or is a route of its own. The default,
  `automatic`, selects as focus moves, as before. A pointer selects either
  way.
- A `Tabs` strip no longer throws as focus leaves it from a tab that is
  not the selected one. That happened where the host refused a selection
  made with the arrow keys, an unsaved form that would not be left for
  one, and Tab was then pressed: the strip moved its Tab stop while the
  focus manager was telling its nodes.
- `SingleReferenceField` edits one related record: a `Cell<K?>` holding
  its id, or null for none. With none it shows the link button; with one,
  that record's row alone, so nothing adds a second. The row carries a
  Replace button, which opens the picker with the record marked, and
  another pick takes its place; Escape, or the pick, hands focus back to
  the button. Remove sets the cell to null. A `ReferenceField` linked a
  list only, and one record was a list of one under a link button that
  would add a second.
- `ReferenceField` takes `maxItems`, the most records it links (its add
  button goes at that many, until a row is removed), and `seed`, the
  records the host already holds, which show at once and are not asked of
  `resolve`. `SingleReferenceField` takes a `seed` of one.
- `CircleButton` takes a `focusNode`, and `expanded` for one that opens a
  popover. `FieldsMessages.replaceReference` names the Replace button, in
  English, French and Arabic.
- A date field shows its time on its locale's own clock. `DateBody` with a
  time, and so `DateField` and `OptionalDateField`, wrote a 24-hour "14:30"
  in every locale; it now writes what the locale does, as a chart's time
  axis already did: "Jun 18, 2026 2:30 PM" in English, Arabic's own day
  period in Arabic. A locale that writes a 24-hour clock (en_GB, French,
  German) reads as before. This changes what an English app's field shows:
  one that wants "14:30" runs in, or passes the field as `locale`, a locale
  that writes it. The editor's hour cell stays 00 to 23 in every locale.
- `ChartCard` has an error state: `error` shows an `ErrorState` in the
  chart's place, the localized "Couldn't load" over the error in words
  (`ErrorTextScope.describe`), with a Retry button where `onRetry` is given
  (`retryKey` finds it in a test). `loading` comes first, so a retry in
  flight shows the skeleton, and an error shows over `isEmpty`. The header
  and its `trailing` control stay as they are. For a dashboard whose cards
  load apart.
- A palette gives an overlay a fill of its own:
  `AdminPalette.popoverSurface` (a popover's surface, the command palette, a
  toast in the surface colour), `modalSurface` (a modal's card, the asset
  picker) and `sheetSurface` (a side sheet). Each is `surface` unless
  authored, and a sheet follows the modal unless it has its own. The stock
  Material dialog and menus take them from `buildAppTheme`.
- What stands on an overlay is drawn in `AdminPalette.withSurface(fill)`,
  the palette with that fill as its `surface`: a `Popover`'s content, a
  `showModal` or `showSideSheet` builder and what each overlay surface holds
  read `context.colors.surface` as the overlay's colour. The roles left to
  derive from the surface follow the fill, an authored role that no longer
  reads on it is moved just far enough, and the three fills stay the
  page's. Where the fill is the surface, this is the palette itself.
- A theme says whether an overlay is ringed in a hairline as well as lifted
  on its shadow: `AdminOverlayStyle.modalOutline` and `popoverOutline`, both
  true by default, read through `modalEdge(palette)` and
  `popoverEdge(palette)`. A modal's card, the command palette, the asset
  picker and a side sheet's inner edge take the first. A popover's surface
  and its arrow take the second, and so every menu, select, picker and hover
  card. The stock Material dialog, popup menu, menu anchor and dropdown menu
  take them from `buildAppTheme`. A dark palette always rings both.
- A theme says how a popover arrives and leaves:
  `AdminOverlayStyle.popoverMotion`, an `AdminOverlayMotion`, null by
  default. A `Popover` plays it on its content, and so does every menu,
  select, combobox, picker and hover card: the content fades, grows from
  `scale` out of the point on its edge that faces its anchor, and slides
  `slide` away from the anchor into place. With none a popover is there,
  and gone, at once, as every popover was until now and as it still is
  under reduced motion.
- A popover asked to close is closed at once to its `PopoverController`,
  its trigger and `onOpenChanged`. Where the theme's motion plays an exit,
  its content stays on screen until that has played, taking no pointer and
  no focus and left out of semantics; opening it again in that time brings
  it back from where it had got to. Escape pressed on the trigger while it
  leaves is taken and does nothing.
- `AdminOverlayMotion` has three more members. `stretch` unfolds an overlay
  from a share of its height, its width kept. `duration` is a duration of
  its own where none of the theme's three is it, read through
  `durationIn(motion)`; reduced motion zeroes it with the rest. `leaves`,
  false, has a popover gone at once where the motion has an entrance and no
  exit. A modal takes the first two, and plays its arrival back whatever
  `leaves` says.
- An overlay that plays its arrival back as it leaves is on the theme's
  exit curve as time runs: a modal, a side sheet, a toast and a modal on a
  `ModalAnchor`. Each handed `motion.exit` to its animation as a
  `reverseCurve`, which Flutter evaluates at the animation's value as it
  runs from 1 to 0, so a curve that accelerates left fast and slowed to a
  stop. Each hands it over flipped now. `AdminOverlayMotion.reverseCurve`
  is read the same way, as the curve the overlay leaves on as time runs.
  An app that plays `context.motion.exit` back in an animation of its own
  passes `exit.flipped`.
- A theme says how a modal arrives and leaves:
  `AdminOverlayStyle.modalMotion`, an `AdminOverlayMotion`. A modal opened
  with `showModal` always fades, as before; `scale` grows its card from a
  smaller size and `slide` moves it down into place from above. `speed`, a
  `MotionSpeed`, names which of the theme's motion durations the move takes
  (`AdminMotion.durationOf`), and `curve` and `reverseCurve` replace the
  motion's `enter` and `exit`. The default is the fade over
  `motion.medium` that every theme had. Under reduced motion a modal is
  still there at once.
- A theme draws a toast in a palette of its own:
  `AdminFeedbackStyle.toastPalette`. The toast's fill and edge, its text,
  its status colours, its action and its close button are that palette's,
  and the page under it keeps its own. `AdminTheme.from` takes a
  `darkFeedback` for the dark set, the light `feedback` where none is
  given, and a brand reaches the toast's palette as it does the shell's
  (`AdminFeedbackStyle.branded`). A dark page rings a toast that the theme
  does not outline only where the toast's palette is dark too.
- A palette says what a tooltip and a stock snack bar are filled with:
  `AdminPalette.inverseSurface`, and `onInverseSurface` for what reads on
  it. Both are optional. A palette that gives neither has its `foreground`
  under its `surface`, as every tooltip was drawn until now; one that gives
  the surface alone has white or near-black on it. A `Tip`, the stock
  tooltip and snack bar themes, and the stock `ColorScheme`'s
  `inverseSurface`, `onInverseSurface` and `inversePrimary` take them, and
  a brand keeps them.
- A control's text follows its size. An `AdminTypeRamp` names
  `fieldTextLarge` and `buttonLarge`, the steps of the text inside a large
  control and of a large button's label, and a ramp that names neither sets
  them on `fieldText`'s and `button`'s. `AdminTypography.fieldTextOf(size)`
  and `buttonOf(size)` give the style for a `ControlSize`. A `Button`, an
  `InputField`, a `SearchField`, a `PasswordField`, a `Combobox`, a
  `MentionField` and a `DateRangePicker` take theirs from it.
  `fieldInputDecoration` sizes its hint and pads its text for the `size` it
  is given, and `fieldTextStyle` and `fieldPaddingY` take a `size` too: a
  body that draws a large field gives all three the same one.
- `AdminButtonStyle.smallLabelWeight` is the weight of a small button's
  label, `labelWeight` where none is given, and `labelWeightOf(size)` the
  weight at a size. A `labelWeight` in a `Button`'s own `style` is its
  weight at every size.
- A theme weighs its large titles and a field's error line apart from its
  headings, and says what a field's label is drawn in, in its
  `AdminTypeSpec`. `title` is the weight of a page's title and a dialog's,
  the `heading` weight where none is given; `message` the weight of
  `AdminTypography.fieldMessage`, which was 500 in every theme; and
  `labelInk` what `AdminTypography.fieldLabel` and a form field's resting
  label are drawn in: `LabelInk.secondary`, as before, or
  `LabelInk.foreground`.
- `AdminTypography.dialogTitle` is the title of a `Modal`, which was the
  `heading` on a line of one and a half times its size. It is at the
  `title` weight on the step an `AdminTypeRamp` names as `dialogTitle`, and
  on `heading`'s step where the ramp names none. A typography built by hand
  that gives none titles a dialog in its `heading`.
- A theme says how its alerts and toasts are drawn: `AdminTokens.feedback`,
  an `AdminFeedbackStyle` read through `context.feedbackStyle` and given to
  `AdminTheme.from` as `feedback`. `alertFill` and `toastFill` fill an
  `Alert` and a toast with the status washed into the surface, inside its
  border (`FeedbackFill.tint`), or with the surface colour inside the
  neutral border, the status left to the icon (`FeedbackFill.surface`).
  `alertBar` and `toastBar` are the width of a bar in the status colour on
  the leading edge, zero for none: a toast's was 4 in every theme, and an
  alert had none. `alertRadius` is an alert's corner, the theme's radius
  where none is given, and `toastOutline` whether a toast is ringed in a
  hairline, which it always was.
- A theme says how its tooltips are drawn, in its `AdminOverlayStyle`:
  `tooltipRadius` is the chip's corner, which was the theme's small radius
  and still is where none is given; `tooltipPaddingX` and `tooltipPaddingY`
  its padding, which was 8 by 4; `tooltipText` its text, the caption or,
  `TooltipText.body`, the body; and `tooltipDelay` how long the pointer
  rests on a target before the tooltip shows, which was 400ms. A `Tip` and
  a stock `Tooltip` both take them, and a `Tip` given a `waitDuration`
  keeps its own.
- A `Sidebar` folds several items under one row: `NavGroup`, a third
  `NavEntry`, takes a label, an icon and its `items`. Closed, its row
  shows the number of its items and a chevron; open, the items follow it,
  a step in. It opens as the current item becomes one of its items, and
  while it is closed over that item its row is drawn, and announced, as
  the current one. `initiallyExpanded` says how it starts,
  `onExpandedChanged` reports each click or key on its row, and `expanded`
  controls it, whatever the current item. In the rail it is its icon
  alone, and a click there opens the rail over the page with the group
  open; in the open rail and in the navigation drawer it is as in the
  whole sidebar. Its row is a Tab stop announced as expanded or collapsed,
  which Enter or Space toggles. ArrowUp, ArrowDown, Home and End step over
  the rows on the screen, so past a closed group's items, and focus on an
  item goes to its group's row as the group closes or the rail folds. A
  group asks no leave guard; its items ask as any item does.
- A press outside a `Sidebar`'s rail closes it while it is open over the
  page. Until now only the pointer leaving it, focus leaving it, Escape
  and an item did, so a rail a key had opened stayed open under a click on
  the page.
- A theme says what a table's chrome is drawn with, in its
  `AdminTableMetrics`: `headerFill` fills the header row with
  `surfaceMuted` (`TableHeaderFill.muted`), with the surface as the rows are
  (`surface`) or with the divider colour (`strong`); `headerInk` writes the
  column headers in the muted grey, a step stronger for the sorted column,
  or in the foreground (`TableHeaderInk`); `headerRule` and `rowRule` draw
  the rule under the header and under each row in `borderSubtle` or in
  `border` (`TableRule`). `TableHeaderText.body`, new, sets the headers at
  the body's own weight. `headerStyleOf`, `headerFillOf`, `headerInkOf`,
  `headerRuleOf` and `rowRuleOf` resolve them against a typography and a
  palette; a header's ink is held to 4.5:1 on its fill.
- A theme says how its tab strips are drawn: `AdminTokens.tabs`, an
  `AdminTabsStyle` read through `context.tabsStyle` and given to
  `AdminTheme.from` as `tabs`. `heightSmall`, `heightMedium` and
  `heightLarge` are a strip's height at each `Tabs.size`, which was 32, 40
  and 48 in every theme. `selectedInk` writes a line strip's selected label
  in the accent or the foreground (`TabsSelectedInk`), and `restInk` the
  others in `foregroundMuted`, `foregroundSecondary` or the foreground
  (`TabsRestInk`), each a step stronger under the pointer. `labelWeight`
  weighs every label, where each was the button's weight, and
  `selectedLabelWeight` the selected one where it is set heavier: a tab is
  then as wide as its label at the heavier weight, so selecting one never
  moves the rest. `indicatorWidth` makes the selected tab's indicator as wide
  as its tab or as its label (`TabsIndicatorWidth`), `indicatorShape` leaves
  its ends square, rounds its top or rounds both (`TabsIndicatorShape`), and
  `indicatorThickness` sets its thickness, `AdminStroke.indicator` where
  none is given. `rule` is what a line strip stands on: a hairline, a rule
  as thick as the indicator, or none (`TabsRule`); `Tabs.baseline: false`
  still draws none.
- More of the kit says what it is to assistive technology, each widget
  with the role Flutter has for it (`SemanticsRole`), asserted through the
  semantics tree. What a screen reader announces changes for these:
  - `Shell`: on the web, the page beside the navigation is the main
    landmark, named "Main content", which a screen reader jumps to past
    the sidebar and the top bar. The other platforms read no such role and
    get nothing: a named container there would be one more stop, the size
    of the page. A shell shown inside another's page is part of that page.
    A main landmark may hold no other and sit in no other, and the
    framework throws in a debug build where one does: an app that marks
    its own main landmark, inside the page or around the shell, or puts
    the shell inside a landmark of its own, passes `mainLandmark: false`,
    new. `ShellMessages` has `mainContent`, new: a subclass for a language
    of the app's own adds it.
  - `Alert`: a danger alert that is read out (`liveRegion`, on by default
    for danger) is an alert. On the web it is read at once, over what the
    screen reader was saying, with its action and its close button; its
    words are the live region the other platforms read. A warning still
    waits its turn.
  - `Toast`: a danger toast is an alert in the same way. The others are
    live regions, as before.
  - `ProgressBar`: a bar with a value is a progress bar named by its
    `label`, where the label was a text beside a bar with no name, or by
    the new `semanticLabel`, for a bar with no label. Its label and its
    percent are the bar's name and value, and are no longer read a second
    time as text. A bar with no value is named by `semanticLabel` in its
    label's place, read as text. The kit's own bars are named: an upload
    row's by its file, the upload summary's by the summary.
  - `TabPanel`, new: what the selected tab of a `Tabs` strip shows, as that
    tab's panel, named by the tab, on the web; nothing on the other
    platforms. `Tabs` draws no content, so the caller wraps what it shows;
    the asset picker's panes are panels.
  - `CommandPalette`: each result says where it stands, "2 of 5", as an
    option of a `Combobox` does, and the results no longer claim to be a
    list: a list's items are its direct children, and a scroll view's own
    nodes stand between.
  - `Tappable` has `semanticHint`, new, read after the name and the state.
- `ACCESSIBILITY.md` records what each component tells assistive
  technology and which tests hold it, the roles in use and the ones left
  out with the reason for each, that no manual screen-reader pass has been
  made, and that on the web Flutter's semantics are off until the user or
  the app turns them on. Its tables are generated by
  `tool/gen_accessibility.dart`, and a test fails when they are out of
  date.
- Every demo of the catalog is pumped with its semantics on and held to
  Flutter's guidelines for targets, a name and 24 by 24
  (`example/test/sweeps/a11y_guidelines_sweep_test.dart`). The targets it
  lets through are listed there, each with its reason.
- A theme says how its sliders are drawn: `AdminTokens.slider`, an
  `AdminSliderStyle` read through `context.sliderStyle` and given to
  `AdminTheme.from` as `slider`. `trackHeight` is the track's height and
  `rail` what the track past the thumb is drawn in: the border colour
  (`SliderRail.border`), `controlBorder` (`control`) or `softFill` (`soft`).
  `thumb` is a `SliderThumb.disc` in the ink; `ringed`, the surface colour
  inside a ring of the ink, on the theme's small shadow; `inset`, the ink
  inside a band of the surface colour, edged in a hairline; or `bar`, M3's
  4dp handle, which parts the track by 6dp on either side. `thumbSize` is
  the thumb's diameter, or a bar's height, and `thumbRing` the width of a
  ring or a band. `ink` draws the track up to the thumb, and the thumb, in
  the accent or in the foreground (`SelectionInk`).
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

- A table's number editor holding text that is no number says so: "Enter
  a number like 1,234.5", on a card under the cell. It was marked invalid
  and said nothing.
- A `DiffView` card is headed with its field's label alone, where the
  field's key followed it in small muted type: "Meta description", where
  it read "Meta description  metaDescription". A card is announced
  without the key too. `showFieldKeys: true` keeps what it drew.
- In a right-to-left page, a `Field` or an `OptionalField` with an email or
  URL `keyboardType` is typed left to right from the left edge, its hint
  there too, where both ran from the right with the caret at the left of
  what was typed. A fixed prefix such as `https://` stands at the left of
  the address, where it stood at the right of it. `keyboardType: null`, or
  `textDirection: TextDirection.rtl`, keeps what it drew. Left to right,
  nothing moves.
- A `TopBar` too narrow for its parts no longer paints its row past its
  end. Its `leading` is cut to the room there is, and one that cannot
  shrink (a row of fixed parts) overflows inside its own box, where the
  search icon or the last action had been pushed out.
- A `ReferenceBody` with `maxItems: 1` shows a Replace button on its chosen
  row, before the Remove one: a 22px disc with a swap glyph. Changing the
  record took removing it and linking again.
- A reference picker takes the room there is beside the row or the button
  that opened it, and scrolls its results there, as a menu, a select's list
  and a combobox do. It kept its 400px where it had less, and stood over
  the field that opened it.
- A stock Material widget that takes the scheme's secondary container (a
  `FilledButton.tonal`, a selected `FilterChip`, a `NavigationBar`'s
  indicator) takes the palette's `softFill` under `onSoft`, as the kit's own
  soft button does. It took `primarySubtle` under `primaryText`. Only
  Material authors a soft fill, so only Material changes: its stock tonal
  button is M3's `secondaryContainer` under `onSecondaryContainer`, #E8DEF8
  under #1D192B (was #EADDFF under #6750A4), and in dark mode its label is
  #E8DEF8 (was #D0BCFF) on the same #4A4458.
- An overlay is filled as its theme's reference system fills it, where that
  is not the card's colour; every overlay was the palette's `surface`. Iris,
  Fluent and Carbon, and the light palettes of shadcn and Ant, do not
  change: their overlays are the card's colour in the reference too.
  - Material: a menu, a select's list, a picker, a hover card and the
    command palette are `surfaceContainer`, #F3EDF7 (was #FEF8FF; the dark
    palette's is already its surface). A modal and the asset picker are
    `surfaceContainerHigh`, #ECE6F0 and #2B2930 in dark mode (was #FEF8FF
    and #211F26). A side sheet is `surfaceContainerLow`, #F7F2FA and
    #1D1B20.
  - Ant, dark mode: every overlay and a toast are `colorBgElevated`,
    #1F1F1F (was #141414). An input on one keeps `colorBgContainer`,
    #141414.
  - shadcn, dark mode: a modal, the asset picker and a side sheet are
    `--background`, #09090B (was #18181B).
  - On those fills, what is drawn on the surface is drawn on the fill: a
    field or an outlined button in a Material dialog takes the dialog's
    colour, and a menu row's highlight is laid over the menu's. A colour
    held to a contrast is held to it on the fill, so some move a shade
    there: Material's warning text is #876200 on a menu (#8A6500 on a
    card), Ant's dark control outline #696969 on a modal (#626262).
- An overlay stands on its shadow alone where the theme's reference system
  draws it so, in light mode; every overlay was ringed in a hairline of the
  palette's `border` in every theme. Iris and shadcn keep the hairline, and
  so does dark mode in every theme: a shadow does not read on a dark page.
  Nothing moves, since the hairline was painted over the surface.
  - Material, Ant and Fluent: a modal, the command palette, the asset
    picker, a side sheet's inner edge, and every menu, select, picker and
    hover card lose it. The stock Material dialog and menus do too.
  - Carbon: every menu, select, picker and hover card loses it. A modal
    keeps it: Carbon's modal container is bordered in `$border-subtle-01`.
- A popover arrives and leaves as each reference theme's does, in the
  three themes whose system moves it; it was there, and gone, at once in
  every theme. This is every menu, select, combobox, date picker, hover
  card and field popover. Iris, Material and Carbon keep that: Carbon shows
  its menus and list boxes with no transition, and Flutter's Material menu
  unfolds in a way this motion does not draw. At rest nothing moves.
  - shadcn: it fades in from 95%, sliding 8 from its anchor's side, over
    150ms on CSS `ease`, and plays that back as it leaves.
  - Ant: it fades in unfolding from 80% of its height, from the edge by its
    trigger, over 200ms on `motionEaseOutQuint`, and folds away on
    `motionEaseInQuint`.
  - Fluent: it fades in sliding 10 from its anchor's side, over 400ms on
    `curveDecelerateMid`, and is gone at once.
- shadcn's dialog eases in and out on CSS `ease`, tw-animate's default,
  where it took the theme's `enter` and `exit` curves.
- A modal, a side sheet, a toast and a modal on a `ModalAnchor` start to
  leave slowly and are fastest as they go, in every theme, as each theme's
  exit curve says; they left fast and slowed to a stop. How long they take
  is unchanged, and nothing moves at rest or on the way in.
- A modal opened with `showModal` arrives and leaves as each reference
  theme's dialog does, where every theme only faded it over its medium
  duration. Iris and Material keep that. At rest nothing moves.
  - shadcn: the card grows from 95% as it fades.
  - Ant: the card grows from 20%, on `motionEaseOutCirc`, and shrinks away
    on `motionEaseInOutCirc`.
  - Fluent: the card grows from 85% over 250ms (was 200), and leaves on
    `curveAccelerateMin`.
  - Carbon: the card slides down 24 into place over 240ms (was 150), on
    the expressive entrance and exit curves.
- A toast is drawn in the inverse scheme in Material and Carbon, where it
  was a card in the page's own colours. The other four themes keep that.
  - Material: an M3 snackbar. On the light page a `#322F35` card under
    `#F5EFF7` text, with the dark scheme's status colours and accent; on
    the dark page a `#E6E0E9` card under `#322F35` text, with the light
    scheme's. It has no outline and no status bar (was outlined, behind a
    4px bar).
  - Carbon: the high-contrast notification. On the Gray 10 page a
    `#393939` card under white text behind a 3px bar in the inverse
    support colour; on the Gray 100 page a `#F4F4F4` card under `#161616`
    text. It has no outline (was tinted with its status, inside its
    border). An `Alert` keeps the low-contrast, tinted form.
- A tooltip's chip, and a stock snack bar, follow each reference theme's
  inverse surface, where every theme filled them with its foreground under
  its card colour. Iris and shadcn keep that.
  - Material: `#322F35` under `#F5EFF7` (was `#1D1B20` under `#FEF8FF`);
    in dark mode the chip is unchanged and its text is `#322F35` (was
    `#211F26`).
  - Ant: `#262626` under white (was `#1F1F1F`); in dark mode a dark chip,
    `#424242` under white, where it was light, `#E0E0E0` under `#141414`.
    The dark sider's tooltips are `#262626` under white too, where they
    were white under the sider's navy.
  - Fluent: `#333333` under white (was `#242424`); in dark mode a dark
    chip, `#3D3D3D` under white, where it was white under `#292929`.
  - Carbon: `#393939` under white (was `#161616`); in dark mode the chip
    is unchanged and its text is `#161616` (was `#262626`).
- A large control's text, and a small button's weight, follow Ant and
  Fluent, where every theme set a large button and a large field in the
  text of the medium ones, and a button's label in one weight at every
  size. The other four themes keep that: their design systems do.
  - Ant: a large button's label and a large field's text are 16/24 (were
    14/22).
  - Fluent: a large button's label and a large field's text are 16/22
    (were 14/20); a small button's label is regular (was semibold).
  The kit draws small buttons of its own (a toast's action, the
  notification centre's "mark all read", a `CopyButton`), so in Fluent
  those are regular too.
- Titles, a field's label and its error follow each reference theme, where
  every theme set a page's title and a `Modal`'s in its heading weight, a
  field's error at weight 500 and a field's label in `foregroundSecondary`.
  Iris keeps those.
  - Material: a page's title is regular (was 500), as `headlineSmall` is; a
    `Modal`'s title is `headlineSmall` too, 24/32 regular (was 16/24 at
    500), so its header is 8 taller; a field's error is regular.
  - shadcn: a field's label is in the foreground (was `#27272A`, and
    `#E4E4E7` in dark); a field's error is regular; a `Modal`'s title is on
    its own 28px line (was 27), so its header is 1 taller.
  - Ant: a field's label is in the foreground (was `#595959`, and `#C2C2C2`
    in dark); a field's error is regular.
  - Fluent: a field's label is in the foreground (was `#424242`, and
    `#D6D6D6` in dark); a field's error is regular; a `Modal`'s title is
    `subtitle1`, 20/28 (was 16 on a 24px line), so its header is 4 taller.
  - Carbon: a page's title is regular (was 600), as `heading-04` is; a
    `Modal`'s title is `heading-03`, 20/28 regular (was 16 on a 24px line
    at 600), so its header is 4 taller; a field's error is regular.
  In shadcn, Ant and Fluent the label of a form's `Field` is in the
  foreground at rest too, where it was in `foregroundMuted` (`#71717A`,
  `#707070` and `#616161` on a light page). In Material and Carbon a
  `StatCard`'s value, which is in the page title's style, is regular with
  it.
- An `Alert` and a toast follow each reference theme, where every theme
  drew an alert tinted with its status at the theme's radius, and a toast
  as an outlined card in the surface colour behind a 4px status bar. Iris
  and Material keep those.
  - shadcn: an alert is a card in the surface colour inside the neutral
    border, its icon alone in the status colour, with a 10px corner (was
    8); a toast has no status bar.
  - Ant: an alert's corner is 8 (was 6); a toast has no status bar and, on
    a light page, no outline.
  - Fluent: a toast has no status bar and, on a light page, no outline.
  - Carbon: an alert carries a 3px bar in the status colour on its leading
    edge; a toast is tinted with its status (was the surface colour) behind
    a 3px bar (was 4).
  A toast keeps its outline in every theme's dark mode, where its shadow
  does not read.
- A tooltip follows each reference theme, where its corner was whatever
  the theme's small radius was for its menu items and small buttons (8, 6,
  4, 2 and 0 in the five reference themes) around 8 by 4 of padding and
  caption text. Iris keeps those.
  - Material: a 4dp corner (was 8).
  - shadcn: an 8px corner (was 6), 12 by 6 of padding, and no delay: a
    tooltip shows as the pointer arrives (was after 400ms).
  - Ant: a 6px corner (was 4), 8 by 6 of padding around text at the body's
    14/22 (was the caption's 12/20), so a one-line tooltip is 34 tall (was
    28).
  - Fluent: a 4px corner (was 2) and 12 by 6 of padding.
  - Carbon: a 2px corner (was square) and 16 of padding all round, around
    text at the body's 14/20 (was the caption's 12/16).
- A `CollectionTable`'s header and rules follow each reference theme, where
  every theme drew a `surfaceMuted` header under muted labels, over a
  `border` rule, with `borderSubtle` between the rows. Iris and Material
  keep those.
  - shadcn: no fill behind the header, its labels in the foreground; the
    rule under every row is the `--border` grey (was the fainter muted
    grey).
  - Ant: header labels in the heading colour (were the muted grey); the
    rule under the header is the split grey the rows use (was the darker
    control border).
  - Fluent: no fill behind the header, its labels regular (were semibold)
    in the foreground; the rule under the header is the one under the rows.
  - Carbon: the header is `$layer-accent`, the grey of its rules (was the
    near-white muted surface), under labels in `$text-primary`; the rule
    under every row is `$border-subtle-01` (was a grey barely off the
    surface).
  A `HeatTable`'s header takes the header's weight and keeps its muted ink.
- Each reference theme draws a `Tabs` line strip as its design system does,
  where every theme drew a strip 32, 40 or 48 tall, its labels at the
  button weight in the muted grey, the selected one in the accent over a
  2px bar as wide as its tab, on a hairline. Iris keeps those. A strip's
  height moves whatever is laid out under it.
  - Material: 40, 48 or 56 tall (was 32, 40, 48); labels at w500 (were w600)
    in on-surface-variant; a 3dp indicator as wide as the label, rounded at
    the top.
  - shadcn: 32, 36 or 40 tall; labels at w500 (were w600), the selected one
    in the foreground (was the primary, the same near-black); no rule under
    the strip.
  - Ant: 38, 46 or 56 tall; labels at w400 (were w600) in the text colour
    (were the muted grey), which take the primary under the pointer; an ink
    bar as wide as the label.
  - Fluent: 32, 44 or 52 tall; labels at w400 in the second neutral, the
    selected one at w600 in the foreground (was the brand colour); a brand
    indicator as wide as the label, round at both ends; no rule under the
    strip.
  - Carbon: labels at w400 in `$text-secondary`, the selected one at w600 in
    `$text-primary` (was Blue 60); the strip stands on a 2px rule (was 1px),
    which the selected tab's indicator covers.
  An enclosed strip changes only in its height and its labels' weight.
- Each reference theme draws its slider as its design system does, where
  every theme drew a 4px track under an 18px disc in the accent. Iris keeps
  those.
  - Material: a 16dp track, the secondary container past the handle, parted
    by a 4×44dp bar with 6dp on either side, half as wide under a press,
    and ending in a stop dot. The slider's row is 44 tall there (was 40).
  - shadcn: a 6px track under a 16px white thumb in a 1px ring of the
    primary, on the small shadow.
  - Ant: a 14px white thumb in a 2px ring of the primary.
  - Fluent: a rail in the neutral accessible stroke (was the divider grey)
    under a 20px thumb, the brand colour inside a 4px white band edged in a
    hairline.
  - Carbon: a 2px track under a 14px thumb, both near-black on a light page
    and near-white on a dark one (were Blue 60).
- A `ValueSlider` whose thumb is taller than a medium control is as tall as
  its thumb.
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
