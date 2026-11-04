/// WP-A: sign-in, set-password, dashboard, setup and shop settings.
abstract class AccessStrings {
  const AccessStrings();

  // sign in
  String get signInTitle;
  String get signInSubtitle;
  String get wrongPassword;
  String get accountLocked;
  String get accountInactive;
  String get demoAccountsTitle;

  /// The toast that greets a teammate once they are signed in.
  String welcomeBack(String name);
  String demoAccountsPassword(String password);

  // set password
  String get setPasswordTitle;
  String inviteWelcome(String name);
  String inviteSubtitle(String inviter, String role);
  String get joinShop;
  String get checkingInvite;
  String get inviteExpiredTitle;
  String get inviteExpiredMessage;
  String get inviteInvalidTitle;
  String get inviteInvalidMessage;
  String get backToSignIn;
  String get passwordTooWeak;
  String get welcomeTitle;
  String welcomeMessage(String name);

  // dashboard
  String greeting(int hour, String name);

  /// [days] as [shown], the number in the page's digits.
  String rangeSegment(int days, String shown);
  String comparedWith(int days, String shown);
  String get rangeLabel;
  String get kpiRevenue;
  String get kpiOrders;
  String get kpiAverageOrder;
  String get kpiNewCustomers;
  String get deltaNew;
  String get revenueChart;
  String revenueChartSubtitle(String shown);
  String get topProductsChart;
  String get topProductsSubtitle;
  String get channelsChart;
  String get channelsSubtitle;
  String get ordersUnit;
  String get attentionTitle;
  String get attentionToShip;
  String get attentionToShipCaption;
  String get attentionLowStock;
  String get attentionLowStockCaption;
  String get attentionMissingTranslations;
  String get attentionMissingTranslationsCaption;
  String get attentionRefunds;
  String get attentionRefundsCaption;
  String get attentionClear;
  String get statsErrorTitle;
  String get emptyTitle;
  String get emptySetupMessage;
  String get emptyReadyMessage;
  String get setUpShop;

  // setup and shop settings
  String get setupTitle;
  String get setupSubtitle;
  String get stepDetails;
  String get stepDetailsSubtitle;
  String get stepShipping;
  String get stepShippingSubtitle;
  String get stepReview;
  String get stepReviewSubtitle;
  String get shopName;
  String get shopNameDescription;
  String get currencyDescription;
  String get supportEmail;
  String get supportEmailDescription;
  String get currency;
  String currencyName(String code);
  String get taxRate;
  String get taxRateDescription;
  String get languages;
  String get languagesDescription;
  String get zones;
  String get zonesDescription;
  String get addZone;
  String get zoneName;
  String get zoneCountries;
  String get zoneCountriesHint;
  String get zoneRate;
  String zoneItem(String name, int index);
  String get zonesRequired;
  String get finishSetup;
  String get reviewIntro;
  String zoneSummary(String countries, String rate);
  String get readyTitle;
  String readyMessage(String shop);
  String get goToDashboard;
  String get addFirstProduct;
  String get shopSettingsSubtitle;
  String get detailsSectionDescription;
  String get shippingSectionDescription;
  String get shopLoadErrorTitle;
}

class AccessStringsEn extends AccessStrings {
  const AccessStringsEn();

  @override
  String get signInTitle => 'Sign in to Potting Shed';
  @override
  String get signInSubtitle => 'The back office of your plant shop.';
  @override
  String get wrongPassword => 'That email and password do not match.';
  @override
  String get accountLocked =>
      'Too many attempts: this account is locked. Ask the shop owner to '
      'unlock it.';
  @override
  String get accountInactive => 'This account can no longer sign in.';
  @override
  String get demoAccountsTitle => 'Demo accounts';
  @override
  String welcomeBack(String name) => 'Welcome back, $name';
  @override
  String demoAccountsPassword(String password) =>
      'Each one signs in with $password';

  @override
  String get setPasswordTitle => 'Choose a password';
  @override
  String inviteWelcome(String name) => 'Welcome, $name';
  @override
  String inviteSubtitle(String inviter, String role) =>
      '$inviter invited you to Potting Shed as $role. Choose a password to '
      'finish.';
  @override
  String get joinShop => 'Join Potting Shed';
  @override
  String get checkingInvite => 'Checking your invitation…';
  @override
  String get inviteExpiredTitle => 'This invitation has expired';
  @override
  String get inviteExpiredMessage =>
      'Invitations last a week. Ask the person who invited you to send a new '
      'one.';
  @override
  String get inviteInvalidTitle => 'This invitation is not valid';
  @override
  String get inviteInvalidMessage =>
      'The link may be incomplete. Open it again from the email, or ask for a '
      'new invitation.';
  @override
  String get backToSignIn => 'Back to sign in';
  @override
  String get passwordTooWeak => 'Choose a longer password.';
  @override
  String get welcomeTitle => 'You are in';
  @override
  String welcomeMessage(String name) => 'Welcome to the team, $name.';

