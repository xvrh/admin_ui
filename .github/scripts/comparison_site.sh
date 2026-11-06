#!/usr/bin/env bash
# The comparison reports of open pull requests, on an orphan branch that
# GitHub Pages and raw.githubusercontent.com serve: pr-<number>/<sha>/ holds
# what `fw compare --report` wrote for that push.
#
#   comparison_site.sh publish <pr> <sha> <report-dir>
#   comparison_site.sh remove <pr>
#
# Every update is one commit with no parent, pushed with a lease, so the branch
# holds the open pull requests' latest reports and no history: pub clones every
# branch of a git dependency, and a branch that kept its pictures would grow
# every app's copy of the kit. A push that loses a race fetches and redoes it.
#
# SITE_REMOTE is the repository to push to; SITE_BRANCH defaults to
# comparison-artifacts.
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
branch=${SITE_BRANCH:-comparison-artifacts}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git -C "$work" init -q

for attempt in $(seq 10); do
  rm -rf "$work/.git/index" "$work/pr-$pr"
  if git -C "$work" fetch -q --depth=1 "$remote" "refs/heads/$branch" 2>/dev/null; then
    lease=$(git -C "$work" rev-parse FETCH_HEAD)
    git -C "$work" read-tree FETCH_HEAD
  else
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
