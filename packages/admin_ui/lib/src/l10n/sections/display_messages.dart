/// @docImport '../admin_ui_localizations.dart';
library;

import '../messages.dart';

/// Strings for the layout, data display, feedback, history, tree-editor and
/// insert-picker widgets.
///
/// [DisplayMessagesEn], [DisplayMessagesFr] and [DisplayMessagesAr] each
/// extend this class directly, so a member added here without its French or
/// Arabic text fails to compile. Add a message to all three in the same edit.
abstract class DisplayMessages extends AdminMessages {
  const DisplayMessages(super.localeName);

  /// [parts] read as one phrase, for an accessible name built from pieces:
  /// "Revenue: $48.2k, up 12%, vs last month".
  String joinParts(List<String> parts);

  // Loading and errors.

  /// The accessible name of a spinner or a progress bar with no text of its
  /// own; [AdminLocalizations.loading] without its ellipsis.
  String get loadingLabel;

  /// A request that ran out of time.
  String get errorTimeout;

  /// A server that could not be reached at all.
  String get errorUnreachable;

  /// A response that came back but could not be parsed.
  String get errorUnreadable;

  /// HTTP 401.
  String get errorUnauthorized;

  /// HTTP 402.
  String get errorPaymentRequired;

  /// HTTP 403.
  String get errorForbidden;

  /// HTTP 404.
  String get errorNotFound;

  /// HTTP 409.
  String get errorConflict;

  /// HTTP 413.
  String get errorTooLarge;

  /// HTTP 429.
  String get errorRateLimited;

  /// HTTP 5xx.
  String get errorServer;

  /// Any other HTTP 4xx.
  String get errorRequestFailed;

  // Breadcrumbs and pagination.

  /// The name of the breadcrumb navigation landmark.
  String get breadcrumb;

  /// The accessible name of the last crumb, the page the reader is on.
  String currentPage(String label);

  /// The caret beside a crumb that lists its sibling pages.
  String get switchPage;

  /// The `…` that stands for [count] collapsed crumbs.
  String showMore(int count);

  /// A page number's accessible name.
  String pageNumber(int page);

  // JSON viewer.

  /// An object's member count, as its folded summary: "3 keys".
  String jsonKeys(int count);

  /// An array's element count, as its folded summary: "3 items".
  String jsonItems(int count);

  String get expandAll;

  String get collapseAll;

  String get copyJson;

  /// A JSON row's action that copies the row's value.
  String get copyValue;

  /// A JSON row's action that copies the row's path, `$.customer.email`.
  String get copyPath;

  /// A source that failed to parse; [detail] is the parser's own message.
  String invalidJson(String detail);

  // Upload.

  /// Every upload in the queue finished: "Upload complete" for one file.
  String uploadDone(int total);

  /// A queue still running or with failures: "Uploaded 2 of 5 · 1 failed".
  String uploadProgress(int done, int total, int failed);

  /// Drops every finished and failed row from the queue.
  String get clearCompleted;

  /// A file waiting for its turn.
  String get queued;

  String get retryUpload;

  String get removeFile;

  String get cancelUpload;

  // Charts and stats.

  /// A chart card with nothing to plot.
  String get chartEmpty;

  /// A stat tile's name and value: "Revenue: $48.2k".
  String statValue(String label, String value);

  /// A rising trend, spoken: "up 12%".
  String trendUp(String delta);

  /// A falling trend, spoken: "down 0.4%".
  String trendDown(String delta);

  // Dashboard.

  String get needsAttention;

  String get recentActivity;

  String get contentMix;

  /// The noun under a donut's total, which is shown on its own line above
  /// it: "items".
  String itemsUnit(int count);

  /// The attention row when nothing needs attention.
  String get allCaughtUp;

  String get noRecentActivity;

  String get noRecentActivityHint;

  /// An attention tile read as one phrase: "7 drafts to publish, across
  /// pages". [label] is the caller's own noun phrase for [count] things.
  String attentionItem(int count, String label, String? caption);

  // Steps.

  /// A step's position and title: "Step 1 of 4: Account".
  String stepOf(int step, int total, String title);

  String get stepCompleted;

  String get stepCurrent;

  String get stepUpcoming;

  String get stepError;

  // Tree editor.

  /// Adds an entry at the root of the tree.
  String get addItem;

  /// An entry with an empty title.
  String get untitled;

  /// The tag of a header entry, which groups its children and points nowhere
  /// itself.
  String get treeHeader;

  String get indent;

  String get outdent;

  String get addChild;

