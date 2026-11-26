import '../../sections/collection_messages.dart';

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
  String get moveCard => 'نقل إلى…';

  @override
  String matchedIn(String field) => 'مطابقة في: $field';
}
