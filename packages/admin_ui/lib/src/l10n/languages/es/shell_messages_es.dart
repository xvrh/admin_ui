import '../../sections/shell_messages.dart';

/// Spanish [ShellMessages].
class ShellMessagesEs extends ShellMessages {
  const ShellMessagesEs([super.localeName = 'es']);

  @override
  String get navigation => 'Navegación';

  @override
  String get mainContent => 'Contenido principal';

  @override
  String get openNavigation => 'Abrir navegación';

  @override
  String get closeNavigation => 'Cerrar navegación';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Descartar';

  @override
  String get publish => 'Publicar';

  @override
  String get morePublishOptions => 'Más opciones de publicación';

  @override
  String get publishing => 'Publicando…';

  @override
  String get saved => 'Guardado';

  @override
  String get published => 'Publicado';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'No se pudo guardar';

  @override
  String get couldNotPublish => 'No se pudo publicar';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} campo requiere atención',
    other: '${number(count)} campos requieren atención',
  );

  @override
  String get noChangesToPublish => 'No hay cambios para publicar';

  @override
  String get noChanges => 'Sin cambios';

  @override
  String get discardChangesTitle => '¿Descartar los cambios?';

  @override
  String get discardChangesMessage =>
      'Tienes cambios sin guardar que se perderán.';

  @override
  String get leaveWhileSavingTitle =>
      'Se están guardando los cambios. ¿Salir de todos modos?';

  @override
  String get leaveWhileSavingMessage =>
      'Tus cambios aún se están guardando. Si el guardado falla después de '
      'que salgas, se perderán.';

  @override
  String get leave => 'Salir';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'tu@example.com';

  @override
  String get password => 'Contraseña';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get or => 'o';

  /// Names the field, so the adjective need not agree with [label].
  @override
  String isRequired(String label) => 'El campo «$label» es obligatorio';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get setPassword => 'Establecer contraseña';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Usa al menos ${number(minLength)} carácter.',
    other: 'Usa al menos ${number(minLength)} caracteres.',
  );

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden.';

  /// A password is feminine.
  @override
  String get strengthWeak => 'Débil';

  @override
  String get strengthFair => 'Aceptable';

  @override
  String get strengthGood => 'Buena';

  @override
  String get strengthStrong => 'Segura';

  @override
  String get verificationCode => 'Código de verificación';

  @override
  String get verify => 'Verificar';

  @override
  String codeIncomplete(int length) => plural(
    length,
    one: 'El código tiene ${number(length)} dígito.',
    other: 'El código tiene ${number(length)} dígitos.',
  );

  @override
  String get recoveryCode => 'Código de recuperación';

  @override
  String get useRecoveryCode => 'Usar un código de recuperación';

  @override
  String get useAuthenticatorApp => 'Usar la aplicación de autenticación';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get authenticatorQrCode =>
      'Código QR para tu aplicación de autenticación';

  @override
  String get cantScanQrCode => '¿No puedes escanear el código?';

  @override
  String get enterSetupKey => 'Escribe esta clave en tu aplicación.';

  @override
  String get copySetupKey => 'Copiar clave';

  @override
  String get copyAllCodes => 'Copiar todo';

  @override
  String get savedRecoveryCodes => 'Ya tengo guardados estos códigos';

  @override
  String get addTagHint => 'Agregar…';

  @override
  String get shared => 'compartido';
}
