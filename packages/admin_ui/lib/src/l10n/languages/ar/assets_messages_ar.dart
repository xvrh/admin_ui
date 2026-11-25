import '../../sections/assets_messages.dart';

/// Arabic [AssetsMessages].
class AssetsMessagesAr extends AssetsMessages {
  const AssetsMessagesAr([super.localeName = 'ar']);

  @override
  String get assets => 'الملفات';

  @override
  String get loadingAssets => 'جارٍ تحميل الملفات…';

  @override
  String get couldNotLoadAssets => 'تعذّر تحميل الملفات';

  @override
  String get noMatchingAssets => 'لا توجد ملفات مطابقة';

  @override
  String get noMatchingAssetsHint => 'جرّب بحثًا أو عامل تصفية مختلفًا.';

  @override
  String get noAssetsYet => 'لا توجد ملفات بعد';

  @override
  String get noAssetsYetHint => 'ارفع الصور والملفات لإنشاء مكتبتك.';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String assetCount(int count) => plural(
    count,
    zero: 'لا ملفات',
    one: 'ملف واحد',
    two: 'ملفان',
    few: '${number(count)} ملفات',
    many: '${number(count)} ملفًا',
    other: '${number(count)} ملف',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} من ${assetCount(total)}';

  @override
  String get searchAssets => 'البحث في الملفات';

  @override
  String get filterByType => 'التصفية حسب النوع';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'كل الأنواع';

  @override
  String get typeImages => 'الصور';

  @override
  String get typeVideos => 'الفيديوهات';

  @override
  String get typeAudio => 'الصوتيات';

  @override
  String get typeDocuments => 'المستندات';

  @override
  String get typeOther => 'أخرى';

  @override
  String get kindImage => 'صورة';

  @override
  String get kindVideo => 'فيديو';

  @override
  String get kindAudio => 'صوت';

  @override
  String get kindDocument => 'مستند';

  @override
  String get kindOther => 'آخر';

  @override
  String get view => 'طريقة العرض';

  @override
  String get gridView => 'عرض شبكي';

  @override
  String get listView => 'عرض قائمة';

  @override
  String get libraryTab => 'المكتبة';

  @override
  String get uploadTab => 'رفع';

  @override
  String get pickerTitle => 'اختيار الوسائط';

  @override
  String get select => 'تحديد';

  @override
  String get loadingMore => 'جارٍ تحميل المزيد…';

  @override
  String get dropToUpload => 'أفلِت الملفات للرفع';

  @override
  String couldNotLoadMore(String reason) => 'تعذّر تحميل المزيد. $reason';

  @override
  String get uploadIncomplete => 'لم يكتمل الرفع. حاول مرة أخرى.';

  @override
  String get asset => 'الملف';

  @override
  String get type => 'النوع';

  @override
  String get size => 'الحجم';

  @override
  String get dimensions => 'الأبعاد';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'المعرّف';

  @override
  String get altText => 'النص البديل';

  @override
  String get defaultAltText => 'النص البديل الافتراضي';

  @override
  String get defaultAltTextHelp =>
      'يُستخدم أينما ظهر هذا الملف، ما لم يُستبدل في موضع استخدامه.';

  @override
  String get saveAltText => 'حفظ النص البديل';

  @override
  String get url => 'الرابط';

  @override
  String get copyUrl => 'نسخ الرابط';

  @override
  String get aspectFree => 'حر';

  @override
  String get imageUnavailable => 'الصورة غير متاحة';

  @override
  String get cropArea => 'منطقة قص الصورة';

  @override
  String get cropAreaHint =>
      'اسحب المقابض للقص. تحرّك مفاتيح الأسهم القص قليلًا، واضغط Shift '
      'مع الاستمرار لخطوات أكبر.';

  @override
  String get positionArea => 'منطقة موضع الصورة';

  @override
  String get positionAreaHint =>
      'اسحب لتغيير الموضع ومرّر للتكبير، وتحرّك مفاتيح الأسهم الصورة قليلًا.';

  @override
  String get zoom => 'التكبير';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'تعديل الميل';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'تدوير لليسار';

  @override
  String get rotateRight => 'تدوير لليمين';

  @override
  String get flipHorizontal => 'قلب أفقي';

  @override
  String get flipVertical => 'قلب رأسي';

