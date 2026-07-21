# HCO Deployment (client install playbook)

Living home for installing AbilityERP tickets onto the **HCO** customer build. Append every new learning here after each HCO install — do not scatter only inside one SAW ticket.

| | |
|--|--|
| **Host (HCO20260714 Production)** | `13.239.162.141` (hostname `HCOproduction`) — installed 2026-07-21; key `Documents\SSH Keys\HCO_Prod_KP.pem`; WebUI `https://abilityerp.hco.net.au/webui/` · report [`PRODUCTION-DEPLOYMENT-20260721.md`](../SAW020_hco20260714_release/report/PRODUCTION-DEPLOYMENT-20260721.md) |
| **Host (HCO20260714 dry run)** | `54.253.165.194` (hostname `ip-172-31-3-32`) — release ticket [`SAW020`](../SAW020_hco20260714_release/) |
| **Host (prior Test)** | `13.210.248.141` (hostname `Test`) — previous IPs `32.236.127.117` retired; most tickets already installed here 2026-07-12/13 |
| **Host (SAW011 / current work)** | `3.27.207.215` (hostname `ip-172-31-4-174`) — SAW011 Accept Shift Request installed 2026-07-18 |
| **WebUI** | Prod `https://abilityerp.hco.net.au/webui/` · dry run `http://54.253.165.194/webui/` · prior Test `http://13.210.248.141/webui/` |
| **SSH** | `ubuntu@<host>` — Test key `Documents\SSH Keys\HCObusiness.pem`; Prod key `Documents\SSH Keys\HCO_Prod_KP.pem`. Prefer `ssh` stdin upload over multi-file `scp` if SCP hangs. |
| **WebUI login** | Test: `SuperUser` / `HCOflamingo` · Prod: SSO `superuser@hco.net.au` → **Admin** |
| **Typical role** | **Admin** (HCO SuperUser role dialog — not always AbilityERP Admin) |
| **DB** | `idempiere` · user `adempiere` · password `flamingo` · schema `adempiere` |
| **iDempiere home** | `/opt/idempiere-server` |
| **Client** | HCO - Disability and Community Services |

Ticket sources: [`Tickets/`](../) · registry [`docs/TICKETS.md`](../../docs/TICKETS.md)

## Hard rules (never break)

1. **Never change any `*_UU` already present on the HCO build.**
2. If UU / name / ID mismatch blocks install: **fix the AbilityERP update process** (SQL lookups, grants, menu parent resolution), not HCO data UUIDs.
3. After each HCO install, update:
   - this folder (`LEARNINGS.md` + any ticket-specific notes below), and
   - that ticket’s **`HCO Future Deployments variables`** section in `Tickets/SAW###_…/NOTES.md` (or DEPLOY.md).
4. Commit + push process fixes so the next production release uses the hardened SQL.
5. Prefer resolve by **`*_UU`** or stable **name** — never hardcode `AD_*_ID` across clients.

## Install loop on HCO

Follow `.cursor/rules/client-update-staging-loop.mdc` and `.cursor/rules/hco-deployment.mdc`.

1. Read ticket `DEPLOY.md` + package under `idempiere-plugins/…`.
2. Preflight on HCO (`psql`, UU present, FROM clause / dependencies OK).
3. Apply ordered SQL (or pack HOW-TO). JAR → manual OSGi console only.
4. Cache Reset / logout-in.
5. WebUI smoke as **Admin** (and AbilityERP Admin if that role is on the dialog).
6. If blocked: patch **repo** SQL → re-apply → document learning here + ticket HCO section.
7. Push GitHub updates before claiming done.

## Related rules / docs

- `.cursor/rules/hco-deployment.mdc` (always-on agent rule)
- `.cursor/rules/client-update-staging-loop.mdc`
- `.cursor/rules/client-update-packs.mdc`
- `docs/DEV-REQUIREMENTS.md` (Admin access — also grant operational **Admin** on HCO when that is the smoke role)

## Per-ticket HCO notes

| Ticket | Notes |
|--------|--------|
| [SAW003](../SAW003_staff_rostering_info/NOTES.md#hco-future-deployments-variables) | Staff Rostering Info on Shift (Rostered) → Employee — HCO install 2026-07-12 |
| [SAW007](../SAW007_activity_tab_integration/NOTES.md#hco-future-deployments-variables) | Activity tabs on BG / Service Booking / Service Agreement — HCO install 2026-07-12 |
| [SAW011](../SAW011_accept_shift_request/NOTES.md#hco-future-deployments-variables) | Accept Shift Request — host `3.27.207.215` install 2026-07-18 (Published lookup + role names) |
| [SAW009](../SAW009_support_day_pattern_number/NOTES.md#hco-future-deployments-variables) | Support Start/End Day pattern numbers — HCO install 2026-07-12 |
| [SAW001](../SAW001_paid_filter_invoice_send_info/NOTES.md#hco-future-deployments-variables) | Paid filter Info Window — first HCO install 2026-07-12 |
| [SAW014](../SAW014_support_location_contact_grid/NOTES.md#hco-future-deployments-variables) | Support Location Email/Phone grid ColumnSQL — HCO install 2026-07-13 |
| [SAW015](../SAW015_skip_dates_copy_from/NOTES.md#hco-future-deployments-variables) | Skip Dates Copy Dates From — HCO install 2026-07-13 |
| [SAW017](../SAW017_booking_generator_bulk/NOTES.md#hco-future-deployments-variables) | Booking Generator bulk — HCO Phase 0 discovery 2026-07-13 (JAR blocker) |
| [SAW018](../SAW018_hco_release_packins/NOTES.md#hco-future-deployments-variables) | HCO release packins (credentials/employee/client/support location) — HCO install 2026-07-13 |
| [SAW016](../SAW016_leave_planning/DEPLOY.md) | Leave Planning Info — redeploy via `redeploy-hco.sh` / JAR `1402` (Support Location Search + parser-safe display) |
| [SAW020](../SAW020_hco20260714_release/README.md) | **HCO20260714** release dry run on `54.253.165.194` — Production runbook |
| [SAW026](../SAW026_vehicle_activity_tab/DEPLOY.md) | Vehicle Activity tab — HCO Test001 plus HCO20260714 host `54.253.165.194`; apply/idempotency and Admin create/link/cleanup smoke validated 2026-07-17 |

Append new rows as tickets are installed.
