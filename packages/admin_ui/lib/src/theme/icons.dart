import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// The glyphs the kit draws on its own: a dialog's close, a menu's check, a
/// field's caret, a column's sort arrows, an upload's file type. Provided via
/// [AdminTokens]; read through `context.icons`.
///
/// Each slot is named for what its glyph says, not for the glyph, and
/// defaults to the Material Icons glyph the kit draws for it, so a theme that
/// sets none draws the kit's own. An app on another icon set gives
/// the slots its glyphs, `AdminIcons(close: …, check: …)` or
/// `const AdminIcons().copyWith(…)`, through `AdminTheme.from(icons: …)` or
/// [AdminTokens.copyWith], and the kit's controls follow. A slot left out
/// keeps the kit's glyph. The glyphs an app passes a control (a `Button`'s
/// `icon`, a nav item's, an empty state's) are the app's, and none is read
/// from here.
///
/// Four slots point the reading direction: [chevronForward], [chevronBack],
/// [arrowForward] and [arrowBack]. Their defaults set
/// [IconData.matchTextDirection], so right to left they are mirrored, and
/// the kit counts on it; a glyph given for one should set it too. The
/// [resizeLeft] family is physical and should not.
///
/// Glyphs do not interpolate: a lerp between two sets takes the nearer one.
@immutable
class AdminIcons {
  // Dismiss, confirm, add.

  /// Closes, dismisses or takes one thing away: a dialog's, a drawer's or a
  /// notification's close, a clear button, a tag's, a filter's or a row's
  /// remove, an upload's cancel, a selection's clear.
  final IconData close;

  /// A check mark: the chosen item of a menu, a list or a segmented control, a
  /// checked checkbox or tile, a step done, a value copied, a change saved, a
  /// thread resolved, a swatch chosen.
  final IconData check;

  /// A checkbox's mixed state: some of what it stands for is checked.
  final IconData indeterminate;

  /// Adds or creates: a row, an item, a node, a saved view, an option made from
  /// what was typed, the tile that adds media.
  final IconData add;

  /// A number field's step up.
  final IconData increment;

  /// A number field's step down.
  final IconData decrement;

  /// More than is shown: an overflow menu, a row's, a card's or a node's
  /// actions, the crumbs a breadcrumb trail folds away, the pages a pager
  /// skips.
  final IconData more;

  /// A table column's menu, in its header.
  final IconData moreVertical;

  /// Opens the navigation drawer on a narrow window.
  final IconData menu;

  // Search and filter.

  /// Searches: a search field, the top bar's search, the command palette's
  /// query, a picker's search box.
  final IconData search;

  /// A search or a filter that matched nothing.
  final IconData noResults;

  /// A filter menu's trigger, when it is given no icon of its own
  /// (`FilterMenuButton`).
  final IconData filter;

  /// Where a search matched, beside the field's name, in a table's match
  /// column.
  final IconData matchedField;

  /// Where a search matched in a result's body, beside its snippet in the
  /// command palette, when the item gives no glyph of its own.
  final IconData matchedContent;

  /// A command palette's jump to one of a form's fields.
  final IconData jumpTo;

  /// The Enter key, on the highlighted row it would pick.
  final IconData enterKey;

  // Edit, copy, undo.

  /// Renames: a saved view's rename.
  final IconData edit;

  /// Copies a value to the clipboard, or duplicates: a copy button, a saved
  /// view's duplicate.
  final IconData copy;

  /// Deletes: an asset, a tree node, a saved view.
  final IconData delete;

  /// Discards unsaved changes or reverts one: a save bar's discard, a saved
  /// view's revert, a field's revert in a diff.
  final IconData undo;

  /// Tries again what failed: a load, an upload, a media item, a reference that
  /// did not resolve.
  final IconData retry;

  /// Puts an image's crop, turn and flip back as they were.
  final IconData reset;

  /// Opens a field's history of changes.
  final IconData history;

  /// Restores an earlier version, in a diff.
  final IconData restore;

  // Links and references.

  /// A link or a reference: a reference's item with no glyph of its own, a JSON
  /// view's copy-path action.
  final IconData link;

  /// A reference whose target is gone.
  final IconData linkBroken;

  /// Adds a reference.
  final IconData addLink;

  /// Replaces a chosen reference with another.
  final IconData replace;

