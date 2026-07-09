# AbilityERP Mobile Worker App

Standalone mobile-first PWA for AbilityERP support workers. **New codebase** — same worker UX/function as AbilityVua, powered by iDempiere PostgreSQL via a dedicated Express API on each EC2 instance.

**Not a fork of AbilityVua.** Reusable across dev/test and client production installs.

## Repository structure

```
├── web/          Next.js 16 PWA (AWS Amplify)
├── api/          Express API (EC2, port 3001)
├── scripts/      EC2 install & update scripts
├── deploy/       Per-environment .env templates
└── ARCHITECTURE.md
```

## Worker features (Phase 1 scope)

1. Available shifts
2. Apply for a shift
3. My schedule
4. Master & current roster (read-only)
5. Digital worker ID
6. Leave & availability
7. Credentials (read-only)
8. Profile

## Local development

### API

```bash
cd api
cp ../scripts/env.example .env   # edit DATABASE_URL, JWT_SECRET
npm install
npm run dev                      # http://localhost:3001
```

Health check: `GET http://localhost:3001/api/health`

### PWA

```bash
cd web
cp .env.example .env.local       # edit API_BASE_URL
npm install
npm run dev                      # http://localhost:3000
```

## EC2 install (existing iDempiere server)

1. Copy `deploy/dev030.env.example` → `/opt/ability-erp-pwa/.env` and fill in values
2. Run `scripts/ec2-install.sh`
3. Add `scripts/nginx-api.conf` to nginx and reload
4. Confirm: `curl https://YOUR-HOST/api/health`

### Updates

```bash
bash /opt/ability-erp-pwa/scripts/ec2-update.sh main
# or: bash scripts/ec2-update.sh v0.2.0
```

## AWS Amplify (PWA)

1. Connect this GitHub repo in Amplify
2. Set **app root** to `web`
3. Add environment variables from `web/.env.example`
4. Set `API_BASE_URL` to your EC2 host (e.g. `https://development030.abilityerp.com.au`) — **no** `/api` suffix

## Auth

- **Primary:** Microsoft Entra ID SSO (`AZURE_*` env vars on Amplify)
- **Fallback:** AD_User username/password via EC2 API
- **Gate:** User must have **Support Worker** role in iDempiere

## Multi-client rollout

Same repo and scripts for every AbilityERP instance. Only `.env` (EC2) and Amplify env vars change per client.

## GitHub

https://github.com/AdamSawtell/AbilityERP_Mobile_APP
