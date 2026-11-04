import '../labs/lane_field_lab.dart';
import 'ui/assets/asset_field_view.dart';
import 'ui/assets/asset_library.dart';
import 'ui/assets/asset_library_connected.dart';
import 'ui/assets/asset_provider_picker.dart';
import 'ui/assets/image_cropper.dart';
import 'ui/auth/auth.dart';
import 'ui/collection/async_value.dart';
import 'ui/collection/collection_advanced.dart';
import 'ui/collection/collection_cards.dart';
import 'ui/collection/collection_connected.dart';
import 'ui/collection/collection_toolbar.dart';
import 'ui/collection/column_chooser.dart';
import 'ui/collection/kanban.dart';
import 'ui/collection/save_view_dialog.dart';
import 'ui/collection/saved_views.dart';
import 'ui/collection/saved_views_inspector.dart';
import 'ui/collection/table/data_table.dart';
import 'ui/collection/table/data_table_cells.dart';
import 'ui/collection/table/data_table_header_menu.dart';
import 'ui/collection/table/data_table_inline_edit.dart';
import 'ui/collection/table/data_table_interaction.dart';
import 'ui/collection/table/data_table_paged.dart';
import 'ui/collection/table/data_table_resize.dart';
import 'ui/collection/table/data_table_selection.dart';
import 'ui/collection/table/data_table_states.dart';
import 'ui/fields/basic/boolean_field_view.dart';
import 'ui/fields/basic/color_field_view.dart';
import 'ui/fields/basic/date_field_view.dart';
import 'ui/fields/basic/field_anatomy.dart';
import 'ui/fields/basic/field_heights.dart';
import 'ui/fields/basic/field_validation_states.dart';
import 'ui/fields/basic/key_value_field_view.dart';
import 'ui/fields/basic/masked_date_field_view.dart';
import 'ui/fields/basic/masked_field_view.dart';
import 'ui/fields/basic/multi_select_field_view.dart';
import 'ui/fields/basic/number_field_view.dart';
import 'ui/fields/basic/reference_field.dart';
import 'ui/fields/basic/select_field_view.dart';
import 'ui/fields/basic/tags_field_view.dart';
import 'ui/fields/basic/text_field_view.dart';
import 'ui/fields/field_group.dart';
import 'ui/fields/form_grid.dart';
import 'ui/fields/forms_reveal.dart';
import 'ui/fields/repeater.dart';
import 'ui/fields/rich/code_field_view.dart';
import 'ui/fields/rich/media_field_view.dart';
import 'ui/fields/translated/source_target_pair_demo.dart';
import 'ui/fields/translated/translatable_media.dart';
import 'ui/fields/translated/translatable_text.dart';
import 'ui/fields/translated/translation.dart';
import 'ui/fields/translated/translation_advanced.dart';
import 'ui/fields/translated/translation_menus.dart';
import 'ui/fields/validation_summary.dart';
import 'ui/foundations/anatomy.dart';
import 'ui/foundations/appearance.dart';
import 'ui/foundations/control_sizes.dart';
import 'ui/foundations/localization.dart';
import 'ui/foundations/status_pill.dart';
import 'ui/foundations/tokens.dart';
import 'ui/primitives/accordion.dart';
import 'ui/primitives/announcement_bar.dart';
import 'ui/primitives/attention_grid.dart';
import 'ui/primitives/avatar.dart';
import 'ui/primitives/breadcrumbs.dart';
import 'ui/primitives/button.dart';
import 'ui/primitives/calendar.dart';
import 'ui/primitives/chart.dart';
import 'ui/primitives/combobox.dart';
import 'ui/primitives/command_palette.dart';
import 'ui/primitives/context_menu.dart';
import 'ui/primitives/controls.dart';
import 'ui/primitives/copy_button.dart';
import 'ui/primitives/count_badge.dart';
import 'ui/primitives/date_range_picker.dart';
import 'ui/primitives/description_list.dart';
import 'ui/primitives/feedback/alert.dart';
import 'ui/primitives/feedback/modal.dart';
import 'ui/primitives/feedback/toast.dart';
import 'ui/primitives/hover_card.dart';
import 'ui/primitives/input_field.dart';
import 'ui/primitives/json_view.dart';
import 'ui/primitives/menu.dart';
import 'ui/primitives/modal_anchor.dart';
import 'ui/primitives/notification_center.dart';
import 'ui/primitives/pagination.dart';
import 'ui/primitives/panel.dart';
import 'ui/primitives/password_field.dart';
import 'ui/primitives/popover.dart';
import 'ui/primitives/search_field.dart';
import 'ui/primitives/search_results.dart';
import 'ui/primitives/side_sheet.dart';
import 'ui/primitives/split_view.dart';
import 'ui/primitives/stat_card.dart';
import 'ui/primitives/states/empty_state.dart';
import 'ui/primitives/states/error_state.dart';
import 'ui/primitives/states/loading.dart';
import 'ui/primitives/states/progress.dart';
import 'ui/primitives/states/skeleton.dart';
import 'ui/primitives/steps.dart';
import 'ui/primitives/tabs.dart';
import 'ui/primitives/timeline.dart';
import 'ui/primitives/tip.dart';
import 'ui/primitives/upload.dart';
import 'ui/screens/capabilities/comments_button.dart';
import 'ui/screens/capabilities/help_button.dart';
import 'ui/screens/capabilities/history_button.dart';
import 'ui/screens/capabilities/mention_field.dart';
import 'ui/screens/customer_form.dart';
import 'ui/screens/edit_layouts.dart';
import 'ui/screens/form_wizard.dart';
import 'ui/screens/history/diff_components.dart';
import 'ui/screens/history/version_history.dart';
import 'ui/screens/leave_guard.dart';
import 'ui/screens/menu/menu_editor_view.dart';
import 'ui/screens/page_scaffold.dart';
import 'ui/screens/record_dialog.dart';
import 'ui/screens/save_bar.dart';
import 'ui/screens/settings_form.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/sidebar_account.dart';

