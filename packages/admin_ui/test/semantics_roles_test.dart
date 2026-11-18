import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/alert_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The nodes announced as [role].
List<SemanticsNode> _withRole(SemanticsRole role) => find.semantics
    .byPredicate((node) => node.getSemanticsData().role == role)
    .evaluate()
    .toList();

/// The nodes labelled exactly [label].
List<SemanticsNode> _labelled(String label) => find.semantics
    .byPredicate((node) => node.getSemanticsData().label == label)
    .evaluate()
    .toList();

/// Whether [node] is under [ancestor].
bool _isUnder(SemanticsNode node, SemanticsNode ancestor) {
  for (var above = node.parent; above != null; above = above.parent) {
    if (above == ancestor) return true;
  }
  return false;
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  builder: (context, navigator) => ToastScope(child: navigator!),
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

Widget _shell({Widget? child}) => Shell(
  topBar: const TopBar(leading: Text('Acme')),
  sidebar: Sidebar(
    entries: [
      NavItem(
        'Pages',
        icon: Icons.description_outlined,
        selected: true,
        onTap: () {},
      ),
    ],
  ),
  child: child ?? const Center(child: Text('The page')),
);

Widget _frame(Widget child, {Locale? locale}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: AdminScope(child: child),
);

class _Library implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult.empty;

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

void main() {
  late SemanticsHandle handle;
  setUp(() => handle = SemanticsBinding.instance.ensureSemantics());
  tearDown(() {
    debugAlertRoleAnnounces = null;
    handle.dispose();
  });

  group('ProgressBar', () {
    testWidgets('with a value, is a progress bar named by its caption, from 0 '
        'to 100', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProgressBar(
            value: 0.617,
            label: 'cover.jpg',
            showPercent: true,
          ),
        ),
      );
      final bar = _withRole(SemanticsRole.progressBar).single;
      final data = bar.getSemanticsData();
      expect(data.label, 'cover.jpg');
      expect(data.value, '62');
      expect(data.minValue, '0');
      expect(data.maxValue, '100');
      // The caption is the bar's name, not a second thing to read.
      expect(_labelled('cover.jpg'), [bar]);
    });

    testWidgets('semanticLabel names a bar with no caption, and one whose '
        'caption says too little', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressBar(value: 0.5, semanticLabel: 'Storage used'),
              ProgressBar(
                value: 0.25,
                label: 'cover.jpg',
                semanticLabel: 'Uploading cover.jpg',
              ),
            ],
          ),
        ),
      );
      expect(
        [
          for (final bar in _withRole(SemanticsRole.progressBar))
            bar.getSemanticsData().label,
        ],
        ['Storage used', 'Uploading cover.jpg'],
      );
      expect(_labelled('cover.jpg'), isEmpty);
    });

    testWidgets('with no value, is no progress bar, and its caption is read as '
        'the text it is', (tester) async {
      await tester.pumpWidget(
        _host(const ProgressBar(value: null, label: 'Uploading…')),
      );
      expect(_withRole(SemanticsRole.progressBar), isEmpty);
      final caption = _labelled('Uploading…').single;
      expect(caption.getSemanticsData().role, SemanticsRole.none);
    });

    testWidgets('an upload row names its bar by the file', (tester) async {
      await tester.pumpWidget(
        _host(
          const UploadZone(
            items: [
              UploadItem(
                id: 'a',
                name: 'cover.jpg',
                status: UploadStatus.uploading,
                progress: 0.4,
              ),
            ],
          ),
        ),
      );
      for (final bar in _withRole(SemanticsRole.progressBar)) {
        expect(bar.getSemanticsData().label, isNotEmpty);
      }
      expect(_withRole(SemanticsRole.progressBar), isNotEmpty);
    });
  });

  group('Alert', () {
    testWidgets('a danger alert is an alert whose words are a live region '
        'inside it', (tester) async {
      await tester.pumpWidget(
        _host(
          Alert(
            'Check your password.',
            title: 'Sign-in failed',
            severity: Severity.danger,
            onDismiss: () {},
          ),
        ),
      );
      final alert = _withRole(SemanticsRole.alert).single;
      // The framework refuses the role on a live region.
      expect(alert, isSemantics(isLiveRegion: false));
      expect(alert.getSemanticsData().label, isEmpty);

      final words = tester.getSemantics(find.text('Check your password.'));
      expect(words.parent, alert);
      expect(
        words,
        isSemantics(
          label: 'Sign-in failed\nCheck your password.',
          isLiveRegion: true,
        ),
      );
      // Its close button is read with it.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Dismiss')).parent,
        alert,
      );
    });

    testWidgets('where the role itself is read out, the words are no live '
        'region: the message is said once', (tester) async {
      debugAlertRoleAnnounces = true;
      await tester.pumpWidget(
        _host(const Alert('Check your password.', severity: Severity.danger)),
      );
      final alert = _withRole(SemanticsRole.alert).single;
      final words = tester.getSemantics(find.text('Check your password.'));
      expect(words.parent, alert);
      expect(
        words,
        isSemantics(label: 'Check your password.', isLiveRegion: false),
      );
    });

    testWidgets('a warning waits its turn, and a danger alert told not to '
        'speak is no alert', (tester) async {
      for (final (severity, liveRegion, live) in const [
        (Severity.warning, null, true),
        (Severity.info, true, true),
        (Severity.success, null, false),
        (Severity.danger, false, false),
      ]) {
        await tester.pumpWidget(
          _host(Alert('Message', severity: severity, liveRegion: liveRegion)),
        );
        expect(
          _withRole(SemanticsRole.alert),
          isEmpty,
          reason: '$severity, liveRegion: $liveRegion',
        );
        expect(
          tester.getSemantics(find.text('Message')),
          isSemantics(label: 'Message', isLiveRegion: live),
          reason: '$severity, liveRegion: $liveRegion',
        );
      }
    });
  });

  group('Toast', () {
    Future<void> show(WidgetTester tester, Toast toast) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Button(
              'Notify',
              onPressed: () => ToastScope.of(context).show(toast),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Notify'));
      await tester.pumpAndSettle();
    }

    Future<void> drain(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    }

    testWidgets('a danger toast is an alert whose words are a live region '
        'inside it', (tester) async {
      await show(
        tester,
        const Toast('The page could not be saved.', severity: Severity.danger),
      );
      final alert = _withRole(SemanticsRole.alert).single;
      expect(alert, isSemantics(isLiveRegion: false));
      final words = tester.getSemantics(
        find.text('The page could not be saved.'),
      );
      expect(words.parent, alert);
      expect(
        words,
        isSemantics(label: 'The page could not be saved.', isLiveRegion: true),
      );
      expect(
        _isUnder(tester.getSemantics(find.bySemanticsLabel('Dismiss')), alert),
        isTrue,
      );
      await drain(tester);
    });

    testWidgets('where the role itself is read out, a danger toast is said '
        'once', (tester) async {
      debugAlertRoleAnnounces = true;
      await show(
        tester,
        const Toast('The page could not be saved.', severity: Severity.danger),
      );
      expect(_withRole(SemanticsRole.alert), hasLength(1));
      expect(
        tester.getSemantics(find.text('The page could not be saved.')),
        isSemantics(isLiveRegion: false),
      );
      await drain(tester);
    });

    testWidgets('any other toast is a live region and no alert', (
      tester,
    ) async {
      for (final severity in [
        Severity.info,
        Severity.success,
        Severity.warning,
      ]) {
        await show(tester, Toast('Page saved.', severity: severity));
        expect(_withRole(SemanticsRole.alert), isEmpty, reason: '$severity');
        expect(
          tester.getSemantics(find.text('Page saved.')),
          isSemantics(label: 'Page saved.', isLiveRegion: true),
          reason: '$severity',
        );
        await drain(tester);
      }
    });
  });

  group('TabPanel', () {
    testWidgets('is a tab panel named by its tab, its content nodes of their '
        'own', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tabs(
                tabs: const [TabItem('Content'), TabItem('SEO')],
                selected: 1,
                onChanged: (_) {},
              ),
              const TabPanel(label: 'SEO', child: Text('Meta title')),
            ],
          ),
        ),
      );
      final panel = _withRole(SemanticsRole.tabPanel).single;
      expect(panel.getSemanticsData().label, 'SEO');
      expect(tester.getSemantics(find.text('Meta title')).parent, panel);
    });

    testWidgets('the asset picker shows one panel, named by the tab it is '
        'on', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _frame(
          Scaffold(
            body: Builder(
              builder: (context) => Button(
                'Pick',
                onPressed: () => showAssetPicker(context, source: _Library()),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      String panel() =>
          _withRole(SemanticsRole.tabPanel).single.getSemanticsData().label;
      expect(panel(), 'Library');
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      expect(panel(), 'Upload');
    });
  });

  group('Shell', () {
    testWidgets('the page is the main landmark, beside the navigation and '
        'under the top bar', (tester) async {
      await tester.pumpWidget(_frame(_shell()));
      final main = _withRole(SemanticsRole.main).single;
      expect(main.getSemanticsData().label, 'Main content');
      expect(_isUnder(tester.getSemantics(find.text('The page')), main), true);
      expect(_isUnder(tester.getSemantics(find.text('Acme')), main), false);
      final navigation = _withRole(SemanticsRole.navigation).single;
      expect(_isUnder(navigation, main), false);
      expect(_isUnder(main, navigation), false);
    });

    testWidgets('the landmark is named in the app\'s language', (tester) async {
      for (final (locale, name) in const [
        (Locale('fr'), 'Contenu principal'),
        (Locale('ar'), 'المحتوى الرئيسي'),
      ]) {
        await tester.pumpWidget(_frame(_shell(), locale: locale));
        await tester.pumpAndSettle();
        expect(
          _withRole(SemanticsRole.main).single.getSemanticsData().label,
          name,
        );
      }
    });

    testWidgets('a shell shown inside another\'s page is no landmark of its '
        'own', (tester) async {
      await tester.pumpWidget(
        _frame(
          _shell(
            child: const Center(
              child: SizedBox(
                width: 480,
                height: 320,
                child: Shell(child: Center(child: Text('Inner page'))),
              ),
            ),
          ),
        ),
      );
      final main = _withRole(SemanticsRole.main).single;
      expect(
        _isUnder(tester.getSemantics(find.text('Inner page')), main),
        true,
      );
    });

    testWidgets('two shells in one window are two named landmarks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _frame(
          const Row(
            children: [
              Expanded(
                child: Shell(child: Center(child: Text('One'))),
              ),
              Expanded(
                child: Shell(child: Center(child: Text('Two'))),
              ),
            ],
          ),
        ),
      );
      expect(_withRole(SemanticsRole.main), hasLength(2));
      // The framework's check of the landmarks runs as a node is sent again.
      await tester.pumpWidget(
        _frame(
          const Row(
            children: [
              Expanded(
                child: Shell(child: Center(child: Text('One'))),
              ),
              Expanded(
                child: Shell(child: Center(child: Text('Three'))),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // The roles the kit leaves out because the framework refuses them: when one
  // of these passes, the role can be given to the widget waiting for it (see
  // ACCESSIBILITY.md).
  group('roles the framework does not take yet', () {
    for (final (role, waiting) in const [
      (SemanticsRole.comboBox, 'Combobox'),
      (SemanticsRole.dragHandle, 'the drag handles of Tree and TreeEditor'),
      (SemanticsRole.tooltip, 'Tip'),
      (SemanticsRole.spinButton, 'the steppers of a number field'),
    ]) {
      testWidgets('$role, for $waiting', (tester) async {
        await tester.pumpWidget(
          _host(Semantics(container: true, role: role, child: const Text('x'))),
        );
        expect(
          tester.takeException(),
          isA<FlutterError>().having(
            (error) => error.message,
            'message',
            contains('Missing checks for role'),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        tester.takeException();
      });
    }

    testWidgets('an alert that is a live region too', (tester) async {
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            role: SemanticsRole.alert,
            liveRegion: true,
            child: const Text('x'),
          ),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (error) => error.message,
          'message',
          contains('is also a live region'),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      tester.takeException();
    });
  });
}
