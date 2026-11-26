import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_pt.dart';
import 'collection_messages_pt.dart';
import 'display_messages_pt.dart';
import 'fields_messages_pt.dart';
import 'inputs_messages_pt.dart';
import 'shell_messages_pt.dart';

/// Brazilian Portuguese [AdminLocalizations].
class AdminLocalizationsPt extends AdminLocalizations {
  const AdminLocalizationsPt([super.localeName = 'pt']);

  @override
  InputsMessages get inputs => const InputsMessagesPt();

  @override
  DisplayMessages get display => const DisplayMessagesPt();

  @override
  CollectionMessages get collection => const CollectionMessagesPt();

  @override
  FieldsMessages get fields => const FieldsMessagesPt();

  @override
  ShellMessages get shell => const ShellMessagesPt();

  @override
  AssetsMessages get assets => const AssetsMessagesPt();

  @override
  String get apply => 'Aplicar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get remove => 'Remover';

  @override
  String removeItem(String name) => 'Remover $name';

  @override
  String get reset => 'Redefinir';

  @override
  String get loading => 'Carregando…';

  @override
  String get saving => 'Salvando…';

  @override
  String get edited => 'Editado';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String get noMatches => 'Nenhuma correspondência';

  @override
  String get couldNotLoad => 'Não foi possível carregar';

  @override
  String get searchFailed => 'Falha na pesquisa';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get searching => 'Pesquisando…';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get somethingWentWrongTryAgain => 'Algo deu errado. Tente novamente.';

  @override
  String get notAllowed => 'Sem permissão de acesso';

  @override
  String get notAllowedAskAdministrator =>
      'Se precisar de acesso, fale com um administrador.';

  @override
  String get goBack => 'Voltar';

  @override
  String get moreActions => 'Mais ações';

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get selectPlaceholder => 'Selecionar…';

  @override
  String get filterPlaceholder => 'Filtrar…';

  @override
  String get searchPlaceholder => 'Pesquisar…';

  @override
  String get addItem => 'Adicionar item';

  @override
  String get addRow => 'Adicionar linha';

  @override
  String get keyLabel => 'Chave';

  @override
  String get valueLabel => 'Valor';

  @override
  String get linkPlaceholder => 'Vincular…';

  @override
  String get restoreLiveVersion => 'Restaurar a versão publicada deste campo';

  @override
  String get assetNotFound => 'Mídia não encontrada';

  @override
  String get assetPreview => 'Prévia da mídia';

  @override
  String get uploadFailed => 'Falha no envio';

  /// The link carries the object: "Arraste e solte ou selecione arquivos".
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: 'Arraste e solte ou ',
    link: switch ((images, multiple)) {
      (false, false) => 'selecione um arquivo',
      (false, true) => 'selecione arquivos',
      (true, false) => 'selecione uma imagem',
      (true, true) => 'selecione imagens',
    },
    after: '',
  );

  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Nada selecionado',
    one: '${number(count)} selecionado',
    other: '${number(count)} selecionados',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} de ${number(total)}';

  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get copy => 'Copiar';

  @override
  String get close => 'Fechar';

  @override
  String get clear => 'Limpar texto';

  @override
  String get search => 'Pesquisa';

  @override
  String get more => 'Mais';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get rowsPerPage => 'Linhas por página:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first – $last de $total';

  @override
  String get previousPage => 'Página anterior';

  @override
  String get nextPage => 'Próxima página';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Próximo mês';

  @override
  String get today => 'Hoje';

  @override
  String rangeStartDate(String date) => 'Data de início $date';

  @override
  String rangeEndDate(String date) => 'Data de término $date';

  @override
  String get selectDate => 'Selecione a data';

  @override
  String get selectDateRange => 'Selecione o intervalo';

  @override
  String get navigationMenu => 'Menu de navegação';

  @override
  String get expand => 'Abrir';

  @override
  String get collapse => 'Recolher';

  @override
  String get proceed => 'Continuar';

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
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'Espaço';

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
