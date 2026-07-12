# AbilityERP Mobile Worker App

Standalone mobile-first PWA for AbilityERP support workers. **New codebase** — same worker UX/function as AbilityVua, powered by iDempiere PostgreSQL via a dedicated Express API on each EC2 instance.

**Not a fork of AbilityVua.** Reusable across dev/test and client production installs.

## Work tracking (SAW### tickets)

Every workstream gets a ticket ID: `SAW###_<short_snake_function>` (example: `SAW001_paid_filter_invoice_send_info`).

| Where | Link |
|-------|------|
| **Registry** | [`docs/TICKETS.md`](docs/TICKETS.md) |
| **GitHub Issues** | [Issues labeled `ticket`](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues?q=label%3Aticket) |
| **Open / in progress** | [Issues with `in-progress`](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues?q=label%3Ain-progress+is%3Aopen) |
| **Rules** | [`.cursor/rules/ticket-ids.mdc`](.cursor/rules/ticket-ids.mdc) |

Commits and Downloads packs should include the `SAW###` id. Next free ID is listed at the bottom of `docs/TICKETS.md`.

## Repository structure

```
├── web/          Next.js 16 PWA (AWS Amplify)
├── api/          Express API (EC2, port 3001)
├── scripts/      EC2 install & update scripts
├── deploy/       Per-environment .env templates
├── docs/         Worker guide, tickets (TICKETS.md), push notifications
├── .cursor/rules/ Project agent rules (tickets, client update loop)
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

### PWA icons (from org logo)

Icons are generated from the iDempiere org logo (`AD_SysConfig` → `ZK_LOGO_SMALL`). Regenerate after a logo change:

```bash
cd web && npm install -D sharp
ORG_LOGO_URL="https://your-org-logo.png" node ../scripts/generate-pwa-icons.js
```

Default source: AbilityERP compact logo on S3 (same as iDempiere web UI).

### PWA

```bash
cd web
cp .env.example .env.local       # edit API_BASE_URL
npm install
npm run dev                      # http://localhost:3000
```

### Amplify environment variables (required)

Set these in the Amplify console for the `web` app:

| Variable | Example |
|----------|---------|
| `API_BASE_URL` | `https://ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com` |
| `NEXT_PUBLIC_APP_URL` | `https://main.d2pmnegzhwkj4b.amplifyapp.com` |

Also confirm in Amplify **Build settings**:
- Monorepo app root: `web`
- Platform: **Web Compute** (SSR — required for Next.js App Router)
- Build spec: repo root `amplify.yml` (includes `platform: WEB_COMPUTE`)

## EC2 install (existing iDempiere server)

**iDempiere AD changes:** see [`docs/DEV-REQUIREMENTS.md`](docs/DEV-REQUIREMENTS.md) — all new processes and buttons require `AD_Process_Access` for **AbilityERP Admin** (and relevant operational roles).

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
4. Set `API_BASE_URL` to your EC2 API host (e.g. `http://ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com`) — **no** `/api` suffix

## Auth

- **Primary:** Microsoft Entra ID SSO (`AZURE_*` env vars on Amplify)
- **Fallback:** AD_User username/password via EC2 API
- **Gate:** User must have **Support Worker** role in iDempiere

## Multi-client rollout

Same repo and scripts for every AbilityERP instance. Only `.env` (EC2) and Amplify env vars change per client.

## GitHub

https://github.com/AdamSawtell/AbilityERP_Mobile_APP

## Documentation

| Doc | Audience |
|-----|----------|
| [docs/WORKER-GUIDE.md](./docs/WORKER-GUIDE.md) | Support workers — install, sign in, use each screen |
| [docs/PUSH-NOTIFICATIONS.md](./docs/PUSH-NOTIFICATIONS.md) | Dev team — push notification roadmap (not built yet) |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Technical architecture |