  @override
  String greeting(int hour, String name) => switch (hour) {
    < 12 => 'Good morning, $name',
    < 18 => 'Good afternoon, $name',
    _ => 'Good evening, $name',
  };
  @override
  String rangeSegment(int days, String shown) => '$shown days';
  @override
  String comparedWith(int days, String shown) =>
      'Last $shown days, compared with the $shown before';
  @override
  String get rangeLabel => 'Period';
  @override
  String get kpiRevenue => 'Revenue';
  @override
  String get kpiOrders => 'Orders';
  @override
  String get kpiAverageOrder => 'Average order';
  @override
  String get kpiNewCustomers => 'New customers';
  @override
  String get deltaNew => 'New';
  @override
  String get revenueChart => 'Revenue';
  @override
  String revenueChartSubtitle(String shown) =>
      'Per day, net of refunds, over the last $shown days';
  @override
  String get topProductsChart => 'Best sellers';
  @override
  String get topProductsSubtitle => 'Units sold';
  @override
  String get channelsChart => 'Where orders come from';
  @override
  String get channelsSubtitle => 'Orders per channel';
  @override
  String get ordersUnit => 'orders';
  @override
  String get attentionTitle => 'Needs your attention';
  @override
  String get attentionToShip => 'orders to ship';
  @override
  String get attentionToShipCaption => 'Paid and waiting to be packed';
  @override
  String get attentionLowStock => 'plants low on stock';
  @override
  String get attentionLowStockCaption => 'At or under their reorder point';
  @override
  String get attentionMissingTranslations => 'missing a translation';
  @override
  String get attentionMissingTranslationsCaption =>
      'Not yet readable in every language';
  @override
  String get attentionRefunds => 'refund requests';
  @override
  String get attentionRefundsCaption => 'Customers waiting on an answer';
  @override
  String get attentionClear => 'All caught up: nothing needs you today.';
  @override
  String get statsErrorTitle => 'The dashboard could not load';
  @override
  String get emptyTitle => 'No sales yet';
  @override
  String get emptySetupMessage =>
      'Set up your shop to start taking orders. Your figures will show here.';
  @override
  String get emptyReadyMessage =>
      'Your figures will show here once the first orders come in.';
  @override
  String get setUpShop => 'Set up your shop';

  @override
  String get setupTitle => 'Set up your shop';
  @override
  String get setupSubtitle =>
      'Three short steps, and your shop is ready to sell.';
  @override
  String get stepDetails => 'Shop details';
  @override
  String get stepDetailsSubtitle => 'Name, contact, prices';
  @override
  String get stepShipping => 'Shipping';
  @override
  String get stepShippingSubtitle => 'Where you deliver';
  @override
  String get stepReview => 'Review';
  @override
  String get stepReviewSubtitle => 'Check and finish';
  @override
  String get shopName => 'Shop name';
  @override
  String get shopNameDescription => 'As customers will see it.';
  @override
  String get currencyDescription => 'Prices and payouts are in it.';
  @override
  String get supportEmail => 'Support email';
  @override
  String get supportEmailDescription => 'Customers write to this address.';
  @override
  String get currency => 'Currency';
  @override
  String currencyName(String code) => switch (code) {
    'EUR' => 'Euro (EUR)',
    'GBP' => 'Pound sterling (GBP)',
    'CHF' => 'Swiss franc (CHF)',
    _ => code,
  };
  @override
  String get taxRate => 'VAT rate';
  @override
  String get taxRateDescription => 'Included in every price you set.';
  @override
  String get languages => 'Languages you sell in';
  @override
  String get languagesDescription => 'Each product is written in these.';
  @override
  String get zones => 'Shipping zones';
  @override
  String get zonesDescription =>
      'Each zone has a flat rate for the countries it covers.';
  @override
  String get addZone => 'Add a zone';
  @override
  String get zoneName => 'Zone';
  @override
  String get zoneCountries => 'Countries';
  @override
  String get zoneCountriesHint => 'A country code, then Enter';
  @override
  String get zoneRate => 'Rate';
  @override
  String zoneItem(String name, int index) =>
      name.isEmpty ? 'zone ${index + 1}' : name;
  @override
  String get zonesRequired => 'Add at least one shipping zone.';
  @override
  String get finishSetup => 'Open my shop';
  @override
  String get reviewIntro =>
      'Check the details below. You can change any of them later in the '
      'shop settings.';
  @override
  String zoneSummary(String countries, String rate) => '$countries · $rate';
  @override
  String get readyTitle => 'Your shop is ready';
  @override
  String readyMessage(String shop) =>
      '$shop can take orders. Add your first plants, or invite your team.';
  @override
  String get goToDashboard => 'Go to the dashboard';
  @override
  String get addFirstProduct => 'Add a product';
  @override
  String get shopSettingsSubtitle => 'What customers see, and where you ship.';
  @override
  String get detailsSectionDescription =>
      'The name, contact and prices shown on the storefront.';
  @override
  String get shippingSectionDescription =>
      'Orders to a country outside every zone cannot be placed.';
  @override
  String get shopLoadErrorTitle => 'The shop settings could not load';
}

