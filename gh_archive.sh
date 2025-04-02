#!/bin/bash

# Check for required input
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 ORG YYYY-MM-DD [exclude_keywords_comma_separated]"
  exit 1
fi

ORG="$1"
CUTOFF_DATE="$2"

# Parse excluded keywords
EXCLUDE_KEYWORDS=()
if [ ! -z "$3" ]; then
  IFS=',' read -ra EXCLUDE_KEYWORDS <<< "$3"
fi

AUTO_CONFIRM=false
if [ "$4" == "--yes" ]; then
  AUTO_CONFIRM=true
fi

# Convert cutoff date to timestamp
CUTOFF_TIMESTAMP=$(date -jf "%Y-%m-%d" "$CUTOFF_DATE" +%s 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Invalid date format. Use YYYY-MM-DD."
  exit 1
fi

# Fetch repositories
echo "Fetching repositories for org '$ORG'..."
REPOS=$(gh repo list "$ORG" --limit 1000 --json name,updatedAt,nameWithOwner)

# Filter repos by date
OLD_REPOS=()
echo "Checking for repos not updated since $CUTOFF_DATE..."
echo ""

REPO_LIST=$(jq -c '.[]' <<< "$REPOS")
while read -r repo; do
  NAME=$(echo "$repo" | jq -r '.name')
  UPDATED=$(echo "$repo" | jq -r '.updatedAt')
  FULL=$(echo "$repo" | jq -r '.nameWithOwner')
  UPDATED_TS=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$UPDATED" +%s)

  SKIP_REPO=false
  for keyword in "${EXCLUDE_KEYWORDS[@]}"; do
    if [[ "$NAME" == *"$keyword"* ]]; then
      SKIP_REPO=true
      break
    fi
  done
  if $SKIP_REPO; then
    continue
  fi

  if [ "$UPDATED_TS" -lt "$CUTOFF_TIMESTAMP" ]; then
    echo "$FULL last updated on $UPDATED"
    OLD_REPOS+=("$FULL")
  fi

done <<< "$REPO_LIST"

# Show summary
echo ""
echo "Found ${#OLD_REPOS[@]} old repositories."

# Prompt to archive
read -p "Do you want to archive all of them? (y/n): " confirm
if [[ "$confirm" == "y" ]] || $AUTO_CONFIRM; then
  for repo in "${OLD_REPOS[@]}"; do
    echo "Archiving $repo..."
    if $AUTO_CONFIRM; then
      gh repo archive "$repo" --yes
    else
      gh repo archive "$repo"
    fi
  done
  echo "All selected repositories have been archived."
else
  echo "No repositories archived."
fi

