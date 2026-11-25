import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Spanish [InputsMessages].
class InputsMessagesEs extends InputsMessages {
  const InputsMessagesEs([super.localeName = 'es']);

  @override
  String get confirm => 'Confirmar';

  @override
  String get copied => 'Copiado';

  @override
  String get copyFailed => 'Error al copiar';

  @override
  String get undo => 'Deshacer';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get couldNotLoadResults => 'No se pudieron cargar los resultados';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} de ${number(count)}';

  @override
  String get dateRange => 'Periodo';

  @override
  String get clearDates => 'Borrar fechas';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) =>
      plural(count, one: 'Último día', other: 'Últimos ${number(count)} días');

  @override
  String get thisMonth => 'Este mes';

  @override
  String get lastMonth => 'Mes pasado';

  @override
  String get yearToDate => 'Año hasta la fecha';

  @override
  String get searchOrJumpTo => 'Buscar o ir a…';

  @override
  String get recent => 'Recientes';

  @override
  String get selectAResult => 'Selecciona un resultado';

  @override
  String matchedIn(String place) => 'Coincidencia en $place';

  @override
  String get matchedInContent => 'Coincidencia en el contenido';

  @override
  String get run => 'Ejecutar';

  @override
  String get open => 'Abrir';

  @override
  String get typeToSearch => 'Escribe para buscar';

  @override
  String noResultsFor(String query) => 'No hay resultados para «$query»';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Sin resultados',
    one: '${number(count)} resultado',
    other: '${number(count)} resultados',
  );

  @override
  String get navigateHint => 'navegar';

  @override
  String get selectHint => 'seleccionar';

  @override
  String get closeHint => 'cerrar';

  @override
  String get keysUpDown => 'Flechas arriba y abajo';

  @override
  String get keyEnter => 'Intro';

  @override
  String get keyEscape => 'Escape';

  @override
  String get fieldsGroup => 'Campos';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get allCaughtUp => 'Estás al día';

  /// A notification is feminine.
  @override
  String get markAllRead => 'Marcar todas como leídas';

  /// Invariable, so it reads both with one notification and as a tab.
  @override
  String get unread => 'Sin leer';

  /// Notifications are feminine.
  @override
  String get allNotifications => 'Todas';

  /// A notification is feminine.
  @override
  String get markAsRead => 'Marcar como leída';

  /// A notification is feminine.
  @override
  String get markAsUnread => 'Marcar como no leída';

  @override
  String get viewAll => 'Ver todas';

  @override
  String get couldNotLoadNotifications =>
      'No se pudieron cargar las notificaciones';

  @override
  String unreadCount(String title, int count) =>
      '$title, ${number(count)} sin leer';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceMode => 'Modo';

  @override
  String get modeLight => 'Claro';

  @override
  String get modeDark => 'Oscuro';

  @override
  String get modeSystem => 'Sistema';

  @override
  String get accentColour => 'Color de énfasis';

  @override
  String get themeAccent => 'Color del tema';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Carmesí',
    'Violet' => 'Violeta',
    'Teal' => 'Verde azulado',
    'Amber' => 'Ámbar',
    _ => name,
  };

  @override
  String get tableDensity => 'Densidad de las tablas';

  /// A density is feminine.
  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compacta',
    TableDensity.standard => 'Estándar',
    TableDensity.comfortable => 'Cómoda',
  };
}
