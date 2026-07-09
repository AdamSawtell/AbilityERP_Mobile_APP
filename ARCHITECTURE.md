# AbilityERP PWA — Architecture & Scope

## Overview

A **new, standalone** mobile-first PWA matching the **AbilityVua** app's UX, screens, and hosting model — but powered by **AbilityERP** (iDempiere on EC2 + PostgreSQL) instead of Supabase. Completely separate codebase — no fork, no shared code with AbilityVua.

| Dimension | AbilityVua | AbilityERP PWA |
|-----------|-----------|----------------|
| Frontend | Next.js 16 + Tailwind CSS | **Same stack, new codebase** |
| PWA | Service worker + manifest | **Same** |
| Hosting | AWS Amplify | **Same** (new Amplify app, new repo) |
| Database | Supabase PostgreSQL (managed) | iDempiere PostgreSQL (EC2) |
| Auth | Supabase Auth + WebAuthn + MS SSO | **SSO-first** (Azure AD / Microsoft Entra ID) + AD_User fallback |
| Data layer | Supabase SDK → client | API proxy on EC2 → PostgreSQL |
| Deployment | `git push origin master` | **Same** (new repo) |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   End User (Mobile Browser)           │
│              PWA installed to home screen             │
└──────────────────────────┬──────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────┐
│               AWS Amplify (hosts Next.js PWA)          │
│                                                       │
│  Next.js 16 App Router + TypeScript + Tailwind CSS    │
│  ┌───────────────────────────────────────────────┐   │
│  │  App Shell (same UX as AbilityVua)             │   │
│  │  - Sidebar navigation (same modules)           │   │
│  │  - SSO: Microsoft Entra ID (OAuth2/OIDC)      │   │
│  │  - Password fallback → EC2 API                 │   │
│  │  - Data: fetch() → EC2 API (no Supabase)       │   │
│  │  - PWA: service worker, manifest, push          │   │
│  └───────────────────────────────────────────────┘   │
│     │                                                  │
│     │  Next.js API routes (BFF layer)                 │
│     │  - /api/auth/ms-callback  (SSO redirect)        │
│     │  - /api/auth/login       (password fallback)    │
│     │  - /api/auth/me          (session check)        │
│     └──────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────┘
                           │ HTTPS (CORS-whitelisted or internal)
                           ▼
