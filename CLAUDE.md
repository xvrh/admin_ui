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
- `fvm dart run tool/check_version.dart`: the kit's version has its
  `CHANGELOG.md` heading, and no heading above it is older.
- `main` takes a change only as a squashed pull request whose checks pass;
  nothing pushes to it directly. `AGENTS.md` is this file, for other agents.

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
- A release is a tag, `v<version>`, on a commit of `main` whose CI passed;
  CI's Release job checks all three on the tag. Nothing can move or delete a
  `v*` tag, since apps resolve it, so a wrong release is fixed by the next
  one.

## Looking at a widget

Every demo in `packages/admin_ui/example` has a `@Preview` wrapped in
`adminUiPreview`. Render one rather than building a harness
(`alias fw='fvm dart run flutterware'`, from the repository root):

```sh
fw run previews entries --package=packages/admin_ui/example
fw run previews screenshot --entry='lib/src/ui/primitives/button.dart#ButtonDemo.new'
fw run previews audit --package=packages/admin_ui/example
fw compare   # this branch's previews and scenarios against its merge base
```

No pixel goldens: the sweeps in `packages/admin_ui/example/test/sweeps` pump
every demo and fail on an exception or an overflow. The Compare workflow runs
`fw compare` on every pull request and keeps one comment on it with the
pictures that moved, base beside head. Read it once the run is done: the
description says why each finding is meant, and a moved look is recorded in
`CHANGELOG.md`.
