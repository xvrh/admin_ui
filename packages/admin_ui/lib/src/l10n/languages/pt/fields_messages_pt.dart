import '../../sections/fields_messages.dart';

/// Brazilian Portuguese [FieldsMessages].
class FieldsMessagesPt extends FieldsMessages {
  const FieldsMessagesPt([super.localeName = 'pt']);

  @override
  String quoted(String text) => '“$text”';

  @override
  String get filterOrAdd => 'Filtrar ou adicionar…';

  @override
  String maxSelected(int max) => 'Máximo de ${number(max)} atingido';

  @override
  String createOption(String value) => 'Criar ${quoted(value)}';

  @override
  String get onLabel => 'Ativado';

  @override
  String get offLabel => 'Desativado';

  @override
  String get selectDate => 'Selecionar data…';

  @override
  String get selectDateTime => 'Selecionar data e hora…';

  @override
  String get selectTime => 'Selecionar hora…';

  @override
  String get clearDate => 'Limpar data';

  @override
  String get year => 'Ano';

  @override
  String get month => 'Mês';

  @override
  String get day => 'Dia';

  @override
  String get hour => 'Hora';

  @override
  String get minute => 'Minuto';

  /// Dia, mês, ano, hora, minuto.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'AAAA', month: 'MM', day: 'DD', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) => 'Digite um número como $example';

  @override
  String numberBetween(String min, String max) =>
      'Digite um número entre $min e $max';

  @override
  String numberAtLeast(String min) => 'Digite $min ou mais';

  @override
  String numberAtMost(String max) => 'Digite $max ou menos';

  @override
  String get decrease => 'Diminuir';

  @override
  String get increase => 'Aumentar';

  @override
  String get pickColor => 'Escolher cor…';

  @override
  String get hexDigitsError => 'Digite 3 ou 6 dígitos hexadecimais';

  @override
  String get setColor => 'Definir';

  @override
  String get validJson => 'JSON válido';

  @override
  String jsonError(int line, int column, String detail) =>
      'Linha ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formatar';

  @override
  String get plainText => 'Texto simples';

  @override
  String get addTag => 'Adicionar tag…';

  @override
  String get noTags => 'Nenhuma tag';

  @override
  String get noEntries => 'Nenhuma entrada';

  @override
  String duplicateKey(String key) =>
      'Chave ${quoted(key)} duplicada — a linha mais abaixo prevalece';

  @override
  String get duplicateKeys =>
      'Chaves duplicadas — a linha mais abaixo prevalece';

  @override
  String get removeRow => 'Remover linha';

  @override
  String get noMedia => 'Nenhuma mídia';

  @override
  String retryItem(String name) => 'Tentar enviar $name novamente';

  @override
  String cancelUpload(String name) => 'Cancelar envio de $name';

  @override
  String get cover => 'Capa';

  @override
  String get processing => 'Processando…';

  @override
  String get addImage => 'Adicionar imagem';

  @override
  String get addFile => 'Adicionar arquivo';

  @override
  String get noReference => 'Nenhuma referência';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get replaceReference => 'Substituir';

  @override
  String get typeToSearch => 'Digite para pesquisar…';

  @override
  String removeItemAt(int position) => 'Remover item ${number(position)}';

  @override
  String get noItemsYet => 'Nenhum item ainda.';

  @override
  String get help => 'Ajuda';

  @override
  String helpFor(String field) => 'Ajuda sobre $field';

  @override
  String get versionHistory => 'Histórico de versões';

  @override
  String get pendingEdit => 'Edição pendente';

  @override
  String get baseline => 'Publicado';

  @override
  String editedDetail(String detail) => 'Editado · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Comentários',
    one: '${number(count)} comentário',
    other: '${number(count)} comentários',
  );

  @override
  String commentsHeading(int count) => 'Comentários · ${number(count)}';

  @override
  String get resolve => 'Resolver';

  @override
  String get replyPlaceholder => 'Responder…';

  @override
  String get sendReply => 'Enviar resposta';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Comentar este campo',
    one: '${number(openThreads)} conversa aberta',
    other: '${number(openThreads)} conversas abertas',
  );

  @override
  String get openThread => 'Abrir conversa';

  @override
  String get translationSource => 'Origem';

  /// A translation is feminine.
  @override
  String get translationUpToDate => 'Atualizada';

  @override
  String get translationNeedsReview => 'Precisa de revisão';

  /// A translation is feminine.
  @override
  String get translationOutdated => 'Desatualizada';

  @override
  String get translationMissing => 'Ausente';

  @override
  String get retranslate => 'Traduzir novamente';

  @override
  String retranslateLanguage(String language) =>
      'Traduzir novamente para $language';

  @override
  String get sourceChanged => 'A origem mudou desde esta tradução';

  @override
  String sourceIn(String language) => 'Origem em $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Idiomas';

  @override
  String get languageMenuHint =>
      'Toque para trocar · marque para comparar lado a lado.';

  @override
  String compareLanguage(String language) => 'Comparar com $language';

  @override
  String switchToLanguage(String language) => 'Mudar para $language';

  @override
  String get editing => 'em edição';

  @override
  String get inherited => 'Herdado';

  @override
  String get custom => 'Personalizado';

  @override
  String inheritedDescription(String source) =>
      'Segue $source — atualiza automaticamente';

  /// Worded so that no article or adjective has to agree with the noun.
  @override
  String customDescription(String? noun) =>
      'Definir ${noun ?? 'valor'} manualmente';

  @override
  String get valueRequired => 'Obrigatório';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Digite pelo menos ${number(min)} caractere',
    other: 'Digite pelo menos ${number(min)} caracteres',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Digite no máximo ${number(max)} caractere',
    other: 'Digite no máximo ${number(max)} caracteres',
  );

  @override
  String get invalidEmail => 'Digite um endereço de e-mail válido';

  @override
  String get invalidUrl => 'Digite um endereço da web válido';

  @override
  String get invalidFormat => 'Digite um valor no formato esperado';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Adicione pelo menos ${number(count)} item',
    other: 'Adicione pelo menos ${number(count)} itens',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Mantenha no máximo ${number(count)} item',
    other: 'Mantenha no máximo ${number(count)} itens',
  );

  @override
  String get checking => 'Verificando…';

  @override
  String get optionalMarker => '(opcional)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} campo precisa de correção',
    other: '${number(count)} campos precisam de correção',
  );

  @override
  String jumpToField(String label) => 'Ir para $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Avançar';

  @override
  String get wizardBack => 'Voltar';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Corrija ${number(count)} campo para continuar',
    other: 'Corrija ${number(count)} campos para continuar',
  );
}