  @override
  String get useImage => 'استخدام الصورة';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    zero: 'يضيفها الترخيص إلى مكتبتك دون استخدام أي تنزيل',
    one: 'يضيفها الترخيص إلى مكتبتك ويستخدم تنزيلًا واحدًا',
    two: 'يضيفها الترخيص إلى مكتبتك ويستخدم تنزيلين',
    few: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيلات',
    many: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيلًا',
    other: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيل',
  );

  @override
  String get selectImageToLicense => 'اختر صورة لترخيصها';

  @override
  String get findStockImages => 'ابحث عن صور جاهزة';

  @override
  String get noResultsHint => 'جرّب بحثًا مختلفًا أو خفّف عوامل التصفية.';

  @override
  String stockSearchPrompt(String provider) =>
      'اكتب للبحث في ملايين الصور على $provider.';

  @override
  String providerResults(String provider) => 'نتائج $provider';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String resultCount(int count) => plural(
    count,
    zero: 'لا نتائج',
    one: 'نتيجة واحدة',
    two: 'نتيجتان',
    few: '${number(count)} نتائج',
    many: '${number(count)} نتيجة',
    other: '${number(count)} نتيجة',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} من ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'البحث في $provider';

  @override
  String get orientation => 'الاتجاه';

  @override
  String get anyOrientation => 'أي اتجاه';

  @override
  String get horizontal => 'أفقي';

  @override
  String get vertical => 'رأسي';

  @override
  String get square => 'مربع';

  @override
  String get imageType => 'نوع الصورة';

  @override
  String get anyType => 'أي نوع';

  @override
  String get photos => 'صور فوتوغرافية';

  @override
  String get illustrations => 'رسوم توضيحية';

  @override
  String get vectors => 'رسوم متجهة';

  @override
  String licenseFrom(String provider) => 'الترخيص من $provider';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    zero: 'يضيف الصورة إلى مكتبتك دون استخدام أي تنزيل من باقة $provider.',
    one: 'يضيف الصورة إلى مكتبتك ويستخدم تنزيلًا واحدًا من باقة $provider.',
    two: 'يضيف الصورة إلى مكتبتك ويستخدم تنزيلين من باقة $provider.',
    few:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيلات من '
        'باقة $provider.',
    many:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيلًا من '
        'باقة $provider.',
    other:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيل من '
        'باقة $provider.',
  );

  @override
  String get couldNotLicense => 'تعذّر ترخيص هذه الصورة';

  @override
  String get licenseAndAdd => 'ترخيص وإضافة';

  @override
  String get couldNotLoadSizes => 'تعذّر تحميل المقاسات';

  @override
  String editItem(String name) => 'تعديل: $name';

  @override
  String get done => 'تم';

  @override
  String get couldNotLoadPreview => 'تعذّر تحميل المعاينة';

  @override
  String get uploading => 'جارٍ الرفع';

  @override
  String get replace => 'استبدال';

  @override
  String get choose => 'اختيار';

  @override
  String get editCrop => 'تعديل القص';

  @override
  String get cropAndFocalPoint => 'القص ونقطة التركيز';

  @override
  String get imagesOnly => 'الصور فقط';

  @override
  String get typeText => 'النصوص';

  @override
  String familyFiles(String family) => 'ملفات $family';

  @override
  String upTo(String size) => 'حتى $size';

  @override
  String get listSeparator => '، ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: الملف ليس صورة.',
    other: 'تعذّرت إضافة $names: الملفات ليست صورًا.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: نوع الملف غير مدعوم.',
    other: 'تعذّرت إضافة $names: أنواع الملفات غير مدعومة.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'تعذّرت إضافة $names: حجم الملف أكبر من $limit.',
    other: 'تعذّرت إضافة $names: حجم الملفات أكبر من $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: إنه مجلد.',
    other: 'تعذّرت إضافة $names: إنها مجلدات.',
  );

  @override
  String refusedMixed(String items) => 'تعذّرت إضافة $items.';

  @override
  String refusedItemNotImage(String name) => '$name (ليس صورة)';

  @override
  String refusedItemNotSupported(String name) => '$name (نوع غير مدعوم)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (أكبر من $limit)';

  @override
  String refusedItemFolder(String name) => '$name (مجلد)';
}
