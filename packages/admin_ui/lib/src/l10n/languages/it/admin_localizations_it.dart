import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_it.dart';
import 'collection_messages_it.dart';
import 'display_messages_it.dart';
import 'fields_messages_it.dart';
import 'inputs_messages_it.dart';
import 'shell_messages_it.dart';

/// Italian [AdminLocalizations].
class AdminLocalizationsIt extends AdminLocalizations {
  const AdminLocalizationsIt([super.localeName = 'it']);

  @override
  InputsMessages get inputs => const InputsMessagesIt();

  @override
  DisplayMessages get display => const DisplayMessagesIt();

  @override
  CollectionMessages get collection => const CollectionMessagesIt();

  @override
  FieldsMessages get fields => const FieldsMessagesIt();

  @override
  ShellMessages get shell => const ShellMessagesIt();

  @override
  AssetsMessages get assets => const AssetsMessagesIt();

  @override
  String get apply => 'Applica';

  @override
  String get retry => 'Riprova';

  @override
  String get remove => 'Rimuovi';

  @override
  String removeItem(String name) => 'Rimuovi $name';

  @override
  String get reset => 'Reimposta';

  @override
  String get loading => 'Caricamento…';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get edited => 'Modificato';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get noMatches => 'Nessuna corrispondenza';

  @override
  String get couldNotLoad => 'Impossibile caricare';

  @override
  String get searchFailed => 'Ricerca non riuscita';

  @override
  String get loadMore => 'Carica altro';

  /// "Ricerca…" alone would read as the search box's placeholder.
  @override
  String get searching => 'Ricerca in corso…';

  @override
  String get somethingWentWrong => 'Si è verificato un errore';

  @override
  String get somethingWentWrongTryAgain =>
      'Si è verificato un errore. Riprova.';

  @override
  String get notAllowed => 'Accesso non consentito';

  @override
  String get notAllowedAskAdministrator =>
      'Se ti serve, chiedi l’accesso a un amministratore.';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get moreActions => 'Altre azioni';

  @override
  String get clearSelection => 'Deseleziona tutto';

  @override
  String get moveUp => 'Sposta su';

  @override
  String get moveDown => 'Sposta giù';

  @override
  String get selectPlaceholder => 'Seleziona…';

  @override
  String get filterPlaceholder => 'Filtra…';

  @override
  String get searchPlaceholder => 'Cerca…';

  @override
  String get addItem => 'Aggiungi elemento';

  @override
  String get addRow => 'Aggiungi riga';

  @override
  String get keyLabel => 'Chiave';

  @override
  String get valueLabel => 'Valore';

  @override
  String get linkPlaceholder => 'Collega…';

  @override
  String get restoreLiveVersion =>
      'Ripristina la versione pubblicata di questo campo';

  @override
  String get assetNotFound => 'Risorsa non trovata';

  @override
  String get assetPreview => 'Anteprima della risorsa';

  @override
  String get uploadFailed => 'Caricamento non riuscito';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Trascina qui un file o ',
      (false, true) => 'Trascina qui i file o ',
      (true, false) => 'Trascina qui un’immagine o ',
      (true, true) => 'Trascina qui le immagini o ',
    },
    link: 'sfoglia',
    after: '',
  );

  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Nessuna selezione',
    one: '${number(count)} selezionato',
    other: '${number(count)} selezionati',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} di ${number(total)}';

  /// The units English writes, with a no-break space before them.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get copy => 'Copia';

  @override
  String get close => 'Chiudi';

  @override
  String get clear => 'Cancella testo';

  @override
  String get search => 'Cerca';

  @override
  String get more => 'Altro';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get dismiss => 'Ignora';

  @override
  String get rowsPerPage => 'Righe per pagina:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first-$last di $total';

  @override
  String get previousPage => 'Pagina precedente';

  @override
  String get nextPage => 'Pagina successiva';

  @override
  String get previousMonth => 'Mese precedente';

  @override
  String get nextMonth => 'Mese successivo';

  @override
  String get today => 'Oggi';

  @override
  String rangeStartDate(String date) => 'Data di inizio $date';

  @override
  String rangeEndDate(String date) => 'Data di fine $date';

  @override
  String get selectDate => 'Seleziona data';

  @override
  String get selectDateRange => 'Seleziona intervallo';

  @override
  String get navigationMenu => 'Menu di navigazione';

  @override
  String get expand => 'Espandi';

  @override
  String get collapse => 'Comprimi';

  @override
  String get proceed => 'Continua';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Maiusc';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyDelete => 'Canc';

  @override
  String get keyboardKeyEnd => 'Fine';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Ins';

  @override
  String get keyboardKeyPageDown => 'Pag giù';

  @override
  String get keyboardKeyPageUp => 'Pag su';

  @override
  String get keyboardKeySpace => 'Barra spaziatrice';

  @override
  String get keyboardKeyCapsLock => 'Bloc Maiusc';

  @override
  String get keyboardKeyPrintScreen => 'Stamp';

  @override
  String get keyboardKeyScrollLock => 'Bloc Scorr';

  @override
  String get keyboardKeyNumLock => 'Bloc Num';

  @override
  String get keyboardKeyFn => 'Fn';
}
