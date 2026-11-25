import '../../sections/shell_messages.dart';

/// Italian [ShellMessages].
class ShellMessagesIt extends ShellMessages {
  const ShellMessagesIt([super.localeName = 'it']);

  @override
  String get navigation => 'Navigazione';

  @override
  String get mainContent => 'Contenuto principale';

  @override
  String get openNavigation => 'Apri navigazione';

  @override
  String get closeNavigation => 'Chiudi navigazione';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Scarta';

  @override
  String get publish => 'Pubblica';

  @override
  String get morePublishOptions => 'Altre opzioni di pubblicazione';

  @override
  String get publishing => 'Pubblicazione…';

  @override
  String get saved => 'Salvato';

  @override
  String get published => 'Pubblicato';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Impossibile salvare';

  @override
  String get couldNotPublish => 'Impossibile pubblicare';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} campo da verificare',
    other: '${number(count)} campi da verificare',
  );

  @override
  String get noChangesToPublish => 'Nessuna modifica da pubblicare';

  @override
  String get noChanges => 'Nessuna modifica';

  @override
  String get discardChangesTitle => 'Scartare le modifiche?';

  @override
  String get discardChangesMessage =>
      'Le modifiche non salvate andranno perse.';

  @override
  String get leaveWhileSavingTitle => 'Salvataggio in corso — uscire comunque?';

  @override
  String get leaveWhileSavingMessage =>
      'Le modifiche sono ancora in fase di salvataggio. Se il salvataggio non '
      'riesce dopo l’uscita, andranno perse.';

  @override
  String get leave => 'Esci';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'nome@example.com';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Accedi';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get or => 'oppure';

  /// "Il campo" carries the agreement [label] cannot.
  @override
  String isRequired(String label) => 'Il campo «$label» è obbligatorio';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get confirmNewPassword => 'Conferma nuova password';

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get setPassword => 'Imposta password';

  @override
  String get changePassword => 'Cambia password';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Usa almeno ${number(minLength)} carattere.',
    other: 'Usa almeno ${number(minLength)} caratteri.',
  );

  @override
  String get passwordsDontMatch => 'Le password non corrispondono.';

  @override
  String get strengthWeak => 'Debole';

  /// A password is feminine.
  @override
  String get strengthFair => 'Discreta';

  /// A password is feminine.
  @override
  String get strengthGood => 'Buona';

  @override
  String get strengthStrong => 'Forte';

  @override
  String get addTagHint => 'Aggiungi…';

  @override
  String get shared => 'condiviso';
}