class AccessStringsFr extends AccessStrings {
  const AccessStringsFr();

  @override
  String get signInTitle => 'Connexion à Potting Shed';
  @override
  String get signInSubtitle => 'L’arrière-boutique de votre jardinerie.';
  @override
  String get wrongPassword =>
      'Cet e-mail et ce mot de passe ne concordent pas.';
  @override
  String get accountLocked =>
      'Trop de tentatives : ce compte est bloqué. Demandez au propriétaire de '
      'la boutique de le débloquer.';
  @override
  String get accountInactive => 'Ce compte ne peut plus se connecter.';
  @override
  String get demoAccountsTitle => 'Comptes de démonstration';
  @override
  String welcomeBack(String name) => 'Bon retour, $name';
  @override
  String demoAccountsPassword(String password) =>
      'Tous se connectent avec $password';

  @override
  String get setPasswordTitle => 'Choisissez un mot de passe';
  @override
  String inviteWelcome(String name) => 'Bienvenue, $name';
  @override
  String inviteSubtitle(String inviter, String role) =>
      '$inviter vous a invité·e sur Potting Shed en tant que $role. '
      'Choisissez un mot de passe pour terminer.';
  @override
  String get joinShop => 'Rejoindre Potting Shed';
  @override
  String get checkingInvite => 'Vérification de votre invitation…';
  @override
  String get inviteExpiredTitle => 'Cette invitation a expiré';
  @override
  String get inviteExpiredMessage =>
      'Une invitation vaut une semaine. Demandez à la personne qui vous a '
      'invité·e de vous en envoyer une nouvelle.';
  @override
  String get inviteInvalidTitle => 'Cette invitation n’est pas valide';
  @override
  String get inviteInvalidMessage =>
      'Le lien est peut-être incomplet. Rouvrez-le depuis l’e-mail, ou '
      'demandez une nouvelle invitation.';
  @override
  String get backToSignIn => 'Retour à la connexion';
  @override
  String get passwordTooWeak => 'Choisissez un mot de passe plus long.';
  @override
  String get welcomeTitle => 'C’est fait';
  @override
  String welcomeMessage(String name) => 'Bienvenue dans l’équipe, $name.';