/// The catalog's demo pages, one insertion-ordered group tree.
///
/// Every group but the last shows what the kit ships. The last, Labs, holds
/// prototypes of what it might: private widgets kept to settle an open design
/// question, each naming it in its class doc. A lab is swept like any other
/// demo, but has no golden.
Map<String, dynamic> genericCatalog() => {
  'Foundations': {
    'Tokens': const TokensDemo(),
    'Anatomy': const AnatomyDemo(),
    'Control sizes': const ControlSizesDemo(),
    'Appearance picker': const AppearanceDemo(),
    'Status pill': const StatusPillDemo(),
    'Localization': const LocalizationDemo(),
  },
  'Primitives': {
    'Button': const ButtonDemo(),
    'Menu': const MenuDemo(),
    'Context menu': const ContextMenuDemo(),
    'Controls': const ControlsDemo(),
    'Avatar': const AvatarDemo(),
    'Tooltip': const TipDemo(),
    'Hover card': const HoverCardDemo(),
    'Popover': const PopoverDemo(),
    'Tabs': const TabsDemo(),
    'Accordion': const AccordionDemo(),
    'Steps / wizard': const StepsDemo(),
    'Pagination': const PaginationDemo(),
    'Count badge': const CountBadgeDemo(),
    'Notification center': const NotificationCenterDemo(),
    'Calendar': const CalendarDemo(),
    'Date-range picker': const DateRangePickerDemo(),
    'Date-range picker / open': const DateRangePickerOpenDemo(),
    'Command palette (⌘K)': const CommandPaletteDemo(),
    'Search results (snippets)': const SearchResultsDemo(),
    'Breadcrumbs': const BreadcrumbsDemo(),
    'Copy button': const CopyButtonDemo(),
    'Announcement bar': const AnnouncementBarDemo(),
    'Description list': const DescriptionListDemo(),
    'JSON viewer': const JsonViewDemo(),
    'Stat card / dashboard': const StatCardDemo(),
    'Attention tiles': const AttentionGridDemo(),
    'Charts / sparklines': const ChartDemo(),
    'Timeline / activity': const TimelineDemo(),
    'Search field': const SearchFieldDemo(),
    'Input field': const InputFieldDemo(),
    'Combobox / autocomplete': const ComboboxDemo(),
    'Combobox / open': const ComboboxOpenDemo(),
    'Combobox / flips near the bottom': const ComboboxFlipDemo(),
    'Password field': const PasswordFieldDemo(),
    'Panel': const PanelDemo(),
    'Side sheet': const SideSheetDemo(),
    'Modal anchor': const ModalAnchorDemo(),
    'Split view (resizable)': const SplitViewDemo(),
    'Upload zone': const UploadZoneDemo(),
    'Feedback': {
      'Alert': const AlertDemo(),
      'Toast': const ToastDemo(),
      'Modal': const ModalDemo(),
      'Modal sizes': const ModalSizesDemo(),
    },
    'States': {
      'Loading': const LoadingDemo(),
      'Progress bar': const ProgressBarDemo(),
      'Skeleton': const SkeletonDemo(),
      'Empty': const EmptyStateDemo(),
      'Error': const ErrorStateDemo(),
    },
  },
  'Fields': {
    'Field group': const FieldGroupDemo(),
    'Form grid': const FormGridDemo(),
    'Validation summary': const ValidationSummaryDemo(),
    'Revealed field': const FormsRevealDemo(),
    'Repeater / array': const RepeaterDemo(),
    'Basic': {
      'Field heights': const FieldHeightsDemo(),
      'Field anatomy': const FieldAnatomyDemo(),
      'Validation states': const FieldValidationStatesDemo(),
      'Text': const TextFieldDemo(),
      'Boolean / toggle': const BooleanFieldDemo(),
      'Select / enum': const SelectFieldDemo(),
      'Select / open': const SelectFieldOpenDemo(),
      'Multi-select / tags': const MultiSelectFieldDemo(),
      'Tags (free-form)': const TagsFieldDemo(),
      'Key → value (map)': const KeyValueFieldDemo(),
      'Reference': const ReferenceFieldDemo(),
      'Number': const NumberFieldDemo(),
      'Date / time': const DateFieldDemo(),
      'Date / time · open': const DateFieldOpenDemo(),
      'Date · masked (experimental)': const MaskedDateFieldDemo(),
      'Color': const ColorFieldDemo(),
      'Masked (phone / card / date)': const MaskedFieldDemo(),
    },
    'Translated': {
      'Source-target pair': const SourceTargetPairDemo(),
      'Text': const TranslatableTextDemo(),
      'Translation': const TranslationDemo(),
      'Translation · advanced': const TranslationAdvancedDemo(),
      'Translation · right-to-left lanes':
          const TranslationAdvancedDemo.rightToLeft(),
      'Translation · open menus': const TranslationMenusDemo(),
      'Media': const TranslatableMediaDemo(),
    },
    'Rich': {
      'Media / upload': const MediaFieldDemo(),
      'Code / JSON field': const CodeFieldDemo(),
    },
  },
  'Assets': {
    'Field (single + picker)': const AssetFieldDemo(),
    'Library / picker': const AssetLibraryDemo(),
    'Library / connected': const AssetLibraryConnectedDemo(),
    'External provider picker': const AssetProviderPickerDemo(),
    'Image cropper / focal': const ImageCropperDemo(),
  },
  'Auth': {
    'Sign in': const SignInDemo(),
    'Set password': const SetPasswordDemo(),
    'Change password': const ChangePasswordDemo(),
  },
  'Collection': {
    'Table': {
      'Basics': const DataTableDemo(),
      'States': const DataTableStatesDemo(),
      'Cell gallery': const DataTableCellsDemo(),
      'Selection + bulk': const DataTableSelectionDemo(),
      'Sorting + pagination': const DataTablePagedDemo(),
      'Resizable columns': const DataTableResizeDemo(),
      'Column header menu': const DataTableHeaderMenuDemo(),
      'Inline cell editing': const DataTableInlineEditDemo(),
      'Interaction': {
        'Editing a cell': const DataTableInteractionDemo.editing(),
        'Header menu open': const DataTableInteractionDemo.headerMenu(),
        'Row hover on a stripe': const DataTableInteractionDemo.hoverStripe(),
        'Row hover on a selection':
            const DataTableInteractionDemo.hoverSelected(),
        'Pointer on a column edge': const DataTableInteractionDemo.resizeEdge(),
        'Scrolled past the pinned column':
            const DataTableInteractionDemo.scrolled(),
      },
    },
    'Toolbar + bulk actions': const CollectionToolbarDemo(),
    'Column chooser': const ColumnChooserDemo(),
    'Saved views': {
      'Full workflow': const SavedViewsDemo(),
      'Serialization inspector': const SavedViewsInspectorDemo(),
      'Save dialog': const SaveViewDialogDemo(),
      'Rename dialog': const SaveViewDialogDemo.rename(),
      'Menu (open)': const SavedViewsMenuDemo(),
    },
    'Connected (controller + fetcher)': const CollectionConnectedDemo(),
    'One value (controller + builder)': const AsyncValueDemo(),
    'Card / grid view': const CollectionCardsDemo(),
    'Kanban board': const KanbanDemo(),
    'Advanced filtering': const CollectionAdvancedDemo(),
  },
  'Screens': {
    'Customer form (RPC + LocalScope)': const CustomerFormDemo(),
    'Settings form': const SettingsFormDemo(),
    'Record dialog': const RecordDialogDemo(),
    'Form wizard': const FormWizardDemo(),
    'Leave guard': const LeaveGuardDemo(),
    'Shell (app frame)': const ShellDemo(),
    'Sidebar account': const SidebarAccountDemo(),
    'Page scaffold': const PageScaffoldDemo(),
    'Page scaffold with tabs': const PageScaffoldDemo.tabs(),
    'Edit layouts (compare)': const EditLayoutsDemo(),
    'Menu editor (tree)': const MenuEditorDemo(),
    'Save bar': const SaveBarDemo(),
    'Capabilities': {
      'Help': const HelpDemo(),
      'Comments (field button)': const CommentsDemo(),
      'Mention field': const MentionFieldDemo(),
      'Mention field / suggestions open': const MentionFieldOpenDemo(),
      'Mention field / suggestions open (ar)':
          const MentionFieldOpenDemo.arabic(),
      'History / draft': const HistoryDemo(),
    },
  },
  'History': {
    'Version diff (full screen)': const VersionHistoryDemo(),
    'Diff in side sheet': const DiffSheetDemo(),
    'Inline text diff': const TextDiffDemo(),
    'Block diff': const BlockDiffDemo(),
  },
  'Labs': {'Lane field': const LaneFieldLabDemo()},
};