  /// Hides an entry from what the tree publishes.
  String get hideEntry;

  /// Shows a hidden entry again.
  String get showEntry;

  /// Announced after a keyboard move, as focus stays on the row.
  String movedUp(String title);

  String movedDown(String title);

  String indented(String title);

  String outdented(String title);

  // Insert picker.

  /// Shows the preview of the highlighted entry.
  String get preview;

  /// The heading of the preview pane, in upper case where the script has
  /// one.
  String get previewHeading;

  /// [previewHeading] for an entry that has no preview.
  String get noPreviewHeading;

  /// Why an entry inserted inline has no preview.
  String get insertsInline;

  /// A search that found nothing; [query] comes quoted.
  String nothingMatches(String query);

  /// The accessible name of the list of entries to insert.
  String get choices;

  // History.

  String get diffAdded;

  String get diffRemoved;

  String get diffChanged;

  String get diffMoved;

  String get diffUnchanged;

  /// A count chip's accessible name: "2 added".
  String addedCount(int count);

  String removedCount(int count);

  String changedCount(int count);

  String movedCount(int count);

  /// The older side of a comparison, set in capitals by the widget.
  String get before;

  /// The newer side of a comparison, set in capitals by the widget.
  String get after;

  /// Who made a version, and when: "Marina Cole · 2 hours ago".
  String authorAndTime(String author, String time);

  /// Where a moved block or record sat, and sits now, 1-based.
  String movedFromTo(int from, int to);

  /// A diff's single-column layout.
  String get unified;

  /// A diff's before | after layout.
  String get split;

  String get noChanges;

  String get versionsIdentical;

  String get noFieldChanges;

  String get noBlockChanges;

  /// The accessible name of a dash standing for no content.
  String get empty;

  /// A word diff's inserted run, spoken, with the pause before the next run.
  String inserted(String text);

  /// A word diff's deleted run, spoken, with the pause before the next run.
  String deleted(String text);

  /// The quiet revert action of a diff.
  String get restore;

  String get restoreThisVersion;

  String get restoreThisField;

  String get restoreThisItem;

  String get restoreLiveBlock;

  /// A field's lane that is not per language.
  String get sharedLane;

  String get versionCurrent;

  String get versionPublished;

  String get versionRestored;

  String get versionArchived;

  /// An archived version by its number: "v3".
  String versionNumber(int version);

  // Mentions.

  /// The accessible name of a mention field's suggestion list.
  String get mentionSuggestions;

  /// Announced as a mention field's suggestions open or change: "3 people
  /// to mention". Never 0, which is `AdminLocalizations.noMatches`.
  String mentionMatches(int count);
}

