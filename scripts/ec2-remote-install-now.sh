#!/usr/bin/env bash
set -euo pipefail

echo "==> Install Node.js 20 if missing"
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
node --version
npm --version

echo "==> Install PM2 if missing"
if ! command -v pm2 >/dev/null 2>&1; then
  sudo npm install -g pm2
fi
pm2 --version

echo "==> Clone or update repo"
APP_DIR=/opt/ability-erp-pwa
if [ ! -d "$APP_DIR/.git" ]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown -R ubuntu:ubuntu "$APP_DIR"
  git clone https://github.com/AdamSawtell/AbilityERP_Mobile_APP.git "$APP_DIR"
else
  git -C "$APP_DIR" fetch origin
  git -C "$APP_DIR" checkout main
  git -C "$APP_DIR" pull origin main
fi

echo "==> Write .env"
JWT_SECRET=$(openssl rand -hex 32)
cat > "$APP_DIR/.env" << EOF
PORT=3001
NODE_ENV=production
APP_VERSION=0.1.0
DATABASE_URL=postgresql://adempiere:flamingo@127.0.0.1:5432/idempiere
JWT_SECRET=${JWT_SECRET}
CORS_ORIGIN=http://localhost:3000,https://development030.abilityerp.com.au
EOF
chmod 600 "$APP_DIR/.env"
ln -sf "$APP_DIR/.env" "$APP_DIR/api/.env"

echo "==> Build API"
cd "$APP_DIR/api"
npm ci
npm run build

echo "==> Start with PM2"
pm2 startOrReload "$APP_DIR/api/ecosystem.config.js"
pm2 save
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u ubuntu --hp /home/ubuntu | tail -1 | bash || true

echo "==> Health check (local)"
curl -sf http://127.0.0.1:3001/api/health
echo ""

echo "==> Configure Apache /api proxy"
APACHE_CONF=/etc/apache2/sites-enabled/000-webui.conf
if ! grep -q "ProxyPass /api/" "$APACHE_CONF"; then
  sudo cp "$APACHE_CONF" "${APACHE_CONF}.bak.abilityerp"
  sudo sed -i '/ProxyPass \/ http:\/\/0.0.0.0:8080\//i\    ProxyPass /api/ http://127.0.0.1:3001/api/\n    ProxyPassReverse /api/ http://127.0.0.1:3001/api/' "$APACHE_CONF"
  sudo apache2ctl configtest
  sudo systemctl reload apache2
fi

echo "==> Health check (apache port 80)"
curl -sf http://127.0.0.1/api/health || echo apache-proxy-check-failed

echo "INSTALL_DONE"
