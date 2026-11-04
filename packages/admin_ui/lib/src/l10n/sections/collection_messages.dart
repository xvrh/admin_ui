import '../messages.dart';

/// Strings for the collection kit: the table, toolbar, filters, pager and
/// views.
///
/// [CollectionMessagesEn], [CollectionMessagesFr] and [CollectionMessagesAr]
/// each extend this class directly, so a member added here without its French
/// or Arabic text fails to compile. Add a message to all three in the same
/// edit.
abstract class CollectionMessages extends AdminMessages {
  const CollectionMessages(super.localeName);

  // ── table and cards ──

  /// The title of an empty collection that no filter narrowed.
  String get nothingHereYet;

  /// Under "No results": a search or a filter left nothing.
  String get noResultsMessage;

  /// Clears the search and every filter of a collection.
  String get clearFilters;

  /// A column menu entry.
  String get sortAscending;

  /// A column menu entry.
  String get sortDescending;

  /// A column menu entry that returns the rows to their unsorted order.
  String get clearSort;

  /// A column menu entry that freezes the column at the table's start.
  String get pinColumn;

  /// A column menu entry that lets a pinned column scroll again.
  String get unpinColumn;

  /// A column menu entry that returns a resized column to its width.
  String get resetWidth;

  /// A column menu entry.
  String get hideColumn;

  /// A column menu entry that opens the column chooser, with an ellipsis.
  String get manageColumns;

  /// The accessible action that opens a column's menu.
  String get columnOptions;

  /// The accessible name of [column]'s menu button.
  String columnOptionsFor(String column);

  /// A sortable column header as read aloud, while another column sorts.
  String notSorted(String column);

  /// A column header as read aloud, while it sorts ascending.
  String sortedAscending(String column);

  /// A column header as read aloud, while it sorts descending.
  String sortedDescending(String column);

  /// The accessible name of the checkbox of the [row]th row, from 1.
  String selectRow(int row);

  /// The accessible name of the header checkbox.
  String get selectAllOnPage;

  /// The accessible name of the checkbox of the [card]th card, from 1.
  String selectCard(int card);

  /// A page size choice: "25 / page".
  String perPage(int size);

  // ── selection bar ──

  /// Clears the selection; short, beside the count.
  String get clear;

  /// Every one of the [total] rows a query matches is selected.
  String allSelected(int total);

  /// [selection], an app's own "{total} selected" label such as "137
  /// products selected", said of every row the query matches.
  String allOf(int total, String selection);

  /// Selects every one of the [total] rows the query matches.
  String selectAllCount(int total);

  // ── filters ──

  /// A yes/no filter's yes.
  String get yes;

  /// A yes/no filter's no.
  String get no;

  /// A date range bound left open.
  String get any;

  /// The label of a date range's first day.
  String get from;

  /// The label of a date range's last day.
  String get to;

  /// The placeholder of a number range's lower bound.
  String get min;

  /// The placeholder of a number range's upper bound.
  String get max;

  /// Clears every filter.
  String get clearAll;

  /// The placeholder of a text filter.
  String get containsPlaceholder;

  /// The accessible name of the × that clears [field]'s filter.
  String clearFilter(String field);

  /// What a filter pill puts between its field and its value.
  String get valueSeparator;

  /// A filter pill as read aloud: [field] and its [value].
  String filterValue(String field, String value);

  /// A number range, either bound of which may be open (null), both
  /// already formatted.
  String numberRange(String? min, String? max);

  /// A date range, either bound of which may be open (null), both
  /// already formatted.
  String dateRange(String? from, String? to);

  /// A typed search term, quoted.
  String quoted(String text);

  /// The chosen [labels] of an options filter, at least one: all of them
  /// up to two, else the first and how many more.
  String optionsSummary(List<String> labels);

  // ── column chooser ──

  /// The column chooser's title and its button.
  String get columns;

  /// The column chooser button's [label] while [hidden] columns are hidden.
  String withHidden(String label, int hidden);

  /// The placeholder of the column chooser's search box.
  String get findColumn;

  /// Shows every listed column.
  String get showAll;

  /// Hides every listed column that can be hidden.
  String get hideAll;

  /// The column chooser's search found nothing.
  String get noMatchingColumns;

  /// The accessible name of the lock on a column that can't be hidden.
  String get locked;

  // ── saved views ──

  /// Moves a view tab one place to the left, as drawn.
  String get moveLeft;

  /// Moves a view tab one place to the right, as drawn.
  String get moveRight;

  /// A view menu entry.
  String get rename;

  /// A view menu entry.
  String get duplicate;

  /// A view menu entry that makes the view open first.
  String get setAsDefault;

  /// The overflow menu of the view tabs.
  String get moreViews;

  /// The accessible name of the + that saves the current query as a view.
  String get saveAsNewView;

