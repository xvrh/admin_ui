/// @docImport '../common/ui/error_text.dart';
/// @docImport 'value_form_controller.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lifecycle state of an editable surface, independent of how it is backed
/// (a collaborative document, a set of plain field controllers, …).
enum FormStatus { clean, dirty, submitting, submitted, error }

/// The contract every admin editing surface exposes: a single observable
/// status, a dirtiness flag for navigation guards, a per-field error map, and a
/// submit/reset lifecycle. UI (save bar, submit button, guard) binds to this and
/// never inspects the backing store directly.
///
/// Concrete backings live with the store they edit: [ValueFormController]
/// over plain values (a dialog, a settings page, a record saved whole), or a
/// controller over a collaborative document in the host app.
abstract class FormController extends ChangeNotifier {
  FormStatus get status;

  /// Per-field validation messages (field id → message, or `null`/absent for
  /// valid), as the backing validates its values.
  Map<String, String?> get errors;

  bool get isValid => errors.values.every((e) => e == null);

  /// How many fields carry a validation message — the save status reads it
  /// ("2 fields need attention").
  int get errorCount => errors.values.where((e) => e != null).length;

  /// Why the last [submit] failed, in words a user can act on — shown by the
  /// save status in place of its generic "Couldn’t save". Null when the
  /// backing has nothing more specific to say.
  String? get submitError => null;

  /// What the last [submit] threw, when the backing has no words of its own
  /// for it: with no [submitError], the save status shows it as
  /// [ErrorTextScope.describe] words it. Null after a submit that failed
  /// with nothing thrown, or did not fail.
  Object? get submitFailure => null;

  /// True while there are edits that would be lost on navigating away. Drives
  /// the unsaved-changes guard. A backing whose edits auto-persist (e.g. a live
  /// collaborative draft) may still report this for the publish indicator while
  /// the guard chooses to ignore it.
  bool get hasUnsavedChanges =>
      status == FormStatus.dirty || status == FormStatus.error;

  /// True while leaving would put edits at risk: [hasUnsavedChanges], or a
  /// submit still in flight — if it fails after the page is gone, the edits
  /// go with it. The unsaved-changes guard reads this.
  bool get blocksNavigation =>
      hasUnsavedChanges || status == FormStatus.submitting;

  /// Submit is live only when there is something valid to submit.
  bool get canSubmit =>
      isValid &&
      status != FormStatus.submitting &&
      (status == FormStatus.dirty || status == FormStatus.error);

  /// Validate, persist, and on success rebase the clean baseline. Sets
  /// [FormStatus.submitting] in flight and [FormStatus.error] on failure.
  Future<void> submit();

  /// [submit] for a button or a shortcut that doesn't await it: a failure is
  /// already [FormStatus.error] (and [submitError]) for the save status to
  /// show, so it is not rethrown into the zone as well.
  void requestSubmit() => unawaited(submit().catchError((Object _) {}));

  /// Discard edits back to the clean baseline.
  void reset();
}
