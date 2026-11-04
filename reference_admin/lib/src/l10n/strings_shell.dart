import '../api/shop_api.dart';

/// The frame's words: navigation, the top bar, the palette, the inbox, the
/// user menu, the offline banner, errors and the placeholder pages.
abstract class ShellStrings {
  const ShellStrings();

  String get appName;

  // navigation
  String get sectionSales;
  String get sectionCatalogue;
  String get sectionShop;
  String get navDashboard;
  String get navOrders;
  String get navCustomers;
  String get navProducts;
  String get navMedia;
  String get navTeam;
  String get navSettings;

  // top bar
  String get searchHint;
  String get switchToDark;
  String get switchToLight;
  String get notifications;
  String get today;
  String get earlier;
  String notificationTitle(NotificationKind kind, String subject);
  String notificationBody(NotificationKind kind, String? actor);
  String get newOrderTitle;
  String newOrderToast(String label, String customer);

  /// A product that has just run low, as a toast: its title, and what is
  /// left.
  String get stockLowTitle;
  String stockLowToast(String product, int left, String leftText);
  String get view;

  /// A short time ago, as a list's timestamp: [formatted] is the count in
  /// the page's digits.
  String agoMinutes(int minutes, String formatted);
  String agoHours(int hours, String formatted);
  String agoDays(int days, String formatted);

  // palette
  String get groupPages;
  String get groupCommands;
  String get groupOrders;
  String get groupProducts;
  String get groupCustomers;
  String get groupRecent;
  String get commandNewProduct;
  String orderHit(String label, String customer);

  // user menu
  String get profile;
  String get appearance;
  String get theme;
  String get mode;
  String get modeSystem;
  String get modeLight;
  String get modeDark;
  String get language;
  String get languageSystem;
  String get signOut;

  // connectivity
  String get offlineTitle;
  String get offlineMessage;

  // errors
  String get errorNetwork;
  String get errorOffline;
  String get errorValidation;
  String get errorConflict;
  String get errorForbidden;
  String get errorNotFound;
  String get errorExpired;
  String get errorServer;

  // guard pages
  String get forbiddenTitle;
  String get forbiddenMessage;
  String get notFoundTitle;
  String notFoundMessage(String path);
  String get backToDashboard;

  /// The placeholder a work package replaces with its screen.
  String get stubMessage;

  // shared vocabulary: every area shows these words
  String orderStatus(OrderStatus status);
  String productStatus(ProductStatus status);
  String staffStatus(StaffStatus status);
  String role(Role role);
  String payment(PaymentMethod method);
  String channel(OrderChannel channel);
  String get partiallyRefunded;

  /// A language's own name, as the language menu lists it.
  String languageName(String code) => switch (code) {
    'en' => 'English',
    'fr' => 'Français',
    'ar' => 'العربية',
    _ => code,
  };

  String error(ShopError error) => switch (error) {
    NetworkError() => errorNetwork,
    OfflineError() => errorOffline,
    ValidationError() => errorValidation,
    ConflictError() => errorConflict,
    ForbiddenError() => errorForbidden,
    NotFoundError() => errorNotFound,
    ExpiredError() => errorExpired,
    ServerError() => errorServer,
  };
}

class ShellStringsEn extends ShellStrings {
  const ShellStringsEn();

