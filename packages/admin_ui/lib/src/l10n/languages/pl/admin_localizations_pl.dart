import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_pl.dart';
import 'collection_messages_pl.dart';
import 'display_messages_pl.dart';
import 'fields_messages_pl.dart';
import 'inputs_messages_pl.dart';
import 'shell_messages_pl.dart';

/// Polish [AdminLocalizations].
class AdminLocalizationsPl extends AdminLocalizations {
  const AdminLocalizationsPl([super.localeName = 'pl']);

  @override
  InputsMessages get inputs => const InputsMessagesPl();

  @override
  DisplayMessages get display => const DisplayMessagesPl();

  @override
  CollectionMessages get collection => const CollectionMessagesPl();

  @override
  FieldsMessages get fields => const FieldsMessagesPl();

  @override
  ShellMessages get shell => const ShellMessagesPl();

  @override
  AssetsMessages get assets => const AssetsMessagesPl();

  @override
  String get apply => 'Zastosuj';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get remove => 'Usuń';

  @override
  String removeItem(String name) => 'Usuń: $name';

  @override
  String get reset => 'Resetuj';

  @override
  String get loading => 'Ładowanie…';

  @override
  String get saving => 'Zapisywanie…';

  @override
  String get edited => 'Edytowano';

  @override
  String get unsavedChanges => 'Niezapisane zmiany';

  @override
  String get noResults => 'Brak wyników';

  @override
  String get noMatches => 'Brak dopasowań';

  @override
  String get couldNotLoad => 'Nie udało się załadować';

  @override
  String get searchFailed => 'Wyszukiwanie nie powiodło się';

  @override
  String get loadMore => 'Załaduj więcej';

  @override
  String get searching => 'Wyszukiwanie…';

  @override
  String get somethingWentWrong => 'Coś poszło nie tak';

  @override
  String get somethingWentWrongTryAgain =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get notAllowed => 'Brak dostępu';

  @override
  String get notAllowedAskAdministrator =>
      'W razie potrzeby poproś administratora o dostęp.';

  @override
  String get goBack => 'Wróć';

  @override
  String get moreActions => 'Więcej działań';

  @override
  String get clearSelection => 'Wyczyść zaznaczenie';

  @override
  String get moveUp => 'Przenieś w górę';

  @override
  String get moveDown => 'Przenieś w dół';

  @override
  String get selectPlaceholder => 'Wybierz…';

  @override
  String get filterPlaceholder => 'Filtruj…';

  @override
  String get searchPlaceholder => 'Szukaj…';

  @override
  String get addItem => 'Dodaj element';

  @override
  String get addRow => 'Dodaj wiersz';

  @override
  String get keyLabel => 'Klucz';

  @override
  String get valueLabel => 'Wartość';

  @override
  String get linkPlaceholder => 'Powiąż…';

  @override
  String get restoreLiveVersion => 'Przywróć opublikowaną wersję tego pola';

  @override
  String get assetNotFound => 'Nie znaleziono zasobu';

  @override
  String get assetPreview => 'Podgląd zasobu';

  @override
  String get uploadFailed => 'Przesyłanie nie powiodło się';

  /// The link names the file or files again, as go or je.
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Przeciągnij i upuść plik lub ',
      (false, true) => 'Przeciągnij i upuść pliki lub ',
      (true, false) => 'Przeciągnij i upuść obraz lub ',
      (true, true) => 'Przeciągnij i upuść obrazy lub ',
    },
    link: multiple ? 'wybierz je' : 'wybierz go',
    after: '',
  );

  /// Impersonal, so the count agrees with no noun.
  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Nic nie zaznaczono',
    other: 'Zaznaczono: ${number(count)}',
  );

  @override
  String countOf(int count, int total) => '${number(count)} z ${number(total)}';

  /// Polish sets a no-break space between a number and its unit.
  @override
  String byteSize(String amount, int power) =>
      '$amount\u00A0${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get copy => 'Kopiuj';

  @override
  String get close => 'Zamknij';

  @override
  String get clear => 'Wyczyść tekst';

  @override
  String get search => 'Szukaj';

  @override
  String get more => 'Więcej';

  @override
  String get selectAll => 'Zaznacz wszystko';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get rowsPerPage => 'Wiersze na stronie:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first–$last z $total';

  @override
  String get previousPage => 'Poprzednia strona';

  @override
  String get nextPage => 'Następna strona';

  @override
  String get previousMonth => 'Poprzedni miesiąc';

  @override
  String get nextMonth => 'Następny miesiąc';

  @override
  String get today => 'Dziś';

  @override
  String rangeStartDate(String date) => 'Data rozpoczęcia: $date';

  @override
  String rangeEndDate(String date) => 'Data zakończenia: $date';

  @override
  String get selectDate => 'Wybierz datę';

  @override
  String get selectDateRange => 'Wybierz zakres';

  @override
  String get navigationMenu => 'Menu nawigacyjne';

  @override
  String get expand => 'Rozwiń';

  @override
  String get collapse => 'Zwiń';

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
  String get keyboardKeyPageDown => 'PgDn';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'Spacja';

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