  /// The accessible name of the default view's star.
  String get defaultView;

  /// The accessible name of [view]'s menu.
  String viewOptions(String view);

  /// The name of a duplicated view called [name].
  String copyOf(String name);

  /// The saved-views tab that applies no view: every row.
  String get allViews;

  /// The accessible name of the compact saved-views menu, which shows the
  /// active [view].
  String currentView(String view);

  /// The title of the dialog that names a new view.
  String get saveViewTitle;

  /// Under [saveViewTitle]: what a view keeps.
  String get saveViewDescription;

  /// The title of the dialog that renames a view.
  String get renameViewTitle;

  /// The label of a view's name field.
  String get viewName;

  /// The error of a view's name field left empty.
  String get viewNameRequired;

  /// The label of the choice of who sees a view.
  String get viewScope;

  /// A view only its author sees.
  String get personalView;

  /// Under [personalView].
  String get personalViewDescription;

  /// A view the whole team sees.
  String get sharedView;

  /// Under [sharedView].
  String get sharedViewDescription;

  // ── kanban and search ──

  /// An empty kanban column while a card is dragged.
  String get dropHere;

  /// An empty kanban column.
  String get noItems;

  /// The accessible action that moves a card to [column].
  String moveTo(String column);

  /// A search match found in [field], a field's label as the form shows
  /// it, capitalised or not: "Matched: Name".
  String matchedIn(String field);
}

/// English [CollectionMessages]. Subclass it to override a few strings.
class CollectionMessagesEn extends CollectionMessages {
  const CollectionMessagesEn([super.localeName = 'en']);

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get noResultsMessage =>
      'Nothing matches the current search or filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get sortAscending => 'Sort ascending';

  @override
  String get sortDescending => 'Sort descending';

  @override
  String get clearSort => 'Clear sort';

  @override
  String get pinColumn => 'Pin column';

  @override
  String get unpinColumn => 'Unpin column';

  @override
  String get resetWidth => 'Reset width';

  @override
  String get hideColumn => 'Hide column';

  @override
  String get manageColumns => 'Manage columns…';

  @override
  String get columnOptions => 'Column options';

  @override
  String columnOptionsFor(String column) => 'Column options for $column';

  @override
  String notSorted(String column) => '$column, not sorted';

  @override
  String sortedAscending(String column) => '$column, sorted ascending';

  @override
  String sortedDescending(String column) => '$column, sorted descending';

  @override
  String selectRow(int row) => 'Select row ${number(row)}';

  @override
  String get selectAllOnPage => 'Select all on page';

  @override
  String selectCard(int card) => 'Select card ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / page';

  @override
  String get clear => 'Clear';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nothing selected',
    one: '${number(total)} selected',
    other: 'All ${number(total)} selected',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'All $selection');

  @override
  String selectAllCount(int total) => 'Select all ${number(total)}';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get any => 'Any';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get clearAll => 'Clear all';

  @override
  String get containsPlaceholder => 'Contains…';

  @override
  String clearFilter(String field) => 'Clear $field filter';

  @override
  String get valueSeparator => ': ';

  @override
  String filterValue(String field, String value) => '$field: $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'From $from',
    (null, final to?) => 'Until $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '“$text”';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Columns';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)} hidden)';

  @override
  String get findColumn => 'Find a column';

  @override
  String get showAll => 'Show all';

  @override
  String get hideAll => 'Hide all';

  @override
  String get noMatchingColumns => 'No matching columns';

  @override
  String get locked => 'Locked';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get rename => 'Rename';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get moreViews => 'More views';

  @override
  String get saveAsNewView => 'Save current as a new view';

  @override
  String get defaultView => 'Default';

  @override
  String viewOptions(String view) => '$view options';

  @override
  String copyOf(String name) => '$name copy';

  @override
  String get allViews => 'All';

  @override
  String currentView(String view) => 'View: $view';

  @override
  String get saveViewTitle => 'Save view';

  @override
  String get saveViewDescription =>
      'Keeps the current filters and sort one click away.';

  @override
  String get renameViewTitle => 'Rename view';

  @override
  String get viewName => 'Name';

  @override
  String get viewNameRequired => 'Give the view a name.';

  @override
  String get viewScope => 'Who sees it';

  @override
  String get personalView => 'Personal';

  @override
  String get personalViewDescription => 'Only you see it';

  @override
  String get sharedView => 'Shared';

  @override
  String get sharedViewDescription => 'Everyone on the team sees it';

  @override
  String get dropHere => 'Drop here';

  @override
  String get noItems => 'No items';

  @override
  String moveTo(String column) => 'Move to $column';

  @override
  String matchedIn(String field) => 'Matched: $field';
}

