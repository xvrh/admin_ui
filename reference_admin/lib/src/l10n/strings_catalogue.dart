/// WP-C: products, the product editor and its history.
///
/// Counts arrive formatted (`context.adminFormats.integer`), so digits
/// follow the app's locale; the plural form is picked from the number.
abstract class CatalogueStrings {
  const CatalogueStrings();

  // The list
  String get newProduct;
  String get searchHint;
  String get colProduct;
  String get colStatus;
  String get colCategory;
  String get colPrice;
  String get colStock;
  String get colTranslations;
  String get colUpdated;
  String get filterStatus;
  String get filterCategory;
  String get filterLowStock;
  String get filterMissingArabic;
  String get lowStock;

  /// The saved-views tab that shows every product, no view applied.
  String get allProducts;

  /// A seeded shared view's name, by its id; [stored] for any other.
  String savedViewName(String id, String stored);
  String productsSelected(int n, String count);
  String get bulkActivate;
  String get bulkDraft;
  String get bulkArchive;
  String bulkDone(int n, String count);
  String get stockNotSaved;
  String get stockInvalid;
  String get emptyTitle;
  String get emptyMessage;
  String get noPhoto;

  // The editor
  String get newProductTitle;
  String get historyTitle;
  String get tabDetails;
  String get sectionCopy;
  String get sectionCopyHelp;
  String get sectionPricing;
  String get sectionOrganisation;
  String get sectionCare;
  String get sectionVariants;
  String get sectionPhotos;
  String get fieldName;
  String get fieldDescription;
  String get fieldSku;
  String get fieldPrice;
  String get fieldCompareAt;
  String get fieldCompareAtHelp;
  String get fieldStock;
  String get fieldLowStockAt;
  String get fieldCategory;
  String get fieldStatus;
  String get fieldTags;
  String get fieldSupplier;
  String get fieldFeatured;
  String get fieldFeaturedDescription;
  String get fieldAvailableFrom;
  String get fieldLabelColor;
  String get fieldCare;
  String get careKeyHint;
  String get careValueHint;
  String get addCare;
  String get fieldVariants;
  String get variantSize;
  String get variantSkuSuffix;
  String get variantPriceDelta;
  String get variantStock;
  String get addVariant;
  String get fieldPhotos;
  String get skuFormat;
  String get skuTaken;
  String get compareAtTooLow;
  String get save;
  String get savedToast;
  String get conflict;
  String get readOnlyNote;
  String get notFoundTitle;
  String get notFoundMessage;
  String updatedBy(String date, String name);
  String get linkSupplier;
  String get searchSuppliers;
  String supplierTerms(String country, String days);

  // History
  String versionLabel(String n);
  String get currentVersion;
  String restoreTitle(String n);
  String restoreMessage(String n);
  String get restore;
  String restoredToast(String n);
  String get noHistory;
  String get stockField;
  String get photosCount;

  // New product
  String get newProductSubtitle;
  String get create;
  String get createdToast;
}

class CatalogueStringsEn extends CatalogueStrings {
  const CatalogueStringsEn();

  @override
  String get newProduct => 'New product';
  @override
  String get searchHint => 'Search by name, SKU or tag…';
  @override
  String get colProduct => 'Product';
  @override
  String get colStatus => 'Status';
  @override
  String get colCategory => 'Category';
  @override
  String get colPrice => 'Price';
  @override
  String get colStock => 'Stock';
  @override
  String get colTranslations => 'Languages';
  @override
  String get colUpdated => 'Updated';
  @override
  String get filterStatus => 'Status';
  @override
  String get filterCategory => 'Category';
  @override
  String get filterLowStock => 'Low stock';
  @override
  String get filterMissingArabic => 'Missing Arabic';
  @override
  String get lowStock => 'Low';
  @override
  String get allProducts => 'All products';
  @override
  String savedViewName(String id, String stored) => switch (id) {
    'products-low-stock' => 'Low stock',
    'products-missing-translations' => 'Missing translations',
    'products-drafts' => 'Drafts',
    _ => stored,
  };
  @override
  String productsSelected(int n, String count) =>
      n == 1 ? '$count product selected' : '$count products selected';
  @override
  String get bulkActivate => 'Set active';
  @override
  String get bulkDraft => 'Move to drafts';
  @override
  String get bulkArchive => 'Archive';
  @override
  String bulkDone(int n, String count) =>
      n == 1 ? '$count product updated' : '$count products updated';
  @override
  String get stockNotSaved => 'Stock not saved';
  @override
  String get stockInvalid => 'Stock is a whole number, zero or more.';
  @override
  String get emptyTitle => 'No products yet';
  @override
  String get emptyMessage => 'Add your first plant, pot or tool.';
  @override
  String get noPhoto => 'No photo';