  @override
  String greeting(int hour, String name) =>
      hour < 18 ? 'Bonjour, $name' : 'Bonsoir, $name';
  @override
  String rangeSegment(int days, String shown) => '$shown jours';
  @override
  String comparedWith(int days, String shown) =>
      '$shown derniers jours, comparés aux $shown précédents';
  @override
  String get rangeLabel => 'Période';
  @override
  String get kpiRevenue => 'Chiffre d’affaires';
  @override
  String get kpiOrders => 'Commandes';
  @override
  String get kpiAverageOrder => 'Panier moyen';
  @override
  String get kpiNewCustomers => 'Nouveaux clients';
  @override
  String get deltaNew => 'Nouveau';
  @override
  String get revenueChart => 'Chiffre d’affaires';
  @override
  String revenueChartSubtitle(String shown) =>
      'Par jour, remboursements déduits, sur les $shown derniers jours';
  @override
  String get topProductsChart => 'Meilleures ventes';
  @override
  String get topProductsSubtitle => 'Unités vendues';
  @override
  String get channelsChart => 'D’où viennent les commandes';
  @override
  String get channelsSubtitle => 'Commandes par canal';
  @override
  String get ordersUnit => 'commandes';
  @override
  String get attentionTitle => 'À traiter';
  @override
  String get attentionToShip => 'commandes à expédier';
  @override
  String get attentionToShipCaption => 'Payées, en attente d’emballage';
  @override
  String get attentionLowStock => 'plantes en stock bas';
  @override
  String get attentionLowStockCaption => 'Au seuil de réassort ou en dessous';
  @override
  String get attentionMissingTranslations => 'traductions manquantes';
  @override
  String get attentionMissingTranslationsCaption =>
      'Pas encore lisibles dans chaque langue';
  @override
  String get attentionRefunds => 'demandes de remboursement';
  @override
  String get attentionRefundsCaption => 'Des clients attendent une réponse';
  @override
  String get attentionClear => 'Tout est à jour : rien ne vous attend.';
  @override
  String get statsErrorTitle => 'Le tableau de bord n’a pas pu se charger';
  @override
  String get emptyTitle => 'Aucune vente pour l’instant';
  @override
  String get emptySetupMessage =>
      'Configurez votre boutique pour prendre des commandes. Vos chiffres '
      's’afficheront ici.';
  @override
  String get emptyReadyMessage =>
      'Vos chiffres s’afficheront ici dès les premières commandes.';
  @override
  String get setUpShop => 'Configurer la boutique';

  @override
  String get setupTitle => 'Configurez votre boutique';
  @override
  String get setupSubtitle =>
      'Trois courtes étapes, et votre boutique est prête à vendre.';
  @override
  String get stepDetails => 'La boutique';
  @override
  String get stepDetailsSubtitle => 'Nom, contact, prix';
  @override
  String get stepShipping => 'Livraison';
  @override
  String get stepShippingSubtitle => 'Où vous livrez';
  @override
  String get stepReview => 'Vérification';
  @override
  String get stepReviewSubtitle => 'Relire et terminer';
  @override
  String get shopName => 'Nom de la boutique';
  @override
  String get shopNameDescription => 'Tel que vos clients le verront.';
  @override
  String get currencyDescription => 'Celle de tous vos prix et versements.';
  @override
  String get supportEmail => 'E-mail du service client';
  @override
  String get supportEmailDescription => 'Vos clients écrivent à cette adresse.';
  @override
  String get currency => 'Devise';
  @override
  String currencyName(String code) => switch (code) {
    'EUR' => 'Euro (EUR)',
    'GBP' => 'Livre sterling (GBP)',
    'CHF' => 'Franc suisse (CHF)',
    _ => code,
  };
  @override
  String get taxRate => 'Taux de TVA';
  @override
  String get taxRateDescription => 'Compris dans chaque prix affiché.';
  @override
  String get languages => 'Langues de vente';
  @override
  String get languagesDescription =>
      'Chaque fiche produit est rédigée dans '
      'ces langues.';
  @override
  String get zones => 'Zones de livraison';
  @override
  String get zonesDescription =>
      'Chaque zone a un tarif unique pour les pays qu’elle couvre.';
  @override
  String get addZone => 'Ajouter une zone';
  @override
  String get zoneName => 'Zone';
  @override
  String get zoneCountries => 'Pays';
  @override
  String get zoneCountriesHint => 'Un code pays, puis Entrée';
  @override
  String get zoneRate => 'Tarif';
  @override
  String zoneItem(String name, int index) =>
      name.isEmpty ? 'zone ${index + 1}' : name;
  @override
  String get zonesRequired => 'Ajoutez au moins une zone de livraison.';
  @override
  String get finishSetup => 'Ouvrir ma boutique';
  @override
  String get reviewIntro =>
      'Relisez les informations ci-dessous. Vous pourrez les modifier plus '
      'tard dans les réglages de la boutique.';
  @override
  String zoneSummary(String countries, String rate) => '$countries · $rate';
  @override
  String get readyTitle => 'Votre boutique est prête';
  @override
  String readyMessage(String shop) =>
      '$shop peut prendre des commandes. Ajoutez vos premières plantes, ou '
      'invitez votre équipe.';
  @override
  String get goToDashboard => 'Aller au tableau de bord';
  @override
  String get addFirstProduct => 'Ajouter un produit';
  @override
  String get shopSettingsSubtitle =>
      'Ce que voient vos clients, et où vous livrez.';
  @override
  String get detailsSectionDescription =>
      'Le nom, le contact et les prix affichés sur la boutique.';
  @override
  String get shippingSectionDescription =>
      'Une commande vers un pays hors de toute zone ne peut pas être passée.';
  @override
  String get shopLoadErrorTitle =>
      'Les réglages de la boutique n’ont pas pu se charger';
}

