import '../../sections/shell_messages.dart';

/// Arabic [ShellMessages].
class ShellMessagesAr extends ShellMessages {
  const ShellMessagesAr([super.localeName = 'ar']);

  @override
  String get navigation => 'التنقل';

  @override
  String get mainContent => 'المحتوى الرئيسي';

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