  // Disclosure and direction.

  /// Discloses what is folded below: an accordion's, a sidebar group's or a
  /// field group's header, an open node of a JSON view. It points down, and the
  /// headers that animate turn it a half turn while open.
  final IconData expand;

  /// Opens a list or a menu under its control: a select's, a date's or a colour
  /// field's caret, a menu button's, a filter's, a tab's, a breadcrumb's or a
  /// language pill's.
  final IconData dropdown;

  /// Points the reading direction: a pager's and a calendar's next, a submenu,
  /// a breadcrumb separator, a row that opens, a closed tree or JSON node (a
  /// tree turns it a quarter turn as the node opens). Give it
  /// `matchTextDirection: true`: right to left, it is mirrored.
  final IconData chevronForward;

  /// Points against the reading direction: a pager's and a calendar's previous.
  /// Give it `matchTextDirection: true`, as [chevronForward].
  final IconData chevronBack;

  /// Leads from one thing to the next in the reading direction: a change's
  /// before to after, a key to its value, a source to its target, a moved
  /// block's place to its new one; scrolls a strip of saved views on. Give it
  /// `matchTextDirection: true`, as [chevronForward].
  final IconData arrowForward;

  /// Scrolls a strip of saved views back. Give it `matchTextDirection: true`,
  /// as [chevronForward].
  final IconData arrowBack;

  /// Opens every node of a JSON view.
  final IconData expandAll;

  /// Closes every node of a JSON view.
  final IconData collapseAll;

  /// Opens the sidebar's account menu, beside the account it switches.
  final IconData switcher;

  // Order and arrangement.

  /// A column sorted ascending, and the menu item that sorts it so.
  final IconData sortAscending;

  /// A column sorted descending, and the menu item that sorts it so.
  final IconData sortDescending;

  /// A column that can be sorted and is not.
  final IconData sortable;

  /// Moves a tree node up among its siblings.
  final IconData moveUp;

  /// Moves a tree node down among its siblings.
  final IconData moveDown;

  /// Makes a tree node a child of the one above it.
  final IconData indent;

  /// Moves a tree node out to its parent's level.
  final IconData outdent;

  /// Adds a child under a tree node.
  final IconData addChild;

  /// A tree editor's header entry.
  final IconData sectionHeader;

  /// The grip a row, a tile, a column or a node is dragged by.
  final IconData dragHandle;

  /// Moves a split view's divider left. Physical, never mirrored: it is the way
  /// the divider goes.
  final IconData resizeLeft;

  /// Moves a split view's divider right. Physical, as [resizeLeft].
  final IconData resizeRight;

  /// Moves a split view's divider up.
  final IconData resizeUp;

  /// Moves a split view's divider down.
  final IconData resizeDown;

  // Tables, lists and saved views.

  /// Chooses a table's columns.
  final IconData columns;

  /// Pins a column to the table's start edge.
  final IconData pin;

  /// A pinned column, on the menu item that unpins it.
  final IconData pinned;

  /// Puts a resized column back at its own width.
  final IconData resetWidth;

  /// Shown, or the action that shows: a visible tree node, a password masked
  /// (it reveals it), an insert's preview.
  final IconData show;

  /// Hidden, or the action that hides: a hidden tree node, a password in clear
  /// (it masks it), a column's hide, an insert with no preview.
  final IconData hide;

  /// Selects every row of a list.
  final IconData selectAll;

  /// Lays a media list out as a grid of tiles.
  final IconData gridView;

  /// Lays a media list out as rows.
  final IconData listView;

  /// Saves a list's filters, sort and columns as a view.
  final IconData saveView;

  /// Makes a saved view the default.
  final IconData setDefault;

  /// Marks the one that comes first: the default saved view, a media list's
  /// cover.
  final IconData defaultBadge;

  /// A saved view only its author sees.
  final IconData personal;

  /// A saved view the team shares.
  final IconData shared;

  // Status.

  /// The info tone: an info alert, toast or empty state, a note at a field's
  /// limit.
  final IconData info;

  /// The success tone: a success alert or toast, an upload done, valid code, a
  /// diff with no changes.
  final IconData success;

  /// The warning tone: a warning alert or toast, a field's warning.
  final IconData warning;

