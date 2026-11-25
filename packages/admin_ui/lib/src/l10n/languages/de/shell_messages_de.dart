import '../../sections/shell_messages.dart';

/// German [ShellMessages].
class ShellMessagesDe extends ShellMessages {
  const ShellMessagesDe([super.localeName = 'de']);

  @override
  String get navigation => 'Navigation';

  @override
  String get mainContent => 'Hauptinhalt';

  @override
  String get openNavigation => 'Navigation öffnen';

  @override
  String get closeNavigation => 'Navigation schließen';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Verwerfen';

  @override
  String get publish => 'Veröffentlichen';

  @override
  String get morePublishOptions => 'Weitere Veröffentlichungsoptionen';

  @override
  String get publishing => 'Wird veröffentlicht…';

  @override
  String get saved => 'Gespeichert';

  @override
  String get published => 'Veröffentlicht';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Speichern fehlgeschlagen';

  @override
  String get couldNotPublish => 'Veröffentlichen fehlgeschlagen';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} Feld fehlerhaft',
    other: '${number(count)} Felder fehlerhaft',
  );

  @override
  String get noChangesToPublish => 'Keine Änderungen zum Veröffentlichen';

  @override
  String get noChanges => 'Keine Änderungen';

  @override
  String get discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String get discardChangesMessage =>
      'Nicht gespeicherte Änderungen gehen verloren.';

  @override
  String get leaveWhileSavingTitle => 'Speichern läuft – trotzdem verlassen?';

  @override
  String get leaveWhileSavingMessage =>
      'Die Änderungen werden noch gespeichert. Schlägt das Speichern nach dem '
      'Verlassen fehl, gehen sie verloren.';

  @override
  String get leave => 'Verlassen';

  @override
  String get email => 'E-Mail';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => 'Passwort';

  @override
  String get signIn => 'Anmelden';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get or => 'oder';

  @override
  String isRequired(String label) => '$label ist ein Pflichtfeld';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get setPassword => 'Passwort festlegen';

  @override
  String get changePassword => 'Passwort ändern';

  /// Zeichen is the same in the singular and the plural.
  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    other: 'Mindestens ${number(minLength)} Zeichen verwenden.',
  );

  @override
  String get passwordsDontMatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get strengthWeak => 'Schwach';

  @override
  String get strengthFair => 'Mittel';

  @override
  String get strengthGood => 'Gut';

  @override
  String get strengthStrong => 'Stark';

  @override
  String get addTagHint => 'Hinzufügen…';

  @override
  String get shared => 'gemeinsam';
}
