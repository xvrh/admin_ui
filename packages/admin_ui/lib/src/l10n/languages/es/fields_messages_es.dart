import '../../sections/fields_messages.dart';

/// Spanish [FieldsMessages].
class FieldsMessagesEs extends FieldsMessages {
  const FieldsMessagesEs([super.localeName = 'es']);

  /// Comillas angulares, with no space inside.
  @override
  String quoted(String text) => '«$text»';

  @override
  String get filterOrAdd => 'Filtrar o agregar…';

  @override
  String maxSelected(int max) => 'Límite de ${number(max)} alcanzado';

  @override
  String createOption(String value) => 'Crear ${quoted(value)}';

  @override
  String get onLabel => 'Activado';

  @override
  String get offLabel => 'Desactivado';

  @override
  String get selectDate => 'Seleccionar fecha…';

  @override
  String get selectDateTime => 'Seleccionar fecha y hora…';

  @override
  String get selectTime => 'Seleccionar hora…';

  @override
  String get clearDate => 'Borrar fecha';

  @override
  String get year => 'Año';

  @override
  String get month => 'Mes';

  @override
  String get day => 'Día';

  @override
  String get hour => 'Hora';

  @override
  String get minute => 'Minuto';

  /// Día, mes, año, hora, minuto.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'AAAA', month: 'MM', day: 'DD', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) => 'Escribe un número como $example';

  @override
  String numberBetween(String min, String max) =>
      'Escribe un número entre $min y $max';

  @override
  String numberAtLeast(String min) => 'Escribe un valor de $min o más';

  @override
  String numberAtMost(String max) => 'Escribe un valor de $max o menos';

  @override
  String get decrease => 'Disminuir';

  @override
  String get increase => 'Aumentar';

  @override
  String get pickColor => 'Elegir un color…';

  @override
  String get hexDigitsError => 'Escribe 3 o 6 dígitos hexadecimales';

  @override
  String get setColor => 'Aplicar';

  @override
  String get validJson => 'JSON válido';

  @override
  String jsonError(int line, int column, String detail) =>
      'Línea ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formatear';

  @override
  String get plainText => 'Texto sin formato';

  @override
  String get addTag => 'Agregar una etiqueta…';

  @override
  String get noTags => 'Sin etiquetas';

  @override
  String get noEntries => 'Sin entradas';

  @override
  String duplicateKey(String key) =>
      'Clave ${quoted(key)} duplicada: prevalece la fila inferior';

  @override
  String get duplicateKeys => 'Claves duplicadas: prevalece la fila inferior';

  @override
  String get removeRow => 'Quitar fila';

  @override
  String get noMedia => 'Sin recursos';

  @override
  String retryItem(String name) => 'Reintentar $name';

  @override
  String cancelUpload(String name) => 'Cancelar la subida de $name';

  @override
  String get cover => 'Portada';

  @override
  String get processing => 'Procesando…';

  @override
  String get addImage => 'Agregar imagen';

  @override
  String get addFile => 'Agregar archivo';

  @override
  String get noReference => 'Sin referencia';

  @override
  String get unavailable => 'No disponible';

  @override
  String get replaceReference => 'Reemplazar';

  @override
  String get typeToSearch => 'Escribe para buscar…';

  @override
  String removeItemAt(int position) => 'Quitar elemento ${number(position)}';

  @override
  String get noItemsYet => 'Aún no hay elementos.';

  @override
  String get help => 'Ayuda';

  @override
  String helpFor(String field) => 'Ayuda sobre $field';

  @override
  String get versionHistory => 'Historial de versiones';

  @override
  String get pendingEdit => 'Edición pendiente';

  @override
  String get baseline => 'Publicado';

  @override
  String editedDetail(String detail) => 'Editado · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Comentarios',
    one: '${number(count)} comentario',
    other: '${number(count)} comentarios',
  );

  @override
  String commentsHeading(int count) => 'Comentarios · ${number(count)}';

  @override
  String get resolve => 'Resolver';

  @override
  String get replyPlaceholder => 'Responder…';

  @override
  String get sendReply => 'Enviar respuesta';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Comentar este campo',
    one: '${number(openThreads)} conversación abierta',
    other: '${number(openThreads)} conversaciones abiertas',
  );

  @override
  String get openThread => 'Abrir conversación';

  @override
  String get translationSource => 'Origen';

  /// A translation is feminine.
  @override
  String get translationUpToDate => 'Actualizada';

  @override
  String get translationNeedsReview => 'Por revisar';

  @override
  String get translationOutdated => 'Desactualizada';

  @override
  String get translationMissing => 'Sin traducir';

  @override
  String get retranslate => 'Volver a traducir';

  /// Language names are masculine: al francés.
  @override
  String retranslateLanguage(String language) =>
      'Volver a traducir al $language';

  @override
  String get sourceChanged => 'El origen cambió desde que se tradujo';

  @override
  String sourceIn(String language) => 'Origen en $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Idiomas';

  @override
  String get languageMenuHint =>
      'Toca para cambiar · marca para comparar en paralelo.';

  @override
  String compareLanguage(String language) => 'Comparar con $language';

  @override
  String switchToLanguage(String language) => 'Cambiar a $language';

  @override
  String get editing => 'en edición';

  @override
  String get inherited => 'Heredado';

  @override
  String get custom => 'Personalizado';

  @override
  String inheritedDescription(String source) =>
      'Igual que el origen ($source): se actualiza automáticamente';

  /// "tu" takes either gender, which [noun] may have.
  @override
  String customDescription(String? noun) => 'Define tu ${noun ?? 'valor'}';

  @override
  String get valueRequired => 'Obligatorio';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Escribe al menos ${number(min)} carácter',
    other: 'Escribe al menos ${number(min)} caracteres',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Escribe como máximo ${number(max)} carácter',
    other: 'Escribe como máximo ${number(max)} caracteres',
  );

  @override
  String get invalidEmail =>
      'Escribe una dirección de correo electrónico válida';

  @override
  String get invalidUrl => 'Escribe una dirección web válida';

  @override
  String get invalidFormat => 'Escribe un valor con el formato esperado';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Agrega al menos ${number(count)} elemento',
    other: 'Agrega al menos ${number(count)} elementos',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Deja como máximo ${number(count)} elemento',
    other: 'Deja como máximo ${number(count)} elementos',
  );

  @override
  String get checking => 'Verificando…';

  @override
  String get optionalMarker => '(opcional)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} campo requiere corrección',
    other: '${number(count)} campos requieren corrección',
  );

  @override
  String jumpToField(String label) => 'Ir a $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Siguiente';

  @override
  String get wizardBack => 'Atrás';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Corrige ${number(count)} campo para continuar',
    other: 'Corrige ${number(count)} campos para continuar',
  );
}
