# CLAUDE.md

`packages/admin_ui` is a public package that apps depend on by git tag. Its
README, CHANGELOG, code, tests and history name no app that uses it, and no
person or company behind one: describe a need in generic terms ("an app
needs per-language menus") and invent neutral example data.

## Tooling

- Run Dart and Flutter through fvm (`fvm dart …`, `fvm flutter …`); `.fvmrc`
  pins the version CI runs.
- `fvm dart run tool/format.dart [--check] [<paths>]` is the formatter CI
  checks with: `dart format`, sorted imports, relative imports in `lib/`.
- `fvm dart analyze --fatal-infos` must be clean.
- `fvm dart run tool/check_constraints.dart`: every dependency constraint
  admits the latest release, or `_heldBack` says why not.

## Material comes from material_ui

Import `package:material_ui/material_ui.dart` and
`package:cupertino_ui/cupertino_ui.dart`, never `package:flutter/material.dart`
or `cupertino.dart`: they are a second copy of Material whose `Theme` the kit
cannot see. `fvm dart fix --apply --code=migrate_design_widgets` rewrites one,
and `test/material_ui_imports_test.dart` fails on one.

## Snapshots and versions

- `api.txt` is the public surface: `fvm dart run tool/gen_barrels.dart` (from
  `packages/admin_ui`) after adding or removing a public declaration.
- `looks.txt` is every theme's resolved tokens: `fvm dart run
  tool/gen_looks.dart` after changing a token.
- Below 1.0 a breaking change bumps the minor, anything else the patch; a
  change of look is breaking. Record each change in `CHANGELOG.md` under the
  next version, looks under a heading of their own. A rename keeps the old
  name deprecated, with a `dart fix` rule, until the next breaking release.
- A release is a tag, `v<version>`, on a commit of `main` whose CI passed.

## Looking at a widget

Every demo in `packages/admin_ui/example` has a `@Preview` wrapped in
`adminUiPreview`. Render one rather than building a harness
(`alias fw='fvm dart run flutterware'`, from the repository root):

```sh
fw run previews entries --package=packages/admin_ui/example
fw run previews screenshot --entry='lib/src/ui/primitives/button.dart#ButtonDemo.new'
fw run previews audit --package=packages/admin_ui/example
```

No pixel goldens: the sweeps in `packages/admin_ui/example/test/sweeps` pump
every demo and fail on an exception or an overflow. A pull request that
changes a look on purpose shows before/after `fw run previews screenshot`s.
