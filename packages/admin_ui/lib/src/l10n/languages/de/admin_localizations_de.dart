import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_de.dart';
import 'collection_messages_de.dart';
import 'display_messages_de.dart';
import 'fields_messages_de.dart';
import 'inputs_messages_de.dart';
import 'shell_messages_de.dart';

/// German [AdminLocalizations].
class AdminLocalizationsDe extends AdminLocalizations {
  const AdminLocalizationsDe([super.localeName = 'de']);

  @override
  InputsMessages get inputs => const InputsMessagesDe();

  @override
  DisplayMessages get display => const DisplayMessagesDe();

  @override
  CollectionMessages get collection => const CollectionMessagesDe();

  @override
  FieldsMessages get fields => const FieldsMessagesDe();

  @override
  ShellMessages get shell => const ShellMessagesDe();

  @override
  AssetsMessages get assets => const AssetsMessagesDe();

  @override
  String get apply => 'Anwenden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get remove => 'Entfernen';

  @override
  String removeItem(String name) => '$name entfernen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get saving => 'Wird gespeichert…';

  @override
  String get edited => 'Bearbeitet';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get noMatches => 'Keine Treffer';

  @override
  String get couldNotLoad => 'Laden fehlgeschlagen';

  @override
  String get searchFailed => 'Suche fehlgeschlagen';

  @override
  String get loadMore => 'Weitere laden';

  @override
  String get searching => 'Suche läuft…';

  @override
  String get somethingWentWrong => 'Ein Fehler ist aufgetreten';

  @override
  String get somethingWentWrongTryAgain =>
      'Ein Fehler ist aufgetreten. Versuchen Sie es erneut.';

  @override
  String get notAllowed => 'Kein Zugriff auf diesen Bereich';

  @override
  String get notAllowedAskAdministrator =>
      'Wenden Sie sich an einen Administrator, wenn Sie Zugriff benötigen.';

  @override
  String get goBack => 'Zurück';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String get moveUp => 'Nach oben verschieben';

  @override
  String get moveDown => 'Nach unten verschieben';

  @override
  String get selectPlaceholder => 'Auswählen…';

  @override
  String get filterPlaceholder => 'Filtern…';

  @override
  String get searchPlaceholder => 'Suchen…';

  @override
  String get addItem => 'Element hinzufügen';

  @override
  String get addRow => 'Zeile hinzufügen';

  @override
  String get keyLabel => 'Schlüssel';

  @override
  String get valueLabel => 'Wert';

  @override
  String get linkPlaceholder => 'Verknüpfen…';

  @override
  String get restoreLiveVersion =>
      'Veröffentlichte Version dieses Felds wiederherstellen';

  @override
  String get assetNotFound => 'Mediendatei nicht gefunden';

  @override
  String get assetPreview => 'Vorschau der Mediendatei';

  @override
  String get uploadFailed => 'Upload fehlgeschlagen';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Datei hierher ziehen oder ',
      (false, true) => 'Dateien hierher ziehen oder ',
      (true, false) => 'Bild hierher ziehen oder ',
      (true, true) => 'Bilder hierher ziehen oder ',
    },
    link: 'auswählen',
    after: '',
  );

  /// The participle does not change with the count.
  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Nichts ausgewählt',
    other: '${number(count)} ausgewählt',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} von ${number(total)}';

  /// German sets a no-break space before the unit.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get copy => 'Kopieren';

  @override
  String get close => 'Schließen';

  @override
  String get clear => 'Text löschen';

  @override
  String get search => 'Suchen';

  @override
  String get more => 'Mehr';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get dismiss => 'Schließen';

  @override
  String get rowsPerPage => 'Zeilen pro Seite:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first–$last von $total';

  @override
  String get previousPage => 'Vorherige Seite';

  @override
  String get nextPage => 'Nächste Seite';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get today => 'Heute';

  @override
  String rangeStartDate(String date) => 'Startdatum $date';

  @override
  String rangeEndDate(String date) => 'Enddatum $date';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get selectDateRange => 'Zeitraum auswählen';

  @override
  String get navigationMenu => 'Navigationsmenü';

  @override
  String get expand => 'Maximieren';

  @override
  String get collapse => 'Minimieren';

  @override
  String get keyboardKeyControl => 'Strg';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Umschalttaste';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Rücktaste';

  @override
  String get keyboardKeyDelete => 'Entf';

  @override
  String get keyboardKeyEnd => 'Ende';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Pos1';

  @override
  String get keyboardKeyInsert => 'Einfg';

  @override
  String get keyboardKeyPageDown => 'Bild ab';

  @override
  String get keyboardKeyPageUp => 'Bild auf';

  @override
  String get keyboardKeySpace => 'Leertaste';

  @override
  String get keyboardKeyCapsLock => 'Feststelltaste';

  @override
  String get keyboardKeyPrintScreen => 'Druck';

  @override
  String get keyboardKeyScrollLock => 'Rollen';

  @override
  String get keyboardKeyNumLock => 'Num';

  @override
  String get keyboardKeyFn => 'Fn';
}
