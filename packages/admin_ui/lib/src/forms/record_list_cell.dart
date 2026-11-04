/// @docImport 'form_wizard.dart';
/// @docImport 'validation.dart';
library;

import 'package:flutter/foundation.dart';

import 'cell.dart';

/// A reactive list of owned records, each editable through a typed sub-handle
/// [H] built from a [RecordScope]. Element identity is the record's stable
/// `id`. Notifies on structural change (add/remove) so a repeater rebuilds. The
/// concrete draft-backed implementation lives in `field_scope.dart` (alongside
/// the cell classes it composes).
///
/// It is a [Cell] of its elements, so a [ListRules] can count its rows and a
/// [FormWizardStep] can name it among the fields it checks.
abstract class RecordListCell<H> extends ChangeNotifier
    implements Cell<List<H>> {
  @override
  String get id;
  List<H> get elements;
  void add();
  void removeAt(int index);

  /// Moves the element at [from] to [to], where [to] indexes the list after the
  /// element is removed (the `removeAt(from); insert(to)` contract).
  void move(int from, int to);
}
