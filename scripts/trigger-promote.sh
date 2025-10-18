#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./trigger-promote.sh <app-name> <image> [project] [revision]
# Example:
#   ./trigger-promote.sh coffee-cup-dev ghcr.io/labotomy-dot-dev/coffee-cup-coffee-cup:dev-210 default f1c9a3b

# --- Configuration ---
GITHUB_OWNER="labotomy-dot-dev"          # e.g. my-org
GITHUB_REPO="coffee-cup"                  # e.g. platform-rollbacks
GITHUB_TOKEN="${GITHUB_TOKEN:-}"         # export before use
EVENT_TYPE="argocd-sync-succeeded"

# --- Input Arguments ---
APP_NAME="${1:-}"
IMAGE="${2:-}"
PROJECT="${3:-default}"
REVISION="${4:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"

if [[ -z "$APP_NAME" || -z "$IMAGE" ]]; then
  echo "❌ Usage: $0 <app-name> <image> [project] [revision]"
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
    "revision": "$REVISION",
    "images": ["$IMAGE"]
  }
}
EOF

# --- Send Dispatch Event ---
echo "🚀 Triggering promotion workflow for app: $APP_NAME"
echo "📦 Image: $IMAGE"
echo "📦 Repository: $GITHUB_OWNER/$GITHUB_REPO"
echo "📤 Sending repository_dispatch event..."
echo "$PAYLOAD" | jq .

RESPONSE=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
  -X POST "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/dispatches" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "$PAYLOAD")

if [[ "$RESPONSE" == "204" ]]; then
  echo "✅ Promotion workflow triggered successfully!"
else
  echo "❌ Failed to trigger workflow. HTTP status: $RESPONSE"
  echo "Response:"
  cat /tmp/resp.json
  exit 1
fi
