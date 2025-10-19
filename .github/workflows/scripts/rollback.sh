#!/bin/bash
echo "Smoke tests failed for production deployment of app $APP_BASE."
echo "Initiating rollback procedure..."
PROD_MANIFEST="products/$APP_BASE/deploy/prod/deploy.yaml"

if [ ! -f "$PROD_MANIFEST" ]; then
  echo "❌ Manifest not found at $PROD_MANIFEST"
  exit 1
fi

# Extract current prod image
CURRENT_IMAGE=$(yq e -r '.spec.template.spec.containers[0].image' "$PROD_MANIFEST")
echo "Current prod image: $CURRENT_IMAGE"

# Extract numeric version (assumes tag like prod-28)
VERSION_NUMBER=$(echo "$CURRENT_IMAGE" | sed -E 's/.*:prod-([0-9]+)$/\1/')
if [[ -z "$VERSION_NUMBER" ]]; then
  echo "⚠️ Could not parse version from current image. Skipping rollback."
  exit 1
fi

# Compute previous version
PREV_VERSION=$((VERSION_NUMBER - 1))
if (( PREV_VERSION < 0 )); then
  echo "⚠️ No previous version exists. Skipping rollback."
  exit 0
fi

# Build previous image name
IMAGE_PREFIX="${CURRENT_IMAGE%%:*}"
PREV_IMAGE="${IMAGE_PREFIX}:prod-$PREV_VERSION"
echo "Rolling back to image: $PREV_IMAGE"

# Update prod manifest
yq e -i ".spec.template.spec.containers[0].image = \"$PREV_IMAGE\"" "$PROD_MANIFEST"

# Commit and push changes
git config user.name "github-actions"
git config user.email "actions@github.com"
git add "$PROD_MANIFEST"
git commit -m "Rollback $APP_BASE to previous version $PREV_IMAGE [skip ci]" || echo "No changes to commit"
git push

echo "✅ Rollback applied successfully"