  @override
  String get appName => 'Potting Shed';
  @override
  String get sectionSales => 'Sales';
  @override
  String get sectionCatalogue => 'Catalogue';
  @override
  String get sectionShop => 'Shop';
  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navOrders => 'Orders';
  @override
  String get navCustomers => 'Customers';
  @override
  String get navProducts => 'Products';
  @override
  String get navMedia => 'Media';
  @override
  String get navTeam => 'Team';
  @override
  String get navSettings => 'Settings';
  @override
  String get searchHint => 'Search orders, plants, customers…';
  @override
  String get switchToDark => 'Switch to dark';
  @override
  String get switchToLight => 'Switch to light';
  @override
  String get notifications => 'Notifications';
  @override
  String get today => 'Today';
  @override
  String get earlier => 'Earlier';
  @override
  String notificationTitle(NotificationKind kind, String subject) =>
      switch (kind) {
        NotificationKind.lowStock => 'Low stock: $subject',
        NotificationKind.newOrder => 'New order $subject',
        NotificationKind.refundRequest => 'Refund requested on $subject',
        NotificationKind.mention => 'You were mentioned on $subject',
        NotificationKind.system => subject,
      };
  @override
  String notificationBody(NotificationKind kind, String? actor) =>
      switch (kind) {
        NotificationKind.lowStock => 'Reorder before it runs out.',
        NotificationKind.newOrder => 'Paid and ready to pick.',
        NotificationKind.refundRequest => 'The customer is waiting on you.',
        NotificationKind.mention => '${actor ?? 'A teammate'} left a note.',
        NotificationKind.system => 'Completed without problems.',
      };
  @override
  String get newOrderTitle => 'New order';
  @override
  String newOrderToast(String label, String customer) =>
      '$label from $customer';
  @override
  String get stockLowTitle => 'Running low';
  @override
  String stockLowToast(String product, int left, String leftText) =>
      left == 1 ? '$product: 1 left' : '$product: $leftText left';
  @override
  String get view => 'View';
  @override
  String agoMinutes(int minutes, String formatted) => '$formatted min';
  @override
  String agoHours(int hours, String formatted) => '$formatted h';
  @override
  String agoDays(int days, String formatted) => '$formatted d';
  @override
  String get groupPages => 'Pages';
  @override
  String get groupCommands => 'Commands';
  @override
  String get groupOrders => 'Orders';
  @override
  String get groupProducts => 'Products';
  @override
  String get groupCustomers => 'Customers';
  @override
  String get groupRecent => 'Recent';
  @override
  String get commandNewProduct => 'New product';
  @override
  String orderHit(String label, String customer) => 'Order $label · $customer';
  @override
  String get profile => 'Profile';
  @override
  String get appearance => 'Appearance';
  @override
  String get theme => 'Theme';
  @override
  String get mode => 'Mode';
  @override
  String get modeSystem => 'System';
  @override
  String get modeLight => 'Light';
  @override
  String get modeDark => 'Dark';
  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'Device language';
  @override
  String get signOut => 'Sign out';
  @override
  String get offlineTitle => 'You’re offline';
  @override
  String get offlineMessage =>
      'Changes can’t be saved until the connection is back.';
  @override
  String get errorNetwork => 'Couldn’t reach the shop. Check your connection.';
  @override
  String get errorOffline => 'You’re offline. Try again once you’re back.';
  @override
  String get errorValidation => 'Some fields need attention.';
  @override
  String get errorConflict =>
      'Someone else changed this. Reload to see their changes.';
  @override
  String get errorForbidden => 'Your role doesn’t allow this.';
  @override
  String get errorNotFound => 'This no longer exists.';
  @override
  String get errorExpired => 'This link has expired.';
  @override
  String get errorServer => 'Something went wrong on our side.';
  @override
  String get forbiddenTitle => 'Not available to your role';
  @override
  String get forbiddenMessage =>
      'Ask the shop owner if you need access to this page.';
  @override
  String get notFoundTitle => 'Page not found';
  @override
  String notFoundMessage(String path) => 'Nothing lives at $path.';
  @override
  String get backToDashboard => 'Back to the dashboard';
  @override
  String get stubMessage => 'This screen is on its way.';

  @override
  String orderStatus(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'Pending',
    OrderStatus.paid => 'Paid',
    OrderStatus.picking => 'Picking',
    OrderStatus.packed => 'Packed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };
  @override
  String productStatus(ProductStatus status) => switch (status) {
    ProductStatus.draft => 'Draft',
    ProductStatus.active => 'Active',
    ProductStatus.archived => 'Archived',
  };
  @override
  String staffStatus(StaffStatus status) => switch (status) {
    StaffStatus.active => 'Active',
    StaffStatus.invited => 'Invited',
    StaffStatus.deactivated => 'Deactivated',
  };
  @override
  String role(Role role) => switch (role) {
    Role.owner => 'Owner',
    Role.manager => 'Manager',
    Role.staff => 'Staff',
    Role.viewer => 'Viewer',
  };
  @override
  String payment(PaymentMethod method) => switch (method) {
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
  };
  @override
  String channel(OrderChannel channel) => switch (channel) {
    OrderChannel.online => 'Online',
    OrderChannel.marketStall => 'Market stall',
    OrderChannel.wholesale => 'Wholesale',
  };
  @override
  String get partiallyRefunded => 'Partially refunded';
}

class ShellStringsFr extends ShellStrings {
  const ShellStringsFr();

