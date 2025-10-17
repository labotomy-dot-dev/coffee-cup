#!/usr/bin/env bash
set -euo pipefail

# Usage: ./trigger-rollback.sh <app-name> [project] [revision]
# Example: ./trigger-rollback.sh coffee-cup-dev default 123abc

# --- Configuration ---
GITHUB_OWNER="labotomy-dot-dev"          # e.g. my-org
GITHUB_REPO="coffee-cup"                  # e.g. platform-rollbacks
GITHUB_TOKEN="${GITHUB_TOKEN:-}"         # Can be set via environment
EVENT_TYPE="argocd-sync-failed"

# --- Input Arguments ---
APP_NAME="${1:-}"
PROJECT="${2:-default}"
REVISION="${3:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"

if [[ -z "$APP_NAME" ]]; then
  echo "❌ Usage: $0 <app-name> [project] [revision]"
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ Please export GITHUB_TOKEN=<your_token> before running."
  exit 1
fi

# --- Prepare Payload ---
read -r -d '' PAYLOAD <<EOF
{
  "event_type": "$EVENT_TYPE",
  "client_payload": {
    "app": "$APP_NAME",
    "project": "$PROJECT",
    "revision": "$REVISION"
  }
}
EOF

# --- Send Dispatch Event ---
echo "📤 Triggering rollback for app: $APP_NAME"
echo "📦 Sending repository_dispatch to $GITHUB_OWNER/$GITHUB_REPO ..."
echo "Payload:"
echo "$PAYLOAD" | jq .

RESPONSE=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
  -X POST "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "$PAYLOAD")

if [[ "$RESPONSE" == "204" ]]; then
  echo "✅ Rollback event successfully sent!"
else
  echo "❌ Failed to trigger rollback. HTTP status: $RESPONSE"
  echo "Response:"
  cat /tmp/resp.json
  exit 1
fi