  /// The danger tone: an error alert, toast or state, a field's error, a load
  /// or an upload that failed.
  final IconData error;

  /// Complete or chosen, filled: an attention grid with nothing left to see to,
  /// a chosen reference.
  final IconData done;

  /// A step that failed, in its circle.
  final IconData stepError;

  /// A translation whose source changed after it was translated.
  final IconData sourceChanged;

  /// An empty state given neither an icon nor a tone.
  final IconData empty;

  /// A chart with nothing to draw.
  final IconData chart;

  /// A stat that went up.
  final IconData trendUp;

  /// A stat that went down.
  final IconData trendDown;

  /// A stat that held.
  final IconData trendFlat;

  // History and diffs.

  /// A value or a block a change added.
  final IconData diffAdded;

  /// A value or a block a change removed.
  final IconData diffRemoved;

  /// A value a change edited.
  final IconData diffChanged;

  /// A block or a record a change moved, and the place it moved from.
  final IconData diffMoved;

  /// A value a change left as it was.
  final IconData diffUnchanged;

  /// Lays a diff out as one column.
  final IconData diffUnified;

  /// Lays a diff out side by side.
  final IconData diffSplit;

  // Fields.

  /// Locked or secret: a password field's lead, a column that cannot be hidden,
  /// a page the user may not open.
  final IconData lock;

  /// A date field's picker.
  final IconData calendar;

  /// A date and time field's picker.
  final IconData time;

  /// A date range field's picker.
  final IconData dateRange;

  /// Leads a colour field's hex input.
  final IconData hex;

  /// A colour swatch with no colour: a dropper, so it reads as unset.
  final IconData pickColor;

  /// The chosen size in a stock import's list of sizes.
  final IconData radioSelected;

  /// A size not chosen in a stock import's list of sizes.
  final IconData radioUnselected;

  // Media and files.

  /// Uploads, or takes files dropped to upload: a drop zone, an asset picker's
  /// upload tab.
  final IconData upload;

  /// The media library: an asset picker's library tab, an empty library.
  final IconData library;

  /// A media field's add, when it takes images only.
  final IconData addImage;

  /// A media field's add, when it takes other files.
  final IconData addFile;

  /// Stands in for an image not shown: a thumbnail with no picture, a swatch's
  /// tile.
  final IconData image;

  /// An image that failed to load, or is missing.
  final IconData imageBroken;

  /// An image file, by its type: an upload, a media item, an asset.
  final IconData fileImage;

  /// A video file, by its type.
  final IconData fileVideo;

  /// An audio file, by its type.
  final IconData fileAudio;

  /// A document or text file, by its type.
  final IconData fileDocument;

  /// A PDF, by its type.
  final IconData filePdf;

  /// An archive, by its type.
  final IconData fileArchive;

  /// A spreadsheet or CSV, by its type.
  final IconData fileSpreadsheet;

  /// A file of any other type.
  final IconData file;

  /// A stock provider's licence terms, under its images.
  final IconData license;

  /// A stock browser's orientation filter.
  final IconData orientation;

  /// A stock browser's image type filter.
  final IconData imageType;

  /// Zooms a zoomable view in.
  final IconData zoomIn;

  /// Zooms a zoomable view out.
  final IconData zoomOut;

  /// Fits a zoomable view's content to its box.
  final IconData zoomFit;

  /// Turns an image a quarter turn counter-clockwise.
  final IconData rotateLeft;

  /// Turns an image a quarter turn clockwise.
  final IconData rotateRight;

  /// Flips an image left to right; a quarter turn of it flips top to bottom.
  final IconData flip;

  // Comments and notifications.

  /// A field's comments, on the button that counts them.
  final IconData comment;

  /// Starts a comment on a field that has none. A round bubble with a plus: the
  /// square `add_comment` glyph reads as a cropped box at this size.
  final IconData addComment;

  /// Opens a comment thread from its anchor.
  final IconData commentThread;

  /// Sends a comment.
  final IconData send;

  /// The notification center's trigger, and its empty state.
  final IconData notifications;

  /// Marks a notification read.
  final IconData markRead;

  /// Marks a notification unread.
  final IconData markUnread;

  // Frame.

  /// The light appearance, in the appearance picker.
  final IconData themeLight;

  /// The dark appearance, in the appearance picker.
  final IconData themeDark;