/// French [CollectionMessages].
class CollectionMessagesFr extends CollectionMessages {
  const CollectionMessagesFr([super.localeName = 'fr']);

  @override
  String get nothingHereYet => 'Rien pour l’instant';

  @override
  String get noResultsMessage =>
      'Rien ne correspond à la recherche ou aux filtres actuels.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get sortAscending => 'Tri croissant';

  @override
  String get sortDescending => 'Tri décroissant';

  @override
  String get clearSort => 'Annuler le tri';

  @override
  String get pinColumn => 'Épingler la colonne';

  @override
  String get unpinColumn => 'Détacher la colonne';

  @override
  String get resetWidth => 'Rétablir la largeur';

  @override
  String get hideColumn => 'Masquer la colonne';

  @override
  String get manageColumns => 'Gérer les colonnes…';

  @override
  String get columnOptions => 'Options de colonne';

  @override
  String columnOptionsFor(String column) => 'Options de la colonne $column';

  @override
  String notSorted(String column) => '$column, non trié';

  @override
  String sortedAscending(String column) => '$column, tri croissant';

  @override
  String sortedDescending(String column) => '$column, tri décroissant';

  @override
  String selectRow(int row) => 'Sélectionner la ligne ${number(row)}';

  @override
  String get selectAllOnPage => 'Tout sélectionner sur la page';

  @override
  String selectCard(int card) => 'Sélectionner la carte ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / page';

  @override
  String get clear => 'Effacer';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Aucune sélection',
    one: '${number(total)} sélectionné',
    other: 'Les ${number(total)} sont sélectionnés',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Tous les résultats : $selection');

  @override
  String selectAllCount(int total) => 'Tout sélectionner (${number(total)})';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get any => 'Indifférent';

  @override
  String get from => 'Début';

  @override
  String get to => 'Fin';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get containsPlaceholder => 'Contient…';

  @override
  String clearFilter(String field) => 'Effacer le filtre $field';

  /// French sets a no-break space before the colon.
  @override
  String get valueSeparator => ' : ';

  @override
  String filterValue(String field, String value) => '$field : $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'À partir du $from',
    (null, final to?) => 'Jusqu’au $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '« $text »';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Colonnes';

  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} masquée)',
    other: '$label (${number(hidden)} masquées)',
  );

  @override
  String get findColumn => 'Rechercher une colonne';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get hideAll => 'Tout masquer';

  @override
  String get noMatchingColumns => 'Aucune colonne correspondante';

  @override
  String get locked => 'Verrouillée';

  @override
  String get moveLeft => 'Déplacer vers la gauche';

  @override
  String get moveRight => 'Déplacer vers la droite';

  @override
  String get rename => 'Renommer';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get setAsDefault => 'Définir par défaut';

  @override
  String get moreViews => 'Plus de vues';

  @override
  String get saveAsNewView => 'Enregistrer comme nouvelle vue';

  @override
  String get defaultView => 'Par défaut';

  @override
  String viewOptions(String view) => 'Options de la vue $view';

  @override
  String copyOf(String name) => '$name (copie)';

  @override
  String get allViews => 'Tout';

  @override
  String currentView(String view) => 'Vue : $view';

  @override
  String get saveViewTitle => 'Enregistrer la vue';

  @override
  String get saveViewDescription =>
      'Garde les filtres et le tri actuels à un clic.';

  @override
  String get renameViewTitle => 'Renommer la vue';

  @override
  String get viewName => 'Nom';

  @override
  String get viewNameRequired => 'Donnez un nom à la vue.';

  @override
  String get viewScope => 'Qui la voit';

  @override
  String get personalView => 'Personnelle';

  @override
  String get personalViewDescription => 'Vous seul la voyez';

  @override
  String get sharedView => 'Partagée';

  @override
  String get sharedViewDescription => 'Toute l’équipe la voit';

  @override
  String get dropHere => 'Déposer ici';

  @override
  String get noItems => 'Aucun élément';

  @override
  String moveTo(String column) => 'Déplacer vers $column';

  @override
  String matchedIn(String field) => 'Correspondance : $field';
}

/// Arabic [CollectionMessages].
class CollectionMessagesAr extends CollectionMessages {
  const CollectionMessagesAr([super.localeName = 'ar']);

  @override
  String get nothingHereYet => 'لا يوجد شيء هنا بعد';

  @override
  String get noResultsMessage => 'لا شيء يطابق البحث أو عوامل التصفية الحالية.';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get sortAscending => 'ترتيب تصاعدي';

  @override
  String get sortDescending => 'ترتيب تنازلي';

  @override
  String get clearSort => 'إلغاء الترتيب';

  @override
  String get pinColumn => 'تثبيت العمود';

  @override
  String get unpinColumn => 'إلغاء تثبيت العمود';

  @override
  String get resetWidth => 'إعادة ضبط العرض';

