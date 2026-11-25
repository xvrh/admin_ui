import '../messages.dart';

/// Strings for the app shell, the auth forms and the generic form save flow.
///
/// Every language's class extends this one directly: [ShellMessagesEn] here,
/// the others in `lib/src/l10n/languages/`. A member added here without
/// its text in every language fails to compile, so add a message to
/// every language in the same edit.
abstract class ShellMessages extends AdminMessages {
  const ShellMessages(super.localeName);

  /// The sidebar's navigation landmark.
  String get navigation;

  /// The shell's main landmark: the page beside the navigation.
  String get mainContent;

  /// The compact shell's menu button, which opens the navigation drawer.
  String get openNavigation;

  /// The navigation drawer's close button.
  String get closeNavigation;

  /// A navigation item's accessible name with its count: "Pages, 3".
  String navItemWithBadge(String label, String badge);

  /// Throws a form's unsaved edits away.
  String get discard;

  /// Makes a document's edits live.
  String get publish;

  /// The accessible name of a split Publish button's caret.
  String get morePublishOptions;

  /// The save status while a publish is in flight, with a trailing ellipsis.
  String get publishing;

  /// The save status once the edits are saved.
  String get saved;

  /// The save status once the edits are live.
  String get published;

  /// A save status with a detail after it, such as when it happened:
  /// "Saved · 2m ago".
  String statusWithDetail(String status, String detail);

  /// The save status after a save failed for no stated reason.
  String get couldNotSave;

  /// The save status after a publish failed for no stated reason.
  String get couldNotPublish;

  /// The save status while [count] fields are in error.
  String fieldsNeedAttention(int count);

  /// Why Publish is disabled on a form with nothing new to publish.
  String get noChangesToPublish;

  /// Why a submit with a caller's own label is disabled on a form with
  /// nothing new to submit.
  String get noChanges;

  /// The title of the prompt before leaving a form with unsaved edits.
  String get discardChangesTitle;

  /// The body of that prompt.
  String get discardChangesMessage;

  /// The title of the prompt before leaving while a save is in flight.
  String get leaveWhileSavingTitle;

  /// The body of that prompt.
  String get leaveWhileSavingMessage;

  /// Confirms leaving while a save is in flight.
  String get leave;

  /// The sign-in form's email label.
  String get email;

  /// The sign-in form's email placeholder: an example address.
  String get emailHint;

  /// The sign-in form's password label.
  String get password;

  /// The sign-in form's submit.
  String get signIn;

  /// The link to recover a forgotten password.
  String get forgotPassword;

  /// The separator between signing in with a password and with a provider.
  String get or;

  /// An auth field left empty on submit, named by its [label].
  String isRequired(String label);

  /// The field for a password being chosen.
  String get newPassword;

  /// The field repeating the chosen password.
  String get confirmPassword;

  /// [confirmPassword] where the form also asks for the current one.
  String get confirmNewPassword;

  /// The field for the password in use, when changing it.
  String get currentPassword;

  /// Submits a first password, or a reset one.
  String get setPassword;

  /// Submits a password change.
  String get changePassword;

  /// A new password shorter than [minLength] characters.
  String passwordTooShort(int minLength);

  /// A confirmation that differs from the new password.
  String get passwordsDontMatch;

  /// The lowest password strength.
  String get strengthWeak;

  /// The second password strength.
  String get strengthFair;

  /// The third password strength.
  String get strengthGood;

  /// The highest password strength.
  String get strengthStrong;

  /// The placeholder of a tags field's add input.
  String get addTagHint;

  /// Marks a field whose one value serves every language.
  String get shared;
}

/// English [ShellMessages]. Subclass it to override a few strings.
class ShellMessagesEn extends ShellMessages {
  const ShellMessagesEn([super.localeName = 'en']);

  @override
  String get navigation => 'Navigation';

  @override
  String get mainContent => 'Main content';

  @override
  String get openNavigation => 'Open navigation';

  @override
  String get closeNavigation => 'Close navigation';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => 'Discard';

  @override
  String get publish => 'Publish';

  @override
  String get morePublishOptions => 'More publish options';

  @override
  String get publishing => 'Publishing…';

  @override
  String get saved => 'Saved';

  @override
  String get published => 'Published';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => 'Couldn’t save';

  @override
  String get couldNotPublish => 'Couldn’t publish';

  @override
  String fieldsNeedAttention(int count) => plural(
    count,
    one: '${number(count)} field needs attention',
    other: '${number(count)} fields need attention',
  );

  @override
  String get noChangesToPublish => 'No changes to publish';

  @override
  String get noChanges => 'No changes';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes that will be lost.';

  @override
  String get leaveWhileSavingTitle => 'Saving in progress — leave anyway?';

  @override
  String get leaveWhileSavingMessage =>
      'Your changes are still being saved. If the save fails after you '
      'leave, they will be lost.';

  @override
  String get leave => 'Leave';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get or => 'or';

  @override
  String isRequired(String label) => '$label is required';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get setPassword => 'Set password';

  @override
  String get changePassword => 'Change password';

  @override
  String passwordTooShort(int minLength) => plural(
    minLength,
    one: 'Use at least ${number(minLength)} character.',
    other: 'Use at least ${number(minLength)} characters.',
  );

  @override
  String get passwordsDontMatch => "Passwords don't match.";

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get addTagHint => 'Add…';

  @override
  String get shared => 'shared';
}