  /// The appearance that follows the system, in the appearance picker.
  final IconData themeSystem;

  /// Leads a sign-in form's email field.
  final IconData email;

  const AdminIcons({
    this.close = Icons.close_rounded,
    this.check = Icons.check_rounded,
    this.indeterminate = Icons.remove_rounded,
    this.add = Icons.add_rounded,
    this.increment = Icons.add_rounded,
    this.decrement = Icons.remove_rounded,
    this.more = Icons.more_horiz_rounded,
    this.moreVertical = Icons.more_vert,
    this.menu = Icons.menu_rounded,
    this.search = Icons.search_rounded,
    this.noResults = Icons.search_off_rounded,
    this.filter = Icons.filter_list_rounded,
    this.matchedField = Icons.title_rounded,
    this.matchedContent = Icons.notes_rounded,
    this.jumpTo = Icons.my_location_outlined,
    this.enterKey = Icons.keyboard_return,
    this.edit = Icons.edit_outlined,
    this.copy = Icons.copy_rounded,
    this.delete = Icons.delete_outline_rounded,
    this.undo = Icons.undo_rounded,
    this.retry = Icons.refresh_rounded,
    this.reset = Icons.restart_alt,
    this.history = Icons.history,
    this.restore = Icons.history_rounded,
    this.link = Icons.link_rounded,
    this.linkBroken = Icons.link_off_rounded,
    this.addLink = Icons.add_link_rounded,
    this.replace = Icons.swap_horiz_rounded,
    this.expand = Icons.expand_more_rounded,
    this.dropdown = Icons.keyboard_arrow_down_rounded,
    this.chevronForward = Icons.chevron_right_rounded,
    this.chevronBack = Icons.chevron_left_rounded,
    this.arrowForward = Icons.arrow_forward_rounded,
    this.arrowBack = Icons.arrow_back_rounded,
    this.expandAll = Icons.unfold_more_rounded,
    this.collapseAll = Icons.unfold_less_rounded,
    this.switcher = Icons.unfold_more_rounded,
    this.sortAscending = Icons.arrow_upward,
    this.sortDescending = Icons.arrow_downward,
    this.sortable = Icons.unfold_more,
    this.moveUp = Icons.arrow_upward_rounded,
    this.moveDown = Icons.arrow_downward_rounded,
    this.indent = Icons.format_indent_increase_rounded,
    this.outdent = Icons.format_indent_decrease_rounded,
    this.addChild = Icons.subdirectory_arrow_right_rounded,
    this.sectionHeader = Icons.segment_rounded,
    this.dragHandle = Icons.drag_indicator_rounded,
    this.resizeLeft = Icons.west_rounded, // Physical: the way a divider goes.
    this.resizeRight = Icons.east_rounded, // Physical: the way a divider goes.
    this.resizeUp = Icons.north_rounded,
    this.resizeDown = Icons.south_rounded,
    this.columns = Icons.view_column_outlined,
    this.pin = Icons.push_pin_outlined,
    this.pinned = Icons.push_pin,
    this.resetWidth = Icons.width_normal_outlined,
    this.show = Icons.visibility_outlined,
    this.hide = Icons.visibility_off_outlined,
    this.selectAll = Icons.select_all_rounded,
    this.gridView = Icons.grid_view_rounded,
    this.listView = Icons.view_list_rounded,
    this.saveView = Icons.bookmark_added_outlined,
    this.setDefault = Icons.star_outline_rounded,
    this.defaultBadge = Icons.star_rounded,
    this.personal = Icons.person_outline,
    this.shared = Icons.group_outlined,
    this.info = Icons.info_outline_rounded,
    this.success = Icons.check_circle_outline_rounded,
    this.warning = Icons.warning_amber_rounded,
    this.error = Icons.error_outline_rounded,
    this.done = Icons.check_circle_rounded,
    this.stepError = Icons.priority_high_rounded,
    this.sourceChanged = Icons.sync_problem_rounded,
    this.empty = Icons.inbox_outlined,
    this.chart = Icons.bar_chart_rounded,
    this.trendUp = Icons.arrow_upward_rounded,
    this.trendDown = Icons.arrow_downward_rounded,
    this.trendFlat = Icons.remove_rounded,
    this.diffAdded = Icons.add_rounded,
    this.diffRemoved = Icons.remove_rounded,
    this.diffChanged = Icons.edit_outlined,
    this.diffMoved = Icons.swap_vert_rounded,
    this.diffUnchanged = Icons.drag_handle_rounded,
    this.diffUnified = Icons.notes_rounded,
    this.diffSplit = Icons.vertical_split_outlined,
    this.lock = Icons.lock_outline_rounded,
    this.calendar = Icons.calendar_month_outlined,
    this.time = Icons.schedule_rounded,
    this.dateRange = Icons.date_range_outlined,
    this.hex = Icons.tag_rounded,
    this.pickColor = Icons.colorize_rounded,
    this.radioSelected = Icons.radio_button_checked_rounded,
    this.radioUnselected = Icons.radio_button_unchecked_rounded,
    this.upload = Icons.cloud_upload_outlined,
    this.library = Icons.photo_library_outlined,
    this.addImage = Icons.add_photo_alternate_outlined,
    this.addFile = Icons.upload_file_outlined,
    this.image = Icons.image_outlined,
    this.imageBroken = Icons.broken_image_outlined,
    this.fileImage = Icons.image_outlined,
    this.fileVideo = Icons.movie_outlined,
    this.fileAudio = Icons.audiotrack_outlined,
    this.fileDocument = Icons.description_outlined,
    this.filePdf = Icons.picture_as_pdf_outlined,
    this.fileArchive = Icons.folder_zip_outlined,
    this.fileSpreadsheet = Icons.table_chart_outlined,
    this.file = Icons.insert_drive_file_outlined,
    this.license = Icons.workspace_premium_outlined,
    this.orientation = Icons.crop_rounded,
    this.imageType = Icons.category_outlined,
    this.zoomIn = Icons.add_rounded,
    this.zoomOut = Icons.remove_rounded,
    this.zoomFit = Icons.fit_screen_rounded,
    this.rotateLeft = Icons.rotate_90_degrees_ccw_outlined,
    this.rotateRight = Icons.rotate_90_degrees_cw_outlined,
    this.flip = Icons.flip,
    this.comment = Icons.mode_comment_outlined,
    this.addComment = Icons.maps_ugc_outlined,
    this.commentThread = Icons.mode_comment,
    this.send = Icons.arrow_upward,
    this.notifications = Icons.notifications_none_rounded,
    this.markRead = Icons.mark_email_read_outlined,
    this.markUnread = Icons.mark_email_unread_outlined,
    this.themeLight = Icons.light_mode_outlined,
    this.themeDark = Icons.dark_mode_outlined,
    this.themeSystem = Icons.brightness_auto_outlined,
    this.email = Icons.mail_outline_rounded,
  });