/// English [DisplayMessages]. Subclass it to override a few strings.
class DisplayMessagesEn extends DisplayMessages {
  const DisplayMessagesEn([super.localeName = 'en']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Loading';

  @override
  String get errorTimeout => 'The server took too long to respond. Try again.';

  @override
  String get errorUnreachable =>
      'Can’t reach the server. Check your connection and try again.';

  @override
  String get errorUnreadable =>
      'The server’s response couldn’t be read. Try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Sign in and try again.';

  @override
  String get errorPaymentRequired => 'That needs a paid plan or more credit.';

  @override
  String get errorForbidden => 'You don’t have permission to do that.';

  @override
  String get errorNotFound =>
      'It couldn’t be found. It may have been moved or deleted.';

  @override
  String get errorConflict =>
      'It was changed somewhere else. Reload and try again.';

  @override
  String get errorTooLarge => 'That’s too large for the server to accept.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorServer =>
      'The server ran into a problem. Try again in a moment.';

  @override
  String get errorRequestFailed => 'The server couldn’t complete the request.';

  @override
  String get breadcrumb => 'Breadcrumb';

  @override
  String currentPage(String label) => '$label, current page';

  @override
  String get switchPage => 'Switch page';

  @override
  String showMore(int count) =>
      plural(count, other: 'Show ${number(count)} more');

  @override
  String pageNumber(int page) => 'Page ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} key',
    other: '${number(count)} keys',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} item',
    other: '${number(count)} items',
  );

  @override
  String get expandAll => 'Expand all';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get copyValue => 'Copy value';

  @override
  String get copyPath => 'Copy path';

  @override
  String invalidJson(String detail) => 'Invalid JSON — $detail';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Upload complete',
    other: 'All ${number(total)} uploaded',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? 'Uploaded ${number(done)} of ${number(total)}'
      : 'Uploaded ${number(done)} of ${number(total)} · '
            '${number(failed)} failed';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get queued => 'Queued';

  @override
  String get retryUpload => 'Retry upload';

  @override
  String get removeFile => 'Remove file';

  @override
  String get cancelUpload => 'Cancel upload';

  @override
  String get chartEmpty => 'No data for this period';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'up $delta';

  @override
  String trendDown(String delta) => 'down $delta';

  @override
  String get needsAttention => 'Needs your attention';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get contentMix => 'Content mix';

  @override
  String itemsUnit(int count) => plural(count, one: 'item', other: 'items');

  @override
  String get allCaughtUp => "You're all caught up — nothing needs attention.";

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get noRecentActivityHint =>
      'Edits, publishes and uploads will show up here.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Step ${number(step)} of ${number(total)}: $title';

  @override
  String get stepCompleted => 'completed';

  @override
  String get stepCurrent => 'current';

  @override
  String get stepUpcoming => 'upcoming';

  @override
  String get stepError => 'error';

  @override
  String get addItem => 'Add item';

  @override
  String get untitled => 'Untitled';

  @override
  String get treeHeader => 'Group';

  @override
  String get indent => 'Indent';

  @override
  String get outdent => 'Outdent';

  @override
  String get addChild => 'Add child';

  @override
  String get hideEntry => 'Hide';

  @override
  String get showEntry => 'Show';

  @override
  String movedUp(String title) => '$title moved up';

  @override
  String movedDown(String title) => '$title moved down';

  @override
  String indented(String title) => '$title indented';

  @override
  String outdented(String title) => '$title outdented';

  @override
  String get preview => 'Preview';

  @override
  String get previewHeading => 'PREVIEW';

  @override
  String get noPreviewHeading => 'NO PREVIEW';

  @override
  String get insertsInline => 'Inserts inline — no preview needed.';

  @override
  String nothingMatches(String query) => 'Nothing matches “$query”';

  @override
  String get choices => 'Choices';

  @override
  String get diffAdded => 'Added';

  @override
  String get diffRemoved => 'Removed';

  @override
  String get diffChanged => 'Changed';

  @override
  String get diffMoved => 'Moved';

  @override
  String get diffUnchanged => 'Unchanged';

  @override
  String addedCount(int count) => '${number(count)} added';

  @override
  String removedCount(int count) => '${number(count)} removed';

  @override
  String changedCount(int count) => '${number(count)} changed';

  @override
  String movedCount(int count) => '${number(count)} moved';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'from position ${number(from)} to ${number(to)}';

  @override
  String get unified => 'Unified';

  @override
  String get split => 'Split';

  @override
  String get noChanges => 'No changes';

  @override
  String get versionsIdentical => 'These two versions are identical.';

  @override
  String get noFieldChanges => 'No field changes.';

  @override
  String get noBlockChanges => 'No block changes.';

  @override
  String get empty => 'Empty';

  @override
  String inserted(String text) => 'inserted: $text, ';

  @override
  String deleted(String text) => 'deleted: $text, ';

  @override
  String get restore => 'Restore';

  @override
  String get restoreThisVersion => 'Restore this version';

  @override
  String get restoreThisField => 'Restore this field';

  @override
  String get restoreThisItem => 'Restore this item';

  @override
  String get restoreLiveBlock => 'Restore the live version of this block';

  @override
  String get sharedLane => 'Shared';

  @override
  String get versionCurrent => 'Current';

  @override
  String get versionPublished => 'Published';

  @override
  String get versionRestored => 'Restored';

  @override
  String get versionArchived => 'Archived';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'People to mention';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 person to mention',
    other: '${number(count)} people to mention',
  );
}

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

/// Arabic [DisplayMessages].
class DisplayMessagesAr extends DisplayMessages {
  const DisplayMessagesAr([super.localeName = 'ar']);

  /// Arabic separates with its own comma.
  @override
  String joinParts(List<String> parts) => parts.join('، ');

  @override
  String get loadingLabel => 'جارٍ التحميل';

  @override
  String get errorTimeout => 'استغرق الخادم وقتًا طويلًا للرد. حاول مرة أخرى.';

  @override
  String get errorUnreachable =>
      'تعذّر الوصول إلى الخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorUnreadable => 'تعذّرت قراءة رد الخادم. حاول مرة أخرى.';

  @override
  String get errorUnauthorized =>
      'انتهت صلاحية جلستك. سجّل الدخول وحاول مرة أخرى.';

  @override
  String get errorPaymentRequired => 'يتطلب هذا خطة مدفوعة أو رصيدًا إضافيًا.';

