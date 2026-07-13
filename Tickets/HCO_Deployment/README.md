# HCO Deployment (client install playbook)

Living home for installing AbilityERP tickets onto the **HCO** customer build. Append every new learning here after each HCO install — do not scatter only inside one SAW ticket.

| | |
|--|--|
| **Host** | `32.236.127.117` (hostname `Test`) |
| **WebUI** | `http://32.236.127.117/webui/` — title like `AvERP HCO Test001 …` |
| **SSH** | `ubuntu@32.236.127.117` — key `C:\Users\sawte\.ssh\HCObusiness.pem` (copy of `d:\HCObusiness.pem`; OpenSSH needs user-only ACL). Prefer `ssh` stdin upload over multi-file `scp` if SCP hangs; kill stale local `ssh.exe`/`scp.exe` if connects stall. |
| **WebUI login** | `SuperUser` / `HCOflamingo` |
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
| [SAW010](../SAW010_timesheet_approval_info_columns/NOTES.md#hco-future-deployments-variables) | Timesheet Approval Info columns — HCO install 2026-07-12 |
| [SAW009](../SAW009_support_day_pattern_number/NOTES.md#hco-future-deployments-variables) | Support Start/End Day pattern numbers — HCO install 2026-07-12 |
| [SAW001](../SAW001_paid_filter_invoice_send_info/NOTES.md#hco-future-deployments-variables) | Paid filter Info Window — first HCO install 2026-07-12 |
| [SAW014](../SAW014_support_location_contact_grid/NOTES.md#hco-future-deployments-variables) | Support Location Email/Phone grid ColumnSQL — HCO install 2026-07-13 |
| [SAW015](../SAW015_skip_dates_copy_from/NOTES.md#hco-future-deployments-variables) | Skip Dates Copy Dates From — HCO install 2026-07-13 |
| [SAW017](../SAW017_booking_generator_bulk/NOTES.md#hco-future-deployments-variables) | Booking Generator bulk — HCO Phase 0 discovery 2026-07-13 (JAR blocker) |
| [SAW018](../SAW018_hco_release_packins/NOTES.md#hco-future-deployments-variables) | HCO release packins (credentials/employee/client/support location) — HCO install 2026-07-13 |

Append new rows as tickets are installed.
