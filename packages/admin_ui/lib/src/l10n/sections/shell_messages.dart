import '../messages.dart';

/// Strings for the app shell, the auth forms and the generic form save flow.
///
/// [ShellMessagesEn], [ShellMessagesFr] and [ShellMessagesAr] each
/// extend this class directly, so a member added here without its French or
/// Arabic text fails to compile. Add a message to all three in the same edit.
abstract class ShellMessages extends AdminMessages {
  const ShellMessages(super.localeName);

  /// The sidebar's navigation landmark.
  String get navigation;

  /// The compact shell's menu button, which opens the navigation drawer.
  String get openNavigation;

  /// The navigation drawer's close button.
  String get closeNavigation;

  /// A navigation item's accessible name with its count: "Pages, 3".
  String navItemWithBadge(String label, String badge);

  /// Throws a form's unsaved edits away.
  String get discard;

  /// Makes a document's edits live.
  String get publish;

  /// The accessible name of a split Publish button's caret.
  String get morePublishOptions;

  /// The save status while a publish is in flight, with a trailing ellipsis.
  String get publishing;

  /// The save status once the edits are saved.
  String get saved;

  /// The save status once the edits are live.
  String get published;

  /// A save status with a detail after it, such as when it happened:
  /// "Saved · 2m ago".
  String statusWithDetail(String status, String detail);

  /// The save status after a save failed for no stated reason.
  String get couldNotSave;

  /// The save status after a publish failed for no stated reason.
  String get couldNotPublish;

  /// The save status while [count] fields are in error.
  String fieldsNeedAttention(int count);

  /// Why Publish is disabled on a form with nothing new to publish.
  String get noChangesToPublish;

  /// Why a submit with a caller's own label is disabled on a form with
  /// nothing new to submit.
  String get noChanges;

  /// The title of the prompt before leaving a form with unsaved edits.
  String get discardChangesTitle;

  /// The body of that prompt.
  String get discardChangesMessage;

  /// The title of the prompt before leaving while a save is in flight.
  String get leaveWhileSavingTitle;

  /// The body of that prompt.
  String get leaveWhileSavingMessage;

  /// Confirms leaving while a save is in flight.
  String get leave;

  /// The sign-in form's email label.
  String get email;

  /// The sign-in form's email placeholder: an example address.
  String get emailHint;

  /// The sign-in form's password label.
  String get password;

  /// The sign-in form's submit.
  String get signIn;

  /// The link to recover a forgotten password.
  String get forgotPassword;

  /// The separator between signing in with a password and with a provider.
  String get or;

  /// An auth field left empty on submit, named by its [label].
  String isRequired(String label);

  /// The field for a password being chosen.
  String get newPassword;

  /// The field repeating the chosen password.
  String get confirmPassword;

  /// [confirmPassword] where the form also asks for the current one.
  String get confirmNewPassword;

  /// The field for the password in use, when changing it.
  String get currentPassword;

  /// Submits a first password, or a reset one.
  String get setPassword;

  /// Submits a password change.
  String get changePassword;

  /// A new password shorter than [minLength] characters.
  String passwordTooShort(int minLength);

  /// A confirmation that differs from the new password.
  String get passwordsDontMatch;

  /// The lowest password strength.
  String get strengthWeak;

  /// The second password strength.
  String get strengthFair;

  /// The third password strength.
  String get strengthGood;

  /// The highest password strength.
  String get strengthStrong;

  /// The placeholder of a tags field's add input.
  String get addTagHint;

  /// Marks a field whose one value serves every language.
  String get shared;
}

/// English [ShellMessages]. Subclass it to override a few strings.
class ShellMessagesEn extends ShellMessages {
  const ShellMessagesEn([super.localeName = 'en']);

  @override
  String get navigation => 'Navigation';

  @override
  String get openNavigation => 'Open navigation';

  @override
  String get closeNavigation => 'Close navigation';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Discard';

  @override
  String get publish => 'Publish';

  @override
  String get morePublishOptions => 'More publish options';

  @override
  String get publishing => 'Publishing…';

  @override
  String get saved => 'Saved';

  @override
  String get published => 'Published';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Couldn’t save';

  @override
  String get couldNotPublish => 'Couldn’t publish';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} field needs attention',
    other: '${number(count)} fields need attention',
  );

  @override
  String get noChangesToPublish => 'No changes to publish';

  @override
  String get noChanges => 'No changes';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes that will be lost.';

  @override
  String get leaveWhileSavingTitle => 'Saving in progress — leave anyway?';

  @override
  String get leaveWhileSavingMessage =>
      'Your changes are still being saved. If the save fails after you '
      'leave, they will be lost.';

  @override
  String get leave => 'Leave';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get or => 'or';

  @override
  String isRequired(String label) => '$label is required';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get setPassword => 'Set password';

  @override
  String get changePassword => 'Change password';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Use at least ${number(minLength)} character.',
    other: 'Use at least ${number(minLength)} characters.',
  );

  @override
  String get passwordsDontMatch => "Passwords don't match.";

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get addTagHint => 'Add…';

  @override
  String get shared => 'shared';
}

