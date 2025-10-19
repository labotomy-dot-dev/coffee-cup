#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./trigger-promote.sh <app-name>
# Example:
#   ./trigger-promote.sh coffee-cup-dev

# --- Configuration ---
GITHUB_OWNER="labotomy-dot-dev"
GITHUB_REPO="coffee-cup"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
EVENT_TYPE="argocd-sync-succeeded"

# --- Input Arguments ---
APP_NAME="${1:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "❌ Usage: $0 <app-name>"
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ Please export GITHUB_TOKEN=<your_token> before running."
  exit 1
fi

# --- Prepare Payload ---
PAYLOAD=$(cat <<EOF
{
  "event_type": "$EVENT_TYPE",
  "client_payload": {
    "app": "$APP_NAME"
  }
}
EOF
)

# --- Send Dispatch Event ---
echo "🚀 Triggering test ArgoCD sync event for app: $APP_NAME"
echo "📦 Repository: $GITHUB_OWNER/$GITHUB_REPO"
echo "📤 Sending repository_dispatch event..."
echo "$PAYLOAD" | jq .

RESPONSE=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
  -X POST "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "$PAYLOAD")

if [[ "$RESPONSE" == "204" ]]; then
  echo "✅ Test ArgoCD sync event triggered successfully!"
else
  echo "❌ Failed to trigger event. HTTP status: $RESPONSE"
  echo "Response:"
  cat /tmp/resp.json
  exit 1
fi
