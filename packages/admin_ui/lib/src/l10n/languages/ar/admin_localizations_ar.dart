import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_ar.dart';
import 'collection_messages_ar.dart';
import 'display_messages_ar.dart';
import 'fields_messages_ar.dart';
import 'inputs_messages_ar.dart';
import 'shell_messages_ar.dart';

/// Arabic [AdminLocalizations].
class AdminLocalizationsAr extends AdminLocalizations {
  const AdminLocalizationsAr([super.localeName = 'ar']);

  @override
  InputsMessages get inputs => const InputsMessagesAr();

  @override
  DisplayMessages get display => const DisplayMessagesAr();

  @override
  CollectionMessages get collection => const CollectionMessagesAr();

  @override
  FieldsMessages get fields => const FieldsMessagesAr();

  @override
  ShellMessages get shell => const ShellMessagesAr();

  @override
  AssetsMessages get assets => const AssetsMessagesAr();

  @override
  String get apply => 'تطبيق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get remove => 'إزالة';

  @override
  String removeItem(String name) => 'إزالة $name';

  @override
  String get reset => 'إعادة الضبط';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get edited => 'معدَّل';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get noMatches => 'لا توجد نتائج مطابقة';

  @override
  String get couldNotLoad => 'تعذّر التحميل';

  @override
  String get searchFailed => 'تعذّر البحث';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get searching => 'جارٍ البحث…';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get somethingWentWrongTryAgain => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get notAllowed => 'ليس لديك صلاحية الوصول إلى هذا';

  @override
  String get notAllowedAskAdministrator =>
      'اطلب ذلك من أحد المسؤولين إذا احتجت إليه.';

  @override
  String get goBack => 'رجوع';

  @override
  String get moreActions => 'إجراءات إضافية';

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get moveUp => 'نقل لأعلى';

  @override
  String get moveDown => 'نقل لأسفل';

  @override
  String get selectPlaceholder => 'اختر…';

  @override
  String get filterPlaceholder => 'تصفية…';

  @override
  String get searchPlaceholder => 'بحث…';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get addRow => 'إضافة صف';

  @override
  String get keyLabel => 'المفتاح';

  @override
  String get valueLabel => 'القيمة';

  @override
  String get linkPlaceholder => 'ربط…';

  @override
  String get restoreLiveVersion => 'استعادة النسخة المنشورة من هذا الحقل';

  @override
  String get assetNotFound => 'لم يُعثر على الملف';

  @override
  String get assetPreview => 'معاينة الملف';

  @override
  String get uploadFailed => 'تعذّر الرفع';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'اسحب ملفًا وأفلته هنا أو ',
      (false, true) => 'اسحب الملفات وأفلتها هنا أو ',
      (true, false) => 'اسحب صورة وأفلتها هنا أو ',
      (true, true) => 'اسحب الصور وأفلتها هنا أو ',
    },
    link: 'تصفَّح',
    after: '',
  );

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'لم يُحدَّد أي عنصر',
    one: 'عنصر واحد محدد',
    two: 'عنصران محددان',
    few: '${number(count)} عناصر محددة',
    many: '${number(count)} عنصرًا محددًا',
    other: '${number(count)} عنصر محدد',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} من ${number(total)}';

  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['بايت', 'كيلوبايت', 'ميغابايت', 'غيغابايت', 'تيرابايت'][power]}';

  @override
  String get cancel => 'الإلغاء';

  @override
  String get save => 'الحفظ';

  @override
  String get delete => 'حذف';

  @override
  String get copy => 'نسخ';

  @override
  String get close => 'إغلاق';

  @override
  String get clear => 'محو النص';

  @override
  String get search => 'بحث';

  @override
  String get more => 'المزيد';

  @override
  String get selectAll => 'اختيار الكل';

  @override
  String get dismiss => 'رفض';

  @override
  String get rowsPerPage => 'عدد الصفوف في الصفحة:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      'من $first إلى $last من إجمالي $total';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get today => 'تاريخ اليوم';

  @override
  String rangeStartDate(String date) => 'تاريخ البدء $date';

  @override
  String rangeEndDate(String date) => 'تاريخ الانتهاء $date';

  @override
  String get selectDate => 'اختيار التاريخ';

  @override
  String get selectDateRange => 'اختيار النطاق';

  @override
  String get navigationMenu => 'قائمة تنقل';

  @override
  String get expand => 'توسيع';

  @override
  String get collapse => 'تصغير';

  @override
  String get proceed => 'المتابعة';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'مفتاح المسافة';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyFn => 'Fn';
}
