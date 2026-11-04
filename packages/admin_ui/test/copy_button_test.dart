import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/copy_button.dart';
import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/theme/sizes.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Answers the clipboard, handing [onSetData] the text, or refuses it when
/// [refuse] is set, as a browser outside a secure context does.
void _clipboard(
  WidgetTester tester, {
  void Function(String text)? onSetData,
  bool refuse = false,
}) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      if (refuse) throw PlatformException(code: 'NotAllowedError');
      onSetData?.call((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
}

/// The label that shows, not the hidden ones that hold the width.
Finder _shown(String text) => find.text(text).hitTestable();

void main() {
  final tokens = AdminTokens.from(palette: irisPalette);

  testWidgets('copies the text and confirms, then reverts', (tester) async {
    String? copied;
    _clipboard(tester, onSetData: (text) => copied = text);

    await tester.pumpWidget(
      const _Host(CopyButton('usr_42', revertAfter: Duration(seconds: 1))),
    );

    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

    await tester.tap(find.byType(CopyButton));
    await tester.pump();

    expect(copied, 'usr_42');
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('labelled mode flips the label to Copied', (tester) async {
    _clipboard(tester);

    await tester.pumpWidget(const _Host(CopyButton('x', label: 'Copy URL')));
    expect(_shown('Copy URL'), findsOneWidget);

    await tester.tap(find.byType(CopyButton));
    await tester.pump();
    expect(_shown('Copied'), findsOneWidget);
    expect(_shown('Copy URL'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the labelled mode is a small ghost Button', (tester) async {
    await tester.pumpWidget(
      _Host(const CopyButton('x', label: 'Copy URL'), tokens: tokens),
    );
    final button = tester.widget<Button>(
      find.ancestor(of: _shown('Copy URL'), matching: find.byType(Button)),
    );
    expect(button.variant, ButtonVariant.ghost);
    expect(button.size, ControlSize.small);
    expect(tester.getSize(find.byType(CopyButton)).height, tokens.sizes.small);
    expect(
      tester.getSize(find.byIcon(Icons.copy_rounded).hitTestable()),
      Size.square(tokens.iconSizes.sm),
    );
  });

  testWidgets('the icon-only mode is an inline IconAction', (tester) async {
    await tester.pumpWidget(_Host(const CopyButton('x'), tokens: tokens));
    final action = tester.widget<IconAction>(find.byType(IconAction));
    expect(action.size, IconActionSize.inline);
    expect(
      tester.getSize(find.byType(CopyButton)),
      Size.square(IconActionSize.inline.box),
    );
    expect(
      tester.getSize(find.byIcon(Icons.copy_rounded)),
      Size.square(tokens.iconSizes.sm),
    );
  });

  for (final (name, label, copiedLabel) in [
    ('a label longer than the confirmation', 'Copy URL', null),
    ('a confirmation longer than the label', 'Copy', 'Copied to clipboard'),
  ]) {
    testWidgets('keeps its width across the swap: $name', (tester) async {
      _clipboard(tester);
      await tester.pumpWidget(
        _Host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CopyButton('x', label: label, copiedLabel: copiedLabel),
              const Text('after', key: Key('after')),
            ],
          ),
          tokens: tokens,
        ),
      );
      final idle = tester.getRect(find.byType(CopyButton));
      final after = tester.getTopLeft(find.byKey(const Key('after')));

      await tester.tap(find.byType(CopyButton));
      await tester.pump();
      final confirmation = _shown(copiedLabel ?? 'Copied');
      expect(confirmation, findsOneWidget);
      expect(tester.getRect(find.byType(CopyButton)), idle);
      expect(tester.getTopLeft(find.byKey(const Key('after'))), after);

      // The fill, which hover tints, spans the whole reserved width.
      final surface = find
          .ancestor(of: confirmation, matching: find.byType(Material))
          .first;
      expect(tester.getSize(surface).width, idle.width);
      await tester.pump(const Duration(seconds: 2));
    });
  }

  testWidgets('hover lays the neutral overlay, seen on a panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        ColoredBox(
          color: tokens.palette.surface,
          child: const CopyButton('x', label: 'Copy URL'),
        ),
        tokens: tokens,
      ),
    );
    final surface = find
        .ancestor(of: _shown('Copy URL'), matching: find.byType(Material))
        .first;
    expect(tester.widget<Material>(surface).color, Colors.transparent);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(surface));
    await tester.pump();
    expect(
      tester.widget<Material>(surface).color,
      Color.alphaBlend(tokens.palette.hoverOverlay, Colors.transparent),
    );
  });

  group('when the clipboard refuses the copy', () {
    testWidgets('icon-only: a danger glyph, named and announced', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      _clipboard(tester, refuse: true);
      var calls = 0;
      await tester.pumpWidget(
        _Host(
          CopyButton('x', failedLabel: 'Copy failed', onCopied: () => calls++),
          tokens: tokens,
        ),
      );

      await tester.tap(find.byType(CopyButton));
      await tester.pump();

      expect(calls, 0);
      final glyph = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(glyph.color, tokens.palette.dangerText);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Copy failed',
      );
      expect(tester.takeAnnouncements().map((a) => a.message), ['Copy failed']);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('labelled: the label and the glyph say so', (tester) async {
      final semantics = tester.ensureSemantics();
      _clipboard(tester, refuse: true);
      var calls = 0;
      await tester.pumpWidget(
        _Host(
          CopyButton('x', label: 'Copy', onCopied: () => calls++),
          tokens: tokens,
        ),
      );
      final idle = tester.getRect(find.byType(CopyButton));

      await tester.tap(find.byType(CopyButton));
      await tester.pump();

      expect(calls, 0);
      expect(_shown('Copy failed'), findsOneWidget);
      final glyph = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded).hitTestable(),
      );
      expect(glyph.color, tokens.palette.dangerText);
      expect(tester.takeAnnouncements().map((a) => a.message), ['Copy failed']);
      // The failure, longer than the label, was reserved for too.
      expect(tester.getRect(find.byType(CopyButton)), idle);

      await tester.pump(const Duration(seconds: 2));
      expect(_shown('Copy'), findsOneWidget);
      semantics.dispose();
    });
  });
}

class _Host extends StatelessWidget {
  final Widget child;
  final AdminTokens? tokens;
  const _Host(this.child, {this.tokens});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: tokens == null ? null : buildAppTheme(tokens!),
    home: Scaffold(body: Center(child: child)),
  );
}
