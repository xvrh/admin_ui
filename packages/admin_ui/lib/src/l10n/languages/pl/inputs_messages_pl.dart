import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Polish [InputsMessages].
class InputsMessagesPl extends InputsMessages {
  const InputsMessagesPl([super.localeName = 'pl']);

  @override
  String get confirm => 'Potwierdź';

  @override
  String get copied => 'Skopiowano';

  @override
  String get copyFailed => 'Nie udało się skopiować';

  @override
  String get undo => 'Cofnij';

  @override
  String get showMore => 'Pokaż więcej';

  @override
  String get showLess => 'Pokaż mniej';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get hidePassword => 'Ukryj hasło';

  @override
  String get clearSearch => 'Wyczyść wyszukiwanie';

  @override
  String get couldNotLoadResults => 'Nie udało się załadować wyników';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} z ${number(count)}';

  @override
  String get dateRange => 'Zakres dat';

  @override
  String get clearDates => 'Wyczyść daty';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) => plural(
    count,
    one: 'Ostatni dzień',
    few: 'Ostatnie ${number(count)} dni',
    many: 'Ostatnie ${number(count)} dni',
    other: 'Ostatnie ${number(count)} dnia',
  );

  @override
  String get thisMonth => 'Bieżący miesiąc';

  @override
  String get lastMonth => 'Poprzedni miesiąc';

  @override
  String get yearToDate => 'Od początku roku';

  @override
  String get searchOrJumpTo => 'Szukaj lub przejdź do…';

  @override
  String get recent => 'Ostatnie';

  @override
  String get selectAResult => 'Wybierz wynik';

  @override
  String matchedIn(String place) => 'Znaleziono w: $place';

  @override
  String get matchedInContent => 'Znaleziono w treści';

  @override
  String get run => 'Uruchom';

  @override
  String get open => 'Otwórz';

  @override
  String get typeToSearch => 'Wpisz, aby wyszukać';

  @override
  String noResultsFor(String query) => 'Brak wyników dla „$query”';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Brak wyników',
    one: '${number(count)} wynik',
    few: '${number(count)} wyniki',
    many: '${number(count)} wyników',
    other: '${number(count)} wyniku',
  );

  @override
  String get navigateHint => 'nawiguj';

  @override
  String get selectHint => 'wybierz';

  @override
  String get closeHint => 'zamknij';

  @override
  String get keysUpDown => 'Strzałki w górę i w dół';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyEscape => 'Escape';

  @override
  String get fieldsGroup => 'Pola';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get allCaughtUp => 'Brak nowych powiadomień';

  @override
  String get markAllRead => 'Oznacz wszystkie jako przeczytane';

  /// A notification is neuter, and so are notifications.
  @override
  String get unread => 'Nieprzeczytane';

  @override
  String get allNotifications => 'Wszystkie';

  @override
  String get markAsRead => 'Oznacz jako przeczytane';

  @override
  String get markAsUnread => 'Oznacz jako nieprzeczytane';

  @override
  String get viewAll => 'Pokaż wszystkie';

  @override
  String get couldNotLoadNotifications => 'Nie udało się załadować powiadomień';

  /// The default title, notifications, is neuter.
  @override
  String unreadCount(String title, int count) => plural(
    count,
    one: '$title, ${number(count)} nieprzeczytane',
    few: '$title, ${number(count)} nieprzeczytane',
    many: '$title, ${number(count)} nieprzeczytanych',
    other: '$title, ${number(count)} nieprzeczytanego',
  );

  @override
  String get appearanceTheme => 'Motyw';

  @override
  String get appearanceMode => 'Tryb';

  @override
  String get modeLight => 'Jasny';

  @override
  String get modeDark => 'Ciemny';

  @override
  String get modeSystem => 'Systemowy';

  @override
  String get accentColour => 'Kolor akcentu';

  @override
  String get themeAccent => 'Kolor motywu';

  /// Adjectives agreeing with kolor.
  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Karmazynowy',
    'Violet' => 'Fioletowy',
    'Teal' => 'Morski',
    'Amber' => 'Bursztynowy',
    _ => name,
  };

  @override
  String get tableDensity => 'Gęstość tabeli';

  /// Adjectives agreeing with gęstość.
  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Kompaktowa',
    TableDensity.standard => 'Standardowa',
    TableDensity.comfortable => 'Przestronna',
  };
}