  @override
  String get newProductTitle => 'New product';
  @override
  String get historyTitle => 'History';
  @override
  String get tabDetails => 'Details';
  @override
  String get sectionCopy => 'Name and description';
  @override
  String get sectionCopyHelp =>
      'English is the source; French and Arabic follow it.';
  @override
  String get sectionPricing => 'Price and stock';
  @override
  String get sectionOrganisation => 'Organisation';
  @override
  String get sectionCare => 'Care';
  @override
  String get sectionVariants => 'Variants';
  @override
  String get sectionPhotos => 'Photos';
  @override
  String get fieldName => 'Name';
  @override
  String get fieldDescription => 'Description';
  @override
  String get fieldSku => 'SKU';
  @override
  String get fieldPrice => 'Price';
  @override
  String get fieldCompareAt => 'Compare-at price';
  @override
  String get fieldCompareAtHelp => 'Shown struck through, above the price.';
  @override
  String get fieldStock => 'In stock';
  @override
  String get fieldLowStockAt => 'Low-stock alert at';
  @override
  String get fieldCategory => 'Category';
  @override
  String get fieldStatus => 'Status';
  @override
  String get fieldTags => 'Tags';
  @override
  String get fieldSupplier => 'Supplier';
  @override
  String get fieldFeatured => 'Featured';
  @override
  String get fieldFeaturedDescription => 'Shown first on the shop’s home page';
  @override
  String get fieldAvailableFrom => 'Available from';
  @override
  String get fieldLabelColor => 'Shelf label';
  @override
  String get fieldCare => 'Care advice';
  @override
  String get careKeyHint => 'Topic';
  @override
  String get careValueHint => 'Advice';
  @override
  String get addCare => 'Add advice';
  @override
  String get fieldVariants => 'Sizes';
  @override
  String get variantSize => 'Size';
  @override
  String get variantSkuSuffix => 'SKU suffix';
  @override
  String get variantPriceDelta => 'Price difference';
  @override
  String get variantStock => 'In stock';
  @override
  String get addVariant => 'Add a size';
  @override
  String get fieldPhotos => 'Photos';
  @override
  String get skuFormat => 'Use PS- and four digits, as in PS-0142';
  @override
  String get skuTaken => 'Another product already uses this SKU';
  @override
  String get compareAtTooLow => 'Must be higher than the price';
  @override
  String get save => 'Save';
  @override
  String get savedToast => 'Product saved';
  @override
  String get conflict =>
      'Someone saved this product meanwhile. Reload it to see their changes.';
  @override
  String get readOnlyNote =>
      'Your role can look at products but not edit them.';
  @override
  String get notFoundTitle => 'Product not found';
  @override
  String get notFoundMessage =>
      'It may have been removed, or the link is mistyped.';
  @override
  String updatedBy(String date, String name) => 'Updated $date by $name';
  @override
  String get linkSupplier => 'Choose a supplier';
  @override
  String get searchSuppliers => 'Search suppliers…';
  @override
  String supplierTerms(String country, String days) =>
      '$country · pays in $days days';

  @override
  String versionLabel(String n) => 'Version $n';
  @override
  String get currentVersion => 'Current';
  @override
  String restoreTitle(String n) => 'Restore version $n?';
  @override
  String restoreMessage(String n) =>
      'The product goes back to how it was in version $n. It is saved as a '
      'new version, so nothing is lost.';
  @override
  String get restore => 'Restore';
  @override
  String restoredToast(String n) => 'Version $n restored';
  @override
  String get noHistory => 'No earlier versions yet.';
  @override
  String get stockField => 'Stock';
  @override
  String get photosCount => 'Photos';

  @override
  String get newProductSubtitle =>
      'Start with the essentials. Photos, sizes and translations come next.';
  @override
  String get create => 'Create product';
  @override
  String get createdToast => 'Product created';
}

class CatalogueStringsFr extends CatalogueStrings {
  const CatalogueStringsFr();

