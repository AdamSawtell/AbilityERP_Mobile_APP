# SAW011 — Deploy to another build

**Ticket:** SAW011_accept_shift_request · **Kind:** idempiere · **JAR:** Yes

## Agent one-liner

bash
cd idempiere-plugins/com.aberp.rosteredshift.process
chmod +x build.sh deploy.sh
./deploy.sh
# installs accept-request bundle + sql/install-accept-shift-request.sql + restarts idempiere
# then logout/in. Do NOT wipe OSGi cache (breaks other AbERP plugins).


Manual SQL-only (still needs JAR for the process class):

bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/install-accept-shift-request.sql
sudo systemctl restart idempiere


## Package

idempiere-plugins/com.aberp.rosteredshift.process/

- Process class: com.aberp.rosteredshift.process.AcceptShiftRequest  
- Bundle symbolic name may be com.aberp.rosteredshift.acceptrequest (see package README / MANIFEST)  
- Primary AD script: sql/install-accept-shift-request.sql

## Restart / cache

- **Yes** restart idempiere  
- **Yes** logout/in  
- **Do not** clear full OSGi cache as a “fix”

## WebUI smoke

1. **Shift (Rostered)** with pending **REQ** on **Response Log**.  
2. Select row → **Accept Shift Request**.  
3. **Employee** tab has the worker; response IsReviewed = Y; shift **Published**; button hidden when already staffed / declined / reviewed.

## Blockers / notes

- Java currently uses Published R_Status_ID = 1000040 — **confirm by name/UU on the target** before go-live; patch if IDs differ.  
- Needs AbERP_RosteredResponseLog + Response Log tab.  
- Grant process access to AbilityERP Admin / Rostering Officer (install SQL should do this; verify).  
- No Downloads pack yet — create AbilityERP-*-SAW011_accept_shift_request-* when shipping.


## AbilityERP Admin access (mandatory)

Install SQL / deploy must grant **AbilityERP Admin** access to every new or newly exposed **window**, **process**, **Info Window**, and **form** (and process access for toolbar buttons). See docs/DEV-REQUIREMENTS.md. After grant: Role Access Update or logout/in. Smoke as Admin.

## Packs

- None yet; apply from repo until thin prod pack exists.