  /// A copy with the given glyphs replaced.
  AdminIcons copyWith({
    IconData? close,
    IconData? check,
    IconData? indeterminate,
    IconData? add,
    IconData? increment,
    IconData? decrement,
    IconData? more,
    IconData? moreVertical,
    IconData? menu,
    IconData? search,
    IconData? noResults,
    IconData? filter,
    IconData? matchedField,
    IconData? matchedContent,
    IconData? jumpTo,
    IconData? enterKey,
    IconData? edit,
    IconData? copy,
    IconData? delete,
    IconData? undo,
    IconData? retry,
    IconData? reset,
    IconData? history,
    IconData? restore,
    IconData? link,
    IconData? linkBroken,
    IconData? addLink,
    IconData? replace,
    IconData? expand,
    IconData? dropdown,
    IconData? chevronForward,
    IconData? chevronBack,
    IconData? arrowForward,
    IconData? arrowBack,
    IconData? expandAll,
    IconData? collapseAll,
    IconData? switcher,
    IconData? sortAscending,
    IconData? sortDescending,
    IconData? sortable,
    IconData? moveUp,
    IconData? moveDown,
    IconData? indent,
    IconData? outdent,
    IconData? addChild,
    IconData? sectionHeader,
    IconData? dragHandle,
    IconData? resizeLeft,
    IconData? resizeRight,
    IconData? resizeUp,
    IconData? resizeDown,
    IconData? columns,
    IconData? pin,
    IconData? pinned,
    IconData? resetWidth,
    IconData? show,
    IconData? hide,
    IconData? selectAll,
    IconData? gridView,
    IconData? listView,
    IconData? saveView,
    IconData? setDefault,
    IconData? defaultBadge,
    IconData? personal,
    IconData? shared,
    IconData? info,
    IconData? success,
    IconData? warning,
    IconData? error,
    IconData? done,
    IconData? stepError,
    IconData? sourceChanged,
    IconData? empty,
    IconData? chart,
    IconData? trendUp,
    IconData? trendDown,
    IconData? trendFlat,
    IconData? diffAdded,
    IconData? diffRemoved,
    IconData? diffChanged,
    IconData? diffMoved,
    IconData? diffUnchanged,
    IconData? diffUnified,
    IconData? diffSplit,
    IconData? lock,
    IconData? calendar,
    IconData? time,
    IconData? dateRange,
    IconData? hex,
    IconData? pickColor,
    IconData? radioSelected,
    IconData? radioUnselected,
    IconData? upload,
    IconData? library,
    IconData? addImage,
    IconData? addFile,
    IconData? image,
    IconData? imageBroken,
    IconData? fileImage,
    IconData? fileVideo,
    IconData? fileAudio,
    IconData? fileDocument,
    IconData? filePdf,
    IconData? fileArchive,
    IconData? fileSpreadsheet,
    IconData? file,
    IconData? license,
    IconData? orientation,
    IconData? imageType,
    IconData? zoomIn,
    IconData? zoomOut,
    IconData? zoomFit,
    IconData? rotateLeft,
    IconData? rotateRight,
    IconData? flip,
    IconData? comment,
    IconData? addComment,
    IconData? commentThread,
    IconData? send,
    IconData? notifications,
    IconData? markRead,
    IconData? markUnread,
    IconData? themeLight,
    IconData? themeDark,
    IconData? themeSystem,
    IconData? email,
  }) => AdminIcons(
    close: close ?? this.close,
    check: check ?? this.check,
    indeterminate: indeterminate ?? this.indeterminate,
    add: add ?? this.add,
    increment: increment ?? this.increment,
    decrement: decrement ?? this.decrement,
    more: more ?? this.more,
    moreVertical: moreVertical ?? this.moreVertical,
    menu: menu ?? this.menu,
    search: search ?? this.search,
    noResults: noResults ?? this.noResults,
    filter: filter ?? this.filter,
    matchedField: matchedField ?? this.matchedField,
    matchedContent: matchedContent ?? this.matchedContent,
    jumpTo: jumpTo ?? this.jumpTo,
    enterKey: enterKey ?? this.enterKey,
    edit: edit ?? this.edit,
    copy: copy ?? this.copy,
    delete: delete ?? this.delete,
    undo: undo ?? this.undo,
    retry: retry ?? this.retry,
    reset: reset ?? this.reset,
    history: history ?? this.history,
    restore: restore ?? this.restore,
    link: link ?? this.link,
    linkBroken: linkBroken ?? this.linkBroken,
    addLink: addLink ?? this.addLink,
    replace: replace ?? this.replace,
    expand: expand ?? this.expand,
    dropdown: dropdown ?? this.dropdown,
    chevronForward: chevronForward ?? this.chevronForward,
    chevronBack: chevronBack ?? this.chevronBack,
    arrowForward: arrowForward ?? this.arrowForward,
    arrowBack: arrowBack ?? this.arrowBack,
    expandAll: expandAll ?? this.expandAll,
    collapseAll: collapseAll ?? this.collapseAll,
    switcher: switcher ?? this.switcher,
    sortAscending: sortAscending ?? this.sortAscending,
    sortDescending: sortDescending ?? this.sortDescending,
    sortable: sortable ?? this.sortable,
    moveUp: moveUp ?? this.moveUp,
    moveDown: moveDown ?? this.moveDown,
    indent: indent ?? this.indent,
    outdent: outdent ?? this.outdent,
    addChild: addChild ?? this.addChild,
    sectionHeader: sectionHeader ?? this.sectionHeader,
    dragHandle: dragHandle ?? this.dragHandle,
    resizeLeft: resizeLeft ?? this.resizeLeft,
    resizeRight: resizeRight ?? this.resizeRight,
    resizeUp: resizeUp ?? this.resizeUp,
    resizeDown: resizeDown ?? this.resizeDown,
    columns: columns ?? this.columns,
    pin: pin ?? this.pin,
    pinned: pinned ?? this.pinned,
    resetWidth: resetWidth ?? this.resetWidth,
    show: show ?? this.show,
    hide: hide ?? this.hide,
    selectAll: selectAll ?? this.selectAll,
    gridView: gridView ?? this.gridView,
    listView: listView ?? this.listView,
    saveView: saveView ?? this.saveView,
    setDefault: setDefault ?? this.setDefault,
    defaultBadge: defaultBadge ?? this.defaultBadge,
    personal: personal ?? this.personal,
    shared: shared ?? this.shared,
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    done: done ?? this.done,
    stepError: stepError ?? this.stepError,
    sourceChanged: sourceChanged ?? this.sourceChanged,
    empty: empty ?? this.empty,
    chart: chart ?? this.chart,
    trendUp: trendUp ?? this.trendUp,
    trendDown: trendDown ?? this.trendDown,
    trendFlat: trendFlat ?? this.trendFlat,
    diffAdded: diffAdded ?? this.diffAdded,
    diffRemoved: diffRemoved ?? this.diffRemoved,
    diffChanged: diffChanged ?? this.diffChanged,
    diffMoved: diffMoved ?? this.diffMoved,
    diffUnchanged: diffUnchanged ?? this.diffUnchanged,
    diffUnified: diffUnified ?? this.diffUnified,
    diffSplit: diffSplit ?? this.diffSplit,
    lock: lock ?? this.lock,
    calendar: calendar ?? this.calendar,
    time: time ?? this.time,
    dateRange: dateRange ?? this.dateRange,
    hex: hex ?? this.hex,
    pickColor: pickColor ?? this.pickColor,
    radioSelected: radioSelected ?? this.radioSelected,
    radioUnselected: radioUnselected ?? this.radioUnselected,
    upload: upload ?? this.upload,
    library: library ?? this.library,
    addImage: addImage ?? this.addImage,
    addFile: addFile ?? this.addFile,
    image: image ?? this.image,
    imageBroken: imageBroken ?? this.imageBroken,
    fileImage: fileImage ?? this.fileImage,
    fileVideo: fileVideo ?? this.fileVideo,
    fileAudio: fileAudio ?? this.fileAudio,
    fileDocument: fileDocument ?? this.fileDocument,
    filePdf: filePdf ?? this.filePdf,
    fileArchive: fileArchive ?? this.fileArchive,
    fileSpreadsheet: fileSpreadsheet ?? this.fileSpreadsheet,
    file: file ?? this.file,
    license: license ?? this.license,
    orientation: orientation ?? this.orientation,
    imageType: imageType ?? this.imageType,
    zoomIn: zoomIn ?? this.zoomIn,
    zoomOut: zoomOut ?? this.zoomOut,
    zoomFit: zoomFit ?? this.zoomFit,
    rotateLeft: rotateLeft ?? this.rotateLeft,
    rotateRight: rotateRight ?? this.rotateRight,
    flip: flip ?? this.flip,
    comment: comment ?? this.comment,
    addComment: addComment ?? this.addComment,
    commentThread: commentThread ?? this.commentThread,
    send: send ?? this.send,
    notifications: notifications ?? this.notifications,
    markRead: markRead ?? this.markRead,
    markUnread: markUnread ?? this.markUnread,
    themeLight: themeLight ?? this.themeLight,
    themeDark: themeDark ?? this.themeDark,
    themeSystem: themeSystem ?? this.themeSystem,
    email: email ?? this.email,
  );

