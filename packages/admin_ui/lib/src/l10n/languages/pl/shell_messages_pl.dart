import '../../sections/shell_messages.dart';

/// Polish [ShellMessages].
class ShellMessagesPl extends ShellMessages {
  const ShellMessagesPl([super.localeName = 'pl']);

  @override
  String get navigation => 'Nawigacja';

  @override
  String get mainContent => 'Główna treść';

  @override
  String get openNavigation => 'Otwórz nawigację';

  @override
  String get closeNavigation => 'Zamknij nawigację';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Odrzuć';

  @override
  String get publish => 'Opublikuj';

  @override
  String get morePublishOptions => 'Więcej opcji publikowania';

  @override
  String get publishing => 'Publikowanie…';

  @override
  String get saved => 'Zapisano';

  @override
  String get published => 'Opublikowano';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Nie udało się zapisać';

  @override
  String get couldNotPublish => 'Nie udało się opublikować';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} pole wymaga uwagi',
    few: '${number(count)} pola wymagają uwagi',
    many: '${number(count)} pól wymaga uwagi',
    other: '${number(count)} pola wymaga uwagi',
  );

  @override
  String get noChangesToPublish => 'Brak zmian do opublikowania';

  @override
  String get noChanges => 'Brak zmian';

  @override
  String get discardChangesTitle => 'Odrzucić zmiany?';

  @override
  String get discardChangesMessage => 'Niezapisane zmiany zostaną utracone.';

  @override
  String get leaveWhileSavingTitle => 'Trwa zapisywanie — wyjść mimo to?';

  @override
  String get leaveWhileSavingMessage =>
      'Zmiany są wciąż zapisywane. Jeśli zapis nie powiedzie się po wyjściu, '
      'zostaną utracone.';

  @override
  String get leave => 'Wyjdź';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'nazwa@example.com';

  @override
  String get password => 'Hasło';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get forgotPassword => 'Zapomniane hasło?';

  @override
  String get or => 'lub';

  @override
  String isRequired(String label) => 'Pole „$label” jest wymagane';

  @override
  String get newPassword => 'Nowe hasło';

  @override
  String get confirmPassword => 'Potwierdź hasło';

  @override
  String get confirmNewPassword => 'Potwierdź nowe hasło';

  @override
  String get currentPassword => 'Bieżące hasło';

  @override
  String get setPassword => 'Ustaw hasło';

  @override
  String get changePassword => 'Zmień hasło';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Hasło musi mieć co najmniej ${number(minLength)} znak.',
    few: 'Hasło musi mieć co najmniej ${number(minLength)} znaki.',
    many: 'Hasło musi mieć co najmniej ${number(minLength)} znaków.',
    other: 'Hasło musi mieć co najmniej ${number(minLength)} znaku.',
  );

  @override
  String get passwordsDontMatch => 'Hasła nie są zgodne.';

  /// A password is neuter.
  @override
  String get strengthWeak => 'Słabe';

  @override
  String get strengthFair => 'Średnie';

  @override
  String get strengthGood => 'Dobre';

  @override
  String get strengthStrong => 'Silne';

  @override
  String get verificationCode => 'Kod weryfikacyjny';

  @override
  String get verify => 'Zweryfikuj';

  @override
  String codeIncomplete(int length) => plural(
    length,
    one: 'Kod ma ${number(length)} cyfrę.',
    few: 'Kod ma ${number(length)} cyfry.',
    many: 'Kod ma ${number(length)} cyfr.',
    other: 'Kod ma ${number(length)} cyfry.',
  );

  @override
  String get recoveryCode => 'Kod odzyskiwania';

  @override
  String get useRecoveryCode => 'Użyj kodu odzyskiwania';

  @override
  String get useAuthenticatorApp => 'Użyj aplikacji uwierzytelniającej';

  @override
  String get backToSignIn => 'Wróć do logowania';

  @override
  String get authenticatorQrCode => 'Kod QR dla aplikacji uwierzytelniającej';

  @override
  String get cantScanQrCode => 'Nie udaje się zeskanować kodu?';

  @override
  String get enterSetupKey => 'Zamiast tego wpisz ten klucz w aplikacji.';

  @override
  String get copySetupKey => 'Kopiuj klucz';

  @override
  String get copyAllCodes => 'Kopiuj wszystko';

  @override
  String get savedRecoveryCodes => 'Kody zostały zapisane';

  @override
  String get addTagHint => 'Dodaj…';

  /// A field is neuter.
  @override
  String get shared => 'wspólne';
}
