import '../../sections/display_messages.dart';

/// Brazilian Portuguese [DisplayMessages].
class DisplayMessagesPt extends DisplayMessages {
  const DisplayMessagesPt([super.localeName = 'pt']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Carregando';

  @override
  String get errorTimeout =>
      'O servidor demorou demais para responder. Tente novamente.';

  @override
  String get errorUnreachable =>
      'Não foi possível conectar ao servidor. Verifique sua conexão e tente '
      'novamente.';

  @override
  String get errorUnreadable =>
      'Não foi possível ler a resposta do servidor. Tente novamente.';

  @override
  String get errorUnauthorized =>
      'Sua sessão expirou. Entre novamente e tente outra vez.';

  @override
  String get errorPaymentRequired =>
      'Isso requer um plano pago ou mais créditos.';

  @override
  String get errorForbidden => 'Você não tem permissão para fazer isso.';

  @override
  String get errorNotFound =>
      'Item não encontrado. Ele pode ter sido movido ou excluído.';

  @override
  String get errorConflict =>
      'Este item foi alterado em outro lugar. Recarregue a página e tente '
      'novamente.';

  @override
  String get errorTooLarge => 'Grande demais para ser aceito pelo servidor.';

  @override
  String get errorRateLimited =>
      'Muitas solicitações. Aguarde um momento e tente novamente.';

  @override
  String get errorServer =>
      'O servidor encontrou um problema. Tente novamente em instantes.';

  @override
  String get errorRequestFailed =>
      'O servidor não conseguiu concluir a solicitação.';

  @override
  String get breadcrumb => 'Trilha de navegação';

  @override
  String currentPage(String label) => '$label, página atual';

  @override
  String get switchPage => 'Trocar de página';

  @override
  String showMore(int count) =>
      plural(count, other: 'Mostrar mais ${number(count)}');

  @override
  String pageNumber(int page) => 'Página ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} chave',
    other: '${number(count)} chaves',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} item',
    other: '${number(count)} itens',
  );

  @override
  String get expandAll => 'Expandir tudo';

  @override
  String get collapseAll => 'Recolher tudo';

  @override
  String get copyJson => 'Copiar JSON';

  @override
  String get copyValue => 'Copiar valor';

  @override
  String get copyPath => 'Copiar caminho';

  @override
  String invalidJson(String detail) => 'JSON inválido — $detail';

  @override
  String get logEmpty => 'Nenhuma saída ainda';

  @override
  String get zoomArea => 'Área com zoom';

  @override
  String get zoomAreaHint =>
      'Role para aplicar zoom e arraste para mover; + e − aplicam zoom, 0 '
      'ajusta à tela e as setas movem.';

  @override
  String get zoomIn => 'Aumentar zoom';

  @override
  String get zoomOut => 'Diminuir zoom';

  @override
  String get zoomToFit => 'Ajustar à tela';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Envio concluído',
    other: 'Todos os ${number(total)} arquivos enviados',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} de ${number(total)} enviados'
      : '${number(done)} de ${number(total)} enviados · '
            '${number(failed)} com falha';

  @override
  String get clearCompleted => 'Limpar concluídos';

  @override
  String get queued => 'Na fila';

  @override
  String get retryUpload => 'Tentar enviar novamente';

  @override
  String get removeFile => 'Remover arquivo';

  @override
  String get cancelUpload => 'Cancelar envio';

  @override
  String get chartEmpty => 'Sem dados para este período';

  @override
  String get heatLess => 'Menos';

  @override
  String get heatMore => 'Mais';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'aumento de $delta';

  @override
  String trendDown(String delta) => 'queda de $delta';

  @override
  String get needsAttention => 'Requer atenção';

  @override
  String get recentActivity => 'Atividade recente';

  @override
  String get contentMix => 'Distribuição do conteúdo';

  @override
  String itemsUnit(int count) => plural(count, one: 'item', other: 'itens');

  @override
  String get allCaughtUp => 'Tudo em dia — nada requer atenção.';

  @override
  String get noRecentActivity => 'Nenhuma atividade recente';

  @override
  String get noRecentActivityHint =>
      'Edições, publicações e envios aparecerão aqui.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Etapa ${number(step)} de ${number(total)}: $title';

  /// A step is feminine.
  @override
  String get stepCompleted => 'concluída';

  @override
  String get stepCurrent => 'atual';

  @override
  String get stepUpcoming => 'pendente';

  @override
  String get stepError => 'erro';

  @override
  String get addItem => 'Adicionar item';

  @override
  String get untitled => 'Sem título';

  @override
  String get treeHeader => 'Grupo';

  @override
  String get indent => 'Aumentar recuo';

  @override
  String get outdent => 'Diminuir recuo';

  @override
  String get addChild => 'Adicionar subitem';

  @override
  String get hideEntry => 'Ocultar';

  @override
  String get showEntry => 'Mostrar';

  @override
  String movedUp(String title) => '$title movido para cima';

  @override
  String movedDown(String title) => '$title movido para baixo';

  @override
  String indented(String title) => 'Recuo de $title aumentado';

  @override
  String outdented(String title) => 'Recuo de $title diminuído';

  @override
  String get rowMovedUp => 'Movido para cima';

  @override
  String get rowMovedDown => 'Movido para baixo';

  @override
  String get rowIndented => 'Recuo aumentado';

  @override
  String get rowOutdented => 'Recuo diminuído';

  @override
  String get resizePanes => 'Redimensionar painéis';

  @override
  String get moveLeft => 'Mover para a esquerda';

  @override
  String get moveRight => 'Mover para a direita';

  @override
  String get preview => 'Prévia';

  @override
  String get previewHeading => 'PRÉVIA';

  @override
  String get noPreviewHeading => 'SEM PRÉVIA';

  @override
  String get insertsInline => 'Inserido no texto — não precisa de prévia.';

  @override
  String nothingMatches(String query) => 'Nada corresponde a “$query”';

  @override
  String get choices => 'Opções';

  @override
  String get diffAdded => 'Adicionado';

  @override
  String get diffRemoved => 'Removido';

  @override
  String get diffChanged => 'Alterado';

  @override
  String get diffMoved => 'Movido';

  @override
  String get diffUnchanged => 'Inalterado';

  @override
  String addedCount(int count) => plural(
    count,
    one: '${number(count)} adicionado',
    other: '${number(count)} adicionados',
  );

  @override
  String removedCount(int count) => plural(
    count,
    one: '${number(count)} removido',
    other: '${number(count)} removidos',
  );

  @override
  String changedCount(int count) => plural(
    count,
    one: '${number(count)} alterado',
    other: '${number(count)} alterados',
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
  String get after => 'Depois';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'da posição ${number(from)} para a ${number(to)}';

  @override
  String get unified => 'Unificado';

  @override
  String get split => 'Lado a lado';

  @override
  String get noChanges => 'Nenhuma alteração';

  @override
  String get versionsIdentical => 'Estas duas versões são idênticas.';

  @override
  String get noFieldChanges => 'Nenhum campo alterado.';

  @override
  String get noBlockChanges => 'Nenhum bloco alterado.';

  @override
  String get empty => 'Vazio';

  @override
  String inserted(String text) => 'inserido: $text, ';

  @override
  String deleted(String text) => 'excluído: $text, ';

  @override
  String get restore => 'Restaurar';

  @override
  String get restoreThisVersion => 'Restaurar esta versão';

  @override
  String get restoreThisField => 'Restaurar este campo';

  @override
  String get restoreThisItem => 'Restaurar este item';

  @override
  String get restoreLiveBlock => 'Restaurar a versão publicada deste bloco';

  @override
  String get sharedLane => 'Compartilhado';

  /// A version is feminine.
  @override
  String get versionCurrent => 'Atual';

  @override
  String get versionPublished => 'Publicada';

  @override
  String get versionRestored => 'Restaurada';

  @override
  String get versionArchived => 'Arquivada';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Pessoas para mencionar';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '${number(count)} pessoa para mencionar',
    other: '${number(count)} pessoas para mencionar',
  );
}
