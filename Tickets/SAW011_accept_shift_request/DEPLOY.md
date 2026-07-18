# SAW011 — Deploy to another build (agent)

**Ticket / slug:** `SAW011_accept_shift_request`  
**Kind:** idempiere · **JAR:** Yes · **Status:** done (seed-ready; check Published ID on other builds)

## Required host access

- SSH · `psql` · WebUI Admin · restart / OSGi  
- Prerequisite: **Shift (Rostered)** + **Response Log** tab + `AbERP_RosteredResponseLog`

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rosteredshift.process
chmod +x build.sh deploy.sh
./deploy.sh
# installs acceptrequest JAR + sql/install-accept-shift-request.sql + restart
# logout/in. Do NOT wipe OSGi cache.
```

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rosteredshift.process/` |
| Process class | `com.aberp.rosteredshift.process.AcceptShiftRequest` |
| **Bundle symbolic name** | `com.aberp.rosteredshift.acceptrequest` |
| Version | `7.1.0.202607181300` (confirm MANIFEST) |
| **Primary AD script** | `sql/install-accept-shift-request.sql` (includes button, display logic, **role-name** process access) |

## Do NOT use on other builds (hardcoded role IDs)

- `sql/grant-process-access-roles.sql`  
- `sql/register-accept-shift-request.sql`  

Use **only** `install-accept-shift-request.sql` (name-based Admin / Rostering Officer / Rostering / Rostering TL / AbilityERP Admin grants).  
`update-accept-button-displaylogic.sql` is for fixes if displaylogic drifts — already embedded in install for fresh installs.

Optional diagnose: `sql/diagnose-accept-shift-install.sql`

## AbilityERP Admin access

Install SQL grants process access by **role name** to:

| Access | Name | Search key |
|--------|------|------------|
| Process | Accept Shift Request | `SHIFT_ACCEPT_REQUEST` |

Roles granted when present: **AbilityERP Admin**, **Admin**, **Rostering Officer**, **Rostering**, **Rostering TL**. Verify after deploy. Smoke **as Admin**.

## Portability (Published status)

Java resolves **Published** under category **Shift Status** by **name** (no hardcoded `R_Status_ID`). Optional check on target:

```sql
SET search_path TO adempiere, public;
SELECT s.r_status_id, s.name, s.value, c.name AS category
FROM r_status s
JOIN r_statuscategory c ON c.r_statuscategory_id = s.r_statuscategory_id
WHERE c.name = 'Shift Status' AND s.name = 'Published';
```

## HCO install (2026-07-18)

Host `3.27.207.215` — see `NOTES.md` § HCO Future Deployments variables. Bundle ACTIVE; AD process + button + role access verified.

## WebUI smoke

Shift with pending **REQ** → Accept Shift Request → Employee assigned · IsReviewed · Published · button hidden when staffed/declined/reviewed.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW011_accept_shift_request-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW011_accept_shift_request-20260712\`

## External ticket text

`Tickets/SAW011_accept_shift_request/EXTERNAL-SUMMARY.md`
