#!/usr/bin/env bash
set -euo pipefail

# Update AbilityERP Worker API on EC2 after a new release.
# Usage: bash /opt/ability-erp-pwa/scripts/ec2-update.sh [tag-or-branch]

APP_DIR="/opt/ability-erp-pwa"
REF="${1:-main}"

echo "==> Updating AbilityERP API in ${APP_DIR} to ${REF}"

cd "${APP_DIR}"
git fetch origin --tags
git checkout "${REF}"
git pull origin "${REF}" 2>/dev/null || true

cd api
npm ci
npm run build

pm2 reload ability-erp-api

echo "==> Health check"
curl -sf "http://127.0.0.1:3001/api/health" | python3 -m json.tool || curl -sf "http://127.0.0.1:3001/api/health"
echo ""
echo "Update complete (ref: ${REF})"
