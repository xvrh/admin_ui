import '../../sections/display_messages.dart';

/// Arabic [DisplayMessages].
class DisplayMessagesAr extends DisplayMessages {
  const DisplayMessagesAr([super.localeName = 'ar']);

  /// Arabic separates with its own comma.
  @override
  String joinParts(List<String> parts) => parts.join('، ');

  @override
  String get loadingLabel => 'جارٍ التحميل';

  @override
  String get errorTimeout => 'استغرق الخادم وقتًا طويلًا للرد. حاول مرة أخرى.';

  @override
  String get errorUnreachable =>
      'تعذّر الوصول إلى الخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorUnreadable => 'تعذّرت قراءة رد الخادم. حاول مرة أخرى.';

  @override
  String get errorUnauthorized =>
      'انتهت صلاحية جلستك. سجّل الدخول وحاول مرة أخرى.';

  @override
  String get errorPaymentRequired => 'يتطلب هذا خطة مدفوعة أو رصيدًا إضافيًا.';

  @override
  String get errorForbidden => 'ليس لديك إذن للقيام بذلك.';

  @override
  String get errorNotFound => 'لم يُعثر عليه. ربما نُقل أو حُذف.';

  @override
  String get errorConflict => 'عُدِّل في مكان آخر. أعد التحميل وحاول مرة أخرى.';

  @override
  String get errorTooLarge => 'الحجم أكبر مما يقبله الخادم.';

  @override
  String get errorRateLimited => 'طلبات كثيرة جدًا. انتظر لحظة وحاول مرة أخرى.';

  @override
  String get errorServer => 'واجه الخادم مشكلة. حاول مرة أخرى بعد لحظات.';

  @override
  String get errorRequestFailed => 'تعذّر على الخادم إتمام الطلب.';

  @override
  String get breadcrumb => 'مسار التنقل';

  @override
  String currentPage(String label) => '$label، الصفحة الحالية';

  @override
  String get switchPage => 'تبديل الصفحة';

  @override
  String showMore(int count) => plural(
    count,
    zero: 'إظهار ${number(count)} عنصر آخر',
    one: 'إظهار عنصر آخر',
    two: 'إظهار عنصرين آخرين',
    few: 'إظهار ${number(count)} عناصر أخرى',
    many: 'إظهار ${number(count)} عنصرًا آخر',
    other: 'إظهار ${number(count)} عنصر آخر',
  );

