import '../../sections/display_messages.dart';

/// Dutch [DisplayMessages].
class DisplayMessagesNl extends DisplayMessages {
  const DisplayMessagesNl([super.localeName = 'nl']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Laden';

  @override
  String get errorTimeout =>
      'De server reageerde niet op tijd. Probeer het opnieuw.';

  @override
  String get errorUnreachable =>
      'Kan de server niet bereiken. Controleer je verbinding en probeer het '
      'opnieuw.';

  @override
  String get errorUnreadable =>
      'Het antwoord van de server kan niet worden gelezen. Probeer het '
      'opnieuw.';

  @override
  String get errorUnauthorized =>
      'Je sessie is verlopen. Log in en probeer het opnieuw.';

  @override
  String get errorPaymentRequired =>
      'Daarvoor is een betaald abonnement of meer tegoed nodig.';

  @override
  String get errorForbidden => 'Je hebt geen toestemming om dat te doen.';

  @override
  String get errorNotFound =>
      'Niet gevonden. Het is mogelijk verplaatst of verwijderd.';

  @override
  String get errorConflict =>
      'Het is elders gewijzigd. Vernieuw de pagina en probeer het opnieuw.';

  @override
  String get errorTooLarge => 'Dat is te groot voor de server.';

  @override
  String get errorRateLimited =>
      'Te veel verzoeken. Wacht even en probeer het opnieuw.';

  @override
  String get errorServer =>
      'Er is een probleem met de server. Probeer het zo opnieuw.';

  @override
  String get errorRequestFailed => 'De server kon het verzoek niet uitvoeren.';

  @override
  String get breadcrumb => 'Kruimelpad';

  @override
  String currentPage(String label) => '$label, huidige pagina';

  @override
  String get switchPage => 'Andere pagina kiezen';

  @override
  String showMore(int count) =>
      plural(count, other: 'Nog ${number(count)} tonen');

  @override
  String pageNumber(int page) => 'Pagina ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} sleutel',
    other: '${number(count)} sleutels',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} item',
    other: '${number(count)} items',
  );

  @override
  String get expandAll => 'Alles uitvouwen';

  @override
  String get collapseAll => 'Alles samenvouwen';

  @override
  String get copyJson => 'JSON kopiëren';

  @override
  String get copyValue => 'Waarde kopiëren';

  @override
  String get copyPath => 'Pad kopiëren';

  @override
  String invalidJson(String detail) => 'Ongeldige JSON — $detail';

  @override
  String get logEmpty => 'Nog geen uitvoer';

  @override
  String get zoomArea => 'Zoombaar gebied';

  @override
  String get zoomAreaHint =>
      'Scrol om te zoomen, sleep om te verschuiven; + en − zoomen, 0 past '
      'alles in beeld, pijltoetsen verschuiven.';

  @override
  String get zoomIn => 'Inzoomen';

  @override
  String get zoomOut => 'Uitzoomen';

  @override
  String get zoomToFit => 'Passend zoomen';

  @override
  String get qrCode => 'QR-code';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Upload voltooid',
    other: 'Alle ${number(total)} geüpload',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} van ${number(total)} geüpload'
      : '${number(done)} van ${number(total)} geüpload · '
            '${number(failed)} mislukt';

  @override
  String get clearCompleted => 'Voltooide wissen';

  @override
  String get queued => 'In wachtrij';

  @override
  String get retryUpload => 'Upload opnieuw proberen';

  @override
  String get removeFile => 'Bestand weghalen';

  @override
  String get cancelUpload => 'Upload annuleren';

  @override
  String get chartEmpty => 'Geen gegevens voor deze periode';

  @override
  String get heatLess => 'Minder';

  @override
  String get heatMore => 'Meer';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'stijging van $delta';

  @override
  String trendDown(String delta) => 'daling van $delta';

  @override
  String get needsAttention => 'Aandacht nodig';

  @override
  String get recentActivity => 'Recente activiteit';

  @override
  String get contentMix => 'Verdeling van inhoud';

  @override
  String itemsUnit(int count) => plural(count, one: 'item', other: 'items');

  @override
  String get allCaughtUp =>
      'Je bent helemaal bij — niets heeft aandacht nodig.';

  @override
  String get noRecentActivity => 'Geen recente activiteit';

  @override
  String get noRecentActivityHint =>
      'Bewerkingen, publicaties en uploads verschijnen hier.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Stap ${number(step)} van ${number(total)}: $title';

  @override
  String get stepCompleted => 'voltooid';

  @override
  String get stepCurrent => 'actief';

  @override
  String get stepUpcoming => 'aankomend';

  @override
  String get stepError => 'fout';

  @override
  String get addItem => 'Item toevoegen';

  @override
  String get untitled => 'Zonder titel';

  @override
  String get treeHeader => 'Groep';

  @override
  String get indent => 'Inspringing vergroten';

  @override
  String get outdent => 'Inspringing verkleinen';

  @override
  String get addChild => 'Subitem toevoegen';

  @override
  String get hideEntry => 'Verbergen';

  @override
  String get showEntry => 'Tonen';

  @override
  String movedUp(String title) => '$title omhoog verplaatst';

  @override
  String movedDown(String title) => '$title omlaag verplaatst';

  @override
  String indented(String title) => 'Inspringing van $title vergroot';

  @override
  String outdented(String title) => 'Inspringing van $title verkleind';

  @override
  String get rowMovedUp => 'Omhoog verplaatst';

  @override
  String get rowMovedDown => 'Omlaag verplaatst';

  @override
  String get rowIndented => 'Inspringing vergroot';

  @override
  String get rowOutdented => 'Inspringing verkleind';

  @override
  String get resizePanes => 'Formaat van deelvensters wijzigen';

  @override
  String get moveLeft => 'Naar links verplaatsen';

  @override
  String get moveRight => 'Naar rechts verplaatsen';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get previewHeading => 'VOORBEELD';

  @override
  String get noPreviewHeading => 'GEEN VOORBEELD';

  @override
  String get insertsInline =>
      'Wordt in de tekst ingevoegd — geen voorbeeld nodig.';

  @override
  String nothingMatches(String query) => 'Geen overeenkomsten voor ‘$query’';

  @override
  String get choices => 'Keuzes';

  @override
  String get diffAdded => 'Toegevoegd';

  @override
  String get diffRemoved => 'Verwijderd';

  @override
  String get diffChanged => 'Gewijzigd';

  @override
  String get diffMoved => 'Verplaatst';

  @override
  String get diffUnchanged => 'Ongewijzigd';

  @override
  String addedCount(int count) => '${number(count)} toegevoegd';

  @override
  String removedCount(int count) => '${number(count)} verwijderd';

  @override
  String changedCount(int count) => '${number(count)} gewijzigd';

  @override
  String movedCount(int count) => '${number(count)} verplaatst';

  /// Vóór, accented, so that it is not read as voor ("for") in capitals.
  @override
  String get before => 'Vóór';

  @override
  String get after => 'Na';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'van positie ${number(from)} naar ${number(to)}';

  @override
  String get unified => 'Gecombineerd';

  @override
  String get split => 'Naast elkaar';

  @override
  String get noChanges => 'Geen wijzigingen';

  @override
  String get versionsIdentical => 'Deze twee versies zijn identiek.';

  @override
  String get noFieldChanges => 'Geen gewijzigde velden.';

  @override
  String get noBlockChanges => 'Geen gewijzigde blokken.';

  @override
  String get empty => 'Leeg';

  @override
  String inserted(String text) => 'ingevoegd: $text, ';

  @override
  String deleted(String text) => 'verwijderd: $text, ';

  @override
  String get restore => 'Herstellen';

  @override
  String get restoreThisVersion => 'Deze versie herstellen';

  @override
  String get restoreThisField => 'Dit veld herstellen';

  @override
  String get restoreThisItem => 'Dit item herstellen';

  @override
  String get restoreLiveBlock => 'Live versie van dit blok herstellen';

  @override
  String get sharedLane => 'Gedeeld';

  @override
  String get versionCurrent => 'Huidig';

  @override
  String get versionPublished => 'Gepubliceerd';

  @override
  String get versionRestored => 'Hersteld';

  @override
  String get versionArchived => 'Gearchiveerd';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Personen om te vermelden';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 persoon om te vermelden',
    other: '${number(count)} personen om te vermelden',
  );
}
