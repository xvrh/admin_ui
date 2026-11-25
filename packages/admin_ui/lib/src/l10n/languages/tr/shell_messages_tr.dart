import '../../sections/shell_messages.dart';

/// Turkish [ShellMessages].
class ShellMessagesTr extends ShellMessages {
  const ShellMessagesTr([super.localeName = 'tr']);

  @override
  String get navigation => 'Gezinme';

  @override
  String get mainContent => 'Ana içerik';

  @override
  String get openNavigation => 'Gezinme menüsünü aç';

  @override
  String get closeNavigation => 'Gezinme menüsünü kapat';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Değişiklikleri at';

  @override
  String get publish => 'Yayımla';

  @override
  String get morePublishOptions => 'Diğer yayımlama seçenekleri';

  @override
  String get publishing => 'Yayımlanıyor…';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get published => 'Yayımlandı';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Kaydedilemedi';

  @override
  String get couldNotPublish => 'Yayımlanamadı';

  @override
  String fieldsNeedAttention(int count) =>
      plural(count, other: '${number(count)} alan dikkat gerektiriyor');

  @override
  String get noChangesToPublish => 'Yayımlanacak değişiklik yok';

  @override
  String get noChanges => 'Değişiklik yok';

  @override
  String get discardChangesTitle => 'Değişiklikler atılsın mı?';

  @override
  String get discardChangesMessage =>
      'Kaydedilmemiş değişiklikleriniz kaybolacak.';

  @override
  String get leaveWhileSavingTitle =>
      'Kaydetme sürüyor — yine de ayrılmak istiyor musunuz?';

  @override
  String get leaveWhileSavingMessage =>
      'Değişiklikleriniz hâlâ kaydediliyor. Siz ayrıldıktan sonra kaydetme '
      'başarısız olursa değişiklikler kaybolacak.';

  @override
  String get leave => 'Ayrıl';

  @override
  String get email => 'E-posta';

  @override
  String get emailHint => 'adiniz@example.com';

  @override
  String get password => 'Şifre';

  @override
  String get signIn => 'Oturum aç';

  @override
  String get forgotPassword => 'Şifrenizi mi unuttunuz?';

  @override
  String get or => 'veya';

  /// "alanı" carries the ending, so [label] stays as it is.
  @override
  String isRequired(String label) => '$label alanı zorunludur';

  @override
  String get newPassword => 'Yeni şifre';

  @override
  String get confirmPassword => 'Şifreyi onaylayın';

  @override
  String get confirmNewPassword => 'Yeni şifreyi onaylayın';

  @override
  String get currentPassword => 'Mevcut şifre';

  @override
  String get setPassword => 'Şifre belirle';

  @override
  String get changePassword => 'Şifreyi değiştir';

  @override
  String passwordTooShort(int minLength) =>
      plural(minLength, other: 'En az ${number(minLength)} karakter kullanın.');

  @override
  String get passwordsDontMatch => 'Şifreler eşleşmiyor.';

  @override
  String get strengthWeak => 'Zayıf';

  @override
  String get strengthFair => 'Orta';

  @override
  String get strengthGood => 'İyi';

  @override
  String get strengthStrong => 'Güçlü';

  @override
  String get addTagHint => 'Ekle…';

  @override
  String get shared => 'ortak';
}