  @override
  String get newProduct => 'Nouveau produit';
  @override
  String get searchHint => 'Rechercher par nom, référence ou étiquette…';
  @override
  String get colProduct => 'Produit';
  @override
  String get colStatus => 'Statut';
  @override
  String get colCategory => 'Catégorie';
  @override
  String get colPrice => 'Prix';
  @override
  String get colStock => 'Stock';
  @override
  String get colTranslations => 'Langues';
  @override
  String get colUpdated => 'Modifié';
  @override
  String get filterStatus => 'Statut';
  @override
  String get filterCategory => 'Catégorie';
  @override
  String get filterLowStock => 'Stock bas';
  @override
  String get filterMissingArabic => 'Arabe manquant';
  @override
  String get lowStock => 'Bas';
  @override
  String get allProducts => 'Tous les produits';
  @override
  String savedViewName(String id, String stored) => switch (id) {
    'products-low-stock' => 'Stock bas',
    'products-missing-translations' => 'Traductions manquantes',
    'products-drafts' => 'Brouillons',
    _ => stored,
  };
  @override
  String productsSelected(int n, String count) =>
      n < 2 ? '$count produit sélectionné' : '$count produits sélectionnés';
  @override
  String get bulkActivate => 'Activer';
  @override
  String get bulkDraft => 'Passer en brouillon';
  @override
  String get bulkArchive => 'Archiver';
  @override
  String bulkDone(int n, String count) =>
      n < 2 ? '$count produit mis à jour' : '$count produits mis à jour';
  @override
  String get stockNotSaved => 'Stock non enregistré';
  @override
  String get stockInvalid => 'Le stock est un nombre entier, zéro ou plus.';
  @override
  String get emptyTitle => 'Aucun produit pour l’instant';
  @override
  String get emptyMessage => 'Ajoutez votre première plante, pot ou outil.';
  @override
  String get noPhoto => 'Sans photo';

  @override
  String get newProductTitle => 'Nouveau produit';
  @override
  String get historyTitle => 'Historique';
  @override
  String get tabDetails => 'Détails';
  @override
  String get sectionCopy => 'Nom et description';
  @override
  String get sectionCopyHelp =>
      'L’anglais est la source ; le français et l’arabe en découlent.';
  @override
  String get sectionPricing => 'Prix et stock';
  @override
  String get sectionOrganisation => 'Organisation';
  @override
  String get sectionCare => 'Entretien';
  @override
  String get sectionVariants => 'Variantes';
  @override
  String get sectionPhotos => 'Photos';
  @override
  String get fieldName => 'Nom';
  @override
  String get fieldDescription => 'Description';
  @override
  String get fieldSku => 'Référence';
  @override
  String get fieldPrice => 'Prix';
  @override
  String get fieldCompareAt => 'Prix barré';
  @override
  String get fieldCompareAtHelp => 'Affiché barré, au-dessus du prix.';
  @override
  String get fieldStock => 'En stock';
  @override
  String get fieldLowStockAt => 'Alerte stock bas à';
  @override
  String get fieldCategory => 'Catégorie';
  @override
  String get fieldStatus => 'Statut';
  @override
  String get fieldTags => 'Étiquettes';
  @override
  String get fieldSupplier => 'Fournisseur';
  @override
  String get fieldFeatured => 'Mis en avant';
  @override
  String get fieldFeaturedDescription =>
      'Affiché en premier sur l’accueil de la boutique';
  @override
  String get fieldAvailableFrom => 'Disponible à partir du';
  @override
  String get fieldLabelColor => 'Étiquette de rayon';
  @override
  String get fieldCare => 'Conseils d’entretien';
  @override
  String get careKeyHint => 'Sujet';
  @override
  String get careValueHint => 'Conseil';
  @override
  String get addCare => 'Ajouter un conseil';
  @override
  String get fieldVariants => 'Tailles';
  @override
  String get variantSize => 'Taille';
  @override
  String get variantSkuSuffix => 'Suffixe de référence';
  @override
  String get variantPriceDelta => 'Écart de prix';
  @override
  String get variantStock => 'En stock';
  @override
  String get addVariant => 'Ajouter une taille';
  @override
  String get fieldPhotos => 'Photos';
  @override
  String get skuFormat => 'PS- suivi de quatre chiffres, comme PS-0142';
  @override
  String get skuTaken => 'Un autre produit utilise déjà cette référence';
  @override
  String get compareAtTooLow => 'Doit être supérieur au prix';
  @override
  String get save => 'Enregistrer';
  @override
  String get savedToast => 'Produit enregistré';
  @override
  String get conflict =>
      'Quelqu’un a enregistré ce produit entre-temps. Rechargez-le pour voir '
      'ses modifications.';
  @override
  String get readOnlyNote =>
      'Votre rôle permet de consulter les produits, pas de les modifier.';
  @override
  String get notFoundTitle => 'Produit introuvable';
  @override
  String get notFoundMessage =>
      'Il a peut-être été supprimé, ou le lien est erroné.';
  @override
  String updatedBy(String date, String name) => 'Modifié le $date par $name';
  @override
  String get linkSupplier => 'Choisir un fournisseur';
  @override
  String get searchSuppliers => 'Rechercher un fournisseur…';
  @override
  String supplierTerms(String country, String days) =>
      '$country · paiement à $days jours';