class AccessStringsAr extends AccessStrings {
  const AccessStringsAr();

  @override
  String get signInTitle => 'تسجيل الدخول إلى Potting Shed';
  @override
  String get signInSubtitle => 'الإدارة الخلفية لمتجر نباتاتك.';
  @override
  String get wrongPassword => 'البريد الإلكتروني وكلمة المرور غير متطابقين.';
  @override
  String get accountLocked =>
      'محاولات كثيرة: هذا الحساب مقفل. اطلب من مالك المتجر فتحه.';
  @override
  String get accountInactive => 'لم يعد بإمكان هذا الحساب تسجيل الدخول.';
  @override
  String get demoAccountsTitle => 'حسابات تجريبية';
  @override
  String welcomeBack(String name) => 'أهلًا بعودتك، $name';
  @override
  String demoAccountsPassword(String password) =>
      'كلها تسجّل الدخول بكلمة المرور $password';

  @override
  String get setPasswordTitle => 'اختر كلمة مرور';
  @override
  String inviteWelcome(String name) => 'أهلًا بك يا $name';
  @override
  String inviteSubtitle(String inviter, String role) =>
      'دعاك $inviter إلى Potting Shed بدور $role. اختر كلمة مرور لإكمال '
      'التسجيل.';
  @override
  String get joinShop => 'الانضمام إلى Potting Shed';
  @override
  String get checkingInvite => 'جارٍ التحقق من دعوتك…';
  @override
  String get inviteExpiredTitle => 'انتهت صلاحية هذه الدعوة';
  @override
  String get inviteExpiredMessage =>
      'تبقى الدعوة صالحة أسبوعًا. اطلب من الشخص الذي دعاك إرسال دعوة جديدة.';
  @override
  String get inviteInvalidTitle => 'هذه الدعوة غير صالحة';
  @override
  String get inviteInvalidMessage =>
      'ربما الرابط ناقص. افتحه من جديد من البريد، أو اطلب دعوة جديدة.';
  @override
  String get backToSignIn => 'العودة إلى تسجيل الدخول';
  @override
  String get passwordTooWeak => 'اختر كلمة مرور أطول.';
  @override
  String get welcomeTitle => 'تم الدخول';
  @override
  String welcomeMessage(String name) => 'أهلًا بك في الفريق يا $name.';

  @override
  String greeting(int hour, String name) =>
      hour < 12 ? 'صباح الخير يا $name' : 'مساء الخير يا $name';
  @override
  String rangeSegment(int days, String shown) =>
      days <= 10 ? '$shown أيام' : '$shown يومًا';
  @override
  String comparedWith(int days, String shown) =>
      'آخر ${rangeSegment(days, shown)}، مقارنةً بالفترة السابقة';
  @override
  String get rangeLabel => 'الفترة';
  @override
  String get kpiRevenue => 'الإيرادات';
  @override
  String get kpiOrders => 'الطلبات';
  @override
  String get kpiAverageOrder => 'متوسط الطلب';
  @override
  String get kpiNewCustomers => 'عملاء جدد';
  @override
  String get deltaNew => 'جديد';
  @override
  String get revenueChart => 'الإيرادات';
  @override
  String revenueChartSubtitle(String shown) =>
      'يوميًا، بعد خصم المبالغ المستردة، خلال آخر $shown يومًا';
  @override
  String get topProductsChart => 'الأكثر مبيعًا';
  @override
  String get topProductsSubtitle => 'الوحدات المبيعة';
  @override
  String get channelsChart => 'مصدر الطلبات';
  @override
  String get channelsSubtitle => 'الطلبات حسب القناة';
  @override
  String get ordersUnit => 'طلبًا';
  @override
  String get attentionTitle => 'يحتاج إلى انتباهك';
  @override
  String get attentionToShip => 'طلبات للشحن';
  @override
  String get attentionToShipCaption => 'مدفوعة وبانتظار التغليف';
  @override
  String get attentionLowStock => 'نباتات مخزونها منخفض';
  @override
  String get attentionLowStockCaption => 'عند حدّ إعادة الطلب أو دونه';
  @override
  String get attentionMissingTranslations => 'تنقصها ترجمة';
  @override
  String get attentionMissingTranslationsCaption => 'غير مقروءة بعد بكل اللغات';
  @override
  String get attentionRefunds => 'طلبات استرداد';
  @override
  String get attentionRefundsCaption => 'عملاء ينتظرون ردًّا';
  @override
  String get attentionClear => 'لا شيء بانتظارك اليوم.';
  @override
  String get statsErrorTitle => 'تعذّر تحميل لوحة المعلومات';
  @override
  String get emptyTitle => 'لا مبيعات بعد';
  @override
  String get emptySetupMessage =>
      'أعدّ متجرك لتبدأ في استقبال الطلبات. ستظهر أرقامك هنا.';
  @override
  String get emptyReadyMessage => 'ستظهر أرقامك هنا مع وصول أولى الطلبات.';
  @override
  String get setUpShop => 'إعداد المتجر';