  @override
  String get appName => 'Potting Shed';
  @override
  String get sectionSales => 'Ventes';
  @override
  String get sectionCatalogue => 'Catalogue';
  @override
  String get sectionShop => 'Boutique';
  @override
  String get navDashboard => 'Tableau de bord';
  @override
  String get navOrders => 'Commandes';
  @override
  String get navCustomers => 'Clients';
  @override
  String get navProducts => 'Produits';
  @override
  String get navMedia => 'Médias';
  @override
  String get navTeam => 'Équipe';
  @override
  String get navSettings => 'Réglages';
  @override
  String get searchHint => 'Rechercher commandes, plantes, clients…';
  @override
  String get switchToDark => 'Passer en sombre';
  @override
  String get switchToLight => 'Passer en clair';
  @override
  String get notifications => 'Notifications';
  @override
  String get today => 'Aujourd’hui';
  @override
  String get earlier => 'Plus tôt';
  @override
  String notificationTitle(NotificationKind kind, String subject) =>
      switch (kind) {
        NotificationKind.lowStock => 'Stock bas : $subject',
        NotificationKind.newOrder => 'Nouvelle commande $subject',
        NotificationKind.refundRequest => 'Remboursement demandé sur $subject',
        NotificationKind.mention => 'On vous a mentionné sur $subject',
        NotificationKind.system => subject,
      };
  @override
  String notificationBody(NotificationKind kind, String? actor) =>
      switch (kind) {
        NotificationKind.lowStock => 'Recommandez avant la rupture.',
        NotificationKind.newOrder => 'Payée et prête à préparer.',
        NotificationKind.refundRequest => 'Le client attend votre réponse.',
        NotificationKind.mention =>
          '${actor ?? 'Un collègue'} a laissé une note.',
        NotificationKind.system => 'Terminé sans problème.',
      };
  @override
  String get newOrderTitle => 'Nouvelle commande';
  @override
  String newOrderToast(String label, String customer) => '$label de $customer';
  @override
  String get stockLowTitle => 'Stock bas';
  @override
  String stockLowToast(String product, int left, String leftText) => left <= 1
      ? '$product : $leftText restant'
      : '$product : $leftText restants';
  @override
  String get view => 'Voir';
  @override
  String agoMinutes(int minutes, String formatted) => '$formatted min';
  @override
  String agoHours(int hours, String formatted) => '$formatted h';
  @override
  String agoDays(int days, String formatted) => '$formatted j';
  @override
  String get groupPages => 'Pages';
  @override
  String get groupCommands => 'Commandes rapides';
  @override
  String get groupOrders => 'Commandes';
  @override
  String get groupProducts => 'Produits';
  @override
  String get groupCustomers => 'Clients';
  @override
  String get groupRecent => 'Récents';
  @override
  String get commandNewProduct => 'Nouveau produit';
  @override
  String orderHit(String label, String customer) =>
      'Commande $label · $customer';
  @override
  String get profile => 'Profil';
  @override
  String get appearance => 'Apparence';
  @override
  String get theme => 'Thème';
  @override
  String get mode => 'Mode';
  @override
  String get modeSystem => 'Système';
  @override
  String get modeLight => 'Clair';
  @override
  String get modeDark => 'Sombre';
  @override
  String get language => 'Langue';
  @override
  String get languageSystem => 'Langue de l’appareil';
  @override
  String get signOut => 'Se déconnecter';
  @override
  String get offlineTitle => 'Vous êtes hors ligne';
  @override
  String get offlineMessage =>
      'Les modifications ne pourront être enregistrées qu’au retour de la '
      'connexion.';
  @override
  String get errorNetwork =>
      'Impossible de joindre la boutique. Vérifiez votre connexion.';
  @override
  String get errorOffline =>
      'Vous êtes hors ligne. Réessayez une fois reconnecté.';
  @override
  String get errorValidation => 'Certains champs sont à corriger.';
  @override
  String get errorConflict =>
      'Quelqu’un d’autre a modifié ceci. Rechargez pour voir ses changements.';
  @override
  String get errorForbidden => 'Votre rôle ne le permet pas.';
  @override
  String get errorNotFound => 'Ceci n’existe plus.';
  @override
  String get errorExpired => 'Ce lien a expiré.';
  @override
  String get errorServer => 'Un problème est survenu de notre côté.';
  @override
  String get forbiddenTitle => 'Non accessible à votre rôle';
  @override
  String get forbiddenMessage =>
      'Demandez l’accès au propriétaire de la boutique si besoin.';
  @override
  String get notFoundTitle => 'Page introuvable';
  @override
  String notFoundMessage(String path) => 'Il n’y a rien à l’adresse $path.';
  @override
  String get backToDashboard => 'Retour au tableau de bord';
  @override
  String get stubMessage => 'Cet écran arrive bientôt.';

