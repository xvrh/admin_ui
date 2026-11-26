import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// German [InputsMessages].
class InputsMessagesDe extends InputsMessages {
  const InputsMessagesDe([super.localeName = 'de']);

  @override
  String get confirm => 'Bestätigen';

  @override
  String get copied => 'Kopiert';

  @override
  String get copyFailed => 'Kopieren fehlgeschlagen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get clearSearch => 'Suchbegriff löschen';

  @override
  String get couldNotLoadResults => 'Ergebnisse konnten nicht geladen werden';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} von ${number(count)}';

  @override
  String get dateRange => 'Zeitraum';

  @override
  String get clearDates => 'Zeitraum löschen';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) =>
      plural(count, one: 'Letzter Tag', other: 'Letzte ${number(count)} Tage');

  @override
  String get thisMonth => 'Dieser Monat';

  @override
  String get lastMonth => 'Vormonat';

  @override
  String get yearToDate => 'Seit Jahresbeginn';

  @override
  String get searchOrJumpTo => 'Suchen oder springen zu…';

  @override
  String get recent => 'Zuletzt verwendet';

  @override
  String get selectAResult => 'Ergebnis auswählen';

  @override
  String matchedIn(String place) => 'Treffer in $place';

  @override
  String get matchedInContent => 'Treffer im Inhalt';

  @override
  String get run => 'Ausführen';

  @override
  String get open => 'Öffnen';

  @override
  String get typeToSearch => 'Suchbegriff eingeben';

  @override
  String noResultsFor(String query) => 'Keine Ergebnisse für „$query“';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Keine Ergebnisse',
    one: '${number(count)} Ergebnis',
    other: '${number(count)} Ergebnisse',
  );

  @override
  String get navigateHint => 'navigieren';

  @override
  String get selectHint => 'auswählen';

  @override
  String get closeHint => 'schließen';

  @override
  String get keysUpDown => 'Pfeiltasten nach oben und unten';

  @override
  String get keyEnter => 'Eingabetaste';

  @override
  String get keyEscape => 'Escape-Taste';

  @override
  String get fieldsGroup => 'Felder';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get allCaughtUp => 'Alles erledigt';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get unread => 'Ungelesen';

  @override
  String get allNotifications => 'Alle';

  @override
  String get markAsRead => 'Als gelesen markieren';

  @override
  String get markAsUnread => 'Als ungelesen markieren';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get couldNotLoadNotifications =>
      'Benachrichtigungen konnten nicht geladen werden';

  @override
  String unreadCount(String title, int count) =>
      '$title, ${number(count)} ungelesen';

  @override
  String get appearanceTheme => 'Design';

  @override
  String get appearanceMode => 'Modus';

  @override
  String get modeLight => 'Hell';

  @override
  String get modeDark => 'Dunkel';

  @override
  String get modeSystem => 'System';

  @override
  String get accentColour => 'Akzentfarbe';

  @override
  String get themeAccent => 'Designfarbe';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Karmesin',
    'Violet' => 'Violett',
    'Teal' => 'Petrol',
    'Amber' => 'Bernstein',
    _ => name,
  };

  @override
  String get tableDensity => 'Tabellendichte';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Kompakt',
    TableDensity.standard => 'Standard',
    TableDensity.comfortable => 'Komfortabel',
  };
}
