/// The catalog's demo entries, which the sweeps pump through
/// `harness/harness.dart`.
library;

import 'package:admin_ui_example/src/catalog.dart';
import 'package:admin_ui_example/src/ui/assets/asset_browse_states.dart';
import 'package:admin_ui_example/src/ui/assets/asset_editor_demo.dart';
import 'package:admin_ui_example/src/ui/assets/asset_library_connected.dart';
import 'package:admin_ui_example/src/ui/assets/asset_provider_picker.dart';
import 'package:admin_ui_example/src/ui/auth/auth.dart';
import 'package:admin_ui_example/src/ui/collection/collection_toolbar.dart';
import 'package:admin_ui_example/src/ui/collection/column_chooser.dart';
import 'package:admin_ui_example/src/ui/collection/filter_editors.dart';
import 'package:admin_ui_example/src/ui/collection/table/data_table_interaction.dart';
import 'package:admin_ui_example/src/ui/collection/table/data_table_states.dart';
import 'package:admin_ui_example/src/ui/editor/insert_picker_demo.dart';
import 'package:admin_ui_example/src/ui/fields/keyboard_focus.dart';
import 'package:admin_ui_example/src/ui/fields/translated/source_target_pair_demo.dart';
import 'package:admin_ui_example/src/ui/foundations/appearance.dart';
import 'package:admin_ui_example/src/ui/foundations/table_tokens.dart';
import 'package:admin_ui_example/src/ui/primitives/button_anatomy.dart';
import 'package:admin_ui_example/src/ui/primitives/command_palette.dart';
import 'package:admin_ui_example/src/ui/primitives/control_states.dart';
import 'package:admin_ui_example/src/ui/primitives/copy_button.dart';
import 'package:admin_ui_example/src/ui/primitives/feedback/feedback_icons.dart';
import 'package:admin_ui_example/src/ui/primitives/icon_action.dart';
import 'package:admin_ui_example/src/ui/primitives/json_view.dart';
import 'package:admin_ui_example/src/ui/primitives/menu.dart';
import 'package:admin_ui_example/src/ui/primitives/notification_center.dart';
import 'package:admin_ui_example/src/ui/primitives/overlay_surfaces.dart';
import 'package:admin_ui_example/src/ui/primitives/states/progress.dart';
import 'package:admin_ui_example/src/ui/primitives/thumbnail_image.dart';
import 'package:admin_ui_example/src/ui/screens/customer_form.dart';
import 'package:admin_ui_example/src/ui/screens/customer_form_states.dart';
import 'package:admin_ui_example/src/ui/screens/form_wizard.dart';
import 'package:admin_ui_example/src/ui/screens/history/quick_diff_demo.dart';
import 'package:admin_ui_example/src/ui/screens/leave_guard.dart';
import 'package:admin_ui_example/src/ui/screens/page_scaffold.dart';
import 'package:admin_ui_example/src/ui/screens/record_dialog.dart';
import 'package:admin_ui_example/src/ui/screens/settings_form.dart';
import 'package:admin_ui_example/src/ui/screens/shell.dart';
import 'package:admin_ui_example/src/ui/screens/shell_drawer.dart';

import 'harness/entries.dart';

export 'harness/entries.dart';

