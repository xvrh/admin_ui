import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Dutch [InputsMessages].
class InputsMessagesNl extends InputsMessages {
  const InputsMessagesNl([super.localeName = 'nl']);

  @override
  String get confirm => 'Bevestigen';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get copyFailed => 'Kopiëren mislukt';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get showMore => 'Meer tonen';

  @override
  String get showLess => 'Minder tonen';

  @override
  String get showPassword => 'Wachtwoord tonen';

  @override
  String get hidePassword => 'Wachtwoord verbergen';

  @override
  String get clearSearch => 'Zoekopdracht wissen';

  @override
  String get couldNotLoadResults => 'Kan resultaten niet laden';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} van ${number(count)}';

  @override
  String get dateRange => 'Periode';

  @override
  String get clearDates => 'Datums wissen';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) => plural(
    count,
    one: 'Afgelopen dag',
    other: 'Afgelopen ${number(count)} dagen',
  );

  @override
  String get thisMonth => 'Deze maand';

  @override
  String get lastMonth => 'Vorige maand';

  @override
  String get yearToDate => 'Dit jaar tot nu toe';

  @override
  String get searchOrJumpTo => 'Zoek of ga naar…';

  @override
  String get recent => 'Recent gebruikt';

  @override
  String get selectAResult => 'Selecteer een resultaat';

  @override
  String matchedIn(String place) => 'Gevonden in $place';

  @override
  String get matchedInContent => 'Gevonden in de inhoud';

  @override
  String get run => 'Uitvoeren';

  @override
  String get open => 'Openen';

  @override
  String get typeToSearch => 'Typ om te zoeken';

  @override
  String noResultsFor(String query) => 'Geen resultaten voor ‘$query’';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Geen resultaten',
    one: '${number(count)} resultaat',
    other: '${number(count)} resultaten',
  );

  @override
  String get navigateHint => 'navigeren';

  @override
  String get selectHint => 'selecteren';

  @override
  String get closeHint => 'sluiten';

  @override
  String get keysUpDown => 'Pijltoetsen omhoog en omlaag';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyEscape => 'Escape';

  @override
  String get fieldsGroup => 'Velden';

  @override
  String get notifications => 'Meldingen';

  @override
  String get allCaughtUp => 'Je bent helemaal bij';

  @override
  String get markAllRead => 'Alles als gelezen markeren';

  @override
  String get unread => 'Ongelezen';

  @override
  String get allNotifications => 'Alle';

  @override
  String get markAsRead => 'Als gelezen markeren';

  @override
  String get markAsUnread => 'Als ongelezen markeren';

  @override
  String get viewAll => 'Alles bekijken';

  @override
  String get couldNotLoadNotifications => 'Kan meldingen niet laden';

  @override
  String unreadCount(String title, int count) =>
      '$title, ${number(count)} ongelezen';

  @override
  String get appearanceTheme => 'Thema';

  @override
  String get appearanceMode => 'Modus';

  @override
  String get modeLight => 'Licht';

  @override
  String get modeDark => 'Donker';

  @override
  String get modeSystem => 'Systeem';

  @override
  String get accentColour => 'Accentkleur';

  @override
  String get themeAccent => 'Themakleur';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Karmozijn',
    'Violet' => 'Violet',
    'Teal' => 'Blauwgroen',
    'Amber' => 'Amber',
    _ => name,
  };

  @override
  String get tableDensity => 'Tabeldichtheid';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compact',
    TableDensity.standard => 'Standaard',
    TableDensity.comfortable => 'Ruim',
  };
}
