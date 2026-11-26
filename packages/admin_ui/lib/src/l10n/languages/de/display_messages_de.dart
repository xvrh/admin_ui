import '../../sections/display_messages.dart';

/// German [DisplayMessages].
class DisplayMessagesDe extends DisplayMessages {
  const DisplayMessagesDe([super.localeName = 'de']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Wird geladen';

  @override
  String get errorTimeout =>
      'Der Server hat nicht rechtzeitig geantwortet. Versuchen Sie es erneut.';

  @override
  String get errorUnreachable =>
      'Der Server ist nicht erreichbar. Prüfen Sie Ihre Verbindung und '
      'versuchen Sie es erneut.';

  @override
  String get errorUnreadable =>
      'Die Antwort des Servers konnte nicht gelesen werden. Versuchen Sie es '
      'erneut.';

  @override
  String get errorUnauthorized =>
      'Ihre Sitzung ist abgelaufen. Melden Sie sich an und versuchen Sie es '
      'erneut.';

  @override
  String get errorPaymentRequired =>
      'Dafür ist ein kostenpflichtiger Tarif oder mehr Guthaben erforderlich.';

  @override
  String get errorForbidden => 'Sie haben keine Berechtigung für diese Aktion.';

  @override
  String get errorNotFound =>
      'Das Element wurde nicht gefunden. Möglicherweise wurde es verschoben '
      'oder gelöscht.';

  @override
  String get errorConflict =>
      'Das Element wurde an anderer Stelle geändert. Laden Sie die Seite neu '
      'und versuchen Sie es erneut.';

  @override
  String get errorTooLarge => 'Zu groß, um vom Server angenommen zu werden.';

  @override
  String get errorRateLimited =>
      'Zu viele Anfragen. Warten Sie einen Moment und versuchen Sie es erneut.';

  @override
  String get errorServer =>
      'Auf dem Server ist ein Problem aufgetreten. Versuchen Sie es in Kürze '
      'erneut.';

  @override
  String get errorRequestFailed =>
      'Der Server konnte die Anfrage nicht verarbeiten.';

  @override
  String get breadcrumb => 'Navigationspfad';

  @override
  String currentPage(String label) => '$label, aktuelle Seite';

  @override
  String get switchPage => 'Seite wechseln';

  @override
  String showMore(int count) => plural(
    count,
    one: '${number(count)} weitere Ebene anzeigen',
    other: '${number(count)} weitere Ebenen anzeigen',
  );

  @override
  String pageNumber(int page) => 'Seite ${number(page)}';

  /// Schlüssel is the same in the singular and the plural.
  @override
  String jsonKeys(int count) =>
      plural(count, other: '${number(count)} Schlüssel');

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} Element',
    other: '${number(count)} Elemente',
  );

  @override
  String get expandAll => 'Alle aufklappen';

  @override
  String get collapseAll => 'Alle zuklappen';

  @override
  String get copyJson => 'JSON kopieren';

  @override
  String get copyValue => 'Wert kopieren';

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String invalidJson(String detail) => 'Ungültiges JSON – $detail';

  @override
  String get logEmpty => 'Noch keine Ausgabe';

  @override
  String get zoomArea => 'Zoombarer Bereich';

  @override
  String get zoomAreaHint =>
      'Zum Zoomen scrollen, zum Verschieben ziehen; + und − zoomen, 0 passt '
      'ein, Pfeiltasten verschieben.';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get zoomToFit => 'Einpassen';

  @override
  String get qrCode => 'QR-Code';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Upload abgeschlossen',
    other: 'Alle ${number(total)} hochgeladen',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} von ${number(total)} hochgeladen'
      : '${number(done)} von ${number(total)} hochgeladen · '
            '${number(failed)} fehlgeschlagen';

  @override
  String get clearCompleted => 'Abgeschlossene entfernen';

  @override
  String get queued => 'In Warteschlange';

  @override
  String get retryUpload => 'Upload erneut versuchen';

  @override
  String get removeFile => 'Datei entfernen';

  @override
  String get cancelUpload => 'Upload abbrechen';

  @override
  String get chartEmpty => 'Keine Daten für diesen Zeitraum';

  @override
  String get heatLess => 'Weniger';

  @override
  String get heatMore => 'Mehr';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'um $delta gestiegen';

  @override
  String trendDown(String delta) => 'um $delta gesunken';

  @override
  String get needsAttention => 'Zu erledigen';

  @override
  String get recentActivity => 'Letzte Aktivitäten';

  @override
  String get contentMix => 'Inhaltsverteilung';

  @override
  String itemsUnit(int count) =>
      plural(count, one: 'Element', other: 'Elemente');

  @override
  String get allCaughtUp => 'Alles erledigt – nichts zu tun.';

  @override
  String get noRecentActivity => 'Keine aktuellen Aktivitäten';

  @override
  String get noRecentActivityHint =>
      'Bearbeitungen, Veröffentlichungen und Uploads werden hier angezeigt.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Schritt ${number(step)} von ${number(total)}: $title';

  @override
  String get stepCompleted => 'abgeschlossen';

  @override
  String get stepCurrent => 'aktuell';

  @override
  String get stepUpcoming => 'ausstehend';

  @override
  String get stepError => 'fehlerhaft';

  @override
  String get addItem => 'Element hinzufügen';

  @override
  String get untitled => 'Ohne Titel';

  @override
  String get treeHeader => 'Gruppe';

  @override
  String get indent => 'Einrücken';

  @override
  String get outdent => 'Ausrücken';

  @override
  String get addChild => 'Unterelement hinzufügen';

  @override
  String get hideEntry => 'Ausblenden';

  @override
  String get showEntry => 'Einblenden';

  @override
  String movedUp(String title) => '$title nach oben verschoben';

  @override
  String movedDown(String title) => '$title nach unten verschoben';

  @override
  String indented(String title) => '$title eingerückt';

  @override
  String outdented(String title) => '$title ausgerückt';

  @override
  String get rowMovedUp => 'Nach oben verschoben';

  @override
  String get rowMovedDown => 'Nach unten verschoben';

  @override
  String get rowIndented => 'Eingerückt';

  @override
  String get rowOutdented => 'Ausgerückt';

  @override
  String get resizePanes => 'Größe der Bereiche ändern';

  @override
  String get moveLeft => 'Nach links verschieben';

  @override
  String get moveRight => 'Nach rechts verschieben';

  @override
  String get preview => 'Vorschau';

  @override
  String get previewHeading => 'VORSCHAU';

  @override
  String get noPreviewHeading => 'KEINE VORSCHAU';

  @override
  String get insertsInline => 'Wird im Text eingefügt – keine Vorschau nötig.';

  @override
  String nothingMatches(String query) => 'Keine Treffer für „$query“';

  @override
  String get choices => 'Optionen';

  @override
  String get diffAdded => 'Hinzugefügt';

  @override
  String get diffRemoved => 'Entfernt';

  @override
  String get diffChanged => 'Geändert';

  @override
  String get diffMoved => 'Verschoben';

  @override
  String get diffUnchanged => 'Unverändert';

  @override
  String addedCount(int count) => '${number(count)} hinzugefügt';

  @override
  String removedCount(int count) => '${number(count)} entfernt';

  @override
  String changedCount(int count) => '${number(count)} geändert';

  @override
  String movedCount(int count) => '${number(count)} verschoben';

  @override
  String get before => 'Vorher';

  @override
  String get after => 'Nachher';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'von Position ${number(from)} nach ${number(to)}';

  @override
  String get unified => 'Einspaltig';

  @override
  String get split => 'Nebeneinander';

  @override
  String get noChanges => 'Keine Änderungen';

  @override
  String get versionsIdentical => 'Diese beiden Versionen sind identisch.';

  @override
  String get noFieldChanges => 'Keine Feldänderungen.';

  @override
  String get noBlockChanges => 'Keine Blockänderungen.';

  @override
  String get empty => 'Leer';

  @override
  String inserted(String text) => 'eingefügt: $text, ';

  @override
  String deleted(String text) => 'gelöscht: $text, ';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get restoreThisVersion => 'Diese Version wiederherstellen';

  @override
  String get restoreThisField => 'Dieses Feld wiederherstellen';

  @override
  String get restoreThisItem => 'Dieses Element wiederherstellen';

  @override
  String get restoreLiveBlock =>
      'Veröffentlichte Version dieses Blocks wiederherstellen';

  @override
  String get sharedLane => 'Gemeinsam';

  @override
  String get versionCurrent => 'Aktuell';

  @override
  String get versionPublished => 'Veröffentlicht';

  @override
  String get versionRestored => 'Wiederhergestellt';

  @override
  String get versionArchived => 'Archiviert';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Personen zum Erwähnen';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 Person zum Erwähnen',
    other: '${number(count)} Personen zum Erwähnen',
  );
}
