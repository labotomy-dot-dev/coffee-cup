#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${GITHUB_EVENT_CLIENT_PAYLOAD_APP:-unknown}"
REVISION="${GITHUB_EVENT_CLIENT_PAYLOAD_REVISION:-unknown}"

ARGOCD_SERVER="argocd.labotomy.dev"
ARGOCD_AUTH_TOKEN="${ARGOCD_AUTH_TOKEN:?ARGOCD_AUTH_TOKEN is required}"

echo "⚠️  Argo CD sync failed for app '$APP_NAME' (revision $REVISION)"
echo "🔁 Triggering rollback to previous healthy revision..."

# Roll back to the last healthy version
argocd app rollback "$APP_NAME" 1 \
  --server "$ARGOCD_SERVER" \
  --auth-token "$ARGOCD_AUTH_TOKEN" \
  --grpc-web

echo "✅ Rollback completed for $APP_NAME."
