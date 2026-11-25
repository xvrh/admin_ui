import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_nl.dart';
import 'collection_messages_nl.dart';
import 'display_messages_nl.dart';
import 'fields_messages_nl.dart';
import 'inputs_messages_nl.dart';
import 'shell_messages_nl.dart';

/// Dutch [AdminLocalizations].
class AdminLocalizationsNl extends AdminLocalizations {
  const AdminLocalizationsNl([super.localeName = 'nl']);

  @override
  InputsMessages get inputs => const InputsMessagesNl();

  @override
  DisplayMessages get display => const DisplayMessagesNl();

  @override
  CollectionMessages get collection => const CollectionMessagesNl();

  @override
  FieldsMessages get fields => const FieldsMessagesNl();

  @override
  ShellMessages get shell => const ShellMessagesNl();

  @override
  AssetsMessages get assets => const AssetsMessagesNl();

  @override
  String get apply => 'Toepassen';

  @override
  String get retry => 'Opnieuw proberen';

  /// Weghalen, not Material's verwijderen, which [delete] says.
  @override
  String get remove => 'Weghalen';

  @override
  String removeItem(String name) => '$name weghalen';

  @override
  String get reset => 'Resetten';

  @override
  String get loading => 'Laden…';

  @override
  String get saving => 'Opslaan…';

  @override
  String get edited => 'Bewerkt';

  @override
  String get unsavedChanges => 'Niet-opgeslagen wijzigingen';

  @override
  String get noResults => 'Geen resultaten';

  @override
  String get noMatches => 'Geen overeenkomsten';

  @override
  String get couldNotLoad => 'Kan niet laden';

  @override
  String get searchFailed => 'Zoeken mislukt';

  @override
  String get loadMore => 'Meer laden';

  @override
  String get searching => 'Zoeken…';

  @override
  String get somethingWentWrong => 'Er is iets misgegaan';

  @override
  String get somethingWentWrongTryAgain =>
      'Er is iets misgegaan. Probeer het opnieuw.';

  @override
  String get notAllowed => 'Je hebt hier geen toegang toe';

  @override
  String get notAllowedAskAdministrator =>
      'Vraag een beheerder om toegang als je die nodig hebt.';

  @override
  String get goBack => 'Terug';

  @override
  String get moreActions => 'Meer acties';

  @override
  String get clearSelection => 'Selectie wissen';

  @override
  String get moveUp => 'Omhoog verplaatsen';

  @override
  String get moveDown => 'Omlaag verplaatsen';

  @override
  String get selectPlaceholder => 'Selecteren…';

  @override
  String get filterPlaceholder => 'Filteren…';

  @override
  String get searchPlaceholder => 'Zoeken…';

  @override
  String get addItem => 'Item toevoegen';

  @override
  String get addRow => 'Rij toevoegen';

  @override
  String get keyLabel => 'Sleutel';

  @override
  String get valueLabel => 'Waarde';

  @override
  String get linkPlaceholder => 'Koppelen…';

  @override
  String get restoreLiveVersion => 'Live versie van dit veld herstellen';

  @override
  String get assetNotFound => 'Mediabestand niet gevonden';

  @override
  String get assetPreview => 'Voorbeeld van mediabestand';

  @override
  String get uploadFailed => 'Upload mislukt';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Sleep een bestand hierheen of ',
      (false, true) => 'Sleep bestanden hierheen of ',
      (true, false) => 'Sleep een afbeelding hierheen of ',
      (true, true) => 'Sleep afbeeldingen hierheen of ',
    },
    link: multiple ? 'selecteer ze' : 'selecteer er een',
    after: '',
  );

  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Niets geselecteerd',
    other: '${number(count)} geselecteerd',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} van ${number(total)}';

  /// A no-break space keeps the unit with its number.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get delete => 'Verwijderen';

  @override
  String get copy => 'Kopiëren';

  @override
  String get close => 'Sluiten';

  @override
  String get clear => 'Tekst wissen';

  @override
  String get search => 'Zoeken';

  @override
  String get more => 'Meer';

  @override
  String get selectAll => 'Alles selecteren';

  @override
  String get dismiss => 'Sluiten';

  @override
  String get rowsPerPage => 'Rijen per pagina:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first-$last van $total';

  @override
  String get previousPage => 'Vorige pagina';

  @override
  String get nextPage => 'Volgende pagina';

  @override
  String get previousMonth => 'Vorige maand';

  @override
  String get nextMonth => 'Volgende maand';

  @override
  String get today => 'Vandaag';

  @override
  String rangeStartDate(String date) => 'Startdatum $date';

  @override
  String rangeEndDate(String date) => 'Einddatum $date';

  @override
  String get selectDate => 'Datum selecteren';

  @override
  String get selectDateRange => 'Periode selecteren';

  @override
  String get navigationMenu => 'Navigatiemenu';

  @override
  String get expand => 'Uitvouwen';

  @override
  String get collapse => 'Samenvouwen';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'Spatie';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyFn => 'Fn';
}
