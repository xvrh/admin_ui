import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

const _countries = [
  ComboboxOption('be', 'Belgium', description: 'Europe · EUR'),
  ComboboxOption('fr', 'France', description: 'Europe · EUR'),
  ComboboxOption('de', 'Germany', description: 'Europe · EUR'),
  ComboboxOption('jp', 'Japan', description: 'Asia · JPY'),
  ComboboxOption('us', 'United States', description: 'Americas · USD'),
  ComboboxOption('br', 'Brazil', description: 'Americas · BRL'),
  ComboboxOption('za', 'South Africa', description: 'Africa · ZAR'),
  ComboboxOption('au', 'Australia', description: 'Oceania · AUD'),
];

String _countryName(String code) =>
    _countries.firstWhere((o) => o.value == code).label;

/// A server stand-in: matches after a short latency.
Future<List<ComboboxOption<String>>> _fetch(String query) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final q = query.toLowerCase();
  return _countries.where((o) => o.label.toLowerCase().contains(q)).toList();
}

class ComboboxDemo extends StatelessWidget {
  @Preview(name: 'Combobox / autocomplete', wrapper: adminUiPreview)
  const ComboboxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 420,
      children: [
        const DemoSection('Local filter'),
        LiveValue<String?>(
          initial: 'be',
          builder: (v, set) => Combobox<String>(
            value: v,
            onChanged: set,
            options: _countries,
            hint: 'Pick a country',
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('No initial value'),
        LiveValue<String?>(
          initial: null,
          builder: (v, set) => Combobox<String>(
            value: v,
            onChanged: set,
            options: _countries,
            hint: 'Search countries…',
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Async only — no local options, labelFor'),
        LiveValue<String?>(
          initial: 'jp',
          builder: (v, set) => Combobox<String>(
            value: v,
            onChanged: set,
            hint: 'Type to search…',
            onSearch: _fetch,
            labelFor: _countryName,
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('A search that fails once, then retries'),
        const _FlakySearch(),
        const Gap(AdminSpacing.xl),

        const DemoSection('Narrow and wide fields'),
        Row(
          children: [
            SizedBox(
              width: 150,
              child: LiveValue<String?>(
                initial: 'fr',
                builder: (v, set) => Combobox<String>(
                  value: v,
                  onChanged: set,
                  options: _countries,
                ),
              ),
            ),
            const Gap(AdminSpacing.md),
            Expanded(
              child: LiveValue<String?>(
                initial: 'us',
                builder: (v, set) => Combobox<String>(
                  value: v,
                  onChanged: set,
                  options: _countries,
                ),
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Read-only (no onChanged) · disabled'),
        const Combobox<String>(
          value: 'jp',
          onChanged: null,
          options: _countries,
        ),
        const Gap(AdminSpacing.md),
        Combobox<String>(
          value: 'jp',
          onChanged: (_) {},
          options: _countries,
          enabled: false,
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('In a labelled field with an error'),
        LabeledField(
          label: 'Country',
          required: true,
          errorText: 'Pick the country the invoice is sent to.',
          child: LiveValue<String?>(
            initial: null,
            builder: (v, set) => Combobox<String>(
              value: v,
              onChanged: set,
              options: _countries,
              hint: 'Pick a country',
            ),
          ),
        ),
      ],
    );
  }
}

/// Fails its first search, so the error row and its retry show.
class _FlakySearch extends StatefulWidget {
  const _FlakySearch();

  @override
  State<_FlakySearch> createState() => _FlakySearchState();
}

class _FlakySearchState extends State<_FlakySearch> {
  String? _value;
  var _calls = 0;

  Future<List<ComboboxOption<String>>> _search(String query) async {
    if (_calls++ == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw StateError('The country service did not answer.');
    }
    return _fetch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Combobox<String>(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      hint: 'Search countries…',
      onSearch: _search,
      labelFor: _countryName,
    );
  }
}

/// The dropdown open on a value: every option listed, the value highlighted
/// and checked, the list as wide as the field. Below it, a search's three
/// other answers: still running, nothing found, and failed.
class ComboboxOpenDemo extends StatelessWidget {
  @Preview(name: 'Combobox / open', wrapper: adminUiPreview)
  const ComboboxOpenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 420,
      children: [
        const DemoSection('Opened with a value'),
        PinnedOpen(
          makeRoom: true,
          child: LiveValue<String?>(
            initial: 'jp',
            builder: (v, set) =>
                Combobox<String>(value: v, onChanged: set, options: _countries),
          ),
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('A search still running'),
        _OpenSearch(search: (_) => Completer<_Results>().future),
        const Gap(AdminSpacing.xl),
        const DemoSection('A search that finds nothing'),
        _OpenSearch(search: (_) async => const []),
        const Gap(AdminSpacing.xl),
        const DemoSection('A search that fails — the error and a retry'),
        _OpenSearch(
          search: (_) async => throw StateError('No answer from the server.'),
        ),
      ],
    );
  }
}

typedef _Results = List<ComboboxOption<String>>;

/// An async-only combobox pinned open on [search]'s answer to the empty
/// query, with room below for the one-row list.
class _OpenSearch extends StatelessWidget {
  final Future<_Results> Function(String query) search;

  const _OpenSearch({required this.search});

  @override
  Widget build(BuildContext context) {
    return PinnedOpen(
      makeRoom: true,
      child: Combobox<String>(
        value: null,
        onChanged: (_) {},
        hint: 'Search countries…',
        onSearch: search,
        labelFor: _countryName,
      ),
    );
  }
}

/// A narrow combobox at the foot of the viewport: its dropdown opens above
/// it, at the minimum width, kept on screen.
class ComboboxFlipDemo extends StatelessWidget {
  @Preview(name: 'Combobox / flips near the bottom', wrapper: adminUiPreview)
  const ComboboxFlipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xxl),
          child: SizedBox(
            width: 160,
            child: PinnedOpen(
              child: LiveValue<String?>(
                initial: 'za',
                builder: (v, set) => Combobox<String>(
                  value: v,
                  onChanged: set,
                  options: _countries,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