  @override
  String orderStatus(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'En attente',
    OrderStatus.paid => 'Payée',
    OrderStatus.picking => 'En préparation',
    OrderStatus.packed => 'Emballée',
    OrderStatus.shipped => 'Expédiée',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.cancelled => 'Annulée',
  };
  @override
  String productStatus(ProductStatus status) => switch (status) {
    ProductStatus.draft => 'Brouillon',
    ProductStatus.active => 'Actif',
    ProductStatus.archived => 'Archivé',
  };
  @override
  String staffStatus(StaffStatus status) => switch (status) {
    StaffStatus.active => 'Actif',
    StaffStatus.invited => 'Invité',
    StaffStatus.deactivated => 'Désactivé',
  };
  @override
  String role(Role role) => switch (role) {
    Role.owner => 'Propriétaire',
    Role.manager => 'Responsable',
    Role.staff => 'Employé',
    Role.viewer => 'Lecteur',
  };
  @override
  String payment(PaymentMethod method) => switch (method) {
    PaymentMethod.card => 'Carte',
    PaymentMethod.bankTransfer => 'Virement',
  };
  @override
  String channel(OrderChannel channel) => switch (channel) {
    OrderChannel.online => 'En ligne',
    OrderChannel.marketStall => 'Marché',
    OrderChannel.wholesale => 'Grossiste',
  };
  @override
  String get partiallyRefunded => 'Partiellement remboursée';
}

class ShellStringsAr extends ShellStrings {
  const ShellStringsAr();

