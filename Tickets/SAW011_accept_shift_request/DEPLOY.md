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
| Version | `7.1.0.202607092140` (confirm MANIFEST) |
| **Primary AD script** | `sql/install-accept-shift-request.sql` (includes button, display logic, **role-name** process access) |

## Do NOT use on other builds (hardcoded role IDs)

- `sql/grant-process-access-roles.sql`  
- `sql/register-accept-shift-request.sql`  

Use **only** `install-accept-shift-request.sql` (name-based Admin / Rostering Officer grants).  
`update-accept-button-displaylogic.sql` is for fixes if displaylogic drifts — already embedded in install for fresh installs.

Optional diagnose: `sql/diagnose-accept-shift-install.sql`

## AbilityERP Admin access

Install SQL grants process access to **AbilityERP Admin** and **Rostering Officer** by **name**. Verify after deploy. Smoke **as Admin**.

## Portability risks (P0 before foreign go-live)

Java hardcodes Published `R_Status_ID = 1000040`. On target:

```sql
SET search_path TO adempiere, public;
SELECT r_status_id, name, value FROM r_status WHERE name ILIKE '%publish%' OR value ILIKE '%PUB%';
```

If not `1000040`, patch `AcceptShiftRequest.java` (or config) before go-live.

## WebUI smoke

Shift with pending **REQ** → Accept Shift Request → Employee assigned · IsReviewed · Published · button hidden when staffed/declined/reviewed.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW011_accept_shift_request-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW011_accept_shift_request-20260712\`

## External ticket text

`Tickets/SAW011_accept_shift_request/EXTERNAL-SUMMARY.md`
