# admin_ui

A Flutter UI kit for building admin apps: an app shell, data tables and
collections, forms and field bodies, overlays, media and asset pickers,
charts, and sign-in screens, themed from one set of design tokens.

The package is [`packages/admin_ui`](packages/admin_ui): its
[README](packages/admin_ui/README.md) covers installing it from a tag, the
themes, and every part of the kit.

| Directory | What it is |
|---|---|
| `packages/admin_ui` | The kit, the one package an app depends on |
| `packages/admin_ui/example` | The preview catalog: every widget and its states |
| `reference_admin` | An admin built on the kit's public barrels alone, over an in-memory shop |
| `tool` | The formatter, the dependency check and the flutterware declarations |

## Working on the kit

The repository is a pub workspace pinned to one Flutter version
([`.fvmrc`](.fvmrc)); with [fvm](https://fvm.app), run each command through
it:

```sh
fvm flutter pub get
fvm dart run tool/format.dart        # the formatter CI checks with
fvm dart analyze --fatal-infos
cd packages/admin_ui && fvm flutter test
```

After changing the public API or a token, regenerate the snapshots and
review their diff: `fvm dart run tool/gen_barrels.dart` writes `api.txt`,
`fvm dart run tool/gen_looks.dart` writes `looks.txt` (both from
`packages/admin_ui`). The README's "Versions" says which bump a change
needs, and the CHANGELOG records it.

## Pull requests

CI runs the checks above and every package's tests. The Compare workflow
runs flutterware's `fw compare`: every preview and scenario rendered on the
pull request's head and on its merge base with `main`, and one comment on the
pull request with what moved, edited in place on each push. Run
`fvm dart run flutterware compare` to see the same before pushing.

The reports live on the `comparison-artifacts` branch, `pr-<number>/<sha>/`
for each open pull request's latest push, as one commit with no history, so
an app's clone of the kit stays small; a closed pull request's report is
removed. Every update force-pushes that branch, so a ruleset must leave it
out. GitHub Pages serves the viewer from it, once switched on: Settings →
Pages → Deploy from a branch → `comparison-artifacts`, `/ (root)`. Until
then the comment's links lead to the run, whose artifact is the report. A
pull request from a fork or from Dependabot has a read-only token, so its
report is only the artifact, and the run's summary says so.

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
