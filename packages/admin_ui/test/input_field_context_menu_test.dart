import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget field) => MaterialApp(
  theme: buildAppTheme(irisTheme.tokens),
  home: Scaffold(body: SizedBox(width: 320, child: field)),
);

Future<void> _rightClick(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a right-click opens the menu the field is given, with the '
      'platform\'s items to add to it', (tester) async {
    List<ContextMenuButtonItem>? platformItems;
    await tester.pumpWidget(
      _app(
        InputField(
          value: 'A colour',
          maxLines: null,
          contextMenuBuilder: (context, editableTextState) {
            platformItems = editableTextState.contextMenuButtonItems;
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: [
                ContextMenuButtonItem(label: 'Color', onPressed: () {}),
                ...editableTextState.contextMenuButtonItems,
              ],
            );
          },
        ),
      ),
    );

    await _rightClick(tester, find.byType(TextField));

    expect(find.text('Color'), findsOneWidget);
    expect(platformItems, isNotEmpty);
  });

  testWidgets('without one, a right-click opens the platform\'s menu', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const InputField(value: 'A colour')));

    await _rightClick(tester, find.byType(TextField));

    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    expect(find.text('Color'), findsNothing);
  });
}
