# SAW026 — Deploy Vehicle Activity tab

**Ticket / slug:** `SAW026_vehicle_activity_tab`  
**Kind:** idempiere · **JAR:** no · **Status:** done

## Required host access

- SSH and `psql` access to the iDempiere database
- WebUI login with Admin access
- Cache Reset or logout/in after AD changes
- An approved maintenance window if that build requires an iDempiere restart to clear stale metadata

## Target

- Parent window: **Vehicle**
- Parent table: `AbERP_Vehicle`
- Child table: `C_ContactActivity`
- Activity Types: Email (`EM`), Meeting (`ME`), Phone call (`PC`), Case Note (`CN`), Task (`TA`)

## Install

Use the ticket wrappers from the repository root:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/01-APPLY.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/95-VERIFY.sql
```

The wrappers resolve the canonical plugin SQL using `\ir`; they can be invoked
from any working directory while the repository layout is intact.

No JAR or OSGi console action is required. Close Vehicle, run Cache Reset, log
out/in, and reopen Vehicle after apply. If the target still serves the previous
layout, restart iDempiere during an approved maintenance window and log in
again.

The apply is idempotent and fails closed when Vehicle, Enquiry Activity, the five Activity Types, the Included Activities validation rule, or AbilityERP Admin is missing. It does not hardcode client `AD_*_ID` values or replace existing client UUIDs.

Do not edit an existing client `*_UU`, including on HCO. Resolve any mismatch
by correcting the migration lookup or deployment process.

## Expected verification

`95-VERIFY.sql` must show:

- one active Vehicle Activity tab linked by `AbERP_Vehicle_ID`;
- link reference **Search** and Vehicle reference UU
  `51ee0d93-0d9d-4d34-8b5b-e62a766c21fc`;
- Activity Types `CN`, `EM`, `ME`, `PC`, and `TA` enabled;
- AbilityERP Admin access active/read-write, plus Admin where present;
- User/Contact and Contact Activity with `IsDisplayed=N` and
  `IsDisplayedGrid=N`;
- Comments with `NumLines=4`;
- grid sequence Start Date, Activity Type, Description, Comments, End Date,
  Complete;
- any existing `AD_Tab_Customization` row normalized to those six fields.

Rollback:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/99-ROLLBACK.sql
```

The conservative rollback retains the link column so existing Activity data is preserved.

## Repository artifacts

See [`ARTIFACTS.md`](ARTIFACTS.md). The ticket contains ordered SQL wrappers,
NO-JAR and NO-PACKOUT declarations. The authoritative migration source remains
under `idempiere-plugins/com.aberp.contactactivity.tabs/sql/`.

## AbilityERP Admin access

Install SQL grants the existing parent window to **AbilityERP Admin** and, where present or required, **Admin**.

| Access | Name | Search key |
|---|---|---|
| Window | Vehicle | — |

## WebUI smoke

1. Log out/in as Admin after installation.
2. Open **Vehicle** and select an existing vehicle.
3. Open **Activity** and confirm the grid shows Start Date, Activity Type,
   Description, Comments, End Date, and Complete only.
4. Confirm User/Contact and Contact Activity are hidden, and Comments uses four lines.
5. Create a record and confirm Activity Type offers Email, Meeting, Phone call,
   Case Note, and Task.
6. Save and confirm the activity remains linked to the selected Vehicle.

## Staging evidence

- **Host:** `54.153.138.216` — HCO Test001
- **Database apply:** pass; second apply also passed idempotently
- **Metadata:** Activity tab ID `1000364`, fixed UU `7d14ac4f-5fef-4f1f-b917-026000000002`, 18 fields, link `AbERP_Vehicle_ID`
- **Vehicle lookup:** canonical Search reference UU `51ee0d93-0d9d-4d34-8b5b-e62a766c21fc`; WebUI renders `S637 CMD`, not `~-1~`
- **Types:** `EM`, `ME`, `PC`, `CN`, and `TA` all enabled
- **Access:** AbilityERP Admin and Admin active/read-write
- **WebUI:** Admin opened Vehicle `S637CMD`, saw all five options, and created Activity `1641183` with Vehicle displayed as `S637 CMD`
- **Layout:** User/Contact and Contact Activity hidden from form/grid; Comments set to four lines; grid reduced to six operational columns
- **Customization override:** existing `AD_Tab_Customization` rows are normalized with dynamically resolved field IDs, so stale user layouts cannot restore hidden fields
- **Layout smoke:** pass after Cache Reset/service restart and reopening Vehicle; grid showed Start Date, Activity Type, Description, Comments, End Date, and Complete
- **Repository wrappers:** `sql/01-APPLY.sql` and `sql/95-VERIFY.sql` executed successfully from `/tmp`, confirming relative source resolution is independent of the current working directory
- **Parent link:** database join confirmed `C_ContactActivity.AbERP_Vehicle_ID=1000000` → Vehicle `S637CMD`
- **Cleanup:** the staging smoke Activity was deleted after verification

### HCO20260714 release host

- **Host:** `54.253.165.194` — HCO Test release host
- **Applied:** 2026-07-17; SQL-only, no restart required
- **Migration:** first attempt failed safely because HCO's `AD_Tab` sequence
  lagged existing IDs; migration hardened to advance affected AD sequences,
  then apply and second idempotency apply passed
- **Metadata:** Activity tab ID `1000362`, fixed UU
  `7d14ac4f-5fef-4f1f-b917-026000000002`, 18 fields, Search-linked
  `AbERP_Vehicle_ID`
- **Access/types:** AbilityERP Admin + Admin read/write; `CN`, `EM`, `ME`, `PC`,
  and `TA` enabled
- **WebUI:** Admin opened Vehicle `S637CMD`, opened Activity, confirmed all five
  types and focused form, and saved Activity `1641178`
- **Parent link:** saved row joined `AbERP_Vehicle_ID=1000000` to `S637CMD`
- **Cleanup:** Activity `1641178` removed after verification; WebUI remained
  HTTP 200

## Packs

- Staging: `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW026_vehicle_activity_tab-20260717\`
- Production: `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW026_vehicle_activity_tab-20260717\`
