import '../../sections/shell_messages.dart';

/// French [ShellMessages].
class ShellMessagesFr extends ShellMessages {
  const ShellMessagesFr([super.localeName = 'fr']);

  @override
  String get navigation => 'Navigation';

  @override
  String get mainContent => 'Contenu principal';

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
