import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Brazilian Portuguese [InputsMessages].
class InputsMessagesPt extends InputsMessages {
  const InputsMessagesPt([super.localeName = 'pt']);

  @override
  String get confirm => 'Confirmar';

  @override
  String get copied => 'Copiado';

  @override
  String get copyFailed => 'Falha ao copiar';

  @override
  String get undo => 'Desfazer';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get clearSearch => 'Limpar pesquisa';

  @override
  String get couldNotLoadResults => 'Não foi possível carregar os resultados';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} de ${number(count)}';

  @override
  String get dateRange => 'Período';

  @override
  String get clearDates => 'Limpar datas';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) =>
      plural(count, one: 'Último dia', other: 'Últimos ${number(count)} dias');

  @override
  String get thisMonth => 'Este mês';

  @override
  String get lastMonth => 'Mês passado';

  @override
  String get yearToDate => 'Ano até hoje';

  @override
  String get searchOrJumpTo => 'Pesquisar ou ir para…';

  @override
  String get recent => 'Recentes';

  @override
  String get selectAResult => 'Selecione um resultado';

  @override
  String matchedIn(String place) => 'Encontrado em: $place';

  @override
  String get matchedInContent => 'Encontrado no conteúdo';

  @override
  String get run => 'Executar';

  @override
  String get open => 'Abrir';

  @override
  String get typeToSearch => 'Digite para pesquisar';

  @override
  String noResultsFor(String query) => 'Nenhum resultado para “$query”';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Nenhum resultado',
    one: '${number(count)} resultado',
    other: '${number(count)} resultados',
  );

  @override
  String get navigateHint => 'navegar';

  @override
  String get selectHint => 'selecionar';

  @override
  String get closeHint => 'fechar';

  @override
  String get keysUpDown => 'Setas para cima e para baixo';

  @override
  String get keyEnter => 'Enter';

  /// The key is labelled, and said, Esc.
  @override
  String get keyEscape => 'Esc';

  @override
  String get fieldsGroup => 'Campos';

  @override
  String get notifications => 'Notificações';

  @override
  String get allCaughtUp => 'Tudo em dia';

  /// A notification is feminine.
  @override
  String get markAllRead => 'Marcar todas como lidas';

  /// A notification is feminine.
  @override
  String get unread => 'Não lida';

  /// Notifications are feminine.
  @override
  String get allNotifications => 'Todas';

  /// A notification is feminine.
  @override
  String get markAsRead => 'Marcar como lida';

  /// A notification is feminine.
  @override
  String get markAsUnread => 'Marcar como não lida';

  /// Notifications are feminine.
  @override
  String get viewAll => 'Ver todas';

  @override
  String get couldNotLoadNotifications =>
      'Não foi possível carregar as notificações';

  /// The default title, notifications, is feminine.
  @override
  String unreadCount(String title, int count) => plural(
    count,
    one: '$title, ${number(count)} não lida',
    other: '$title, ${number(count)} não lidas',
  );

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceMode => 'Modo';

  @override
  String get modeLight => 'Claro';

  @override
  String get modeDark => 'Escuro';

  @override
  String get modeSystem => 'Sistema';

  @override
  String get accentColour => 'Cor de destaque';

  @override
  String get themeAccent => 'Cor do tema';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Carmesim',
    'Violet' => 'Violeta',
    'Teal' => 'Azul-petróleo',
    'Amber' => 'Âmbar',
    _ => name,
  };

  @override
  String get tableDensity => 'Densidade das tabelas';

  /// A density is feminine.
  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compacta',
    TableDensity.standard => 'Padrão',
    TableDensity.comfortable => 'Confortável',
  };
}