  @override
  String get hideColumn => 'إخفاء العمود';

  @override
  String get manageColumns => 'إدارة الأعمدة…';

  @override
  String get columnOptions => 'خيارات العمود';

  @override
  String columnOptionsFor(String column) => 'خيارات العمود $column';

  @override
  String notSorted(String column) => '$column، غير مرتَّب';

  @override
  String sortedAscending(String column) => '$column، مرتَّب تصاعديًا';

  @override
  String sortedDescending(String column) => '$column، مرتَّب تنازليًا';

  @override
  String selectRow(int row) => 'تحديد الصف ${number(row)}';

  @override
  String get selectAllOnPage => 'تحديد الكل في الصفحة';

  @override
  String selectCard(int card) => 'تحديد البطاقة ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / صفحة';

  @override
  String get clear => 'مسح';

  /// The count follows the definite noun, so it takes no agreement from 3
  /// up.
  @override
  String allSelected(int total) => plural(
    total,
    zero: 'لم يُحدَّد أي عنصر',
    one: 'العنصر الوحيد محدد',
    two: 'العنصران كلاهما محددان',
    few: 'جميع العناصر الـ${number(total)} محددة',
    many: 'جميع العناصر الـ${number(total)} محددة',
    other: 'جميع العناصر الـ${number(total)} محددة',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'كل النتائج: $selection');

  @override
  String selectAllCount(int total) => 'تحديد الكل (${number(total)})';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get any => 'غير محدد';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get min => 'الحد الأدنى';

  @override
  String get max => 'الحد الأقصى';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get containsPlaceholder => 'يحتوي على…';

  @override
  String clearFilter(String field) => 'مسح عامل التصفية $field';

  @override
  String get valueSeparator => ': ';

  @override
  String filterValue(String field, String value) => '$field: $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'من $from',
    (null, final to?) => 'حتى $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '”$text“';

  /// Counts the others in words: a sign before a number would land on the
  /// wrong side of it in right-to-left text.
  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a، $b',
    [final first, ...final rest] => plural(
      rest.length,
      one: '$first وخيار آخر',
      two: '$first وخياران آخران',
      few: '$first و${number(rest.length)} خيارات أخرى',
      many: '$first و${number(rest.length)} خيارًا آخر',
      other: '$first و${number(rest.length)} خيار آخر',
    ),
    [] => '',
  };

  @override
  String get columns => 'الأعمدة';

  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (عمود مخفي)',
    two: '$label (عمودان مخفيان)',
    few: '$label (${number(hidden)} أعمدة مخفية)',
    many: '$label (${number(hidden)} عمودًا مخفيًا)',
    other: '$label (${number(hidden)} عمود مخفي)',
  );

  @override
  String get findColumn => 'البحث عن عمود';

  @override
  String get showAll => 'إظهار الكل';

  @override
  String get hideAll => 'إخفاء الكل';

  @override
  String get noMatchingColumns => 'لا توجد أعمدة مطابقة';

  @override
  String get locked => 'مقفل';

  @override
  String get moveLeft => 'نقل إلى اليسار';

  @override
  String get moveRight => 'نقل إلى اليمين';

  @override
  String get rename => 'إعادة التسمية';

  @override
  String get duplicate => 'تكرار';

  @override
  String get setAsDefault => 'تعيين كافتراضي';

  @override
  String get moreViews => 'طرق عرض إضافية';

  @override
  String get saveAsNewView => 'حفظ الحالي كطريقة عرض جديدة';

  @override
  String get defaultView => 'افتراضي';

  @override
  String viewOptions(String view) => 'خيارات $view';

  @override
  String copyOf(String name) => '$name (نسخة)';

  @override
  String get allViews => 'الكل';

  @override
  String currentView(String view) => 'طريقة العرض: $view';

  @override
  String get saveViewTitle => 'حفظ طريقة العرض';

  @override
  String get saveViewDescription =>
      'تبقى عوامل التصفية والترتيب الحالية على بُعد نقرة.';

  @override
  String get renameViewTitle => 'إعادة تسمية طريقة العرض';

  @override
  String get viewName => 'الاسم';

  @override
  String get viewNameRequired => 'أدخل اسمًا لطريقة العرض.';

  @override
  String get viewScope => 'من يراها';

  @override
  String get personalView => 'شخصية';

  @override
  String get personalViewDescription => 'تراها أنت فقط';

  @override
  String get sharedView => 'مشتركة';

  @override
  String get sharedViewDescription => 'يراها الفريق كله';

  @override
  String get dropHere => 'أفلِت هنا';

  @override
  String get noItems => 'لا توجد عناصر';

  @override
  String moveTo(String column) => 'نقل إلى $column';

  @override
  String matchedIn(String field) => 'مطابقة في: $field';
}
