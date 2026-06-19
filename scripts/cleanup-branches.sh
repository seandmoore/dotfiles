#!/usr/bin/env bash
# Delete stale/merged remote branches, leaving just `main` and `feature`.
#
# Run from a normal clone with push access to GitHub (NOT from a sandbox proxy,
# which silently ignores ref deletions). Safe to re-run — branches already gone
# are skipped.
#
#   ./scripts/cleanup-branches.sh
set -euo pipefail

branches=(
  claude/dotfiles-review-LZ19t            # orphan early history — no shared ancestor with main
  claude/ci-and-dev-setup                 # merged into main (PR #13)
  claude/aur-package-malware-check-fa7ztu # merged into main
  claude/dotfiles-laptop-gestures-599bqs  # superseded by `feature`
)

for b in "${branches[@]}"; do
  echo ":: deleting origin/$b"
  git push origin --delete "$b" || echo "   (skip: $b already gone or not deletable)"
done

echo
echo "Done. You should now have just 'main' and 'feature'."
git ls-remote --heads origin | awk '{print "  " $2}'
