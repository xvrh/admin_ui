import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Italian [InputsMessages].
class InputsMessagesIt extends InputsMessages {
  const InputsMessagesIt([super.localeName = 'it']);

  @override
  String get confirm => 'Conferma';

  @override
  String get copied => 'Copiato';

  @override
  String get copyFailed => 'Copia non riuscita';

  @override
  String get undo => 'Annulla';

  @override
  String get showMore => 'Mostra altro';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get clearSearch => 'Cancella ricerca';

  @override
  String get couldNotLoadResults => 'Impossibile caricare i risultati';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} di ${number(count)}';

  @override
  String get dateRange => 'Intervallo di date';

  @override
  String get clearDates => 'Cancella date';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) => plural(
    count,
    one: 'Ultimo giorno',
    other: 'Ultimi ${number(count)} giorni',
  );

  @override
  String get thisMonth => 'Questo mese';

  @override
  String get lastMonth => 'Mese scorso';

  @override
  String get yearToDate => 'Da inizio anno';

  @override
  String get searchOrJumpTo => 'Cerca o vai a…';

  @override
  String get recent => 'Recenti';

  @override
  String get selectAResult => 'Seleziona un risultato';

  /// A colon, as [place] comes without the article Italian would put
  /// before it.
  @override
  String matchedIn(String place) => 'Corrispondenza in: $place';

  @override
  String get matchedInContent => 'Corrispondenza nel contenuto';

  @override
  String get run => 'Esegui';

  @override
  String get open => 'Apri';

  @override
  String get typeToSearch => 'Digita per cercare';

  /// Caporali, with no space inside.
  @override
  String noResultsFor(String query) => 'Nessun risultato per «$query»';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Nessun risultato',
    one: '${number(count)} risultato',
    other: '${number(count)} risultati',
  );

  @override
  String get navigateHint => 'naviga';

  @override
  String get selectHint => 'seleziona';

  @override
  String get closeHint => 'chiudi';

  @override
  String get keysUpDown => 'Frecce su e giù';

  @override
  String get keyEnter => 'Invio';

  @override
  String get keyEscape => 'Esc';

  @override
  String get fieldsGroup => 'Campi';

  @override
  String get notifications => 'Notifiche';

  @override
  String get allCaughtUp => 'Nessuna notifica';

  @override
  String get markAllRead => 'Segna tutte come lette';

  /// A notification is feminine.
  @override
  String get unread => 'Non letta';

  /// Notifications are feminine.
  @override
  String get allNotifications => 'Tutte';

  /// A notification is feminine.
  @override
  String get markAsRead => 'Segna come letta';

  /// A notification is feminine.
  @override
  String get markAsUnread => 'Segna come non letta';

  @override
  String get viewAll => 'Visualizza tutte';

  @override
  String get couldNotLoadNotifications => 'Impossibile caricare le notifiche';

  /// The default title, notifications, is feminine.
  @override
  String unreadCount(String title, int count) => plural(
    count,
    one: '$title, ${number(count)} non letta',
    other: '$title, ${number(count)} non lette',
  );

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceMode => 'Modalità';

  @override
  String get modeLight => 'Chiaro';

  @override
  String get modeDark => 'Scuro';

  @override
  String get modeSystem => 'Sistema';

  @override
  String get accentColour => 'Colore d’accento';

  @override
  String get themeAccent => 'Colore del tema';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Cremisi',
    'Violet' => 'Viola',
    'Teal' => 'Verde petrolio',
    'Amber' => 'Ambra',
    _ => name,
  };

  @override
  String get tableDensity => 'Densità delle tabelle';

  /// A density is feminine.
  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compatta',
    TableDensity.standard => 'Standard',
    TableDensity.comfortable => 'Comoda',
  };
}
