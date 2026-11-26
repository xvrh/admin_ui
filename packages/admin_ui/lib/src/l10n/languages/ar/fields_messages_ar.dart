import '../../sections/fields_messages.dart';

/// Arabic [FieldsMessages].
class FieldsMessagesAr extends FieldsMessages {
  const FieldsMessagesAr([super.localeName = 'ar']);

  @override
  String quoted(String text) => '”$text“';

  @override
  String get filterOrAdd => 'تصفية أو إضافة…';

  @override
  String maxSelected(int max) => 'بلغت الحد الأقصى (${number(max)})';

  @override
  String createOption(String value) => 'إنشاء ${quoted(value)}';

  @override
  String get onLabel => 'مفعّل';

  @override
  String get offLabel => 'معطّل';

  @override
  String get selectDate => 'اختر تاريخًا…';

  @override
  String get selectDateTime => 'اختر التاريخ والوقت…';

  @override
  String get selectTime => 'اختر وقتًا…';

  @override
  String get clearDate => 'مسح التاريخ';

  @override
  String get year => 'السنة';

  @override
  String get month => 'الشهر';

  @override
  String get day => 'اليوم';

  @override
  String get hour => 'الساعة';

  @override
  String get minute => 'الدقيقة';

  /// The parts' own words: Arabic has no letters to repeat per digit.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'سنة', month: 'شهر', day: 'يوم', hour: 'ساعة', minute: 'دقيقة');

  @override
  String numberLike(String example) => 'أدخل رقمًا مثل $example';

  @override
  String numberBetween(String min, String max) => 'أدخل رقمًا من $min إلى $max';

  @override
  String numberAtLeast(String min) => 'أدخل $min أو أكثر';

  @override
  String numberAtMost(String max) => 'أدخل $max أو أقل';

  @override
  String get decrease => 'إنقاص';

  @override
  String get increase => 'زيادة';

  @override
  String get pickColor => 'اختر لونًا…';

  @override
  String get hexDigitsError => 'أدخل 3 أو 6 أرقام ست عشرية';

  @override
  String get setColor => 'تعيين';

  @override
  String get validJson => 'JSON صالح';

  @override
  String jsonError(int line, int column, String detail) =>
      'السطر ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'تنسيق';

  @override
  String get plainText => 'نص عادي';

  @override
  String get addTag => 'أضف وسمًا…';

  @override
  String get noTags => 'لا توجد وسوم';

  @override
  String get noEntries => 'لا توجد إدخالات';

  @override
  String duplicateKey(String key) =>
      'المفتاح ${quoted(key)} مكرر — يُعتمد الصف الأدنى';

  @override
  String get duplicateKeys => 'مفاتيح مكررة — يُعتمد الصف الأدنى';

  @override
  String get removeRow => 'إزالة الصف';

  @override
  String get noMedia => 'لا توجد وسائط';

  @override
  String retryItem(String name) => 'إعادة محاولة $name';

  @override
  String cancelUpload(String name) => 'إلغاء رفع $name';

  @override
  String get cover => 'الغلاف';

  @override
  String get processing => 'جارٍ المعالجة…';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get addFile => 'إضافة ملف';

  @override
  String get noReference => 'لا يوجد مرجع';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get replaceReference => 'استبدال';

  @override
  String get typeToSearch => 'اكتب للبحث…';

  @override
  String removeItemAt(int position) => 'إزالة العنصر ${number(position)}';

  @override
  String get noItemsYet => 'لا توجد عناصر بعد.';

  @override
  String get help => 'مساعدة';

  @override
  String helpFor(String field) => 'مساعدة بشأن $field';

  @override
  String get versionHistory => 'سجل الإصدارات';

  @override
  String get pendingEdit => 'تعديل معلّق';

  @override
  String get baseline => 'المنشور';

  @override
  String editedDetail(String detail) => 'معدَّل · $detail';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String comments(int count) => plural(
    count,
    zero: 'التعليقات',
    one: 'تعليق واحد',
    two: 'تعليقان',
    few: '${number(count)} تعليقات',
    many: '${number(count)} تعليقًا',
    other: '${number(count)} تعليق',
  );

  @override
  String commentsHeading(int count) => 'التعليقات · ${number(count)}';

  @override
  String get resolve => 'حلّ';

  @override
  String get replyPlaceholder => 'ردّ…';

