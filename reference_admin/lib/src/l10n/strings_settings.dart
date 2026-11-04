/// WP-E: the settings pages (appearance and profile) and their tabs.
abstract class SettingsStrings {
  const SettingsStrings();

  /// The settings pages' shared title, over their tabs.
  String get settingsTitle;
  String get appearanceTitle;
  String get profileTitle;

  /// The shop settings page's tab.
  String get shopTab;

  String get appearanceSubtitle;

  /// The card of the kit's appearance picker.
  String get displayTitle;
  String get displayDescription;

  String get previewLabel;
  String get previewPrimary;
  String get previewSecondary;
  String get previewStatus;

  String get languageTitle;
  String get languageDescription;
  String get reduceMotionLabel;
  String get reduceMotionDescription;

  String get profileSubtitle;
  String get accountTitle;

  /// Who changes the account's details: [canManageTeam] does it on Team.
  String accountDescription({required bool canManageTeam});
  String get nameLabel;
  String get emailLabel;
  String get roleLabel;
  String get statusLabel;
  String get lastActiveLabel;

  /// When they were last active, from a short span such as `3 h`.
  String activeAgo(String span);
  String get passwordTitle;
  String get passwordDescription;
  String get wrongCurrentPassword;
  String get passwordTooWeak;
  String get passwordChanged;
  String get passwordChangedDetail;
}

class SettingsStringsEn extends SettingsStrings {
  const SettingsStringsEn();

  @override
  String get settingsTitle => 'Settings';
  @override
  String get appearanceTitle => 'Appearance';
  @override
  String get profileTitle => 'Profile';
  @override
  String get shopTab => 'Shop';
  @override
  String get appearanceSubtitle =>
      'Changes apply at once and follow you to any device you sign in on.';
  @override
  String get displayTitle => 'Display';
  @override
  String get displayDescription =>
      'A theme, light or dark, a brand colour, and table rows.';
  @override
  String get previewLabel => 'Preview';
  @override
  String get previewPrimary => 'Save';
  @override
  String get previewSecondary => 'Cancel';
  @override
  String get previewStatus => 'Paid';
  @override
  String get languageTitle => 'Language and motion';
  @override
  String get languageDescription => 'Dates, numbers and prices follow it too.';
  @override
  String get reduceMotionLabel => 'Reduce motion';
  @override
  String get reduceMotionDescription =>
      'Menus, sheets and toasts appear without sliding or fading.';
  @override
  String get profileSubtitle =>
      'Your account, and the password you sign in with.';
  @override
  String get accountTitle => 'Account';
  @override
  String accountDescription({required bool canManageTeam}) => canManageTeam
      ? 'You can change these under Team.'
      : 'Ask the shop’s owner to change these.';
  @override
  String get nameLabel => 'Name';
  @override
  String get emailLabel => 'Email';
  @override
  String get roleLabel => 'Role';
  @override
  String get statusLabel => 'Status';
  @override
  String get lastActiveLabel => 'Last active';
  @override
  String activeAgo(String span) => '$span ago';
  @override
  String get passwordTitle => 'Password';
  @override
  String get passwordDescription =>
      'At least 8 characters. You stay signed in on this device.';
  @override
  String get wrongCurrentPassword =>
      'That is not your current password. Check it and try again.';
  @override
  String get passwordTooWeak => 'Choose a longer password.';
  @override
  String get passwordChanged => 'Password changed';
  @override
  String get passwordChangedDetail => 'Use it the next time you sign in.';
}

class SettingsStringsFr extends SettingsStrings {
  const SettingsStringsFr();