  @override
  String get appName => 'Potting Shed';
  @override
  String get sectionSales => 'المبيعات';
  @override
  String get sectionCatalogue => 'الكتالوج';
  @override
  String get sectionShop => 'المتجر';
  @override
  String get navDashboard => 'لوحة التحكم';
  @override
  String get navOrders => 'الطلبات';
  @override
  String get navCustomers => 'العملاء';
  @override
  String get navProducts => 'المنتجات';
  @override
  String get navMedia => 'الوسائط';
  @override
  String get navTeam => 'الفريق';
  @override
  String get navSettings => 'الإعدادات';
  @override
  String get searchHint => 'ابحث في الطلبات والنباتات والعملاء…';
  @override
  String get switchToDark => 'التبديل إلى الوضع الداكن';
  @override
  String get switchToLight => 'التبديل إلى الوضع الفاتح';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get today => 'اليوم';
  @override
  String get earlier => 'سابقًا';
  @override
  String notificationTitle(NotificationKind kind, String subject) =>
      switch (kind) {
        NotificationKind.lowStock => 'مخزون منخفض: $subject',
        NotificationKind.newOrder => 'طلب جديد $subject',
        NotificationKind.refundRequest => 'طلب استرداد على $subject',
        NotificationKind.mention => 'تمت الإشارة إليك في $subject',
        NotificationKind.system => subject,
      };
  @override
  String notificationBody(NotificationKind kind, String? actor) =>
      switch (kind) {
        NotificationKind.lowStock => 'أعد الطلب قبل نفاد الكمية.',
        NotificationKind.newOrder => 'مدفوع وجاهز للتجهيز.',
        NotificationKind.refundRequest => 'العميل بانتظار ردك.',
        NotificationKind.mention => 'ترك ${actor ?? 'زميل'} ملاحظة.',
        NotificationKind.system => 'اكتمل دون مشاكل.',
      };
  @override
  String get newOrderTitle => 'طلب جديد';
  @override
  String newOrderToast(String label, String customer) => '$label من $customer';
  @override
  String get stockLowTitle => 'المخزون ينفد';
  @override
  String stockLowToast(String product, int left, String leftText) =>
      '$product: بقي $leftText';
  @override
  String get view => 'عرض';
  @override
  String agoMinutes(int minutes, String formatted) => '$formatted د';
  @override
  String agoHours(int hours, String formatted) => '$formatted س';
  @override
  String agoDays(int days, String formatted) => '$formatted ي';
  @override
  String get groupPages => 'الصفحات';
  @override
  String get groupCommands => 'الأوامر';
  @override
  String get groupOrders => 'الطلبات';
  @override
  String get groupProducts => 'المنتجات';
  @override
  String get groupCustomers => 'العملاء';
  @override
  String get groupRecent => 'الأخيرة';
  @override
  String get commandNewProduct => 'منتج جديد';
  @override
  String orderHit(String label, String customer) => 'الطلب $label · $customer';
  @override
  String get profile => 'الملف الشخصي';
  @override
  String get appearance => 'المظهر';
  @override
  String get theme => 'السمة';
  @override
  String get mode => 'الوضع';
  @override
  String get modeSystem => 'النظام';
  @override
  String get modeLight => 'فاتح';
  @override
  String get modeDark => 'داكن';
  @override
  String get language => 'اللغة';
  @override
  String get languageSystem => 'لغة الجهاز';
  @override
  String get signOut => 'تسجيل الخروج';
  @override
  String get offlineTitle => 'أنت غير متصل';
  @override
  String get offlineMessage => 'لا يمكن حفظ التغييرات حتى يعود الاتصال.';
  @override
  String get errorNetwork => 'تعذر الوصول إلى المتجر. تحقق من اتصالك.';
  @override
  String get errorOffline => 'أنت غير متصل. حاول مجددًا عند عودة الاتصال.';
  @override
  String get errorValidation => 'بعض الحقول تحتاج إلى تصحيح.';
  @override
  String get errorConflict =>
      'غيّر شخص آخر هذا العنصر. أعد التحميل لرؤية تغييراته.';
  @override
  String get errorForbidden => 'دورك لا يسمح بذلك.';
  @override
  String get errorNotFound => 'هذا العنصر لم يعد موجودًا.';
  @override
  String get errorExpired => 'انتهت صلاحية هذا الرابط.';
  @override
  String get errorServer => 'حدث خطأ من جهتنا.';
  @override
  String get forbiddenTitle => 'غير متاح لدورك';
  @override
  String get forbiddenMessage =>
      'اطلب من مالك المتجر الوصول إلى هذه الصفحة إن احتجت إليها.';
  @override
  String get notFoundTitle => 'الصفحة غير موجودة';
  @override
  String notFoundMessage(String path) => 'لا يوجد شيء على العنوان $path.';
  @override
  String get backToDashboard => 'العودة إلى لوحة التحكم';
  @override
  String get stubMessage => 'هذه الشاشة قيد الإنشاء.';

  @override
  String orderStatus(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'قيد الانتظار',
    OrderStatus.paid => 'مدفوع',
    OrderStatus.picking => 'قيد التجهيز',
    OrderStatus.packed => 'مغلّف',
    OrderStatus.shipped => 'تم الشحن',
    OrderStatus.delivered => 'تم التسليم',
    OrderStatus.cancelled => 'ملغى',
  };
  @override
  String productStatus(ProductStatus status) => switch (status) {
    ProductStatus.draft => 'مسودة',
    ProductStatus.active => 'نشط',
    ProductStatus.archived => 'مؤرشف',
  };
  @override
  String staffStatus(StaffStatus status) => switch (status) {
    StaffStatus.active => 'نشط',
    StaffStatus.invited => 'مدعو',
    StaffStatus.deactivated => 'معطّل',
  };
  @override
  String role(Role role) => switch (role) {
    Role.owner => 'المالك',
    Role.manager => 'مدير',
    Role.staff => 'موظف',
    Role.viewer => 'مشاهد',
  };
  @override
  String payment(PaymentMethod method) => switch (method) {
    PaymentMethod.card => 'بطاقة',
    PaymentMethod.bankTransfer => 'تحويل بنكي',
  };
  @override
  String channel(OrderChannel channel) => switch (channel) {
    OrderChannel.online => 'عبر الإنترنت',
    OrderChannel.marketStall => 'كشك السوق',
    OrderChannel.wholesale => 'بالجملة',
  };
  @override
  String get partiallyRefunded => 'مسترد جزئيًا';
}
