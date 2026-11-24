# Accessibility

What the kit tells assistive technology, what its tests hold it to, and what
nobody has checked. The two tables are written from the package by
`fvm dart run tool/gen_accessibility.dart`, and
`test/accessibility_status_test.dart` fails when they are out of date.

## What has not been tested

**No manual screen-reader pass has been made.** Nobody has listened to the
kit in VoiceOver, NVDA, JAWS or TalkBack. Everything below is what a test
reads from Flutter's semantics tree: the name, the role and the state a
widget hands the platform, not the words a screen reader makes of them. What
a role does on each platform is read from the engine's source at the Flutter
`.fvmrc` pins, not heard. An app that must meet a standard runs its own pass.

## On the web, semantics are off until asked for

A Flutter web app draws on a canvas and builds no accessibility tree until
one is asked for. Until then a screen reader finds one thing on the page, a
button named "Enable accessibility", and the user turns the tree on by
pressing it. An app turns it on for everyone at startup:

```dart
import 'package:flutter/semantics.dart';

void main() {
  runApp(const MyApp());
  SemanticsBinding.instance.ensureSemantics();
}
```

The tree costs a DOM node for each semantics node, which is why Flutter
leaves it off. On Android, iOS and the desktops the platform turns it on
when assistive technology starts, and the app does nothing.

## What the tests hold

- **Name, role and state.** One widget, `Tappable`, makes the node of most
  controls: a button or a link with its label, its enabled, selected,
  expanded, checked or toggled state, and whether it holds focus
  (`test/core_tappable_semantics_test.dart`,
  `test/controls_semantics_test.dart`). The roles the kit sets are asserted
  through the semantics tree in `test/semantics_roles_test.dart` and in the
  tests the table names.
- **Keyboard.** Every control is reached with Tab and worked with the keys
  of its pattern: `test/controls_keyboard_test.dart`,
  `test/controls_focus_test.dart`, and the tests the table names.
- **Contrast.** Each palette's text and control roles are held to their
  ratio in every theme, mode and brand accent
  (`test/palettes_contrast_test.dart`), and Flutter's text contrast
  guideline runs over 27 exhibits in each
  (`test/sweep_a11y_guidelines_test.dart`).
- **Targets.** Flutter's guidelines for targets, a name and 24 by 24
  (WCAG 2.2, 2.5.8), run over those exhibits in every theme and mode, and
  over every demo of the catalog with its semantics on
  (`example/test/sweeps/a11y_guidelines_sweep_test.dart`). The targets that
  sweep lets through are listed in it, each with its reason: the gaps in
  the table below.
- **Text size and motion.** Every demo is pumped at twice the text size and
  with reduced motion (`example/test/sweeps`).