  /// [a] below the midpoint, [b] from it: a glyph does not interpolate.
  static AdminIcons lerp(AdminIcons a, AdminIcons b, double t) =>
      t < 0.5 ? a : b;

  /// Every slot, by name, in declaration order.
  List<(String, IconData)> get _slots => [
    ('close', close),
    ('check', check),
    ('indeterminate', indeterminate),
    ('add', add),
    ('increment', increment),
    ('decrement', decrement),
    ('more', more),
    ('moreVertical', moreVertical),
    ('menu', menu),
    ('search', search),
    ('noResults', noResults),
    ('filter', filter),
    ('matchedField', matchedField),
    ('matchedContent', matchedContent),
    ('jumpTo', jumpTo),
    ('enterKey', enterKey),
    ('edit', edit),
    ('copy', copy),
    ('delete', delete),
    ('undo', undo),
    ('retry', retry),
    ('reset', reset),
    ('history', history),
    ('restore', restore),
    ('link', link),
    ('linkBroken', linkBroken),
    ('addLink', addLink),
    ('replace', replace),
    ('expand', expand),
    ('dropdown', dropdown),
    ('chevronForward', chevronForward),
    ('chevronBack', chevronBack),
    ('arrowForward', arrowForward),
    ('arrowBack', arrowBack),
    ('expandAll', expandAll),
    ('collapseAll', collapseAll),
    ('switcher', switcher),
    ('sortAscending', sortAscending),
    ('sortDescending', sortDescending),
    ('sortable', sortable),
    ('moveUp', moveUp),
    ('moveDown', moveDown),
    ('indent', indent),
    ('outdent', outdent),
    ('addChild', addChild),
    ('sectionHeader', sectionHeader),
    ('dragHandle', dragHandle),
    ('resizeLeft', resizeLeft),
    ('resizeRight', resizeRight),
    ('resizeUp', resizeUp),
    ('resizeDown', resizeDown),
    ('columns', columns),
    ('pin', pin),
    ('pinned', pinned),
    ('resetWidth', resetWidth),
    ('show', show),
    ('hide', hide),
    ('selectAll', selectAll),
    ('gridView', gridView),
    ('listView', listView),
    ('saveView', saveView),
    ('setDefault', setDefault),
    ('defaultBadge', defaultBadge),
    ('personal', personal),
    ('shared', shared),
    ('info', info),
    ('success', success),
    ('warning', warning),
    ('error', error),
    ('done', done),
    ('stepError', stepError),
    ('sourceChanged', sourceChanged),
    ('empty', empty),
    ('chart', chart),
    ('trendUp', trendUp),
    ('trendDown', trendDown),
    ('trendFlat', trendFlat),
    ('diffAdded', diffAdded),
    ('diffRemoved', diffRemoved),
    ('diffChanged', diffChanged),
    ('diffMoved', diffMoved),
    ('diffUnchanged', diffUnchanged),
    ('diffUnified', diffUnified),
    ('diffSplit', diffSplit),
    ('lock', lock),
    ('calendar', calendar),
    ('time', time),
    ('dateRange', dateRange),
    ('hex', hex),
    ('pickColor', pickColor),
    ('radioSelected', radioSelected),
    ('radioUnselected', radioUnselected),
    ('upload', upload),
    ('library', library),
    ('addImage', addImage),
    ('addFile', addFile),
    ('image', image),
    ('imageBroken', imageBroken),
    ('fileImage', fileImage),
    ('fileVideo', fileVideo),
    ('fileAudio', fileAudio),
    ('fileDocument', fileDocument),
    ('filePdf', filePdf),
    ('fileArchive', fileArchive),
    ('fileSpreadsheet', fileSpreadsheet),
    ('file', file),
    ('license', license),
    ('orientation', orientation),
    ('imageType', imageType),
    ('zoomIn', zoomIn),
    ('zoomOut', zoomOut),
    ('zoomFit', zoomFit),
    ('rotateLeft', rotateLeft),
    ('rotateRight', rotateRight),
    ('flip', flip),
    ('comment', comment),
    ('addComment', addComment),
    ('commentThread', commentThread),
    ('send', send),
    ('notifications', notifications),
    ('markRead', markRead),
    ('markUnread', markUnread),
    ('themeLight', themeLight),
    ('themeDark', themeDark),
    ('themeSystem', themeSystem),
    ('email', email),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminIcons && listEquals(other._slots, _slots);

  @override
  int get hashCode => Object.hashAll(_slots);

  /// Names the slots that are not the kit's own glyph.
  @override
  String toString() {
    final kit = const AdminIcons()._slots;
    final own = [
      for (final (i, (name, glyph)) in _slots.indexed)
        if (glyph != kit[i].$2)
          '$name U+${glyph.codePoint.toRadixString(16).toUpperCase()} '
              '${glyph.fontFamily}',
    ];
    return 'AdminIcons(${own.isEmpty ? 'the kit\'s' : own.join(', ')})';
  }
}
