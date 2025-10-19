#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./trigger-event.sh <app-name> [project-name] [event-type]
# Examples:
#   ./trigger-event.sh coffee-cup-dev dev argocd-sync-succeeded
#   ./trigger-event.sh coffee-cup-prod prod argocd-sync-failed

# --- Configuration ---
GITHUB_OWNER="labotomy-dot-dev"
GITHUB_REPO="coffee-cup"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# --- Input Arguments ---
APP_NAME="${1:-}"
PROJECT_NAME="${2:-dev}"
EVENT_TYPE="${3:-argocd-sync-succeeded}"

# --- Validations ---
if [[ -z "$APP_NAME" ]]; then
  echo "❌ Usage: $0 <app-name> [project-name] [event-type]"
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
    "app": "$APP_NAME",
    "project": "$PROJECT_NAME"
  }
}
EOF
)

# --- Send Dispatch Event ---
echo "🚀 Triggering GitHub event..."
echo "📦 Repository: $GITHUB_OWNER/$GITHUB_REPO"
echo "📤 Event type: $EVENT_TYPE"
echo "📱 App: $APP_NAME"
echo "🧱 Project: $PROJECT_NAME"
echo "$PAYLOAD" | jq .

RESPONSE=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
  -X POST "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "$PAYLOAD")

if [[ "$RESPONSE" == "204" ]]; then
  echo "✅ Event '$EVENT_TYPE' triggered successfully for app '$APP_NAME' (project: $PROJECT_NAME)!"
else
  echo "❌ Failed to trigger event. HTTP status: $RESPONSE"
  echo "Response:"
  cat /tmp/resp.json
  exit 1
fi
