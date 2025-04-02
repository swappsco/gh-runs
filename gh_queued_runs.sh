#!/bin/bash

# Usage:
#   ./gh_actions_queue.sh swappsco list
#   ./gh_actions_queue.sh swappsco cancel [limit]
#   ./gh_actions_queue.sh swappsco/dejusticia list
#   ./gh_actions_queue.sh swappsco/dejusticia cancel [limit]
#   ./gh_actions_queue.sh swappsco list 20 --debug

set -e

TARGET="$1"
ACTION="${2:-list}"
CANCEL_LIMIT="${3:-20}"
DEBUG="false"
DRY_RUN="false"

for arg in "$@"; do
  if [ "$arg" = "--debug" ]; then
    DEBUG="true"
    echo "🛠️  Debug mode enabled"
  elif [ "$arg" = "--dry-run" ]; then
    DRY_RUN="true"
    echo "🧪 Dry-run mode enabled: no actual cancellations will be made."
  fi
done

if [ -z "$TARGET" ]; then
  echo "❌ Usage: $0 owner[/repo] [list|cancel] [limit] [--debug]"
  exit 1
fi

if [ "$DEBUG" = "--debug" ]; then
  echo "🛠️  Debug mode enabled"
fi

CANCELLABLE_REPOS=()

debug() {
  if [ "$DEBUG" = "true" ]; then
    echo "$@"
  fi
}

process_repo() {
  local REPO="$1"
  local ACTION="$2"
  local LIMIT="$3"

  debug "🔧 Running: gh run list --repo \"$REPO\" --json databaseId,status | jq -r '.[] | select(.status == \"queued\" or .status == \"in_progress\") | .databaseId'"

  ALL_CANCELLABLE_IDS_RAW=$(gh run list --repo "$REPO" --json databaseId,status \
    | jq -r '.[] | select(.status == "queued" or .status == "in_progress") | .databaseId')

  CLEANED_IDS=$(echo "$ALL_CANCELLABLE_IDS_RAW" | grep -v '^$' || true)

  RUN_IDS_ARRAY=()
  while IFS= read -r line; do
    [ -n "$line" ] && RUN_IDS_ARRAY+=("$line")
  done <<EOF
$CLEANED_IDS
EOF

  TOTAL_CANCELLABLE="${#RUN_IDS_ARRAY[@]}"

  if [ "$TOTAL_CANCELLABLE" -eq 0 ]; then
    return
  fi

  CANCELLABLE_REPOS+=("$REPO")

  if [ "$DEBUG" = "--debug" ]; then
    echo "📦 $REPO has $TOTAL_CANCELLABLE cancellable run(s):"
    printf "%s\n" "${RUN_IDS_ARRAY[@]}"
    echo
  fi

  if [ "$ACTION" = "cancel" ]; then
    if [ "$DRY_RUN" = "false" ]; then
      debug "🚨 Cancelling up to $LIMIT run(s) in $REPO..."
      for ID in "${RUN_IDS_ARRAY[@]:0:$LIMIT}"; do
        echo "➡️  Cancelling run $ID..."
        gh run cancel "$ID" --repo "$REPO"
      done
      echo "✅ Finished cancelling runs in $REPO."
      echo
    fi
  fi
}

if [[ "$TARGET" == *"/"* ]]; then
  process_repo "$TARGET" "$ACTION" "$CANCEL_LIMIT"
else
  ORG="$TARGET"
  debug "🔎 Getting list of repositories with cancellable runs for organization '$ORG'..."

  TMPFILE=$(mktemp)
  gh repo list "$ORG" --limit 10 --json name --jq '.[].name' > "$TMPFILE"

  while read -r repo_name; do
    [ -z "$repo_name" ] && continue
    FULL_REPO="$ORG/$repo_name"
    debug "➡️ Processing $FULL_REPO..."
    process_repo "$FULL_REPO" "$ACTION" "$CANCEL_LIMIT"
  done < "$TMPFILE"

  rm -f "$TMPFILE"
fi

# Final summary (always shown)
if [ "${#CANCELLABLE_REPOS[@]}" -gt 0 ]; then
  echo "📋 Repositories with cancellable runs:"
  for repo in "${CANCELLABLE_REPOS[@]}"; do
    echo "$repo – https://github.com/$repo/actions"
  done
else
  echo "✅ No cancellable runs found in any repository."
fi