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

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