  @override
  String get settingsTitle => 'Réglages';
  @override
  String get appearanceTitle => 'Apparence';
  @override
  String get profileTitle => 'Profil';
  @override
  String get shopTab => 'Boutique';
  @override
  String get appearanceSubtitle =>
      'Les changements s’appliquent aussitôt et vous suivent sur tous vos '
      'appareils.';
  @override
  String get displayTitle => 'Affichage';
  @override
  String get displayDescription =>
      'Un thème, clair ou sombre, une couleur de marque, et les lignes des tableaux.';
  @override
  String get previewLabel => 'Aperçu';
  @override
  String get previewPrimary => 'Enregistrer';
  @override
  String get previewSecondary => 'Annuler';
  @override
  String get previewStatus => 'Payée';
  @override
  String get languageTitle => 'Langue et animations';
  @override
  String get languageDescription =>
      'Les dates, les nombres et les prix la suivent aussi.';
  @override
  String get reduceMotionLabel => 'Réduire les animations';
  @override
  String get reduceMotionDescription =>
      'Menus, panneaux et notifications s’affichent sans glisser ni fondre.';
  @override
  String get profileSubtitle =>
      'Votre compte, et le mot de passe avec lequel vous vous connectez.';
  @override
  String get accountTitle => 'Compte';
  @override
  String accountDescription({required bool canManageTeam}) => canManageTeam
      ? 'Vous pouvez les modifier dans Équipe.'
      : 'Demandez au propriétaire de la boutique de les modifier.';
  @override
  String get nameLabel => 'Nom';
  @override
  String get emailLabel => 'E-mail';
  @override
  String get roleLabel => 'Rôle';
  @override
  String get statusLabel => 'Statut';
  @override
  String get lastActiveLabel => 'Dernière activité';
  @override
  String activeAgo(String span) => 'il y a $span';
  @override
  String get passwordTitle => 'Mot de passe';
  @override
  String get passwordDescription =>
      'Au moins 8 caractères. Vous restez connecté sur cet appareil.';
  @override
  String get wrongCurrentPassword =>
      'Ce n’est pas votre mot de passe actuel. Vérifiez-le et réessayez.';
  @override
  String get passwordTooWeak => 'Choisissez un mot de passe plus long.';
  @override
  String get passwordChanged => 'Mot de passe modifié';
  @override
  String get passwordChangedDetail =>
      'Utilisez-le à votre prochaine connexion.';
}

class SettingsStringsAr extends SettingsStrings {
  const SettingsStringsAr();

  @override
  String get settingsTitle => 'الإعدادات';
  @override
  String get appearanceTitle => 'المظهر';
  @override
  String get profileTitle => 'الملف الشخصي';
  @override
  String get shopTab => 'المتجر';
  @override
  String get appearanceSubtitle =>
      'تُطبَّق التغييرات فورًا وترافقك على أي جهاز تسجّل الدخول منه.';
  @override
  String get displayTitle => 'العرض';
  @override
  String get displayDescription =>
      'سمة فاتحة أو داكنة، ولون العلامة، وكثافة صفوف الجداول.';
  @override
  String get previewLabel => 'معاينة';
  @override
  String get previewPrimary => 'حفظ';
  @override
  String get previewSecondary => 'إلغاء';
  @override
  String get previewStatus => 'مدفوع';
  @override
  String get languageTitle => 'اللغة والحركة';
  @override
  String get languageDescription => 'تتبعها التواريخ والأرقام والأسعار أيضًا.';
  @override
  String get reduceMotionLabel => 'تقليل الحركة';
  @override
  String get reduceMotionDescription =>
      'تظهر القوائم واللوحات والإشعارات دون انزلاق أو تلاشٍ.';
  @override
  String get profileSubtitle => 'حسابك، وكلمة المرور التي تسجّل الدخول بها.';
  @override
  String get accountTitle => 'الحساب';
  @override
  String accountDescription({required bool canManageTeam}) => canManageTeam
      ? 'يمكنك تعديلها من صفحة الفريق.'
      : 'اطلب من مالك المتجر تعديل هذه البيانات.';
  @override
  String get nameLabel => 'الاسم';
  @override
  String get emailLabel => 'البريد الإلكتروني';
  @override
  String get roleLabel => 'الدور';
  @override
  String get statusLabel => 'الحالة';
  @override
  String get lastActiveLabel => 'آخر نشاط';
  @override
  String activeAgo(String span) => 'قبل $span';
  @override
  String get passwordTitle => 'كلمة المرور';
  @override
  String get passwordDescription =>
      '8 أحرف على الأقل. ستبقى متصلًا على هذا الجهاز.';
  @override
  String get wrongCurrentPassword =>
      'هذه ليست كلمة مرورك الحالية. تحقّق منها وحاول مجددًا.';
  @override
  String get passwordTooWeak => 'اختر كلمة مرور أطول.';
  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';
  @override
  String get passwordChangedDetail => 'استخدمها في تسجيل دخولك التالي.';
}