  @override
  String get errorForbidden => 'ليس لديك إذن للقيام بذلك.';

  @override
  String get errorNotFound => 'لم يُعثر عليه. ربما نُقل أو حُذف.';

  @override
  String get errorConflict => 'عُدِّل في مكان آخر. أعد التحميل وحاول مرة أخرى.';

  @override
  String get errorTooLarge => 'الحجم أكبر مما يقبله الخادم.';

  @override
  String get errorRateLimited => 'طلبات كثيرة جدًا. انتظر لحظة وحاول مرة أخرى.';

  @override
  String get errorServer => 'واجه الخادم مشكلة. حاول مرة أخرى بعد لحظات.';

  @override
  String get errorRequestFailed => 'تعذّر على الخادم إتمام الطلب.';

  @override
  String get breadcrumb => 'مسار التنقل';

  @override
  String currentPage(String label) => '$label، الصفحة الحالية';

  @override
  String get switchPage => 'تبديل الصفحة';

  @override
  String showMore(int count) => plural(
    count,
    zero: 'إظهار ${number(count)} عنصر آخر',
    one: 'إظهار عنصر آخر',
    two: 'إظهار عنصرين آخرين',
    few: 'إظهار ${number(count)} عناصر أخرى',
    many: 'إظهار ${number(count)} عنصرًا آخر',
    other: 'إظهار ${number(count)} عنصر آخر',
  );

