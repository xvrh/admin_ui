#!/usr/bin/env bash
# The comparison reports of open pull requests, on a branch of the repository
# that GitHub Pages and raw.githubusercontent.com serve them from:
# pr-<number>/<sha>/ holds what `fw compare --report` wrote for that push.
#
#   comparison_site.sh publish <pr> <sha> <report-dir>
#   comparison_site.sh remove <pr>
#
# Every update is one commit with no parent, pushed with a lease, so the branch
# holds the open pull requests' latest reports and no history. A push that
# loses a race fetches and redoes it.
#
# SITE_REMOTE is the repository to push to; SITE_BRANCH defaults to main.
# With SITE_DEPLOY_KEY, git reaches github.com over SSH
# with that private key, checking GitHub's host keys as its API lists them.
set -euo pipefail

usage() {
  echo "usage: $0 publish <pr> <sha> <report-dir> | remove <pr>" >&2
  exit 64
}

mode=${1:-}
pr=${2:-}
[[ $pr =~ ^[0-9]+$ ]] || usage
case $mode in
  publish)
    [[ $# -eq 4 && $3 =~ ^[0-9a-f]{7,40}$ && -f $4/comment.md ]] || usage
    sha=$3
    report=$(cd "$4" && pwd)
    ;;
  remove) [[ $# -eq 2 ]] || usage ;;
  *) usage ;;
esac

remote=${SITE_REMOTE:?SITE_REMOTE names the repository to push to}
branch=${SITE_BRANCH:-main}

work=$(mktemp -d)
ssh_dir=$(mktemp -d)
trap 'rm -rf "$work" "$ssh_dir"' EXIT
git -C "$work" init -q

if [[ -n ${SITE_DEPLOY_KEY:-} ]]; then
  printf '%s\n' "$SITE_DEPLOY_KEY" >"$ssh_dir/key"
  chmod 600 "$ssh_dir/key"
  curl -fsSL https://api.github.com/meta \
    | jq -r '.ssh_keys[] | "github.com " + .' >"$ssh_dir/known_hosts"
  export GIT_SSH_COMMAND="ssh -F /dev/null -i $ssh_dir/key -o IdentitiesOnly=yes \
-o UserKnownHostsFile=$ssh_dir/known_hosts -o StrictHostKeyChecking=yes"
fi

for attempt in $(seq 10); do
  rm -rf "$work/.git/index" "$work/pr-$pr"
  if git -C "$work" ls-remote -q --exit-code "$remote" "refs/heads/$branch" >/dev/null; then
    git -C "$work" fetch -q --depth=1 "$remote" "refs/heads/$branch"
    lease=$(git -C "$work" rev-parse FETCH_HEAD)
    git -C "$work" read-tree FETCH_HEAD
  else
    # 2 is "no such ref"; anything else is git failing to reach the remote.
    status=$?
    if [[ $status -ne 2 ]]; then
      echo "Cannot read $remote." >&2
      exit 1
    fi
    # No branch yet. The empty lease makes the push fail if one appeared.
    lease=
  fi
  git -C "$work" rm -r -q --cached --ignore-unmatch -- "pr-$pr"

  if [[ $mode == publish ]]; then
    mkdir -p "$work/pr-$pr/$sha"
    cp -R "$report/." "$work/pr-$pr/$sha/"
    # Pages would run the viewer through Jekyll otherwise.
    : >"$work/.nojekyll"
    git -C "$work" add -f -- .nojekyll "pr-$pr"
    message="Comparison for #$pr at $sha"
  else
    if [[ -z $lease ]] || git -C "$work" diff --cached --quiet FETCH_HEAD; then
      echo "Nothing of #$pr on $branch."
      exit 0
    fi
    message="Remove the comparison for #$pr"
  fi

  tree=$(git -C "$work" write-tree)
  commit=$(git -C "$work" \
    -c user.name='github-actions[bot]' \
    -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
    commit-tree "$tree" -m "$message")
  if git -C "$work" push -q --force-with-lease="refs/heads/$branch:$lease" \
    "$remote" "$commit:refs/heads/$branch"; then
    echo "$message: $branch is $commit."
    exit 0
  fi
  echo "Lost a race for $branch (attempt $attempt); trying again." >&2
  # Jittered, so writers that collided do not collide again in step.
  sleep $((1 + RANDOM % (attempt * 2)))
done

echo "Could not update $branch." >&2
exit 1
