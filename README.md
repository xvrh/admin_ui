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

The reports live in a repository of their own, `<this repository>-comparisons`
(or the `COMPARISON_REPOSITORY` variable), never on a branch of this one: pub
caches a git dependency as a mirror of every branch, and a report runs to
100 MB. Its `main` holds `pr-<number>/<sha>/` for each open pull request's
latest push, as one commit with no history; a closed pull request's report is
removed. raw.githubusercontent.com serves the comment's picture and GitHub
Pages the viewer. Setting it up, once, with a deploy key that can write to
that repository alone:

```sh
gh repo create <owner>/admin_ui-comparisons --public
ssh-keygen -t ed25519 -N '' -C fw-compare -f comparison_key
gh repo deploy-key add comparison_key.pub --repo <owner>/admin_ui-comparisons --allow-write --title fw-compare
gh secret set COMPARISON_DEPLOY_KEY --repo <owner>/admin_ui < comparison_key
rm comparison_key comparison_key.pub
```

After the first report lands, switch on Pages for that repository: Settings →
Pages → Deploy from a branch → `main`, `/ (root)`. Without the secret the
comment still comes, with the table and no picture, and its links lead to the
run, whose artifact is the report. A pull request from a fork or from
Dependabot gets no secrets and a read-only token, so its report is only the
artifact, and the run's summary says so.

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
