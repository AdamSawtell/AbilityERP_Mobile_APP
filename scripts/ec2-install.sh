#!/usr/bin/env bash
set -euo pipefail

# First-time install of AbilityERP Worker API on an existing iDempiere EC2 instance.
# Usage (on EC2):
#   curl -fsSL .../ec2-install.sh | bash -s -- --repo https://github.com/AdamSawtell/AbilityERP_Mobile_APP.git
#
# Or after cloning locally:
#   sudo bash scripts/ec2-install.sh

APP_DIR="/opt/ability-erp-pwa"
REPO_URL="https://github.com/AdamSawtell/AbilityERP_Mobile_APP.git"
BRANCH="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --dir) APP_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "==> AbilityERP API install to ${APP_DIR}"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found. Install Node.js 20+ first (e.g. via NodeSource or nvm)."
  exit 1
fi

if ! command -v pm2 >/dev/null 2>&1; then
  echo "Installing PM2..."
  npm install -g pm2
fi

sudo mkdir -p "${APP_DIR}"
sudo chown -R "${USER}:${USER}" "${APP_DIR}"

if [[ ! -d "${APP_DIR}/.git" ]]; then
  git clone --branch "${BRANCH}" "${REPO_URL}" "${APP_DIR}"
else
  git -C "${APP_DIR}" fetch origin
  git -C "${APP_DIR}" checkout "${BRANCH}"
  git -C "${APP_DIR}" pull origin "${BRANCH}"
fi

cd "${APP_DIR}/api"

if [[ ! -f "${APP_DIR}/.env" ]]; then
  echo "Creating ${APP_DIR}/.env from template — EDIT BEFORE STARTING IN PRODUCTION"
  cp "${APP_DIR}/scripts/env.example" "${APP_DIR}/.env"
fi
ln -sf "${APP_DIR}/.env" "${APP_DIR}/api/.env"

npm ci
npm run build

pm2 startOrReload ecosystem.config.js
pm2 save

echo ""
echo "Install complete."
echo "1. Edit ${APP_DIR}/.env (DATABASE_URL, JWT_SECRET, CORS_ORIGIN)"
echo "2. Add nginx snippet: ${APP_DIR}/scripts/nginx-api.conf"
echo "3. Reload nginx: sudo nginx -t && sudo systemctl reload nginx"
echo "4. Health check: curl -s http://127.0.0.1:3001/api/health"
