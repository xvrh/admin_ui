import '../../sections/shell_messages.dart';

/// Brazilian Portuguese [ShellMessages].
class ShellMessagesPt extends ShellMessages {
  const ShellMessagesPt([super.localeName = 'pt']);

  @override
  String get navigation => 'Navegação';

  @override
  String get mainContent => 'Conteúdo principal';

  @override
  String get openNavigation => 'Abrir navegação';

  @override
  String get closeNavigation => 'Fechar navegação';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Descartar';

  @override
  String get publish => 'Publicar';

  @override
  String get morePublishOptions => 'Mais opções de publicação';

  @override
  String get publishing => 'Publicando…';

  @override
  String get saved => 'Salvo';

  @override
  String get published => 'Publicado';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Não foi possível salvar';

  @override
  String get couldNotPublish => 'Não foi possível publicar';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} campo requer atenção',
    other: '${number(count)} campos requerem atenção',
  );

  @override
  String get noChangesToPublish => 'Nenhuma alteração para publicar';

  @override
  String get noChanges => 'Nenhuma alteração';

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String get discardChangesMessage =>
      'Há alterações não salvas que serão perdidas.';

  @override
  String get leaveWhileSavingTitle =>
      'Salvamento em andamento — sair mesmo assim?';

  @override
  String get leaveWhileSavingMessage =>
      'Suas alterações ainda estão sendo salvas. Se o salvamento falhar '
      'depois que você sair, elas serão perdidas.';

  @override
  String get leave => 'Sair';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'nome@example.com';

  @override
  String get password => 'Senha';

  @override
  String get signIn => 'Entrar';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get or => 'ou';

  /// Names the field, so that nothing has to agree with the label.
  @override
  String isRequired(String label) => 'O campo “$label” é obrigatório';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get confirmNewPassword => 'Confirmar nova senha';

  @override
  String get currentPassword => 'Senha atual';

  @override
  String get setPassword => 'Definir senha';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Use pelo menos ${number(minLength)} caractere.',
    other: 'Use pelo menos ${number(minLength)} caracteres.',
  );

  @override
  String get passwordsDontMatch => 'As senhas não coincidem.';

  /// A password is feminine.
  @override
  String get strengthWeak => 'Fraca';

  @override
  String get strengthFair => 'Razoável';

  /// A password is feminine.
  @override
  String get strengthGood => 'Boa';

  @override
  String get strengthStrong => 'Forte';

  @override
  String get addTagHint => 'Adicionar…';

  @override
  String get shared => 'compartilhado';
}