/// French [ShellMessages].
class ShellMessagesFr extends ShellMessages {
  const ShellMessagesFr([super.localeName = 'fr']);

  @override
  String get navigation => 'Navigation';

  @override
  String get openNavigation => 'Ouvrir la navigation';

  @override
  String get closeNavigation => 'Fermer la navigation';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Abandonner';

  @override
  String get publish => 'Publier';

  @override
  String get morePublishOptions => 'Plus d’options de publication';

  @override
  String get publishing => 'Publication…';

  @override
  String get saved => 'Enregistré';

  @override
  String get published => 'Publié';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Enregistrement impossible';

  @override
  String get couldNotPublish => 'Publication impossible';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} champ à vérifier',
    other: '${number(count)} champs à vérifier',
  );

  @override
  String get noChangesToPublish => 'Aucune modification à publier';

  @override
  String get noChanges => 'Aucune modification';

  @override
  String get discardChangesTitle => 'Abandonner les modifications ?';

  @override
  String get discardChangesMessage =>
      'Vos modifications non enregistrées seront perdues.';

  @override
  String get leaveWhileSavingTitle =>
      'Enregistrement en cours — quitter quand même ?';

  @override
  String get leaveWhileSavingMessage =>
      'Vos modifications sont en cours d’enregistrement. Si l’enregistrement '
      'échoue après votre départ, elles seront perdues.';

  @override
  String get leave => 'Quitter';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'vous@example.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get or => 'ou';

  @override
  String isRequired(String label) => 'Le champ « $label » est obligatoire';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get setPassword => 'Définir le mot de passe';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Utilisez au moins ${number(minLength)} caractère.',
    other: 'Utilisez au moins ${number(minLength)} caractères.',
  );

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get strengthWeak => 'Faible';

  @override
  String get strengthFair => 'Moyen';

  @override
  String get strengthGood => 'Bon';

  @override
  String get strengthStrong => 'Fort';

  @override
  String get addTagHint => 'Ajouter…';

  @override
  String get shared => 'partagé';
}

/// Arabic [ShellMessages].
class ShellMessagesAr extends ShellMessages {
  const ShellMessagesAr([super.localeName = 'ar']);

  @override
  String get navigation => 'التنقل';

  @override
  String get openNavigation => 'فتح التنقل';

  @override
  String get closeNavigation => 'إغلاق التنقل';

  @override
  String navItemWithBadge(String label, String badge) => '$label، $badge';

  @override
  String get discard => 'تجاهل';

  @override
  String get publish => 'نشر';

  @override
  String get morePublishOptions => 'خيارات نشر إضافية';

  @override
  String get publishing => 'جارٍ النشر…';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get published => 'تم النشر';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'تعذّر الحفظ';

  @override
  String get couldNotPublish => 'تعذّر النشر';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    zero: 'لا توجد حقول تحتاج إلى مراجعة',
    one: 'حقل واحد يحتاج إلى مراجعة',
    two: 'حقلان يحتاجان إلى مراجعة',
    few: '${number(count)} حقول تحتاج إلى مراجعة',
    many: '${number(count)} حقلًا يحتاج إلى مراجعة',
    other: '${number(count)} حقل يحتاج إلى مراجعة',
  );

  @override
  String get noChangesToPublish => 'لا توجد تغييرات لنشرها';

  @override
  String get noChanges => 'لا توجد تغييرات';

  @override
  String get discardChangesTitle => 'هل تريد تجاهل التغييرات؟';

  @override
  String get discardChangesMessage => 'لديك تغييرات غير محفوظة ستُفقد.';

  @override
  String get leaveWhileSavingTitle =>
      'الحفظ قيد التقدم — هل تريد المغادرة على أي حال؟';

  @override
  String get leaveWhileSavingMessage =>
      'لا يزال حفظ تغييراتك جاريًا. إذا فشل الحفظ بعد مغادرتك فستُفقد.';

  @override
  String get leave => 'مغادرة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get or => 'أو';

  @override
  String isRequired(String label) => 'حقل ”$label“ مطلوب';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get setPassword => 'تعيين كلمة المرور';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    zero: 'استخدم ${number(minLength)} حرف على الأقل.',
    one: 'استخدم حرفًا واحدًا على الأقل.',
    two: 'استخدم حرفين على الأقل.',
    few: 'استخدم ${number(minLength)} أحرف على الأقل.',
    many: 'استخدم ${number(minLength)} حرفًا على الأقل.',
    other: 'استخدم ${number(minLength)} حرف على الأقل.',
  );

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthFair => 'مقبولة';

  @override
  String get strengthGood => 'جيدة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get addTagHint => 'إضافة…';

  @override
  String get shared => 'مشترك';
}
