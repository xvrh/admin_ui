import '../../sections/display_messages.dart';

/// French [DisplayMessages].
class DisplayMessagesFr extends DisplayMessages {
  const DisplayMessagesFr([super.localeName = 'fr']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Chargement';

  @override
  String get errorTimeout =>
      'Le serveur a mis trop de temps à répondre. Réessayez.';

  @override
  String get errorUnreachable =>
      'Impossible de joindre le serveur. Vérifiez votre connexion et '
      'réessayez.';

  @override
  String get errorUnreadable =>
      'La réponse du serveur est illisible. Réessayez.';

  @override
  String get errorUnauthorized =>
      'Votre session a expiré. Reconnectez-vous et réessayez.';

  @override
  String get errorPaymentRequired =>
      'Cette action nécessite une offre payante ou davantage de crédit.';

  @override
  String get errorForbidden =>
      'Vous n’avez pas l’autorisation d’effectuer cette action.';

  @override
  String get errorNotFound =>
      'Élément introuvable. Il a peut-être été déplacé ou supprimé.';

  @override
  String get errorConflict =>
      'Il a été modifié ailleurs. Rechargez la page et réessayez.';

  @override
  String get errorTooLarge =>
      'Trop volumineux pour être accepté par le serveur.';

  @override
  String get errorRateLimited =>
      'Trop de requêtes. Patientez un instant et réessayez.';

  @override
  String get errorServer =>
      'Le serveur a rencontré un problème. Réessayez dans un instant.';

  @override
  String get errorRequestFailed => 'Le serveur n’a pas pu traiter la requête.';

  @override
  String get breadcrumb => 'Fil d’Ariane';

  @override
  String currentPage(String label) => '$label, page actuelle';

  @override
  String get switchPage => 'Changer de page';

  @override
  String showMore(int count) => plural(
    count,
    one: 'Afficher ${number(count)} autre',
    other: 'Afficher ${number(count)} autres',
  );

  @override
  String pageNumber(int page) => 'Page ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} clé',
    other: '${number(count)} clés',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} élément',
    other: '${number(count)} éléments',
  );

  @override
  String get expandAll => 'Tout développer';

  @override
  String get collapseAll => 'Tout réduire';

  @override
  String get copyJson => 'Copier le JSON';

  @override
  String get copyValue => 'Copier la valeur';

  @override
  String get copyPath => 'Copier le chemin';

  @override
  String invalidJson(String detail) => 'JSON non valide — $detail';

  @override
  String get logEmpty => 'Aucune sortie pour l’instant';

  @override
  String get zoomArea => 'Vue zoomable';

  @override
  String get zoomAreaHint =>
      'Faites défiler pour zoomer, glissez pour vous déplacer ; + et − '
      'zooment, 0 ajuste, les flèches déplacent.';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get zoomToFit => 'Ajuster à la vue';

  @override
  String get qrCode => 'Code QR';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Envoi terminé',
    other: 'Les ${number(total)} fichiers sont envoyés',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} sur ${number(total)} envoyés'
      : '${number(done)} sur ${number(total)} envoyés · '
            '${number(failed)} en échec';

  @override
  String get clearCompleted => 'Effacer les terminés';

  @override
  String get queued => 'En attente';

  @override
  String get retryUpload => 'Relancer l’envoi';

  @override
  String get removeFile => 'Retirer le fichier';

  @override
  String get cancelUpload => 'Annuler l’envoi';

  @override
  String get chartEmpty => 'Aucune donnée pour cette période';

  @override
  String get heatLess => 'Moins';

  @override
  String get heatMore => 'Plus';

  /// French sets a no-break space before the colon.
  @override
  String statValue(String label, String value) => '$label : $value';

  @override
  String trendUp(String delta) => 'en hausse de $delta';

  @override
  String trendDown(String delta) => 'en baisse de $delta';

  @override
  String get needsAttention => 'À traiter';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get contentMix => 'Répartition du contenu';

  @override
  String itemsUnit(int count) =>
      plural(count, one: 'élément', other: 'éléments');

  @override
  String get allCaughtUp => 'Tout est à jour — rien à traiter.';

  @override
  String get noRecentActivity => 'Aucune activité récente';

  @override
  String get noRecentActivityHint =>
      'Les modifications, publications et envois apparaîtront ici.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Étape ${number(step)} sur ${number(total)} : $title';

  @override
  String get stepCompleted => 'terminée';

  @override
  String get stepCurrent => 'en cours';

  @override
  String get stepUpcoming => 'à venir';

  @override
  String get stepError => 'erreur';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get untitled => 'Sans titre';

  @override
  String get treeHeader => 'Groupe';

  @override
  String get indent => 'Augmenter le retrait';

  @override
  String get outdent => 'Diminuer le retrait';

  @override
  String get addChild => 'Ajouter un sous-élément';

  @override
  String get hideEntry => 'Masquer';

  @override
  String get showEntry => 'Afficher';

  @override
  String movedUp(String title) => '$title déplacé vers le haut';

  @override
  String movedDown(String title) => '$title déplacé vers le bas';

  @override
  String indented(String title) => 'Retrait de $title augmenté';

  @override
  String outdented(String title) => 'Retrait de $title diminué';

  @override
  String get rowMovedUp => 'Déplacé vers le haut';

  @override
  String get rowMovedDown => 'Déplacé vers le bas';

  @override
  String get rowIndented => 'Retrait augmenté';

  @override
  String get rowOutdented => 'Retrait diminué';

  @override
  String get resizePanes => 'Redimensionner les volets';

  @override
  String get moveLeft => 'Déplacer vers la gauche';

  @override
  String get moveRight => 'Déplacer vers la droite';

  @override
  String get preview => 'Aperçu';

  @override
  String get previewHeading => 'APERÇU';

  @override
  String get noPreviewHeading => 'AUCUN APERÇU';

  @override
  String get insertsInline =>
      'S’insère dans le texte — aucun aperçu nécessaire.';

  @override
  String nothingMatches(String query) => 'Rien ne correspond à « $query »';

  @override
  String get choices => 'Choix';

  @override
  String get diffAdded => 'Ajouté';

  @override
  String get diffRemoved => 'Supprimé';

  @override
  String get diffChanged => 'Modifié';

  @override
  String get diffMoved => 'Déplacé';

  @override
  String get diffUnchanged => 'Inchangé';

  @override
  String addedCount(int count) => plural(
    count,
    one: '${number(count)} ajouté',
    other: '${number(count)} ajoutés',
  );

  @override
  String removedCount(int count) => plural(
    count,
    one: '${number(count)} supprimé',
    other: '${number(count)} supprimés',
  );

  @override
  String changedCount(int count) => plural(
    count,
    one: '${number(count)} modifié',
    other: '${number(count)} modifiés',
  );

  @override
  String movedCount(int count) => plural(
    count,
    one: '${number(count)} déplacé',
    other: '${number(count)} déplacés',
  );

  @override
  String get before => 'Avant';

  @override
  String get after => 'Après';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'de la position ${number(from)} à ${number(to)}';

  @override
  String get unified => 'Unifiée';

  @override
  String get split => 'Côte à côte';

  @override
  String get noChanges => 'Aucune modification';

  @override
  String get versionsIdentical => 'Ces deux versions sont identiques.';

  @override
  String get noFieldChanges => 'Aucun champ modifié.';

  @override
  String get noBlockChanges => 'Aucun bloc modifié.';

  @override
  String get empty => 'Vide';

  @override
  String inserted(String text) => 'inséré : $text, ';

  @override
  String deleted(String text) => 'supprimé : $text, ';

  @override
  String get restore => 'Restaurer';

  @override
  String get restoreThisVersion => 'Restaurer cette version';

  @override
  String get restoreThisField => 'Restaurer ce champ';

  @override
  String get restoreThisItem => 'Restaurer cet élément';

  @override
  String get restoreLiveBlock => 'Rétablir la version en ligne de ce bloc';

  @override
  String get sharedLane => 'Commun';

  @override
  String get versionCurrent => 'Actuelle';

  @override
  String get versionPublished => 'Publiée';

  @override
  String get versionRestored => 'Restaurée';

  @override
  String get versionArchived => 'Archivée';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Personnes à mentionner';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 personne à mentionner',
    other: '${number(count)} personnes à mentionner',
  );
}
