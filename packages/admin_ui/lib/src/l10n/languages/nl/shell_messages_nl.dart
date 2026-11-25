import '../../sections/shell_messages.dart';

/// Dutch [ShellMessages].
class ShellMessagesNl extends ShellMessages {
  const ShellMessagesNl([super.localeName = 'nl']);

  @override
  String get navigation => 'Navigatie';

  @override
  String get mainContent => 'Hoofdinhoud';

  @override
  String get openNavigation => 'Navigatie openen';

  @override
  String get closeNavigation => 'Navigatie sluiten';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Negeren';

  @override
  String get publish => 'Publiceren';

  @override
  String get morePublishOptions => 'Meer publicatieopties';

  @override
  String get publishing => 'Publiceren…';

  @override
  String get saved => 'Opgeslagen';

  @override
  String get published => 'Gepubliceerd';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Opslaan mislukt';

  @override
  String get couldNotPublish => 'Publiceren mislukt';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} veld heeft aandacht nodig',
    other: '${number(count)} velden hebben aandacht nodig',
  );

  @override
  String get noChangesToPublish => 'Geen wijzigingen om te publiceren';

  @override
  String get noChanges => 'Geen wijzigingen';

  @override
  String get discardChangesTitle => 'Wijzigingen negeren?';

  @override
  String get discardChangesMessage =>
      'Niet-opgeslagen wijzigingen gaan verloren.';

  @override
  String get leaveWhileSavingTitle =>
      'Bezig met opslaan — pagina toch verlaten?';

  @override
  String get leaveWhileSavingMessage =>
      'Je wijzigingen worden nog opgeslagen. Als het opslaan mislukt nadat je '
      'de pagina hebt verlaten, gaan ze verloren.';

  @override
  String get leave => 'Verlaten';

  @override
  String get email => 'E-mailadres';

  @override
  String get emailHint => 'naam@example.com';

  @override
  String get password => 'Wachtwoord';

  @override
  String get signIn => 'Inloggen';

  @override
  String get forgotPassword => 'Wachtwoord vergeten?';

  @override
  String get or => 'of';

  @override
  String isRequired(String label) => '$label is verplicht';

  @override
  String get newPassword => 'Nieuw wachtwoord';

  @override
  String get confirmPassword => 'Wachtwoord bevestigen';

  @override
  String get confirmNewPassword => 'Nieuw wachtwoord bevestigen';

  @override
  String get currentPassword => 'Huidig wachtwoord';

  @override
  String get setPassword => 'Wachtwoord instellen';

  @override
  String get changePassword => 'Wachtwoord wijzigen';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Gebruik minimaal ${number(minLength)} teken.',
    other: 'Gebruik minimaal ${number(minLength)} tekens.',
  );

  @override
  String get passwordsDontMatch => 'Wachtwoorden komen niet overeen.';

  @override
  String get strengthWeak => 'Zwak';

  @override
  String get strengthFair => 'Redelijk';

  @override
  String get strengthGood => 'Goed';

  @override
  String get strengthStrong => 'Sterk';

  @override
  String get addTagHint => 'Toevoegen…';

  @override
  String get shared => 'gedeeld';
}