  @override
  String versionLabel(String n) => 'Version $n';
  @override
  String get currentVersion => 'Actuelle';
  @override
  String restoreTitle(String n) => 'Restaurer la version $n ?';
  @override
  String restoreMessage(String n) =>
      'Le produit redevient tel qu’il était dans la version $n. Il est '
      'enregistré comme une nouvelle version : rien n’est perdu.';
  @override
  String get restore => 'Restaurer';
  @override
  String restoredToast(String n) => 'Version $n restaurée';
  @override
  String get noHistory => 'Aucune version antérieure pour l’instant.';
  @override
  String get stockField => 'Stock';
  @override
  String get photosCount => 'Photos';

  @override
  String get newProductSubtitle =>
      'Commencez par l’essentiel. Photos, tailles et traductions ensuite.';
  @override
  String get create => 'Créer le produit';
  @override
  String get createdToast => 'Produit créé';
}

class CatalogueStringsAr extends CatalogueStrings {
  const CatalogueStringsAr();

  @override
  String get newProduct => 'منتج جديد';
  @override
  String get searchHint => 'ابحث بالاسم أو الرمز أو الوسم…';
  @override
  String get colProduct => 'المنتج';
  @override
  String get colStatus => 'الحالة';
  @override
  String get colCategory => 'الفئة';
  @override
  String get colPrice => 'السعر';
  @override
  String get colStock => 'المخزون';
  @override
  String get colTranslations => 'اللغات';
  @override
  String get colUpdated => 'آخر تعديل';
  @override
  String get filterStatus => 'الحالة';
  @override
  String get filterCategory => 'الفئة';
  @override
  String get filterLowStock => 'مخزون منخفض';
  @override
  String get filterMissingArabic => 'بلا عربية';
  @override
  String get lowStock => 'منخفض';
  @override
  String get allProducts => 'كل المنتجات';
  @override
  String savedViewName(String id, String stored) => switch (id) {
    'products-low-stock' => 'مخزون منخفض',
    'products-missing-translations' => 'ترجمات ناقصة',
    'products-drafts' => 'مسودات',
    _ => stored,
  };
  @override
  String productsSelected(int n, String count) => switch (n) {
    1 => 'تم تحديد منتج واحد',
    2 => 'تم تحديد منتجين',
    _ when n % 100 >= 3 && n % 100 <= 10 => 'تم تحديد $count منتجات',
    _ => 'تم تحديد $count منتجًا',
  };
  @override
  String get bulkActivate => 'تفعيل';
  @override
  String get bulkDraft => 'نقل إلى المسودات';
  @override
  String get bulkArchive => 'أرشفة';
  @override
  String bulkDone(int n, String count) => switch (n) {
    1 => 'تم تحديث منتج واحد',
    2 => 'تم تحديث منتجين',
    _ when n % 100 >= 3 && n % 100 <= 10 => 'تم تحديث $count منتجات',
    _ => 'تم تحديث $count منتجًا',
  };
  @override
  String get stockNotSaved => 'لم يُحفظ المخزون';
  @override
  String get stockInvalid => 'المخزون عدد صحيح، صفر أو أكثر.';
  @override
  String get emptyTitle => 'لا منتجات بعد';
  @override
  String get emptyMessage => 'أضف أول نبتة أو أصيص أو أداة.';
  @override
  String get noPhoto => 'بلا صورة';

