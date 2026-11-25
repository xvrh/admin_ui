import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_es.dart';
import 'collection_messages_es.dart';
import 'display_messages_es.dart';
import 'fields_messages_es.dart';
import 'inputs_messages_es.dart';
import 'shell_messages_es.dart';

/// Spanish [AdminLocalizations].
class AdminLocalizationsEs extends AdminLocalizations {
  const AdminLocalizationsEs([super.localeName = 'es']);

  @override
  InputsMessages get inputs => const InputsMessagesEs();

  @override
  DisplayMessages get display => const DisplayMessagesEs();

  @override
  CollectionMessages get collection => const CollectionMessagesEs();

  @override
  FieldsMessages get fields => const FieldsMessagesEs();

  @override
  ShellMessages get shell => const ShellMessagesEs();

  @override
  AssetsMessages get assets => const AssetsMessagesEs();

  @override
  String get apply => 'Aplicar';

  @override
  String get retry => 'Reintentar';

  @override
  String get remove => 'Quitar';

  @override
  String removeItem(String name) => 'Quitar $name';

  @override
  String get reset => 'Restablecer';

  @override
  String get loading => 'Cargando…';

  @override
  String get saving => 'Guardando…';

  @override
  String get edited => 'Editado';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get noMatches => 'Sin coincidencias';

  @override
  String get couldNotLoad => 'No se pudo cargar';

  @override
  String get searchFailed => 'Error al buscar';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get searching => 'Buscando…';

  @override
  String get somethingWentWrong => 'Se produjo un error';

  @override
  String get somethingWentWrongTryAgain =>
      'Se produjo un error. Vuelve a intentarlo.';

  @override
  String get notAllowed => 'No tienes acceso a este contenido';

  @override
  String get notAllowedAskAdministrator =>
      'Si lo necesitas, pídeselo a un administrador.';

  @override
  String get goBack => 'Volver';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get moveUp => 'Mover hacia arriba';

  @override
  String get moveDown => 'Mover hacia abajo';

  @override
  String get selectPlaceholder => 'Seleccionar…';

  @override
  String get filterPlaceholder => 'Filtrar…';

  @override
  String get searchPlaceholder => 'Buscar…';

  @override
  String get addItem => 'Agregar elemento';

  @override
  String get addRow => 'Agregar fila';

  @override
  String get keyLabel => 'Clave';

  @override
  String get valueLabel => 'Valor';

  @override
  String get linkPlaceholder => 'Vincular…';

  @override
  String get restoreLiveVersion =>
      'Restaurar la versión publicada de este campo';

  @override
  String get assetNotFound => 'Recurso no encontrado';

  @override
  String get assetPreview => 'Vista previa del recurso';

  @override
  String get uploadFailed => 'Error al subir';

  /// The pronoun of the link agrees with what is dropped.
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => switch ((images, multiple)) {
    (false, false) => (
      before: 'Arrastra y suelta un archivo o ',
      link: 'selecciónalo',
      after: '',
    ),
    (false, true) => (
      before: 'Arrastra y suelta archivos o ',
      link: 'selecciónalos',
      after: '',
    ),
    (true, false) => (
      before: 'Arrastra y suelta una imagen o ',
      link: 'selecciónala',
      after: '',
    ),
    (true, true) => (
      before: 'Arrastra y suelta imágenes o ',
      link: 'selecciónalas',
      after: '',
    ),
  };

  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Ningún elemento seleccionado',
    one: '${number(count)} seleccionado',
    other: '${number(count)} seleccionados',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} de ${number(total)}';

  /// With a no-break space before the unit.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get copy => 'Copiar';

  @override
  String get close => 'Cerrar';

  @override
  String get clear => 'Borrar texto';

  @override
  String get search => 'Buscar';

  @override
  String get more => 'Más';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get dismiss => 'Cerrar';

  @override
  String get rowsPerPage => 'Filas por página:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first‑$last de $total';

  @override
  String get previousPage => 'Página anterior';

  @override
  String get nextPage => 'Página siguiente';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get today => 'Hoy';

  @override
  String rangeStartDate(String date) => 'Fecha de inicio $date';

  @override
  String rangeEndDate(String date) => 'Fecha de finalización $date';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get selectDateRange => 'Seleccionar periodo';

  @override
  String get navigationMenu => 'Menú de navegación';

  @override
  String get expand => 'Mostrar';

  @override
  String get collapse => 'Ocultar';

  @override
  String get proceed => 'Continuar';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Mayús';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Retroceso';

  @override
  String get keyboardKeyDelete => 'Supr';

  @override
  String get keyboardKeyEnd => 'Fin';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Inicio';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'Av Pág';

  @override
  String get keyboardKeyPageUp => 'Re Pág';

  @override
  String get keyboardKeySpace => 'Espacio';

  @override
  String get keyboardKeyCapsLock => 'Bloq Mayús';

  @override
  String get keyboardKeyPrintScreen => 'Impr Pant';

  @override
  String get keyboardKeyScrollLock => 'Bloq Despl';

  @override
  String get keyboardKeyNumLock => 'Bloq Num';

  @override
  String get keyboardKeyFn => 'Fn';
}
