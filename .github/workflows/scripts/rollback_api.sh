#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${GITHUB_EVENT_CLIENT_PAYLOAD_APP:-unknown}"
REVISION="${GITHUB_EVENT_CLIENT_PAYLOAD_REVISION:-unknown}"
GITHUB_REPO="labotomy-dot-dev/coffee-cup"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

echo "🔄 Starting GitOps rollback for $APP_NAME (revision: $REVISION)"

# Get last commit that changed the app’s manifest
LAST_COMMIT=$(gh api repos/$GITHUB_REPO/commits --jq ".[0].sha")

# Create a revert commit for the failed deployment
gh api repos/$GITHUB_REPO/git/commits \
  -f message="Rollback: $APP_NAME reverted after failed sync (ArgoCD revision $REVISION)" \
  -f parents="[$LAST_COMMIT]" \
  -f tree=$(gh api repos/$GITHUB_REPO/git/commits/$LAST_COMMIT --jq '.tree.sha') \
  --jq '.sha'

echo "✅ Rollback commit created and pushed. Argo CD will re-sync automatically."
