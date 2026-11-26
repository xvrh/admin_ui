import '../../sections/display_messages.dart';

/// Spanish [DisplayMessages].
class DisplayMessagesEs extends DisplayMessages {
  const DisplayMessagesEs([super.localeName = 'es']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Cargando';

  @override
  String get errorTimeout =>
      'El servidor tardó demasiado en responder. Vuelve a intentarlo.';

  @override
  String get errorUnreachable =>
      'No se puede conectar con el servidor. Comprueba tu conexión y vuelve '
      'a intentarlo.';

  @override
  String get errorUnreadable =>
      'No se pudo leer la respuesta del servidor. Vuelve a intentarlo.';

  @override
  String get errorUnauthorized =>
      'Tu sesión ha expirado. Inicia sesión y vuelve a intentarlo.';

  @override
  String get errorPaymentRequired =>
      'Para esto se necesita un plan de pago o más crédito.';

  @override
  String get errorForbidden => 'No tienes permiso para realizar esta acción.';

  @override
  String get errorNotFound =>
      'No se encontró. Es posible que se haya movido o eliminado.';

  @override
  String get errorConflict =>
      'Se modificó en otro lugar. Recarga la página y vuelve a intentarlo.';

  @override
  String get errorTooLarge =>
      'Es demasiado grande para que el servidor lo acepte.';

  @override
  String get errorRateLimited =>
      'Demasiadas solicitudes. Espera un momento y vuelve a intentarlo.';

  @override
  String get errorServer =>
      'El servidor tuvo un problema. Vuelve a intentarlo en un momento.';

  @override
  String get errorRequestFailed =>
      'El servidor no pudo completar la solicitud.';

  @override
  String get breadcrumb => 'Ruta de navegación';

  @override
  String currentPage(String label) => '$label, página actual';

  @override
  String get switchPage => 'Cambiar de página';

  @override
  String showMore(int count) =>
      plural(count, other: 'Mostrar ${number(count)} más');

  @override
  String pageNumber(int page) => 'Página ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} clave',
    other: '${number(count)} claves',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} elemento',
    other: '${number(count)} elementos',
  );

  @override
  String get expandAll => 'Expandir todo';

  @override
  String get collapseAll => 'Contraer todo';

  @override
  String get copyJson => 'Copiar JSON';

  @override
  String get copyValue => 'Copiar valor';

  @override
  String get copyPath => 'Copiar ruta';

  @override
  String invalidJson(String detail) => 'JSON no válido: $detail';

  @override
  String get logEmpty => 'Aún no hay salida';

  @override
  String get zoomArea => 'Área con zoom';

  @override
  String get zoomAreaHint =>
      'Desplázate para hacer zoom y arrastra para mover la vista; + y − '
      'acercan o alejan, 0 ajusta y las flechas mueven la vista.';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get zoomToFit => 'Ajustar a la pantalla';

  @override
  String get qrCode => 'Código QR';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Subida completada',
    other: 'Se subieron los ${number(total)} archivos',
  );

  /// "con error" reads after one file as after several.
  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? 'Subidos: ${number(done)} de ${number(total)}'
      : 'Subidos: ${number(done)} de ${number(total)} · '
            '${number(failed)} con error';

  @override
  String get clearCompleted => 'Borrar completados';

  @override
  String get queued => 'En cola';

  @override
  String get retryUpload => 'Reintentar subida';

  @override
  String get removeFile => 'Quitar archivo';

  @override
  String get cancelUpload => 'Cancelar subida';

  @override
  String get chartEmpty => 'No hay datos para este periodo';

  @override
  String get heatLess => 'Menos';

  @override
  String get heatMore => 'Más';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'sube $delta';

  @override
  String trendDown(String delta) => 'baja $delta';

  @override
  String get needsAttention => 'Requiere tu atención';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get contentMix => 'Distribución del contenido';

  @override
  String itemsUnit(int count) =>
      plural(count, one: 'elemento', other: 'elementos');

  @override
  String get allCaughtUp => 'Estás al día: nada requiere atención.';

  @override
  String get noRecentActivity => 'Sin actividad reciente';

  @override
  String get noRecentActivityHint =>
      'Aquí aparecerán las ediciones, publicaciones y subidas.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Paso ${number(step)} de ${number(total)}: $title';

  @override
  String get stepCompleted => 'completado';

  @override
  String get stepCurrent => 'actual';

  @override
  String get stepUpcoming => 'pendiente';

  @override
  String get stepError => 'error';

  @override
  String get addItem => 'Agregar elemento';

  @override
  String get untitled => 'Sin título';

  @override
  String get treeHeader => 'Grupo';

  @override
  String get indent => 'Aumentar sangría';

  @override
  String get outdent => 'Reducir sangría';

  @override
  String get addChild => 'Agregar subelemento';

  @override
  String get hideEntry => 'Ocultar';

  @override
  String get showEntry => 'Mostrar';

  /// Impersonal, so the participle need not agree with [title].
  @override
  String movedUp(String title) => 'Se movió $title hacia arriba';

  @override
  String movedDown(String title) => 'Se movió $title hacia abajo';

  @override
  String indented(String title) => 'Se aumentó la sangría de $title';

  @override
  String outdented(String title) => 'Se redujo la sangría de $title';

  @override
  String get rowMovedUp => 'Se movió hacia arriba';

  @override
  String get rowMovedDown => 'Se movió hacia abajo';

  @override
  String get rowIndented => 'Se aumentó la sangría';

  @override
  String get rowOutdented => 'Se redujo la sangría';

  @override
  String get resizePanes => 'Cambiar el tamaño de los paneles';

  @override
  String get moveLeft => 'Mover a la izquierda';

  @override
  String get moveRight => 'Mover a la derecha';

  @override
  String get preview => 'Vista previa';

  @override
  String get previewHeading => 'VISTA PREVIA';

  @override
  String get noPreviewHeading => 'SIN VISTA PREVIA';

  @override
  String get insertsInline =>
      'Se inserta en el texto: no necesita vista previa.';

  @override
  String nothingMatches(String query) => 'Nada coincide con «$query»';

  @override
  String get choices => 'Opciones';

  @override
  String get diffAdded => 'Agregado';

  @override
  String get diffRemoved => 'Eliminado';

  @override
  String get diffChanged => 'Modificado';

  @override
  String get diffMoved => 'Movido';

  @override
  String get diffUnchanged => 'Sin modificar';

  @override
  String addedCount(int count) => plural(
    count,
    one: '${number(count)} agregado',
    other: '${number(count)} agregados',
  );

  @override
  String removedCount(int count) => plural(
    count,
    one: '${number(count)} eliminado',
    other: '${number(count)} eliminados',
  );

  @override
  String changedCount(int count) => plural(
    count,
    one: '${number(count)} modificado',
    other: '${number(count)} modificados',
  );

  @override
  String movedCount(int count) => plural(
    count,
    one: '${number(count)} movido',
    other: '${number(count)} movidos',
  );

  @override
  String get before => 'Antes';

  @override
  String get after => 'Después';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'de la posición ${number(from)} a la ${number(to)}';

  /// A layout is feminine: la vista.
  @override
  String get unified => 'Unificada';

  @override
  String get split => 'En paralelo';

  @override
  String get noChanges => 'Sin cambios';

  @override
  String get versionsIdentical => 'Estas dos versiones son idénticas.';

  @override
  String get noFieldChanges => 'No hay cambios en los campos.';

  @override
  String get noBlockChanges => 'No hay cambios en los bloques.';

  @override
  String get empty => 'Vacío';

  @override
  String inserted(String text) => 'insertado: $text, ';

  @override
  String deleted(String text) => 'eliminado: $text, ';

  @override
  String get restore => 'Restaurar';

  @override
  String get restoreThisVersion => 'Restaurar esta versión';

  @override
  String get restoreThisField => 'Restaurar este campo';

  @override
  String get restoreThisItem => 'Restaurar este elemento';

  @override
  String get restoreLiveBlock =>
      'Restaurar la versión publicada de este bloque';

  @override
  String get sharedLane => 'Compartido';

  /// A version is feminine.
  @override
  String get versionCurrent => 'Actual';

  @override
  String get versionPublished => 'Publicada';

  @override
  String get versionRestored => 'Restaurada';

  @override
  String get versionArchived => 'Archivada';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Personas para mencionar';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 persona para mencionar',
    other: '${number(count)} personas para mencionar',
  );
}
