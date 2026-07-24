#!/usr/bin/env bash
set -euo pipefail

# Update AbilityERP Worker API on EC2 after a new release.
# Usage: bash /opt/ability-erp-pwa/scripts/ec2-update.sh [tag-or-branch]
# Local uncommitted changes are stashed so deploy always matches origin.

APP_DIR="/opt/ability-erp-pwa"
REF="${1:-main}"

echo "==> Updating AbilityERP API in ${APP_DIR} to ${REF}"

cd "${APP_DIR}"
git fetch origin --tags
if [[ -n "$(git status --porcelain)" ]]; then
  echo "==> Stashing local changes before deploy"
  git stash push -u -m "ec2-update auto-stash $(date -u +%Y%m%dT%H%M%SZ)" || true
fi
git checkout "${REF}"
git reset --hard "origin/${REF}"

cd api
npm ci
npm run build

pm2 reload ability-erp-api --update-env

echo "==> Health check"
curl -sf "http://127.0.0.1:3001/api/health" | python3 -m json.tool || curl -sf "http://127.0.0.1:3001/api/health"
echo ""
echo "Update complete (ref: ${REF} @ $(git -C "${APP_DIR}" rev-parse --short HEAD))"
