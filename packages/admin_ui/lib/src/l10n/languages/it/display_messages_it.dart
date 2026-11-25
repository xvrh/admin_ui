import '../../sections/display_messages.dart';

/// Italian [DisplayMessages].
class DisplayMessagesIt extends DisplayMessages {
  const DisplayMessagesIt([super.localeName = 'it']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Caricamento';

  @override
  String get errorTimeout =>
      'Il server ha impiegato troppo tempo a rispondere. Riprova.';

  @override
  String get errorUnreachable =>
      'Impossibile raggiungere il server. Controlla la connessione e riprova.';

  @override
  String get errorUnreadable =>
      'Impossibile leggere la risposta del server. Riprova.';

  @override
  String get errorUnauthorized =>
      'La sessione è scaduta. Accedi di nuovo e riprova.';

  @override
  String get errorPaymentRequired =>
      'Serve un piano a pagamento o più credito.';

  @override
  String get errorForbidden =>
      'Non hai l’autorizzazione per eseguire questa operazione.';

  @override
  String get errorNotFound =>
      'Elemento non trovato. Potrebbe essere stato spostato o eliminato.';

  @override
  String get errorConflict =>
      'È stato modificato altrove. Ricarica la pagina e riprova.';

  @override
  String get errorTooLarge => 'Troppo grande per essere accettato dal server.';

  @override
  String get errorRateLimited =>
      'Troppe richieste. Attendi un momento e riprova.';

  @override
  String get errorServer =>
      'Si è verificato un problema sul server. Riprova tra poco.';

  @override
  String get errorRequestFailed =>
      'Il server non è riuscito a completare la richiesta.';

  @override
  String get breadcrumb => 'Percorso di navigazione';

  @override
  String currentPage(String label) => '$label, pagina corrente';

  @override
  String get switchPage => 'Cambia pagina';

  @override
  String showMore(int count) => plural(
    count,
    one: 'Mostra ${number(count)} altro',
    other: 'Mostra altri ${number(count)}',
  );

  @override
  String pageNumber(int page) => 'Pagina ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} chiave',
    other: '${number(count)} chiavi',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} elemento',
    other: '${number(count)} elementi',
  );

  @override
  String get expandAll => 'Espandi tutto';

  @override
  String get collapseAll => 'Comprimi tutto';

  @override
  String get copyJson => 'Copia JSON';

  @override
  String get copyValue => 'Copia valore';

  @override
  String get copyPath => 'Copia percorso';

  @override
  String invalidJson(String detail) => 'JSON non valido — $detail';

  @override
  String get logEmpty => 'Ancora nessun output';

  @override
  String get zoomArea => 'Area ingrandibile';

  @override
  String get zoomAreaHint =>
      'Scorri per lo zoom, trascina per spostarti; + e − regolano lo zoom, '
      '0 adatta alla vista, le frecce spostano.';

  @override
  String get zoomIn => 'Aumenta zoom';

  @override
  String get zoomOut => 'Riduci zoom';

  @override
  String get zoomToFit => 'Adatta alla vista';

  /// "File" does not change in the plural.
  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Caricamento completato',
    other: 'Caricati tutti i ${number(total)} file',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? 'Caricati ${number(done)} di ${number(total)}'
      : plural(
          failed,
          one:
              'Caricati ${number(done)} di ${number(total)} · '
              '${number(failed)} non riuscito',
          other:
              'Caricati ${number(done)} di ${number(total)} · '
              '${number(failed)} non riusciti',
        );

  @override
  String get clearCompleted => 'Rimuovi completati';

  @override
  String get queued => 'In coda';

  @override
  String get retryUpload => 'Riprova caricamento';

  @override
  String get removeFile => 'Rimuovi file';

  @override
  String get cancelUpload => 'Annulla caricamento';

  @override
  String get chartEmpty => 'Nessun dato per questo periodo';

  @override
  String get heatLess => 'Meno';

  @override
  String get heatMore => 'Più';

  @override
  String statValue(String label, String value) => '$label: $value';

  /// "di" rather than "del", which a number such as 8% would elide.
  @override
  String trendUp(String delta) => 'in aumento di $delta';

  /// "di" rather than "del", which a number such as 8% would elide.
  @override
  String trendDown(String delta) => 'in calo di $delta';

  @override
  String get needsAttention => 'Richiede attenzione';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String get contentMix => 'Distribuzione dei contenuti';

  @override
  String itemsUnit(int count) =>
      plural(count, one: 'elemento', other: 'elementi');

  @override
  String get allCaughtUp => 'Tutto in ordine — nulla richiede attenzione.';

  @override
  String get noRecentActivity => 'Nessuna attività recente';

  @override
  String get noRecentActivityHint =>
      'Qui compariranno modifiche, pubblicazioni e caricamenti.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Passaggio ${number(step)} di ${number(total)}: $title';

  /// A step, passaggio, is masculine.
  @override
  String get stepCompleted => 'completato';

  @override
  String get stepCurrent => 'in corso';

  @override
  String get stepUpcoming => 'da completare';

  @override
  String get stepError => 'errore';

  @override
  String get addItem => 'Aggiungi elemento';

  @override
  String get untitled => 'Senza titolo';

  @override
  String get treeHeader => 'Gruppo';

  @override
  String get indent => 'Aumenta rientro';

  @override
  String get outdent => 'Riduci rientro';

  @override
  String get addChild => 'Aggiungi sottoelemento';

  @override
  String get hideEntry => 'Nascondi';

  @override
  String get showEntry => 'Mostra';

  @override
  String movedUp(String title) => '$title spostato su';

  @override
  String movedDown(String title) => '$title spostato giù';

  @override
  String indented(String title) => 'Rientro di $title aumentato';

  @override
  String outdented(String title) => 'Rientro di $title ridotto';

  @override
  String get rowMovedUp => 'Spostato su';

  @override
  String get rowMovedDown => 'Spostato giù';

  @override
  String get rowIndented => 'Rientro aumentato';

  @override
  String get rowOutdented => 'Rientro ridotto';

  @override
  String get resizePanes => 'Ridimensiona riquadri';

  @override
  String get moveLeft => 'Sposta a sinistra';

  @override
  String get moveRight => 'Sposta a destra';

  @override
  String get preview => 'Anteprima';

  @override
  String get previewHeading => 'ANTEPRIMA';

  @override
  String get noPreviewHeading => 'NESSUNA ANTEPRIMA';

  @override
  String get insertsInline =>
      'Si inserisce nel testo — nessuna anteprima necessaria.';

  /// Caporali, with no space inside.
  @override
  String nothingMatches(String query) => 'Nessuna corrispondenza per «$query»';

  @override
  String get choices => 'Opzioni';

  @override
  String get diffAdded => 'Aggiunto';

  @override
  String get diffRemoved => 'Rimosso';

  @override
  String get diffChanged => 'Modificato';

  @override
  String get diffMoved => 'Spostato';

  @override
  String get diffUnchanged => 'Invariato';

  @override
  String addedCount(int count) => plural(
    count,
    one: '${number(count)} aggiunto',
    other: '${number(count)} aggiunti',
  );

  @override
  String removedCount(int count) => plural(
    count,
    one: '${number(count)} rimosso',
    other: '${number(count)} rimossi',
  );

  @override
  String changedCount(int count) => plural(
    count,
    one: '${number(count)} modificato',
    other: '${number(count)} modificati',
  );

  @override
  String movedCount(int count) => plural(
    count,
    one: '${number(count)} spostato',
    other: '${number(count)} spostati',
  );

  @override
  String get before => 'Prima';

  @override
  String get after => 'Dopo';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  /// "posizione" twice, as "alla" before a number such as 8 would elide.
  @override
  String movedFromTo(int from, int to) =>
      'dalla posizione ${number(from)} alla posizione ${number(to)}';

  /// A layout, vista, is feminine.
  @override
  String get unified => 'Unificata';

  /// A layout, vista, is feminine.
  @override
  String get split => 'Affiancata';

  @override
  String get noChanges => 'Nessuna modifica';

  @override
  String get versionsIdentical => 'Le due versioni sono identiche.';

  @override
  String get noFieldChanges => 'Nessun campo modificato.';

  @override
  String get noBlockChanges => 'Nessun blocco modificato.';

  @override
  String get empty => 'Vuoto';

  @override
  String inserted(String text) => 'inserito: $text, ';

  @override
  String deleted(String text) => 'eliminato: $text, ';

  @override
  String get restore => 'Ripristina';

  @override
  String get restoreThisVersion => 'Ripristina questa versione';

  @override
  String get restoreThisField => 'Ripristina questo campo';

  @override
  String get restoreThisItem => 'Ripristina questo elemento';

  @override
  String get restoreLiveBlock =>
      'Ripristina la versione pubblicata di questo blocco';

  @override
  String get sharedLane => 'Condiviso';

  @override
  String get versionCurrent => 'Attuale';

  /// A version is feminine.
  @override
  String get versionPublished => 'Pubblicata';

  /// A version is feminine.
  @override
  String get versionRestored => 'Ripristinata';

  /// A version is feminine.
  @override
  String get versionArchived => 'Archiviata';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Persone da menzionare';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '${number(count)} persona da menzionare',
    other: '${number(count)} persone da menzionare',
  );
}