  @override
  String pageNumber(int page) => 'الصفحة ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    zero: '${number(count)} مفتاح',
    one: 'مفتاح واحد',
    two: 'مفتاحان',
    few: '${number(count)} مفاتيح',
    many: '${number(count)} مفتاحًا',
    other: '${number(count)} مفتاح',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    zero: '${number(count)} عنصر',
    one: 'عنصر واحد',
    two: 'عنصران',
    few: '${number(count)} عناصر',
    many: '${number(count)} عنصرًا',
    other: '${number(count)} عنصر',
  );

  @override
  String get expandAll => 'توسيع الكل';

  @override
  String get collapseAll => 'طي الكل';

  @override
  String get copyJson => 'نسخ JSON';

  @override
  String get copyValue => 'نسخ القيمة';

  @override
  String get copyPath => 'نسخ المسار';

  @override
  String invalidJson(String detail) => 'JSON غير صالح — $detail';

  @override
  String get logEmpty => 'لا توجد مخرجات بعد';

  @override
  String get zoomArea => 'عرض قابل للتكبير';

  @override
  String get zoomAreaHint =>
      'مرّر للتكبير واسحب للتحريك؛ + و − للتكبير والتصغير، و0 للملاءمة، '
      'ومفاتيح الأسهم للتحريك.';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get zoomToFit => 'ملاءمة للعرض';

  @override
  String get qrCode => 'رمز QR';

  @override
  String uploadDone(int total) => plural(
    total,
    zero: 'لم يُرفع أي ملف',
    one: 'اكتمل الرفع',
    two: 'تم رفع الملفين',
    few: 'تم رفع الملفات الـ${number(total)}',
    many: 'تم رفع ${number(total)} ملفًا',
    other: 'تم رفع ${number(total)} ملف',
  );

  @override
  String uploadProgress(int done, int total, int failed) {
    final uploaded = 'تم رفع ${number(done)} من ${number(total)}';
    if (failed == 0) return uploaded;
    final failures = plural(
      failed,
      one: 'تعذّر رفع ملف واحد',
      two: 'تعذّر رفع ملفين',
      few: 'تعذّر رفع ${number(failed)} ملفات',
      many: 'تعذّر رفع ${number(failed)} ملفًا',
      other: 'تعذّر رفع ${number(failed)} ملف',
    );
    return '$uploaded · $failures';
  }

  @override
  String get clearCompleted => 'مسح المكتمل';

  @override
  String get queued => 'في الانتظار';

  @override
  String get retryUpload => 'إعادة محاولة الرفع';

  @override
  String get removeFile => 'إزالة الملف';

  @override
  String get cancelUpload => 'إلغاء الرفع';

  @override
  String get chartEmpty => 'لا توجد بيانات لهذه الفترة';

  @override
  String get heatLess => 'أقل';

  @override
  String get heatMore => 'أكثر';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'ارتفاع $delta';

  @override
  String trendDown(String delta) => 'انخفاض $delta';

  @override
  String get needsAttention => 'يحتاج إلى انتباهك';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get contentMix => 'توزيع المحتوى';

  @override
  String itemsUnit(int count) => plural(
    count,
    zero: 'عنصر',
    one: 'عنصر',
    two: 'عنصران',
    few: 'عناصر',
    many: 'عنصرًا',
    other: 'عنصر',
  );

  @override
  String get allCaughtUp => 'كل شيء على ما يرام — لا شيء يحتاج إلى انتباهك.';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get noRecentActivityHint =>
      'ستظهر هنا التعديلات وعمليات النشر والرفع.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label، $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'الخطوة ${number(step)} من ${number(total)}: $title';

  @override
  String get stepCompleted => 'مكتملة';

  @override
  String get stepCurrent => 'الحالية';

  @override
  String get stepUpcoming => 'قادمة';

  @override
  String get stepError => 'خطأ';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get untitled => 'بلا عنوان';

  @override
  String get treeHeader => 'مجموعة';

  @override
  String get indent => 'زيادة الإزاحة';

  @override
  String get outdent => 'إنقاص الإزاحة';

  @override
  String get addChild => 'إضافة عنصر فرعي';

  @override
  String get hideEntry => 'إخفاء';

  @override
  String get showEntry => 'إظهار';

  @override
  String movedUp(String title) => 'نُقل $title لأعلى';

  @override
  String movedDown(String title) => 'نُقل $title لأسفل';

  @override
  String indented(String title) => 'زيدت إزاحة $title';

  @override
  String outdented(String title) => 'أُنقصت إزاحة $title';

  @override
  String get rowMovedUp => 'نُقل لأعلى';

  @override
  String get rowMovedDown => 'نُقل لأسفل';

  @override
  String get rowIndented => 'زيدت الإزاحة';

  @override
  String get rowOutdented => 'أُنقصت الإزاحة';

  @override
  String get resizePanes => 'تغيير حجم الأجزاء';

  @override
  String get moveLeft => 'نقل لليسار';

  @override
  String get moveRight => 'نقل لليمين';

  @override
  String get preview => 'معاينة';

  @override
  String get previewHeading => 'معاينة';

  @override
  String get noPreviewHeading => 'لا توجد معاينة';

  @override
  String get insertsInline => 'يُدرج داخل النص — لا حاجة إلى معاينة.';

  @override
  String nothingMatches(String query) => 'لا شيء يطابق ”$query“';

  @override
  String get choices => 'الخيارات';

  @override
  String get diffAdded => 'مضاف';

  @override
  String get diffRemoved => 'محذوف';

  @override
  String get diffChanged => 'معدَّل';

  @override
  String get diffMoved => 'منقول';

  @override
  String get diffUnchanged => 'بلا تغيير';

  @override
  String addedCount(int count) => plural(
    count,
    zero: '${number(count)} إضافة',
    one: 'إضافة واحدة',
    two: 'إضافتان',
    few: '${number(count)} إضافات',
    many: '${number(count)} إضافة',
    other: '${number(count)} إضافة',
  );

  @override
  String removedCount(int count) => plural(
    count,
    zero: '${number(count)} عملية حذف',
    one: 'عملية حذف واحدة',
    two: 'عمليتا حذف',
    few: '${number(count)} عمليات حذف',
    many: '${number(count)} عملية حذف',
    other: '${number(count)} عملية حذف',
  );

  @override
  String changedCount(int count) => plural(
    count,
    zero: '${number(count)} تعديل',
    one: 'تعديل واحد',
    two: 'تعديلان',
    few: '${number(count)} تعديلات',
    many: '${number(count)} تعديلًا',
    other: '${number(count)} تعديل',
  );

  @override
  String movedCount(int count) => plural(
    count,
    zero: '${number(count)} عملية نقل',
    one: 'عملية نقل واحدة',
    two: 'عمليتا نقل',
    few: '${number(count)} عمليات نقل',
    many: '${number(count)} عملية نقل',
    other: '${number(count)} عملية نقل',
  );

  @override
  String get before => 'قبل';

  @override
  String get after => 'بعد';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'من الموضع ${number(from)} إلى ${number(to)}';

  @override
  String get unified => 'موحّد';

  @override
  String get split => 'جنبًا إلى جنب';

  @override
  String get noChanges => 'لا توجد تغييرات';

  @override
  String get versionsIdentical => 'هاتان النسختان متطابقتان.';

  @override
  String get noFieldChanges => 'لا تغييرات في الحقول.';

  @override
  String get noBlockChanges => 'لا تغييرات في الكتل.';

  @override
  String get empty => 'فارغ';

  @override
  String inserted(String text) => 'مُدرج: $text، ';

  @override
  String deleted(String text) => 'محذوف: $text، ';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreThisVersion => 'استعادة هذه النسخة';

  @override
  String get restoreThisField => 'استعادة هذا الحقل';

  @override
  String get restoreThisItem => 'استعادة هذا العنصر';

  @override
  String get restoreLiveBlock => 'استعادة النسخة المنشورة من هذه الكتلة';

  @override
  String get sharedLane => 'مشترك';

  @override
  String get versionCurrent => 'الحالية';

  @override
  String get versionPublished => 'منشورة';

  @override
  String get versionRestored => 'مستعادة';

  @override
  String get versionArchived => 'مؤرشفة';

  @override
  String versionNumber(int version) => 'الإصدار $version';

  @override
  String get mentionSuggestions => 'أشخاص للإشارة إليهم';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: 'شخص واحد للإشارة إليه',
    two: 'شخصان للإشارة إليهما',
    few: '${number(count)} أشخاص للإشارة إليهم',
    many: '${number(count)} شخصًا للإشارة إليهم',
    other: '${number(count)} شخص للإشارة إليهم',
  );
}