/// Every `@Preview` constructor that [genericCatalog] does not list.
/// `entries_guard_test.dart` fails when a new one is in neither, so no demo
/// goes untested unnoticed.
const previewOnly = <PreviewOnlyDemo>[
  PreviewOnlyDemo('ControlStatesDemo', 'Control states', ControlStatesDemo.new),
  PreviewOnlyDemo('IconActionDemo', 'Icon action', IconActionDemo.new),
  PreviewOnlyDemo(
    'ButtonAnatomyDemo',
    'Button · variants and tones',
    ButtonAnatomyDemo.new,
  ),
  PreviewOnlyDemo(
    'MenuHighlightDemo',
    'Menu keyboard highlight',
    MenuHighlightDemo.new,
  ),
  PreviewOnlyDemo('MenuPlacementDemo', 'Menu placement', MenuPlacementDemo.new),
  PreviewOnlyDemo(
    'OverlaySurfacesDemo',
    'Overlay surfaces',
    OverlaySurfacesDemo.new,
  ),
  PreviewOnlyDemo(
    'ThumbnailImageDemo',
    'Thumbnail image',
    ThumbnailImageDemo.new,
  ),
  PreviewOnlyDemo(
    'CommandPaletteResultsDemo',
    'Command palette — 40 results',
    CommandPaletteResultsDemo.new,
  ),
  PreviewOnlyDemo(
    'CommandPaletteSelectionDemo',
    'Command palette — selected hits',
    CommandPaletteSelectionDemo.new,
  ),
  PreviewOnlyDemo('TableTokensDemo', 'Table tokens', TableTokensDemo.new),
  PreviewOnlyDemo(
    'CopyButtonStatesDemo',
    'Copy button — copied and error',
    CopyButtonStatesDemo.new,
  ),
  PreviewOnlyDemo(
    'JsonViewDemo.rowActions',
    'JSON viewer · row actions, a long value shown whole',
    JsonViewDemo.rowActions,
  ),
  PreviewOnlyDemo(
    'FilterEditorsDemo',
    'Filter editor · options, open',
    FilterEditorsDemo.new,
  ),
  PreviewOnlyDemo(
    'FilterEditorsDemo.yesNo',
    'Filter editor · yes/no, open',
    FilterEditorsDemo.yesNo,
  ),
  PreviewOnlyDemo(
    'PasswordStrengthDemo',
    'Password strength',
    PasswordStrengthDemo.new,
  ),
  PreviewOnlyDemo(
    'KeyboardFocusDemo.select',
    'Focus · select trigger',
    KeyboardFocusDemo.select,
  ),
  PreviewOnlyDemo(
    'KeyboardFocusDemo.date',
    'Focus · date trigger',
    KeyboardFocusDemo.date,
  ),
  PreviewOnlyDemo(
    'KeyboardFocusDemo.colour',
    'Focus · colour trigger',
    KeyboardFocusDemo.colour,
  ),
  PreviewOnlyDemo(
    'KeyboardFocusDemo.asset',
    'Focus · asset tile',
    KeyboardFocusDemo.asset,
  ),
  PreviewOnlyDemo(
    'KeyboardFocusDemo.tableCheck',
    'Focus · row checkbox',
    KeyboardFocusDemo.tableCheck,
  ),
  PreviewOnlyDemo(
    'SourceTargetPairNarrowDemo',
    'Source-target pair — narrow (360 px)',
    SourceTargetPairNarrowDemo.new,
  ),
  PreviewOnlyDemo(
    'DataTableInteractionDemo',
    'Interaction states',
    DataTableInteractionDemo.new,
  ),
  PreviewOnlyDemo(
    'DataTableStatesDemo.narrow',
    'States (narrow)',
    DataTableStatesDemo.narrow,
  ),
  PreviewOnlyDemo(
    'CollectionToolbarStatesDemo',
    'Toolbar states',
    CollectionToolbarStatesDemo.new,
  ),
  PreviewOnlyDemo(
    'ColumnChooserPanelDemo',
    'Column chooser panel',
    ColumnChooserPanelDemo.new,
  ),
  PreviewOnlyDemo(
    'UnifiedBlockPickerDemo',
    'Block picker',
    UnifiedBlockPickerDemo.new,
  ),
  PreviewOnlyDemo(
    'MediaTileStatesDemo',
    'Media tile — states',
    MediaTileStatesDemo.new,
  ),
  PreviewOnlyDemo(
    'AssetLibraryNarrowDemo',
    'Library — narrow',
    AssetLibraryNarrowDemo.new,
  ),
  PreviewOnlyDemo(
    'AssetLibraryPagedDemo',
    'Library — paginated',
    AssetLibraryPagedDemo.new,
  ),
  PreviewOnlyDemo(
    'AssetLibraryConnectedDemo.error',
    'Library — connected, error',
    AssetLibraryConnectedDemo.error,
  ),
  PreviewOnlyDemo('AssetDetailDemo', 'Asset detail', AssetDetailDemo.new),
  PreviewOnlyDemo('AssetEditorDemo', 'Asset editor', AssetEditorDemo.new),
  PreviewOnlyDemo(
    'AssetCropDialogDemo',
    'Crop dialog (ratio presets)',
    AssetCropDialogDemo.new,
  ),
  PreviewOnlyDemo(
    'AssetPickerOpenDemo',
    'Media picker (open)',
    AssetPickerOpenDemo.new,
  ),
  PreviewOnlyDemo(
    'ProviderImportSheetDemo',
    'Provider import sheet',
    ProviderImportSheetDemo.new,
  ),
  PreviewOnlyDemo(
    'ProviderImportSheetDemo.sizesFailed',
    'Provider import sheet — sizes failed',
    ProviderImportSheetDemo.sizesFailed,
  ),
  PreviewOnlyDemo(
    'CustomerFormDemo.invalid',
    'Customer form (invalid edit)',
    CustomerFormDemo.invalid,
  ),
  PreviewOnlyDemo(
    'CustomerFormStatesDemo.validating',
    'Customer form (checking email)',
    CustomerFormStatesDemo.validating,
  ),
  PreviewOnlyDemo(
    'CustomerFormStatesDemo.submitting',
    'Customer form (saving)',
    CustomerFormStatesDemo.submitting,
  ),
  PreviewOnlyDemo(
    'CustomerFormStatesDemo.failed',
    'Customer form (save failed)',
    CustomerFormStatesDemo.failed,
  ),
  PreviewOnlyDemo(
    'SettingsFormDemo.invalid',
    'Settings form (invalid)',
    SettingsFormDemo.invalid,
  ),
  PreviewOnlyDemo(
    'RecordDialogDemo.invalid',
    'Record dialog (invalid)',
    RecordDialogDemo.invalid,
  ),
  PreviewOnlyDemo(
    'FormWizardDemo.blocked',
    'Form wizard (blocked step)',
    FormWizardDemo.blocked,
  ),
  PreviewOnlyDemo(
    'LeaveGuardDemo.prompt',
    'Leave guard (prompt open)',
    LeaveGuardDemo.prompt,
  ),
  PreviewOnlyDemo(
    'ShellDemo.narrow',
    'Shell (narrow window)',
    ShellDemo.narrow,
  ),
  PreviewOnlyDemo('ShellDemo.tablet', 'Shell (tablet width)', ShellDemo.tablet),
  PreviewOnlyDemo('ShellDemo.phone', 'Shell (phone width)', ShellDemo.phone),
  PreviewOnlyDemo(
    'ShellDemo.besidePage',
    'Shell (top bar over the page)',
    ShellDemo.besidePage,
  ),
  PreviewOnlyDemo(
    'ShellDemo.besidePageTablet',
    'Shell (top bar over the page, tablet width)',
    ShellDemo.besidePageTablet,
  ),
  PreviewOnlyDemo(
    'ShellDrawerDemo',
    'Shell (phone, drawer open)',
    ShellDrawerDemo.new,
  ),
  PreviewOnlyDemo(
    'NotificationInboxSheetDemo',
    'Notification inbox (phone sheet)',
    NotificationInboxSheetDemo.new,
  ),
  PreviewOnlyDemo(
    'AppearanceDemo.carbonTeal',
    'Appearance picker · Carbon dark, Teal',
    AppearanceDemo.carbonTeal,
  ),
  PreviewOnlyDemo(
    'PageScaffoldDemo.narrow',
    'Page scaffold (narrow window)',
    PageScaffoldDemo.narrow,
  ),
  PreviewOnlyDemo('QuickDiffDemo', 'Quick diffs', QuickDiffDemo.new),
  PreviewOnlyDemo(
    'ProgressBarSeveritiesDemo',
    'Progress bar · severities',
    ProgressBarSeveritiesDemo.new,
  ),
  PreviewOnlyDemo(
    'FeedbackIconsDemo',
    'Feedback · icons',
    FeedbackIconsDemo.new,
  ),
];

/// The [genericCatalog] pages in catalog order, each id its group path.
List<DemoEntry> catalogEntries() => catalogEntriesOf(genericCatalog());

/// Every demo the tests pump: the catalog pages, then [previewOnly] as
/// `Preview / <name>`. Throws when two share an id.
List<DemoEntry> demoEntries() =>
    uniqueEntries([...catalogEntries(), ...previewEntriesOf(previewOnly)]);

/// The entry of [demoEntries] with [id]; throws when there is none, so a
/// list of ids to pump never drops a renamed demo silently.
DemoEntry demoEntry(String id) => entryWithId(demoEntries(), id);
