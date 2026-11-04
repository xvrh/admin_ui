import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/ui/demo_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness/harness.dart';

/// The sweep harness itself, on demos made up here so a catalog change
/// cannot move these numbers.
void main() {
  final iris = RenderConfig.of('Iris', ThemeMode.light);

  testWidgets('a page is cropped to its width and content', (tester) async {
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / Tall page',
        () => const DemoPage(
          maxWidth: 400,
          children: [SizedBox(height: 1000), SizedBox(height: 700)],
        ),
      ),
      iris,
    );
    // 1700 of content under 32 of padding on each side.
    expect(tester.view.physicalSize, const Size(400, 1764));
    await unmountAndDrain(tester);
  });

  testWidgets('a crop stays within 320 and maxHeight', (tester) async {
    final short = DemoEntry(
      'Harness / Short page',
      () => const DemoPage(children: [SizedBox(height: 10)]),
    );
    await pumpEntry(tester, short, iris);
    expect(tester.view.physicalSize, const Size(460, 320));
    await unmountAndDrain(tester);

    final tall = DemoEntry(
      'Harness / Very tall page',
      () => const DemoPage(children: [SizedBox(height: 5000)]),
    );
    await pumpEntry(tester, tall, iris, maxHeight: 1200);
    expect(tester.view.physicalSize, const Size(460, 1200));
    await unmountAndDrain(tester);
  });

  testWidgets('a given size wins', (tester) async {
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / Sized',
        () => const DemoPage(children: [SizedBox(height: 10)]),
      ),
      iris,
      size: const Size(700, 500),
    );
    expect(tester.view.physicalSize, const Size(700, 500));
    await unmountAndDrain(tester);
  });

  testWidgets('an open popover past the page widens it and stays open', (
    tester,
  ) async {
    await pumpEntry(
      tester,
      DemoEntry('Harness / Open popover', () => const _OpenPopoverPage()),
      iris,
    );
    // The panel hangs 200 past the page's right edge, plus the margin kept
    // around it, on both sides so the page stays centred.
    expect(tester.view.physicalSize.width, 400 + 2 * (200 + 16));
    expect(find.text('Panel'), findsOneWidget);
    await unmountAndDrain(tester);
  });

  testWidgets("the config's locale reaches the demo", (tester) async {
    Locale? locale;
    AdminLocalizations? kit;
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / Localizations',
        () => Builder(
          builder: (context) {
            locale = Localizations.localeOf(context);
            kit = AdminLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
      iris.copyWith(locale: const Locale('fr')),
    );
    expect(locale, const Locale('fr'));
    expect(kit, isNotNull);
    await unmountAndDrain(tester);
  });

  testWidgets('platform settings reach the demo', (tester) async {
    late MediaQueryData media;
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / Media',
        () => Builder(
          builder: (context) {
            media = MediaQuery.of(context);
            return const SizedBox();
          },
        ),
      ),
      iris.copyWith(textScale: 2, disableAnimations: true),
    );
    expect(media.textScaler.scale(10), 20);
    expect(media.disableAnimations, isTrue);
    expect(media.reduceMotion, isTrue);
    expect(media.devicePixelRatio, 1);
    expect(tester.view.physicalSize, defaultSurface);
    await unmountAndDrain(tester);
  });

  testWidgets('symbols and Arabic fall back to the test fonts', (tester) async {
    late TextStyle body;
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / Arabic',
        () => Builder(
          builder: (context) {
            body = context.type.body;
            return Text('مرحبا', style: body);
          },
        ),
      ),
      RenderConfig.of(
        'shadcn',
        ThemeMode.dark,
      ).copyWith(locale: const Locale('ar')),
    );
    expect(body.fontFamily, 'Inter');
    expect(body.fontFamilyFallback, [
      // The test platform's UI font, ahead of the script fallbacks.
      'Roboto',
      'Test symbols',
      'Noto Naskh Arabic',
    ]);
    expect(textWithoutFont(), isEmpty);
    await unmountAndDrain(tester);
  });

  testWidgets('a theme with no font draws in the platform family, rich '
      'spans and replaced styles alike', (tester) async {
    late TextStyle caption;
    await pumpEntry(
      tester,
      DemoEntry(
        'Harness / No font',
        () => Builder(
          builder: (context) {
            caption = context.type.caption;
            return Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Plain ',
                    children: [
                      TextSpan(text: 'strong', style: context.type.bodyStrong),
                      TextSpan(text: ' مرحبا', style: context.type.body),
                    ],
                  ),
                ),
                DefaultTextStyle(style: caption, child: const Text('A tip')),
              ],
            );
          },
        ),
      ),
      RenderConfig.of('Ant', ThemeMode.light),
    );
    expect(caption.fontFamily, testPlatformFamily);
    expect(textWithoutFont(), isEmpty);
    await unmountAndDrain(tester);
  });

  testWidgets('a span with a fallback and no family fails: it draws in the '
      'default family, not its parent\'s', (tester) async {
    final entry = DemoEntry(
      'Harness / Fallback only',
      () => const Text.rich(
        TextSpan(
          text: 'Parent ',
          children: [
            TextSpan(
              text: 'Boxes',
              style: TextStyle(fontFamilyFallback: ['Noto Naskh Arabic']),
            ),
          ],
        ),
      ),
    );
    Object? failure;
    try {
      await pumpEntry(tester, entry, iris);
    } on TestFailure catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<TestFailure>().having(
        (failure) => failure.message,
        'message',
        allOf(
          contains('"Boxes" in the default family, Noto Naskh Arabic'),
          isNot(contains('"Parent"')),
        ),
      ),
    );
    await unmountAndDrain(tester);
  });

  testWidgets('text in a family no test font serves fails', (tester) async {
    final entry = DemoEntry(
      'Harness / Unknown family',
      () => const Text('Boxes', style: TextStyle(fontFamily: 'Nowhere Sans')),
    );
    Object? failure;
    try {
      await pumpEntry(tester, entry, iris);
    } on TestFailure catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<TestFailure>().having(
        (failure) => failure.message,
        'message',
        contains('"Boxes" in Nowhere Sans'),
      ),
    );
    await unmountAndDrain(tester);
  });
}

/// A 400-wide page whose menu, open from the start, hangs 200 past its
/// right edge.
class _OpenPopoverPage extends StatefulWidget {
  const _OpenPopoverPage();

  @override
  State<_OpenPopoverPage> createState() => _OpenPopoverPageState();
}

class _OpenPopoverPageState extends State<_OpenPopoverPage> {
  final _menu = MenuController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _menu.open());
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 400,
      padding: EdgeInsets.zero,
      children: [
        RawMenuAnchor(
          controller: _menu,
          overlayBuilder: (context, info) => Positioned(
            left: info.anchorRect.left,
            top: info.anchorRect.bottom,
            child: const SizedBox(
              width: 600,
              height: 100,
              child: ColoredBox(color: Color(0xFF3366FF), child: Text('Panel')),
            ),
          ),
          child: const SizedBox(height: 40),
        ),
      ],
    );
  }
}
