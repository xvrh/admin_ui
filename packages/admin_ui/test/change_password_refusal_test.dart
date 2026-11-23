// A server's refusal of a password change shows under the field it is
// about: the current password's under the current password, the new one's
// under the new one, and only what is no field's in the alert above. A
// field's message is about what the field held when it came.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _wrong = 'That is not your current password';
const _weak = 'Too easy to guess';

/// The form, with what its host knows of the last submit.
class _Host extends StatefulWidget {
  final String? current;
  final String? next;

  const _Host({super.key, this.current, this.next});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool submitting = false;
  String? error;
  late String? current = widget.current;
  late String? next = widget.next;
  final submitted = <(String, String)>[];

  /// A submit starts, as a host shows it.
  void submit() => setState(() => submitting = true);

  /// The submit ends, with what the server said.
  void answer({String? error, String? current, String? next}) => setState(() {
    submitting = false;
    this.error = error;
    this.current = current;
    this.next = next;
  });

  @override
  Widget build(BuildContext context) => ChangePasswordForm(
    onSubmit: (c, n) => submitted.add((c, n)),
    submitting: submitting,
    errorText: error,
    currentErrorText: current,
    newErrorText: next,
  );
}

Future<_HostState> _pump(
  WidgetTester tester, {
  String? current,
  String? next,
  bool fill = true,
}) async {
  final key = GlobalKey<_HostState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: _Host(key: key, current: current, next: next),
          ),
        ),
      ),
    ),
  );
  if (fill) {
    await tester.enterText(_field(0), 'oldpass00');
    await tester.enterText(_field(1), 'newpass11');
    await tester.enterText(_field(2), 'newpass11');
    await tester.pump();
  }
  return key.currentState!;
}

/// The current password, the new one and its confirmation, in order.
Finder _field(int index) => find.byType(PasswordField).at(index);

/// [text] under the field at [index].
Finder _under(int index, String text) =>
    find.descendant(of: _field(index), matching: find.text(text));

bool _focused(WidgetTester tester, int index) => tester
    .widget<EditableText>(
      find.descendant(of: _field(index), matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

/// A submit that the server answers with [current] and [next].
Future<void> _refuse(
  WidgetTester tester,
  _HostState host, {
  String? error,
  String? current,
  String? next,
}) async {
  host.submit();
  await tester.pump();
  host.answer(error: error, current: current, next: next);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a refusal of the current password shows under it, and '
      'nowhere else', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong);
    expect(_under(0, _wrong), findsOneWidget);
    expect(find.text(_wrong), findsOneWidget);
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('a refusal of the new password shows under it', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, next: _weak);
    expect(_under(1, _weak), findsOneWidget);
    expect(find.text(_weak), findsOneWidget);
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('what is no field\'s is still an alert above the form', (
    tester,
  ) async {
    final host = await _pump(tester);
    await _refuse(tester, host, error: 'Try again later', current: _wrong);
    expect(
      find.descendant(
        of: find.byType(Alert),
        matching: find.text('Try again later'),
      ),
      findsOneWidget,
    );
    expect(_under(0, _wrong), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(Alert)).dy,
      lessThan(tester.getTopLeft(_field(0)).dy),
    );
  });

  testWidgets('each field\'s message goes when that field is edited, and '
      'the other\'s stays', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong, next: _weak);
    expect(_under(0, _wrong), findsOneWidget);
    expect(_under(1, _weak), findsOneWidget);

    await tester.enterText(_field(0), 'oldpass01');
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    expect(_under(1, _weak), findsOneWidget);

    await tester.enterText(_field(1), 'newpass12');
    await tester.pump();
    expect(find.text(_weak), findsNothing);
  });

  testWidgets('the password it refused, typed again, shows it again', (
    tester,
  ) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong, next: _weak);
    await tester.enterText(_field(0), 'other');
    await tester.enterText(_field(1), 'otherpass1');
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    expect(find.text(_weak), findsNothing);

    await tester.enterText(_field(0), 'oldpass00');
    await tester.enterText(_field(1), 'newpass11');
    await tester.pump();
    expect(_under(0, _wrong), findsOneWidget);
    expect(_under(1, _weak), findsOneWidget);
  });

  testWidgets('focus alone does not take a message away', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong, next: _weak);
    await tester.tap(_field(1));
    await tester.pump();
    await tester.tap(_field(0));
    await tester.pump();
    await tester.tap(_field(2));
    await tester.pump();
    expect(_under(0, _wrong), findsOneWidget);
    expect(_under(1, _weak), findsOneWidget);
  });

  testWidgets('the next submit to end with the same message shows it for '
      'what the field holds then', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong, next: _weak);
    await tester.enterText(_field(0), 'oldpass01');
    await tester.enterText(_field(1), 'newpass12');
    await tester.enterText(_field(2), 'newpass12');
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    expect(find.text(_weak), findsNothing);

    await _refuse(tester, host, current: _wrong, next: _weak);
    expect(_under(0, _wrong), findsOneWidget);
    expect(_under(1, _weak), findsOneWidget);
  });

  testWidgets('a submit that ends with none takes them away', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, current: _wrong, next: _weak);
    await _refuse(tester, host);
    expect(find.text(_wrong), findsNothing);
    expect(find.text(_weak), findsNothing);
  });

  testWidgets('the form\'s own message shows in a refusal\'s place', (
    tester,
  ) async {
    final host = await _pump(tester, fill: false);
    await tester.tap(find.text('Change password'));
    await tester.pump();
    await _refuse(tester, host, current: _wrong, next: _weak);
    expect(_under(0, 'Current password is required'), findsOneWidget);
    expect(find.text(_wrong), findsNothing);
    expect(find.text(_weak), findsNothing);
    expect(host.submitted, isEmpty);
  });

  testWidgets('the submit that brings a refusal takes focus to its field, '
      'the current password\'s first', (tester) async {
    for (final (current, next, index) in [
      (_wrong, null, 0),
      (null, _weak, 1),
      (_wrong, _weak, 0),
    ]) {
      final host = await _pump(tester);
      await tester.tap(_field(2));
      await tester.pump();
      await _refuse(tester, host, current: current, next: next);
      expect(_focused(tester, index), isTrue, reason: '$current / $next');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a submit that ends with no refusal leaves focus where it '
      'was', (tester) async {
    final host = await _pump(tester);
    await tester.tap(_field(2));
    await tester.pump();
    await _refuse(tester, host, error: 'Try again later');
    expect(_focused(tester, 0), isFalse);
    expect(_focused(tester, 1), isFalse);
  });

  testWidgets('a message given from the start shows', (tester) async {
    await _pump(tester, current: _wrong, next: _weak, fill: false);
    expect(_under(0, _wrong), findsOneWidget);
    expect(_under(1, _weak), findsOneWidget);
  });

  testWidgets('NewPasswordFields shows a message from outside under the '
      'new password, behind its own length rule', (tester) async {
    Widget fields(String? errorText) => MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: NewPasswordFields(onChanged: (_) {}, errorText: errorText),
      ),
    );
    await tester.pumpWidget(fields(null));
    await tester.enterText(_field(0), 'newpass11');
    await tester.pumpWidget(fields(_weak));
    expect(_under(0, _weak), findsOneWidget);

    await tester.enterText(_field(0), 'short');
    await tester.tap(_field(1));
    await tester.pump();
    expect(find.text(_weak), findsNothing);
    expect(find.textContaining('at least 8'), findsOneWidget);
  });
}