No test holds a high-contrast mode (there is none), a touch target of 44 or
48 (the kit's controls are sized for a pointer), or the order a screen
reader walks a page in.

## Roles in use

A role says what a node is where its flags cannot: a tab, a dialog, a table
cell. Flutter passes it to the platform, and the platforms differ:

- **Web.** Most roles become the ARIA role of the same name. A role takes
  the place of what the node's flags would have made it, so a role never
  goes on the node of a button or a text field.
- **Android.** A progress bar, a menu, a menu item, a list and a radio
  group take the class name of the matching view. The other roles are
  ignored.
- **iOS, macOS, Windows, Linux.** No role is read. A node is announced from
  its flags, its label and its value, as it was before roles existed.

So a role adds to what the flags say and never stands in for them: a tab is
still a selected button, an alert's words are still a live region wherever
the role says nothing.

A landmark and a tab panel are containers with a name, and on Android and
iOS a node with a name is a stop of its own: a rectangle the size of the
page, read before the page's first control. So `Shell`'s `main` and a
`TabPanel` are given, role and name, only on the web, and are nothing
elsewhere. The `navigation` landmarks of `Sidebar` and `Breadcrumbs` are
older and are named on every platform: on a phone each is a stop that
reads "Navigation" or "Breadcrumb" before its links. Whether that stop
earns its place has not been decided, nor tried with a screen reader.

A main landmark may hold no other and sit in no other, and the framework
throws in a debug build where one does. An app that marks a main landmark
of its own, or puts the `Shell` inside a landmark, passes
`Shell(mainLandmark: false)`.

<!-- roles:begin -->
| Role | Set in |
|---|---|
| `alert` | `common/ui/alert.dart`, `common/ui/toast.dart` |
| `alertDialog` | `common/ui/modal.dart` |
| `cell` | `collection/ui/collection_table.dart` |
| `columnHeader` | `collection/ui/collection_table.dart` |
| `dialog` | `assets/ui/asset_picker.dart`, `common/ui/modal.dart`, `common/ui/side_sheet.dart` |
| `main` | `shell/ui/shell.dart` |
| `menu` | `common/ui/menu.dart` |
| `menuItem` | `common/ui/menu.dart` |
| `menuItemCheckbox` | `common/ui/menu.dart` |
| `menuItemRadio` | `common/ui/menu.dart` |
| `navigation` | `common/ui/breadcrumbs.dart`, `shell/ui/sidebar.dart` |
| `radioGroup` | `common/ui/choice.dart`, `common/ui/segmented.dart` |
| `row` | `collection/ui/collection_table.dart` |
| `tab` | `common/ui/tabs.dart` |
| `tabBar` | `common/ui/tabs.dart` |
| `tabPanel` | `common/ui/tabs.dart` |
| `table` | `collection/ui/collection_table.dart` |
<!-- roles:end -->

A determinate `ProgressBar` is a `progressBar` too, from Material's
indicator inside it.

## Roles left out

Flutter offers these and the kit sets none of them, each for the reason
beside it. `test/semantics_roles_test.dart` holds the framework's refusals,
so the day one passes, its widget can take the role.

- `comboBox`: for `Combobox`. The framework refuses the role in a debug
  build ("Missing checks for role"), and the web ignores it. The field is a
  text field that says whether it is open.
- `dragHandle`: for the handles of `Tree` and `TreeEditor`. Refused the
  same way. A row moves from its menu and with Alt and the arrows.
- `tooltip`: for `Tip`. Refused the same way.
- `spinButton`: for the steppers of a number field and a calendar's month
  buttons. Refused the same way.
- `hotKey`: refused the same way, and no widget records a shortcut.
- `status`: for the messages that wait their turn (a `Toast`, a `Spinner`,
  the save status, a field's error). Only the web reads the role, the
  framework refuses it on a live region, and on the web a status is read
  when its words change inside a region that is already there, not when it
  arrives with them, as a toast and a spinner do. They stay live regions,
  which every platform reads on arrival and on change.
- `loadingSpinner`: for `Spinner`. The web gives it no ARIA role and moves
  the name from text to a label on an element with no role, which a screen
  reader skips; no other platform reads it.
- `list`, `listItem`: for the results of a `CommandPalette` and other rows
  that scroll. A list's items must be its direct children, and a scroll
  view's own nodes stand between any node around it and its rows; a list
  inside the scroll view takes the rows from the collection Android reads,
  and the role on the scroll view takes the place of the web's scroll
  container. A row says where it stands, "2 of 5", as an option of a
  `Combobox` does.
- `listBox`, `option`: for the popup of a `Combobox`. Newer than Flutter
  3.47, the oldest the kit builds on.
- `slider`: for `ValueSlider` and a `SplitView` divider. Newer than Flutter
  3.47. Both are sliders by their flag, with a value and its steps.
- `form`: for the kit's forms. A form is a landmark only when it has a
  name, and the kit's forms take none.
- `region`: for an `Accordion`'s sections and a `KanbanBoard`'s columns. A
  page of them crowds the list of landmarks a screen reader offers.
- `complementary`, `contentInfo`: the `Shell` has no aside and no footer.
- `menuBar`: the kit has no menu bar.

## Status by component

A row is a component. *Roles it sets* are the roles its source names.
*Keyboard*, *Name, role and state* and *Contrast* name the test files that
build the component and press keys, read the semantics tree, or measure
contrast: where to look, and no proof that every key or state is covered.
*Targets* says where its targets are measured: among the exhibits, in a
demo of the catalog, or both. *Known gaps* is what is missing.

<!-- status:begin -->
| Component | Roles it sets | Keyboard | Name, role and state | Contrast | Targets | Known gaps |
|---|---|---|---|---|---|---|
| `Button` |  | `auth`, `button`, `controls_anatomy` and 17 more | `alert`, `auth`, `button` and 20 more | `alert`, `buttons_anatomy`, `controls_anatomy` and 7 more | exhibits, demos |  |
| `IconAction` |  | `core_icon_action`, `tappable`, `toolbar_kanban` | `core_icon_action`, `tappable`, `toolbar_kanban` | `buttons_anatomy`, `shell_anatomy`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `TextLink` |  | `controls_text_link` | `controls_text_link` | none | demos | As tall as its line of text, 16 to 18px: under 24px where it is not in a sentence. |
| `Toggle` |  | `controls_anatomy`, `controls_followups`, `controls_keyboard` and 2 more | `controls_anatomy`, `controls_followups`, `controls_semantics` and 1 more | `controls_anatomy`, `controls_followups`, `controls_on_colors` and 3 more | exhibits, demos | With no label, its target is its track, 18 to 22px tall in every theme but Material and Carbon. |
| `Check` |  | `controls_anatomy`, `controls_check_indeterminate`, `controls_followups` and 2 more | `controls_anatomy`, `controls_followups`, `controls_semantics` | `controls_anatomy`, `controls_followups`, `controls_on_colors` and 3 more | exhibits, demos | With no label, its target is its box, 16 or 18px by the theme. |
| `Choice` | `radioGroup` | `controls_anatomy`, `controls_followups`, `controls_keyboard` and 2 more | `controls_anatomy`, `controls_followups`, `controls_semantics` and 2 more | `controls_anatomy`, `controls_followups`, `controls_selection_style` and 2 more | exhibits, demos | An option has no name but its visible label. |
| `Segmented` | `radioGroup` | `controls_anatomy`, `controls_followups`, `controls_keyboard` and 3 more | `controls_anatomy`, `controls_followups`, `controls_segmented_variants` and 4 more | `controls_anatomy`, `controls_followups`, `controls` and 3 more | exhibits, demos | Fluent's small segment is 22px tall. |
| `ValueSlider` |  | `controls_followups`, `inputs_rtl` | `controls_followups`, `inputs_rtl`, `slider` | `controls_followups` | demos | Takes no label. Announced by Material's `Slider`; the `slider` role is newer than the oldest Flutter the kit builds on. |
| `Tag` |  | `controls_semantics`, `inputs_rtl`, `layout_tabs` and 2 more | `controls_semantics`, `inputs_rtl`, `layout_tabs` and 4 more | `controls_on_colors`, `controls`, `layout_tabs` and 2 more | exhibits, demos |  |
| `Tabs` | `tab`, `tabBar` | `controls_api_tabs_keyed`, `controls_focus`, `layout_motion` and 2 more | `controls_api_tabs_keyed`, `layout_tabs`, `semantics_roles` and 2 more | `controls_focus`, `layout_tabs`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `TabPanel` | `tabPanel` | none | `semantics_roles` | none | none | On the web only: the other platforms read no such role. |
| `Pagination` |  | `layout_keyboard` | `connected_pager`, `layout_keyboard` | `sweep_a11y_guidelines` | exhibits, demos |  |
| `Breadcrumbs` | `navigation` | `controls_focus`, `display_rtl`, `frame_breadcrumbs` and 1 more | `display_l10n`, `frame_breadcrumbs`, `save_flow_chrome_page` | `controls_focus`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `Accordion` |  | `layout_keyboard`, `layout_motion` | `layout_keyboard` | `sweep_a11y_guidelines` | exhibits, demos |  |
| `Menu` | `menu`, `menuItem`, `menuItemCheckbox`, `menuItemRadio` | `inputs_rtl`, `menus_checkbox`, `menus_header` and 4 more | `inputs_rtl`, `menus_checkbox`, `menus_header` and 4 more | `surfaces_overlay`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `MenuButton` |  | `inputs_rtl`, `menu_button`, `menus_keyboard` | `inputs_rtl`, `menus_keyboard` | none | demos |  |
| `Combobox` |  | `combobox`, `controls_followups`, `listboxes_combobox` | `controls_followups`, `listboxes_combobox` | `controls_followups` | demos | A text field that says whether it is open, with no `comboBox` role: the framework refuses it. Its options are buttons that say whether they are selected and where they stand, "2 of 5": the list box and option roles are newer than the oldest Flutter. |
| `SearchField` |  | `search_field`, `text_inputs_auth_inputs` | `text_inputs_auth_inputs` | `sweep_a11y_guidelines`, `text_inputs_auth_inputs` | exhibits, demos |  |
| `Calendar` |  | `controls_followups`, `dates_calendar`, `fields_l10n` and 1 more | `controls_followups`, `dates_calendar`, `fields_l10n` and 1 more | `controls_followups` | demos |  |
| `DateRangePicker` |  | `date_range_picker`, `dates_calendar` | `date_range_picker`, `dates_calendar` | `sweep_a11y_guidelines` | exhibits, demos |  |
| `CommandPalette` |  | `command_palette`, `menus_palette` | `menus_palette` | `command_palette`, `menus_palette`, `surfaces_overlay` and 1 more | exhibits, demos | Its results are buttons that say whether they are selected and where they stand, in no list: see the roles left out. |
| `Tip` |  | `hovers_tip_placement`, `tip` | `hovers_tip_placement` | `core_inverse_surface`, `tooltip_anatomy` | demos | No `tooltip` role: the framework refuses it. |
| `Alert` | `alert` | none | `alert`, `semantics_roles`, `text_inputs_auth_forms` | `alert`, `feedback_style`, `sweep_a11y_guidelines` | exhibits, demos | A danger alert that is read out is an `alert`; a warning is a live region; info and success are not read out unless asked to be. |
| `AnnouncementBar` |  | none | `announcement_bar`, `dialogs_announcement_wrap` | `announcement_bar`, `dialogs_announcement_wrap`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `Toast` | `alert` | `inputs_rtl`, `overlays_toast`, `toasts_handle` | `inputs_rtl`, `overlays_toast`, `semantics_roles` and 1 more | `feedback_style`, `surfaces_overlay`, `sweep_a11y_guidelines` | exhibits, demos | A danger toast is an `alert`; the others are live regions. |
| `Modal` | `alertDialog`, `dialog` | `overlays_modal`, `overlays_toast` | `dialogs_modal_size`, `overlays_modal`, `overlays_toast` | `surfaces_overlay`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `SideSheet` | `dialog` | `inputs_rtl`, `overlays_sheet`, `side_sheet` | `inputs_rtl`, `overlays_sheet`, `shell_notification_inbox` | `surfaces_overlay`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `Spinner` |  | `controls_semantics` | `controls_semantics` | none | demos | A named live region with no `loadingSpinner` role: see the roles left out. |
| `ProgressBar` | `progressBar`, from Material's indicator | none | `display_l10n`, `semantics_roles`, `sweeps_reduced_motion` | `progress_bar` | demos | With no value it is no progress bar, and its name is read as text. Where no role is read (iOS, the desktops) its value is the number alone, "62". |
| `Shell` | `main` | `form_leave_sidebar`, `save_flow_chrome_page`, `shell_compact` and 2 more | `save_flow_chrome_page`, `semantics_roles`, `shell_compact` and 2 more | `shell_anatomy` | demos | The main landmark is on the web only: the other platforms read no such role. |
| `Sidebar` | `navigation` | `form_leave_sidebar`, `frame_sidebar`, `save_flow_chrome_page` and 4 more | `frame_sidebar`, `save_flow_chrome_page`, `semantics_roles` and 5 more | `collection_shell_contrast`, `frame_sidebar`, `shell_anatomy` and 2 more | exhibits, demos | Its landmark is a named container on every platform: on a phone, a stop that reads "Navigation" before its links. |
| `SplitView` |  | `display_rtl`, `layout_motion`, `split_view` | `split_view` | none | demos |  |
| `Tree` |  | `controls_focus`, `display_rtl`, `layout_motion` and 1 more | `tree_keyboard` | `controls_focus` | demos | Flutter has no tree or tree item role: a row's caret is a button named Expand or Collapse that says whether it is open. Its drag handle has no `dragHandle` role: the framework refuses it; a row moves from its menu and with Alt and the arrows. |
| `TreeEditor` |  | `canvas_tree_focus`, `display_rtl`, `history_a11y` and 1 more | `canvas_tree_focus`, `editor_tokens`, `history_a11y` and 1 more | `history_a11y`, `history_tree_editor` | demos |  |
| `KanbanBoard` |  | `sweep_collection_assets`, `toolbar_kanban` | `sweep_collection_assets`, `toolbar_kanban` | `toolbar_a11y` | demos |  |
| `CollectionTable` | `cell`, `columnHeader`, `row`, `table` | `collection_builders`, `collection_followups`, `collection_l10n` and 12 more | `collection_followups`, `collection_rtl`, `collection_table_edit_trigger` and 6 more | `collection_followups`, `collection_shell_contrast`, `table_a11y` and 3 more | demos |  |
| `ColumnChooser` |  | `toolbar_column_chooser` | `toolbar_column_chooser` | `toolbar_a11y`, `toolbar_column_chooser` | demos |  |
| `NotificationCenter` |  | `inbox_actions`, `inbox_states`, `inputs_rtl` and 1 more | `inbox_actions`, `inbox_states`, `inputs_rtl` and 2 more | `inbox_actions`, `notification_center`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `UploadZone` |  | `controls_focus`, `layout_keyboard` | `display_l10n`, `layout_keyboard`, `semantics_roles` | `controls_focus`, `dataviz_on_colors`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `StatCard` |  | `layout_keyboard` | `content_stat_card_loading`, `layout_keyboard`, `stat_card_trend` | `dataviz_on_colors`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `FieldShell` |  | `core_field_state`, `field_bodies_state`, `field_shell_translation_lanes` and 3 more | `core_field_state`, `core_source_target_pair`, `field_bodies_state` and 7 more | `core_type_roles`, `field_bodies_state`, `fields_content_contrast` and 2 more | exhibits, demos |  |
| `ValidationSummary` |  | none | `form_wizard_summary` | none | demos | A live region that waits its turn, not an `alert`: it is read again as the count changes. Its links are a line of text tall. |
| `SaveCluster` |  | `save_flow_chrome_cluster` | `save_flow_chrome_cluster` | none | none | Its "fields need attention" link is 16px tall. |
| `AssetLibrary` |  | `asset_browse_keyboard`, `sweep_collection_assets` | `asset_browse_a11y`, `media_library_connected`, `sweep_collection_assets` | `asset_browse_a11y`, `asset_browse_thumbnail`, `collection_shell_contrast` | demos |  |
| `CopyButton` |  | `controls_focus`, `text_inputs_auth_inputs` | `text_inputs_auth_inputs` | `controls_focus`, `text_inputs_auth_inputs` | demos |  |
| `JsonView` |  | `display_json_view_rows`, `display_rtl`, `layout_keyboard` | `display_json_view_rows`, `display_l10n`, `layout_keyboard` | none | demos |  |
| `ZoomView` |  | `zoom_view` | `zoom_view` | none | demos |  |
| `FormWizard` |  | `form_wizard_steps` | `form_wizard_steps`, `form_wizard_summary` | none | demos |  |
| `CommentsButton` |  | `comments_button`, `fields_content_contrast`, `fields_l10n` and 2 more | `field_shell_translation_shell`, `fields_l10n`, `sweep_field_triggers` and 1 more | `fields_content_contrast`, `history_followups`, `sweep_a11y_guidelines` | exhibits, demos |  |
| `HistoryButton` |  | `fields_l10n`, `sweep_field_triggers`, `translation_tokens` | `field_shell_translation_shell`, `fields_l10n`, `sweep_field_triggers` and 1 more | `history_followups`, `sweep_a11y_guidelines` | exhibits, demos |  |
<!-- status:end -->