  @override
  String get newProductTitle => 'منتج جديد';
  @override
  String get historyTitle => 'السجل';
  @override
  String get tabDetails => 'التفاصيل';
  @override
  String get sectionCopy => 'الاسم والوصف';
  @override
  String get sectionCopyHelp =>
      'الإنجليزية هي المصدر، والفرنسية والعربية تُترجمان عنها.';
  @override
  String get sectionPricing => 'السعر والمخزون';
  @override
  String get sectionOrganisation => 'التنظيم';
  @override
  String get sectionCare => 'العناية';
  @override
  String get sectionVariants => 'الأحجام';
  @override
  String get sectionPhotos => 'الصور';
  @override
  String get fieldName => 'الاسم';
  @override
  String get fieldDescription => 'الوصف';
  @override
  String get fieldSku => 'رمز المنتج';
  @override
  String get fieldPrice => 'السعر';
  @override
  String get fieldCompareAt => 'السعر قبل الخصم';
  @override
  String get fieldCompareAtHelp => 'يظهر مشطوبًا فوق السعر.';
  @override
  String get fieldStock => 'المتوفر';
  @override
  String get fieldLowStockAt => 'تنبيه انخفاض المخزون عند';
  @override
  String get fieldCategory => 'الفئة';
  @override
  String get fieldStatus => 'الحالة';
  @override
  String get fieldTags => 'الوسوم';
  @override
  String get fieldSupplier => 'المورّد';
  @override
  String get fieldFeatured => 'مميّز';
  @override
  String get fieldFeaturedDescription => 'يظهر أولًا في الصفحة الرئيسية للمتجر';
  @override
  String get fieldAvailableFrom => 'متاح ابتداءً من';
  @override
  String get fieldLabelColor => 'بطاقة الرف';
  @override
  String get fieldCare => 'نصائح العناية';
  @override
  String get careKeyHint => 'الموضوع';
  @override
  String get careValueHint => 'النصيحة';
  @override
  String get addCare => 'إضافة نصيحة';
  @override
  String get fieldVariants => 'الأحجام';
  @override
  String get variantSize => 'الحجم';
  @override
  String get variantSkuSuffix => 'لاحقة الرمز';
  @override
  String get variantPriceDelta => 'فرق السعر';
  @override
  String get variantStock => 'المتوفر';
  @override
  String get addVariant => 'إضافة حجم';
  @override
  String get fieldPhotos => 'الصور';
  @override
  String get skuFormat => 'استخدم PS- وأربعة أرقام، مثل PS-0142';
  @override
  String get skuTaken => 'هذا الرمز مستخدم لمنتج آخر';
  @override
  String get compareAtTooLow => 'يجب أن يكون أعلى من السعر';
  @override
  String get save => 'حفظ';
  @override
  String get savedToast => 'تم حفظ المنتج';
  @override
  String get conflict =>
      'حفظ شخص آخر هذا المنتج في الأثناء. أعد تحميله لترى تعديلاته.';
  @override
  String get readOnlyNote => 'يتيح لك دورك عرض المنتجات دون تعديلها.';
  @override
  String get notFoundTitle => 'المنتج غير موجود';
  @override
  String get notFoundMessage => 'ربما حُذف، أو أن الرابط غير صحيح.';
  @override
  String updatedBy(String date, String name) => 'عُدّل في $date بواسطة $name';
  @override
  String get linkSupplier => 'اختر مورّدًا';
  @override
  String get searchSuppliers => 'ابحث عن مورّد…';
  @override
  String supplierTerms(String country, String days) =>
      '$country · الدفع خلال $days يومًا';

  @override
  String versionLabel(String n) => 'الإصدار $n';
  @override
  String get currentVersion => 'الحالي';
  @override
  String restoreTitle(String n) => 'استعادة الإصدار $n؟';
  @override
  String restoreMessage(String n) =>
      'يعود المنتج كما كان في الإصدار $n، ويُحفظ ذلك إصدارًا جديدًا، فلا '
      'يضيع شيء.';
  @override
  String get restore => 'استعادة';
  @override
  String restoredToast(String n) => 'تمت استعادة الإصدار $n';
  @override
  String get noHistory => 'لا إصدارات سابقة بعد.';
  @override
  String get stockField => 'المخزون';
  @override
  String get photosCount => 'الصور';

  @override
  String get newProductSubtitle =>
      'ابدأ بالأساسيات، ثم أضف الصور والأحجام والترجمات.';
  @override
  String get create => 'إنشاء المنتج';
  @override
  String get createdToast => 'تم إنشاء المنتج';
}
