import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The placeholder of a page the signed-in user may not open: a muted lock,
// the kit's words or the app's, and a way back where one is given.

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  double width = 480,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('says so in the kit\'s words, under a muted lock', (
    tester,
  ) async {
    await _pump(tester, const ForbiddenState());
    expect(find.text('You don’t have access to this'), findsOneWidget);
    expect(find.text('Ask an administrator if you need it.'), findsOneWidget);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.lock_outline_rounded);
    expect(
      icon.color,
      tester.element(find.byType(ForbiddenState)).colors.foregroundMuted,
    );
    // Nothing failed: no retry, and no button with nowhere to go.
    expect(find.byType(Button), findsNothing);
  });

  testWidgets('follows the app\'s language', (tester) async {
    await _pump(
      tester,
      ForbiddenState(onBack: () {}),
      locale: const Locale('fr'),
    );
    expect(find.text('Vous n’avez pas accès à ceci'), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);

    await _pump(
      tester,
      ForbiddenState(onBack: () {}),
      locale: const Locale('ar'),
    );
    expect(find.text('ليس لديك صلاحية الوصول إلى هذا'), findsOneWidget);
    expect(find.text('رجوع'), findsOneWidget);
  });

  testWidgets('offers the way back it is given, and calls it', (tester) async {
    var back = 0;
    const key = Key('back');
    await _pump(tester, ForbiddenState(onBack: () => back++, backKey: key));
    expect(find.text('Go back'), findsOneWidget);
    await tester.tap(find.byKey(key));
    expect(back, 1);
  });

  testWidgets('takes the app\'s own words', (tester) async {
    await _pump(
      tester,
      ForbiddenState(
        title: 'Not available to editors',
        message: 'Only an owner invites people.',
        backLabel: 'Back to the dashboard',
        icon: Icons.shield_outlined,
        onBack: () {},
      ),
    );
    expect(find.text('Not available to editors'), findsOneWidget);
    expect(find.text('Only an owner invites people.'), findsOneWidget);
    expect(find.text('Back to the dashboard'), findsOneWidget);
    expect(find.text('You don’t have access to this'), findsNothing);
    expect(find.text('Go back'), findsNothing);
    expect(
      tester.widget<Icon>(find.byType(Icon).first).icon,
      Icons.shield_outlined,
    );
  });

  testWidgets('an empty message shows none', (tester) async {
    await _pump(tester, const ForbiddenState(message: ''));
    expect(find.text('You don’t have access to this'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('fills the room it has, and is its minimum height with none', (
    tester,
  ) async {
    // In a page, the whole of it, its content centred.
    await _pump(tester, const ForbiddenState(message: ''));
    expect(tester.getSize(find.byType(ForbiddenState)).height, 600);

    // In a list, where the height is its own.
    await _pump(
      tester,
      const SingleChildScrollView(child: ForbiddenState(message: '')),
    );
    expect(tester.getSize(find.byType(ForbiddenState)).height, 160);
    await _pump(
      tester,
      const SingleChildScrollView(
        child: ForbiddenState(message: '', minHeight: 320),
      ),
    );
    expect(tester.getSize(find.byType(ForbiddenState)).height, 320);
  });

  testWidgets('holds at twice the text size in a narrow panel', (tester) async {
    await _pump(
      tester,
      ForbiddenState(onBack: () {}),
      textScale: 2,
      width: 260,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Go back'), findsOneWidget);
  });
}