┌─────────────────────────────────────────────────────┐
│              EC2 — iDempiere Server                    │
│───────────────────────────────────────────────────────│
│  ┌───────────────────────────────────────────────┐   │
│  │  API Proxy Server (Node.js/Express)            │   │
│  │  Port: 3001 (behind nginx on 443)              │   │
│  │                                                │   │
│  │  - Auth:                                       │   │
│  │    POST /api/auth/login       (AD_User pw)     │   │
│  │    POST /api/auth/sso         (verify SSO JWT) │   │
│  │    GET  /api/auth/ad-user     (find AD_User by │   │
│  │          email/UPN for SSO mapping)            │   │
│  │                                                │   │
│  │  - Module endpoints (one per module):          │   │
│  │    GET/POST/PUT /api/clients/*                 │   │
│  │    GET/POST/PUT /api/enquiries/*               │   │
│  │    GET/POST/PUT /api/products/*                │   │
│  │    GET/POST/PUT /api/rostering/*               │   │
│  │    GET/POST/PUT /api/timesheets/*              │   │
│  │    GET/POST/PUT /api/invoices/*                │   │
│  │    ... (one per AbilityVua module)             │   │
│  │                                                │   │
│  │  - JWT middleware on all endpoints             │   │
│  │  - Connection pool to PostgreSQL (read-write)  │   │
│  │  - CORS: Amplify domain only                   │   │
│  └─────────────────┬─────────────────────────────┘   │
│                    │ localhost:5432                   │
│  ┌─────────────────▼─────────────────────────────┐   │
│  │  PostgreSQL (database: idempiere)              │   │
│  │  schema: adempiere (1,078 tables)              │   │
│  │                                                │   │
│  │  - AD_User (auth + roles)                      │   │
│  │  - AD_Client (tenant isolation)                │   │
│  │  - C_BPartner (clients, business partners)     │   │
│  │  - M_Product (products, price lists)           │   │
│  │  - C_Order (service bookings, NDIS-customised) │   │
│  │  - C_Invoice / C_InvoiceLine (invoicing)       │   │
│  │  - 130x aberp_* tables (NDIS-specific)         │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Why this approach

1. **Zero iDempiere plugin dev** — No Java, no OSGi. The API server talks directly to PostgreSQL alongside iDempiere.
2. **Same EC2** — ~1ms DB latency, no network hops, no data egress costs.
3. **Same stack as frontend** — Express.js + TypeScript. Same devs, same IDE, same patterns.
4. **Incremental** — Start with Auth + one module (e.g. Clients), validate, then expand.
5. **No Supabase dependency** — Auth, data, everything comes from your ERP.
6. **Full separation from AbilityVua** — standalone repo, independent deploy.

**iDempiere plugin / AD work:** follow [`docs/DEV-REQUIREMENTS.md`](docs/DEV-REQUIREMENTS.md) (process access to Admin role, deploy checklist, cache refresh).

---

## Auth Model — SSO-First

### Primary: Microsoft Entra ID (Azure AD) SSO

The PWA uses **OAuth2 / OpenID Connect** with Microsoft Entra ID as the primary authentication method. This is the most common identity provider for Australian NDIS providers.

**Login flow:**
1. User clicks **"Sign in with Microsoft"** on the login screen.
2. PWA redirects to Microsoft Entra ID's `/authorize` endpoint.
3. User authenticates with their organisation Microsoft account.
4. Microsoft redirects back to the PWA's callback URL (Next.js API route `/api/auth/ms-callback`).
5. PWA exchanges the auth code for an ID token + access token via the BFF (Backend-for-Frontend) on the Next.js API route.
6. BFF extracts the user's email / UPN from the ID token.
7. BFF calls the EC2 API to find the matching `AD_User` record by email.
8. If found: EC2 API returns a signed **application JWT** with `{ AD_User_ID, AD_Client_ID, Name, C_BPartner_ID, Roles[] }`.
9. If not found: the user is prompted to link their Microsoft account to an ERP user, or access is denied.
10. Application JWT is stored in an `httpOnly` session cookie (set by the BFF).
11. All subsequent API calls carry the JWT via `Authorization: Bearer <token>`.

**Flow diagram:**
```
Browser                  Amplify (Next.js)              EC2 API              Microsoft
  │                              │                        │                    │
  │  ── "Sign in with MS" ──▶   │                        │                    │
  │                             │  ── authorize redirect ──────────────────▶   │
  │  ◀── redirect to MS ────   │                        │                    │
  │  ── auth code ─────────▶   │                        │                    │
  │                             │  ── code for tokens ───────────────────▶   │
  │                             │  ◀── ID token ──────────────────────────   │
  │                             │                        │                    │
  │                             │  ── find AD_User by email ──▶              │
  │                             │  ◀── JWT issued ────────                   │
  │  ◀── session cookie + redirect ──                      │                    │
  │  ── API calls (JWT) ─────▶   │  ── proxy with JWT ──▶  │                    │
```

### Backup: Password login (AD_User)

For users who don't have Microsoft accounts (e.g. external workers, agency staff):

1. User enters username + password in the PWA login form.
2. PWA calls `POST /api/auth/login` on the EC2 API directly.
3. API validates against `AD_User.password` (plaintext comparison).
4. On success: returns signed JWT.
5. Password stored in `httpOnly` session cookie via Next.js BFF.

### iDempiere password handling
- **Passwords are stored in plaintext** in `AD_User.password` (confirmed — samples show plain values like "flamingo", no hashing)
- Direct comparison works for the fallback path
- **Security note:** Add bcrypt hashing in the API layer for password-based logins. The DB stays plaintext for iDempiere compatibility; the API hashes on write and compares hash on login.

### Roles / permissions
- `AD_User_Roles` maps to PWA capabilities
- Each API endpoint checks the JWT's role claims
- Roles discovered: Support Worker, Support Manager, Rostering Officer, Employee Mobile, Finance Admin, Financial Controller, Quality Coordinator, System Administrator, etc.

---

## Module Mapping (AbilityVua → iDempiere Tables)

**DB credentials:** `pg://adempiere:flamingo@127.0.0.1:5432/idempiere` on EC2 (schema: `adempiere`)
**Clients:** System(ID=0), GardenWorld(ID=11), AbilityERP(ID=1000002)
**Auth:** SSO via Microsoft Entra ID (primary) + AD_User password fallback
**Custom schema:** 130 `aberp_*` tables for NDIS-specific functionality

| AbilityVua Module | iDempiere Table(s) | Key Columns | Type |
|-------------------|-------------------|-------------|------|
| **Login / Auth** | `AD_User` | `ad_user_id`, `password` (plaintext), `name`, `email`, `c_bpartner_id`, `islocked`, `isactive` | Core |
| **User Roles** | `AD_User_Roles` + `AD_Role` | `ad_user_id`, `ad_role_id` → `ad_role.name` | Core |
| **Clients (Support Receivers)** | `C_BPartner` (116 cols) | `c_bpartner_id`, `name`, `value`, `aberp_first_name`, `aberp_last_name`, `aberp_preferred_name`, `aberp_gender_id`, `aberp_disability_id`, `aberp_ndis_region`, `aberp_funding_body_id`, `aberp_living_arrangement`, `aberp_date_commencement`, `aberp_date_support_ceased`, `birthday`, `phone`, `email`, `aberp_is_support_receiver`, `aberp_is_estimated`, `aberp_age`, `taxid` | Custom |
| **Client Locations** | `C_BPartner_Location` + `C_Location` | `c_bpartner_id`, `c_location_id` → `address1`, `city`, `postal`, `aberp_ishomeaddress`, `aberp_issupportaddress` | Standard |
| **Support Plans** | `aberp_supportplans` (108 cols) | `aberp_supportplans_id`, `c_bpartner_id`, `name`, `value`, `aberp_plans_assessment_id`, `aberp_finarr_id`, `aberp_language_id`, `aberp_diet_id`, `aberp_allergies_id`, `aberp_medical_conditions_id`, `aberp_communications_id` | **Custom** |
| **Client Support Budgets** | `aberp_clientsp` + `aberp_clientspbudget` | `c_bpartner_id`, `aberp_clientpaymenttype_id`, `value`, `c_currency_id` | **Custom** |
| **Client SP Transactions** | `aberp_clientsptrx` | Client budget transactions | **Custom** |
| **Enquiries** | `aberp_enquiry` (50 cols) | `aberp_enquiry_id`, `documentno`, `c_location_id`, `aberp_enquirysource_id`, `aberp_disability_id`, `aberp_funding_body_id`, `aberp_gender_id`, `aberp_services_id`, `r_status_id`, `processed` | **Custom** |
| **Service Agreements** | `aberp_service_agreement` (12 cols) | `aberp_service_agreement_id`, `name`, `value`, `description` | **Custom** |
| **Service Bookings** | `C_Order` (heavily customised) | `c_order_id`, `documentno`, `c_bpartner_id`, `c_doctype_id`, `docstatus`, `grandtotal`, `aberp_shift_type_id`, `aberp_startdate`, `aberp_enddate`, `aberp_max_support_receivers`, `aberp_vehicle_id`, `aberp_masterlocation_id`, `aberp_service_opportunity_id`, `aberp_bookinggenerator_id` | **Custom hybrid** |
| **Products / Services** | `M_Product` | `m_product_id`, `name`, `value`, `description`, `producttype`, `classification`, `c_uom_id`, `aberp_time_of_day_id` | Standard + Custom |
| **Price Lists** | `M_PriceList` → `M_PriceList_Version` → `M_ProductPrice` | `m_pricelist_id`, `name`, `m_product_id`, `pricelist`, `pricestd`, `priceprecision`, `c_currency_id` | Standard |
| **Rostering** | `aberp_rostered_shift` (61 cols) | `aberp_rostered_shift_id`, `documentno`, `aberp_shift_type_id`, `aberp_masterlocation_id`, `aberp_vehicle_id`, `aberp_time_of_day_id`, `r_status_id` | **Custom** |
| **Roster Staff** | `aberp_rostered_shiftstaff` (44 cols) | `aberp_rostered_shift_id`, `c_bpartner_staff_id`, `m_product_id`, `m_pricelist_id`, `aberp_timesheetandexpenses_id`, `aberp_user_contact_id` | **Custom** |
| **Roster Receivers** | `aberp_rostered_shiftreceiver` (27 cols) | Client linked to roster | **Custom** |
| **Timesheets** | `aberp_timesheetandexpenses` (65 cols) | `aberp_timesheetandexpenses_id`, `documentno`, `c_bpartner_staff_id`, `aberp_rostered_shift_id`, `docstatus`, `processed`, `c_doctype_id`, `aberp_pr_period_id` | **Custom** |
| **Invoices** | `C_Invoice` + `C_InvoiceLine` | `c_invoice_id`, `documentno`, `c_bpartner_id`, `dateinvoiced`, `grandtotal`, `docstatus`, `c_order_id`, `aberp_supportreceiver_id`, `aberp_ndis_region`, `aberp_vehicle_id`, `aberp_masterlocation_id`, `issotrx` | Standard + Custom |
| **Claims** | `aberp_claim_type` (ref) + | Claim types linked to products/services | **Custom** |
| **Service Track** | `aberp_servicetrack` (91 cols) | `aberp_servicetrack_id`, `documentno`, `docstatus`, `c_bpartner_id`, `c_doctype_id`, `c_charge_id`, `c_payment_id`, `c_currency_id` | **Custom** |
| **Business Partners** | `C_BPartner` (filter by type) | `isvendor`, `iscustomer`, `isemployee`, `c_bp_group_id` | Standard |
| **Employees** | `C_BPartner` (where `isemployee='Y'`) + `HR_Employee` + `AD_User` | `c_bpartner_id`, `ad_user_id`, `aberp_employee_contract_id`, `aberp_classification_id` | Standard + Custom |
| **Employee Contracts** | `aberp_employee_contract` (27 cols) | `aberp_employee_contract_id`, `c_bpartner_id`, `value`, `aberp_user_contact_id`, `aberp_classification_id`, `aberp_timesheet_rules_id` | **Custom** |
| **Employee Pay / Remuneration** | `aberp_remuneration` + `aberp_remunerationline` | `aberp_remuneration_id`, `c_uom_id`, `aberp_externalid` | **Custom** |
| **Locations** | `C_Location` (+ `aberp_masterlocation`) | Addresses, service delivery sites | Standard + Custom |
| **Fleet / Vehicles** | `aberp_vehicle` (42 cols) | `aberp_vehicle_id`, `name`, `value`, `aberp_vehicle_body_id`, `aberp_driver_id`, `aberp_masterlocation_id`, `aberp_insurer_id` | **Custom** |
| **Vehicle Usage** | `aberp_vehicleusagerecord` + `aberp_vehicleusagereceiver` | KM tracking, linked to shifts | **Custom** |
| **Incidents** | `aberp_incident` (64 cols) | `aberp_incident_id`, `documentno`, `c_bpartner_id`, `c_bpartner_staff_id`, `c_bpartner_staff2_id`, `aberp_incident_status_id`, `aberp_masterlocation_id`, `ad_user_id`, `ad_role_id`, `processed` | **Custom** |
| **Complaints** | `R_Request` + `aberp_request_category_link` + `aberp_requesttype_role` | Standard iDempiere requests + custom categories | Custom hybrid |
| **Contracts** | `aberp_contract` (22 cols) | `aberp_contract_id`, `c_bpartner_id`, `aberp_contracttype_id`, `aberp_masterlocation_id`, `aberp_vehicle_id` | **Custom** |
| **Credentials** | `aberp_credentials` + `aberp_credentialassignment` | `aberp_credentials_id`, `name`, `value`, `aberp_credentialstype_id`, `aberp_credentialscategory_id` | **Custom** |
| **Booking Generator** | `aberp_bookinggenerator` (46 cols) | `aberp_bookinggenerator_id`, `c_bpartner_id`, `m_pricelist_id`, `aberp_masterlocation_id`, `aberp_vehicle_id`, `aberp_service_opportunity_id`, `c_doctypetarget_id` | **Custom** |
| **Service Patterns** | `aberp_servicepattern` (35 cols) + `aberp_bookinggenerator` | Recurring service templates | **Custom** |
| **Roster Templates** | `aberp_rostered_shifttemplate` + `aberp_rostered_shifttemplateline` | Recurring roster patterns | **Custom** |
| **System Config** | `AD_SysConfig` | Key-value config store | Core |
| **NDIS Reference** | `aberp_ndis_cat`, `aberp_ndis_region`, `aberp_disability`, `aberp_gender`, `aberp_language` | NDIS lookups | **Custom** |
| **Reports** | Aggregate queries on all above | Dashboard views | Build |

**Key relationships:**
- `C_BPartner` — central entity. Clients, employees, business partners all typed by flags
- `AD_User` → `C_BPartner` via `c_bpartner_id`
- `C_Order` = service bookings (heavy NDIS customisation)
- `aberp_rostered_shift` → `aberp_rostered_shiftstaff` (staff) + `aberp_rostered_shiftreceiver` (clients)
- `aberp_timesheetandexpenses` links to `aberp_rostered_shift` + `c_bpartner_staff_id`

---

## Technology Stack

### PWA (Frontend — new repo, deployed on Amplify)
| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Next.js 16 App Router | Same modern stack as AbilityVua |
| Language | TypeScript | Type safety |
| Styling | Tailwind CSS v4 | Same as AbilityVua |
| SSO | `next-auth` or `msal` for Microsoft Entra ID | OIDC/OAuth2 — standard for enterprise |
| HTTP client | Native `fetch()` + thin wrapper | No heavy client lib needed |
| Auth session | `httpOnly` cookie (set by Next.js BFF) | Secure, XSS-proof |
| PWA | `next-pwa` or manual `sw.js` | Proven pattern |
| Hosting | AWS Amplify | Same as AbilityVua |

### API Server (on EC2)
| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Express.js (TypeScript) | Same lang as frontend, familiar team |
| ORM | `node-postgres` (pg) + raw SQL | iDempiere schema needs direct SQL control |
| Auth | `jsonwebtoken` + `jose` (for SSO JWT verification) | Stateless auth, verify Microsoft's JWTs |
| Validation | `zod` | Type-safe request validation |
| CORS | `cors` middleware | Lock to Amplify domain |
| Process mgmt | `pm2` | Production process manager |
| Deploy | systemd service + nginx reverse proxy | Standard Linux deployment |

### EC2 Server Config
- Node.js Express server alongside iDempiere on same EC2
- nginx: `/api/*` → `localhost:3001`
- PostgreSQL: `localhost:5432` via connection pool
- PM2 daemon: auto-restart on crash
- Systemd: start on boot after PostgreSQL

---

## Project Structure (New Repo)

```
ability-erp-pwa/
├── web/                              # Next.js PWA (Amplify root)
│   ├── src/
│   │   ├── app/
│   │   │   ├── (auth)/
│   │   │   │   ├── login/
│   │   │   │   └── callback/ms/      # SSO redirect handler
│   │   │   ├── clients/
│   │   │   ├── enquiries/
│   │   │   ├── rostering/
│   │   │   ├── products/
│   │   │   ├── invoices/
│   │   │   ├── ...                   # One route per module
│   │   │   └── layout.tsx            # AppShell (same as AbilityVua UX)
│   │   ├── lib/
│   │   │   ├── api-client.ts         # fetch wrapper → EC2 API
│   │   │   ├── auth-config.ts        # SSO config (client ID, tenant, scopes)
│   │   │   └── types.ts              # Shared types
│   │   └── components/               # Reusable UI
│   ├── public/
│   │   ├── sw.js                     # Service worker
│   │   └── manifest.json             # PWA manifest
│   ├── src/app/api/auth/             # Next.js BFF routes
│   │   ├── ms-callback/route.ts      # SSO callback handler
│   │   ├── login/route.ts            # Password fallback
│   │   └── me/route.ts               # Session check
│   ├── next.config.ts
│   ├── package.json
│   └── amplify.yml                   # Amplify CI config
│
├── api/                              # Express API (deployed to EC2)
│   ├── src/
│   │   ├── index.ts                  # Express entry
│   │   ├── db/
│   │   │   ├── pool.ts               # PG connection pool
│   │   │   └── queries/              # SQL per module
│   │   ├── middleware/
│   │   │   ├── jwt-auth.ts           # JWT verification
│   │   │   └── validate.ts           # Zod schemas
│   │   ├── routes/
│   │   │   ├── auth.ts               # POST /login, POST /sso
│   │   │   ├── clients.ts
│   │   │   ├── enquiries.ts
│   │   │   ├── products.ts
│   │   │   ├── rostering.ts
│   │   │   ├── timesheets.ts
│   │   │   ├── invoices.ts
│   │   │   └── ... (one per module)
│   │   └── types.ts
│   ├── pm2.config.js
│   ├── tsconfig.json
│   └── package.json
│
├── db/
│   └── table-mappings.md             # SQL queries per module
│
└── README.md
```

---

## Implementation Phases

### Phase 0: Schema Discovery ✅ *(Completed)*
1. ✅ Connected to PostgreSQL `idempiere` on EC2 (schema: `adempiere`)
2. ✅ Discovered `adempiere` schema with 1,078 tables (1078)
3. ✅ Mapped every AbilityVua module to iDempiere tables
4. ✅ Identified 130 custom `aberp_*` NDIS tables
5. ✅ Confirmed plaintext passwords in `AD_User.password`
6. ✅ Documented roles: Support Worker, Support Manager, Rostering Officer, Employee Mobile, etc.
7. ✅ Auth design confirmed: SSO-first + AD_User fallback

### Phase 1: Foundation *(Ready to start)*
1. **Set up the new repo** — `ability-erp-pwa` on GitHub, Amplify app configured
2. **SSO setup** — Register app in Microsoft Entra ID (get tenant ID, client ID, client secret)
3. **Scaffold the API server** on EC2
   - Express.js + TypeScript + PG pool
   - `POST /api/auth/login` (AD_User plaintext check → JWT)
   - `POST /api/auth/sso` (verify Microsoft JWT → find AD_User by email → application JWT)
   - PM2 + nginx config
4. **Scaffold the PWA** (new repo)
   - Next.js 16 + Tailwind + Amplify
   - Microsoft SSO login (MSAL)
   - Password fallback (API client)
   - JWT session management (httpOnly cookie)
5. **Pick one module** — Build, test, validate end-to-end
   - **Recommend:** Clients (C_BPartner) — simplest, most foundational, touches SSO → data flow
6. **Deploy via Amplify** — `git push origin main`

### Phase 2: Core Modules (Parallel)
| Tier | Modules | Tables |
|------|---------|--------|
| 1 | Enquiries, Products, Price Lists, Employees | `aberp_enquiry`, `M_Product`, `M_PriceList`, `C_BPartner(isemployee)` |
| 2 | Service Bookings, Invoices, Service Agreements | `C_Order`, `C_Invoice`, `aberp_service_agreement` |
| 3 | Rostering, Timesheets, Support Plans | `aberp_rostered_shift`, `aberp_timesheetandexpenses`, `aberp_supportplans` |
| 4 | Claims, Incidents, Fleet, Reports | `aberp_servicetrack`, `aberp_incident`, `aberp_vehicle` |

### Phase 3: Production Hardening
- Rate limiting + WAF on EC2 API endpoint
- Monitoring (health checks, error tracking)
- PWA offline support (IndexedDB cache for key reference data)
- Backup/DR strategy

---

## Key Risks & Mitigations

| Risk | Status | Mitigation |
|------|--------|-----------|
| iDempiere schema complexity | ✅ Resolved | Fully explored 1,078 tables, 130 custom mapped |
| Password hashing | ✅ Resolved | Plaintext — direct comparison works. Add bcrypt layer later. |
| SSO user mapping (AD_User email) | ⚠️ Active | Need to confirm AD_User.email is populated for all users. If not, may need a linking step. |
| Microsoft Entra ID app registration | ⚠️ Active | Requires Azure AD admin. Need tenant ID, client ID, client secret, redirect URI. |
| EC2 API exposure | ⚠️ Active | nginx allowlist + Amplify IPs + Cloudflare Tunnel as alternative |
| Writes bypass iDempiere business logic | ⚠️ Active | Document trigger-heavy tables; use iDempiere ModelValidator endpoint for critical writes |
| Amplify cold starts + EC2 latency | ⚠️ Active | API is fast (direct DB queries); warm with health-check ping |

---

## Schema Access

Discovery completed. DB: PostgreSQL `idempiere` on EC2 (schema: `adempiere`).
All table mappings documented above. Full SQL query specs per module to be produced in `db/table-mappings.md` during Phase 1.
