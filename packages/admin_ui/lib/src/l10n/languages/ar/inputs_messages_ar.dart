import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Arabic [InputsMessages].
class InputsMessagesAr extends InputsMessages {
  const InputsMessagesAr([super.localeName = 'ar']);

  @override
  String get confirm => 'تأكيد';

  @override
  String get copied => 'تم النسخ';

  @override
  String get copyFailed => 'تعذّر النسخ';

  @override
  String get undo => 'تراجع';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get couldNotLoadResults => 'تعذّر تحميل النتائج';

  @override
  String optionOf(String label, int position, int count) =>
      '$label، ${number(position)} من ${number(count)}';

  @override
  String get dateRange => 'النطاق الزمني';

  @override
  String get clearDates => 'مسح التواريخ';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String lastDays(int count) => plural(
    count,
    one: 'آخر يوم',
    two: 'آخر يومين',
    few: 'آخر ${number(count)} أيام',
    many: 'آخر ${number(count)} يومًا',
    other: 'آخر ${number(count)} يوم',
  );

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get yearToDate => 'منذ بداية العام';

  @override
  String get searchOrJumpTo => 'ابحث أو انتقل إلى…';

  @override
  String get recent => 'الأخيرة';

  @override
  String get selectAResult => 'اختر نتيجة';

  @override
  String matchedIn(String place) => 'مطابقة في $place';

  @override
  String get matchedInContent => 'مطابقة في المحتوى';

  @override
  String get run => 'تشغيل';

  @override
  String get open => 'فتح';

  @override
  String get typeToSearch => 'اكتب للبحث';

  @override
  String noResultsFor(String query) => 'لا توجد نتائج لـ ”$query“';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'لا توجد نتائج',
    one: 'نتيجة واحدة',
    two: 'نتيجتان',
    few: '${number(count)} نتائج',
    many: '${number(count)} نتيجة',
    other: '${number(count)} نتيجة',
  );

  @override
  String get navigateHint => 'للتنقل';

  @override
  String get selectHint => 'للاختيار';

  @override
  String get closeHint => 'للإغلاق';

  @override
  String get keysUpDown => 'السهمان لأعلى ولأسفل';

  @override
  String get keyEnter => 'إدخال';

  @override
  String get keyEscape => 'مفتاح الخروج';

  @override
  String get fieldsGroup => 'الحقول';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get allCaughtUp => 'لا توجد إشعارات جديدة';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get unread => 'غير مقروء';

  @override
  String get allNotifications => 'الكل';

  @override
  String get markAsRead => 'تحديد كمقروء';

  @override
  String get markAsUnread => 'تحديد كغير مقروء';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get couldNotLoadNotifications => 'تعذّر تحميل الإشعارات';

  @override
  String unreadCount(String title, int count) {
    final unread = plural(
      count,
      one: 'إشعار واحد غير مقروء',
      two: 'إشعاران غير مقروءين',
      few: '${number(count)} إشعارات غير مقروءة',
      many: '${number(count)} إشعارًا غير مقروء',
      other: '${number(count)} إشعار غير مقروء',
    );
    return '$title، $unread';
  }

  @override
  String get appearanceTheme => 'السمة';

  @override
  String get appearanceMode => 'الوضع';

  @override
  String get modeLight => 'فاتح';

  @override
  String get modeDark => 'داكن';

  @override
  String get modeSystem => 'النظام';

  @override
  String get accentColour => 'لون التمييز';

  @override
  String get themeAccent => 'لون السمة';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'قرمزي',
    'Violet' => 'بنفسجي',
    'Teal' => 'أزرق مخضرّ',
    'Amber' => 'كهرماني',
    _ => name,
  };

  @override
  String get tableDensity => 'كثافة الجداول';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'مضغوطة',
    TableDensity.standard => 'عادية',
    TableDensity.comfortable => 'مريحة',
  };
}
