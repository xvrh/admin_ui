# admin_ui

A Flutter UI kit for building admin apps: an app shell, data tables and
collections, forms and field bodies, overlays, media and asset pickers,
charts, and sign-in screens, themed from one set of design tokens.

The package is [`packages/admin_ui`](packages/admin_ui): its
[README](packages/admin_ui/README.md) covers pinning it to a commit, the
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

`main` takes a change only as a squashed pull request whose CI and Compare
checks pass. Nothing pushes to it directly, force-pushes it or deletes it, so
every commit an app pins stays on it. This is a repository ruleset that no
one may bypass: an agent working with the owner's credentials would get any
bypass the owner has.

CI runs the checks above and every package's tests. The Compare workflow
runs flutterware's `fw compare`: every preview and scenario rendered on the
pull request's head and on its merge base with `main`, and one comment on the
pull request with what moved, edited in place on each push. Run
`fvm dart run flutterware compare` to see the same before pushing.

The reports live in a private S3 bucket that CloudFront serves, never on a
branch of this repository: pub caches a git dependency as a mirror of every
branch, and a report can run to 100 MB. The bucket holds `pr-<number>/<sha>/`
for each open pull request's latest push. The publish job writes there as a
role it assumes with GitHub's OIDC token, so no key is stored, and only this
repository's pull request runs can assume it.

What bounds it: a push replaces its pull request's previous report, closing
the pull request deletes it, and anything left expires after 30 days, with
versioning off so a delete frees the space. What it costs: storage is the
open pull requests' latest reports at a few cents per GB-month, a push's
upload is a fraction of a cent, and CloudFront's free allowance (1 TB and 10
million requests a month) covers reading them. An optional budget mails an
alert past a monthly amount.

[`.github/aws/comparisons.yaml`](.github/aws/comparisons.yaml) creates all of
it, once, from a shell signed in to the AWS account (add
`CreateOidcProvider=false` if `aws iam list-open-id-connect-providers` already
lists token.actions.githubusercontent.com; CloudFront takes a few minutes):

```sh
aws cloudformation deploy --region <region> --stack-name admin-ui-comparisons \
  --template-file .github/aws/comparisons.yaml --capabilities CAPABILITY_IAM \
  --parameter-overrides Repository=<owner>/admin_ui AlertEmail=<email> \
  SubjectPrefix="$(gh api repos/<owner>/admin_ui/actions/oidc/customization/sub \
    --jq '.sub_claim_prefix // ""')"
for pair in BUCKET:Bucket REGION:Region ROLE_ARN:RoleArn URL:Url; do
  gh variable set "COMPARISON_${pair%%:*}" --body "$(aws cloudformation describe-stacks \
    --region <region> --stack-name admin-ui-comparisons --output text \
    --query "Stacks[0].Outputs[?OutputKey=='${pair#*:}'].OutputValue")"
done
```

Removing it is `aws s3 rm --recursive s3://<bucket>`, then `aws
cloudformation delete-stack --stack-name admin-ui-comparisons`, then deleting
the four `COMPARISON_*` variables. Until they exist, the comment still comes,
with the table and no picture, and its links lead to the run, whose artifact
is the report. A pull request from a fork or from Dependabot gets a read-only
token and no OIDC token, so its report is only the artifact, and the run's
summary says so.

## Upgrades

Every Monday the Upgrade workflow moves `.fvmrc` to the latest Flutter beta
and runs `tool/upgrade.dart`, which moves every pub dependency to its latest
release. A constraint that excludes one is widened to it, unless
`tool/check_constraints.dart` holds it back with a reason, and
`pubspec.lock` takes the newest version every constraint allows. The
workflow opens one pull request with the result, or updates the one already
open. Its description lists what moved and what that asks of the pull
request: a moved constraint of the kit, or a moved look, goes in the
CHANGELOG. CI and Compare run on it as on any other pull request, and a red
check is the upgrade's breakage, to fix on its branch. The next run leaves a
branch with someone else's commit on it alone; otherwise it rebuilds the
branch from `main`. On a Flutter move, Compare renders both sides with the
new Flutter, so its pictures show what the packages moved; CI's sweeps and
tests are what check Flutter itself.

By hand, the same is `fvm dart run tool/upgrade.dart`, after moving `.fvmrc`
and running `fvm install` for a new Flutter. `.fvmrc` is the only place the
version is written: every workflow installs the Flutter it names
(`.github/actions/flutter`). The `environment: flutter:` of the example and
of `reference_admin` is a floor, since a comparison resolves its base under
the branch's Flutter.

The pull request comes from a GitHub App. One opened with a workflow's own
token starts no workflow, so its checks would never report and `main`'s
ruleset would hold it forever. Make the app once:

1. [New GitHub App](https://github.com/settings/apps/new): any name and
   homepage URL, Webhook unticked, the repository permissions Contents and
   Pull requests on Read and write, installable only on this account.
2. Install it on this repository alone, and generate a private key on its
   page.
3. Give the workflow its ID and key, then run it once instead of waiting for
   Monday:

```sh
gh variable set UPGRADE_APP_ID --body <the app's App ID>
gh secret set UPGRADE_APP_PRIVATE_KEY < <the downloaded key>.pem
gh workflow run upgrade.yaml
```

Until both exist, the run fails at its first step and says so.

## Licence

BSD 3-Clause; see [LICENSE](LICENSE).