  @override
  String get sendReply => 'إرسال الرد';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'علّق على هذا الحقل',
    one: 'نقاش مفتوح واحد',
    two: 'نقاشان مفتوحان',
    few: '${number(openThreads)} نقاشات مفتوحة',
    many: '${number(openThreads)} نقاشًا مفتوحًا',
    other: '${number(openThreads)} نقاش مفتوح',
  );

  @override
  String get openThread => 'فتح النقاش';

  @override
  String get translationSource => 'المصدر';

  @override
  String get translationUpToDate => 'محدَّثة';

  @override
  String get translationNeedsReview => 'بحاجة إلى مراجعة';

  @override
  String get translationOutdated => 'قديمة';

  @override
  String get translationMissing => 'ناقصة';

  @override
  String get retranslate => 'إعادة الترجمة';

  @override
  String retranslateLanguage(String language) => 'إعادة الترجمة إلى $language';

  @override
  String get sourceChanged => 'تغيّر المصدر منذ هذه الترجمة';

  @override
  String sourceIn(String language) => 'المصدر باللغة $language';

  @override
  String fieldInLanguage(String field, String language) => '$field، $language';

  @override
  String get languages => 'اللغات';

  @override
  String get languageMenuHint => 'اضغط للتبديل · حدّد للمقارنة جنبًا إلى جنب.';

  @override
  String compareLanguage(String language) => 'مقارنة $language';

  @override
  String switchToLanguage(String language) => 'التبديل إلى $language';

  @override
  String get editing => 'قيد التحرير';

  @override
  String get inherited => 'موروث';

  @override
  String get custom => 'مخصص';

  @override
  String inheritedDescription(String source) =>
      'يطابق المصدر ($source) — يُحدَّث تلقائيًا';

  @override
  String customDescription(String? noun) =>
      noun == null ? 'عيّن قيمة خاصة بك' : 'عيّن $noun بنفسك';

  @override
  String get valueRequired => 'مطلوب';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String tooShort(int min) => plural(
    min,
    one: 'أدخل حرفًا واحدًا على الأقل',
    two: 'أدخل حرفين على الأقل',
    few: 'أدخل ${number(min)} أحرف على الأقل',
    many: 'أدخل ${number(min)} حرفًا على الأقل',
    other: 'أدخل ${number(min)} حرف على الأقل',
  );

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String tooLong(int max) => plural(
    max,
    one: 'أدخل حرفًا واحدًا على الأكثر',
    two: 'أدخل حرفين على الأكثر',
    few: 'أدخل ${number(max)} أحرف على الأكثر',
    many: 'أدخل ${number(max)} حرفًا على الأكثر',
    other: 'أدخل ${number(max)} حرف على الأكثر',
  );

  @override
  String get invalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا';

  @override
  String get invalidUrl => 'أدخل عنوان ويب صالحًا';

  @override
  String get invalidFormat => 'أدخل قيمة بالتنسيق المطلوب';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'أضف عنصرًا واحدًا على الأقل',
    two: 'أضف عنصرين على الأقل',
    few: 'أضف ${number(count)} عناصر على الأقل',
    many: 'أضف ${number(count)} عنصرًا على الأقل',
    other: 'أضف ${number(count)} عنصر على الأقل',
  );

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'لا تتجاوز عنصرًا واحدًا',
    two: 'لا تتجاوز عنصرين',
    few: 'لا تتجاوز ${number(count)} عناصر',
    many: 'لا تتجاوز ${number(count)} عنصرًا',
    other: 'لا تتجاوز ${number(count)} عنصر',
  );

  @override
  String get checking => 'جارٍ التحقق…';

  @override
  String get optionalMarker => '(اختياري)';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: 'حقل واحد بحاجة إلى تصحيح',
    two: 'حقلان بحاجة إلى تصحيح',
    few: '${number(count)} حقول بحاجة إلى تصحيح',
    many: '${number(count)} حقلًا بحاجة إلى تصحيح',
    other: '${number(count)} حقل بحاجة إلى تصحيح',
  );

  @override
  String jumpToField(String label) => 'الانتقال إلى $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'التالي';

  @override
  String get wizardBack => 'السابق';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'صحّح حقلًا واحدًا للمتابعة',
    two: 'صحّح حقلين للمتابعة',
    few: 'صحّح ${number(count)} حقول للمتابعة',
    many: 'صحّح ${number(count)} حقلًا للمتابعة',
    other: 'صحّح ${number(count)} حقل للمتابعة',
  );
}