  @override
  String get setupTitle => 'إعداد متجرك';
  @override
  String get setupSubtitle => 'ثلاث خطوات قصيرة، ويصبح متجرك جاهزًا للبيع.';
  @override
  String get stepDetails => 'بيانات المتجر';
  @override
  String get stepDetailsSubtitle => 'الاسم والتواصل والأسعار';
  @override
  String get stepShipping => 'الشحن';
  @override
  String get stepShippingSubtitle => 'أين توصّل';
  @override
  String get stepReview => 'المراجعة';
  @override
  String get stepReviewSubtitle => 'راجع وأنهِ';
  @override
  String get shopName => 'اسم المتجر';
  @override
  String get shopNameDescription => 'كما سيراه العملاء.';
  @override
  String get currencyDescription => 'عملة كل الأسعار والمدفوعات.';
  @override
  String get supportEmail => 'بريد خدمة العملاء';
  @override
  String get supportEmailDescription => 'يراسلك العملاء على هذا العنوان.';
  @override
  String get currency => 'العملة';
  @override
  String currencyName(String code) => switch (code) {
    'EUR' => 'اليورو (EUR)',
    'GBP' => 'الجنيه الإسترليني (GBP)',
    'CHF' => 'الفرنك السويسري (CHF)',
    _ => code,
  };
  @override
  String get taxRate => 'نسبة ضريبة القيمة المضافة';
  @override
  String get taxRateDescription => 'مشمولة في كل سعر تحدّده.';
  @override
  String get languages => 'لغات البيع';
  @override
  String get languagesDescription => 'يُكتب كل منتج بهذه اللغات.';
  @override
  String get zones => 'مناطق الشحن';
  @override
  String get zonesDescription => 'لكل منطقة سعر ثابت للدول التي تشملها.';
  @override
  String get addZone => 'إضافة منطقة';
  @override
  String get zoneName => 'المنطقة';
  @override
  String get zoneCountries => 'الدول';
  @override
  String get zoneCountriesHint => 'رمز الدولة ثم Enter';
  @override
  String get zoneRate => 'السعر';
  @override
  String zoneItem(String name, int index) =>
      name.isEmpty ? 'المنطقة ${index + 1}' : name;
  @override
  String get zonesRequired => 'أضف منطقة شحن واحدة على الأقل.';
  @override
  String get finishSetup => 'افتح متجري';
  @override
  String get reviewIntro =>
      'راجع البيانات أدناه. يمكنك تغيير أي منها لاحقًا من إعدادات المتجر.';
  @override
  String zoneSummary(String countries, String rate) => '$countries · $rate';
  @override
  String get readyTitle => 'متجرك جاهز';
  @override
  String readyMessage(String shop) =>
      'يمكن لـ $shop استقبال الطلبات الآن. أضف نباتاتك الأولى، أو ادعُ فريقك.';
  @override
  String get goToDashboard => 'الذهاب إلى لوحة المعلومات';
  @override
  String get addFirstProduct => 'إضافة منتج';
  @override
  String get shopSettingsSubtitle => 'ما يراه العملاء، وأين تشحن.';
  @override
  String get detailsSectionDescription =>
      'الاسم ووسيلة التواصل والأسعار المعروضة في المتجر.';
  @override
  String get shippingSectionDescription =>
      'لا يمكن الطلب إلى دولة خارج كل المناطق.';
  @override
  String get shopLoadErrorTitle => 'تعذّر تحميل إعدادات المتجر';
}