  @override
  String pageNumber(int page) => 'الصفحة ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    zero: '${number(count)} مفتاح',
    one: 'مفتاح واحد',
    two: 'مفتاحان',
    few: '${number(count)} مفاتيح',
    many: '${number(count)} مفتاحًا',
    other: '${number(count)} مفتاح',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    zero: '${number(count)} عنصر',
    one: 'عنصر واحد',
    two: 'عنصران',
    few: '${number(count)} عناصر',
    many: '${number(count)} عنصرًا',
    other: '${number(count)} عنصر',
  );

  @override
  String get expandAll => 'توسيع الكل';

  @override
  String get collapseAll => 'طي الكل';

  @override
  String get copyJson => 'نسخ JSON';

  @override
  String get copyValue => 'نسخ القيمة';

  @override
  String get copyPath => 'نسخ المسار';

  @override
  String invalidJson(String detail) => 'JSON غير صالح — $detail';

  @override
  String uploadDone(int total) => plural(
    total,
    zero: 'لم يُرفع أي ملف',
    one: 'اكتمل الرفع',
    two: 'تم رفع الملفين',
    few: 'تم رفع الملفات الـ${number(total)}',
    many: 'تم رفع ${number(total)} ملفًا',
    other: 'تم رفع ${number(total)} ملف',
  );

  @override
  String uploadProgress(int done, int total, int failed) {
    final uploaded = 'تم رفع ${number(done)} من ${number(total)}';
    if (failed == 0) return uploaded;
    final failures = plural(
      failed,
      one: 'تعذّر رفع ملف واحد',
      two: 'تعذّر رفع ملفين',
      few: 'تعذّر رفع ${number(failed)} ملفات',
      many: 'تعذّر رفع ${number(failed)} ملفًا',
      other: 'تعذّر رفع ${number(failed)} ملف',
    );
    return '$uploaded · $failures';
  }

  @override
  String get clearCompleted => 'مسح المكتمل';

  @override
  String get queued => 'في الانتظار';

  @override
  String get retryUpload => 'إعادة محاولة الرفع';

  @override
  String get removeFile => 'إزالة الملف';

  @override
  String get cancelUpload => 'إلغاء الرفع';

  @override
  String get chartEmpty => 'لا توجد بيانات لهذه الفترة';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'ارتفاع $delta';

  @override
  String trendDown(String delta) => 'انخفاض $delta';

  @override
  String get needsAttention => 'يحتاج إلى انتباهك';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get contentMix => 'توزيع المحتوى';

  @override
  String itemsUnit(int count) => plural(
    count,
    zero: 'عنصر',
    one: 'عنصر',
    two: 'عنصران',
    few: 'عناصر',
    many: 'عنصرًا',
    other: 'عنصر',
  );

  @override
  String get allCaughtUp => 'كل شيء على ما يرام — لا شيء يحتاج إلى انتباهك.';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get noRecentActivityHint =>
      'ستظهر هنا التعديلات وعمليات النشر والرفع.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label، $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'الخطوة ${number(step)} من ${number(total)}: $title';

  @override
  String get stepCompleted => 'مكتملة';

  @override
  String get stepCurrent => 'الحالية';

  @override
  String get stepUpcoming => 'قادمة';

  @override
  String get stepError => 'خطأ';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get untitled => 'بلا عنوان';

  @override
  String get treeHeader => 'مجموعة';

  @override
  String get indent => 'زيادة الإزاحة';

  @override
  String get outdent => 'إنقاص الإزاحة';

  @override
  String get addChild => 'إضافة عنصر فرعي';

  @override
  String get hideEntry => 'إخفاء';

  @override
  String get showEntry => 'إظهار';

  @override
  String movedUp(String title) => 'نُقل $title لأعلى';

  @override
  String movedDown(String title) => 'نُقل $title لأسفل';

  @override
  String indented(String title) => 'زيدت إزاحة $title';

  @override
  String outdented(String title) => 'أُنقصت إزاحة $title';

  @override
  String get preview => 'معاينة';

  @override
  String get previewHeading => 'معاينة';

  @override
  String get noPreviewHeading => 'لا توجد معاينة';

  @override
  String get insertsInline => 'يُدرج داخل النص — لا حاجة إلى معاينة.';

  @override
  String nothingMatches(String query) => 'لا شيء يطابق ”$query“';

  @override
  String get choices => 'الخيارات';

  @override
  String get diffAdded => 'مضاف';

  @override
  String get diffRemoved => 'محذوف';

  @override
  String get diffChanged => 'معدَّل';

  @override
  String get diffMoved => 'منقول';

  @override
  String get diffUnchanged => 'بلا تغيير';

  @override
  String addedCount(int count) => plural(
    count,
    zero: '${number(count)} إضافة',
    one: 'إضافة واحدة',
    two: 'إضافتان',
    few: '${number(count)} إضافات',
    many: '${number(count)} إضافة',
    other: '${number(count)} إضافة',
  );

  @override
  String removedCount(int count) => plural(
    count,
    zero: '${number(count)} عملية حذف',
    one: 'عملية حذف واحدة',
    two: 'عمليتا حذف',
    few: '${number(count)} عمليات حذف',
    many: '${number(count)} عملية حذف',
    other: '${number(count)} عملية حذف',
  );

  @override
  String changedCount(int count) => plural(
    count,
    zero: '${number(count)} تعديل',
    one: 'تعديل واحد',
    two: 'تعديلان',
    few: '${number(count)} تعديلات',
    many: '${number(count)} تعديلًا',
    other: '${number(count)} تعديل',
  );

  @override
  String movedCount(int count) => plural(
    count,
    zero: '${number(count)} عملية نقل',
    one: 'عملية نقل واحدة',
    two: 'عمليتا نقل',
    few: '${number(count)} عمليات نقل',
    many: '${number(count)} عملية نقل',
    other: '${number(count)} عملية نقل',
  );

  @override
  String get before => 'قبل';

  @override
  String get after => 'بعد';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'من الموضع ${number(from)} إلى ${number(to)}';

  @override
  String get unified => 'موحّد';

  @override
  String get split => 'جنبًا إلى جنب';

  @override
  String get noChanges => 'لا توجد تغييرات';

  @override
  String get versionsIdentical => 'هاتان النسختان متطابقتان.';

  @override
  String get noFieldChanges => 'لا تغييرات في الحقول.';

  @override
  String get noBlockChanges => 'لا تغييرات في الكتل.';

  @override
  String get empty => 'فارغ';

  @override
  String inserted(String text) => 'مُدرج: $text، ';

  @override
  String deleted(String text) => 'محذوف: $text، ';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreThisVersion => 'استعادة هذه النسخة';

  @override
  String get restoreThisField => 'استعادة هذا الحقل';

  @override
  String get restoreThisItem => 'استعادة هذا العنصر';

  @override
  String get restoreLiveBlock => 'استعادة النسخة المنشورة من هذه الكتلة';

  @override
  String get sharedLane => 'مشترك';

  @override
  String get versionCurrent => 'الحالية';

  @override
  String get versionPublished => 'منشورة';

  @override
  String get versionRestored => 'مستعادة';

  @override
  String get versionArchived => 'مؤرشفة';

  @override
  String versionNumber(int version) => 'الإصدار $version';

  @override
  String get mentionSuggestions => 'أشخاص للإشارة إليهم';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: 'شخص واحد للإشارة إليه',
    two: 'شخصان للإشارة إليهما',
    few: '${number(count)} أشخاص للإشارة إليهم',
    many: '${number(count)} شخصًا للإشارة إليهم',
    other: '${number(count)} شخص للإشارة إليهم',
  );
}
