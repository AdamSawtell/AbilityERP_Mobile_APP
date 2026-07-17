# SAW026 — Deploy Vehicle Activity tab

**Ticket / slug:** `SAW026_vehicle_activity_tab`  
**Kind:** idempiere · **JAR:** no · **Status:** done

## Required host access

- SSH and `psql` access to the iDempiere database
- WebUI login with Admin access
- Cache Reset or logout/in after AD changes

## Target

- Parent window: **Vehicle**
- Parent table: `AbERP_Vehicle`
- Child table: `C_ContactActivity`
- Activity Types: Email (`EM`), Meeting (`ME`), Phone call (`PC`), Case Note (`CN`), Task (`TA`)

## Install

From the repository:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f idempiere-plugins/com.aberp.contactactivity.tabs/sql/05-add-vehicle-activity-tab.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f idempiere-plugins/com.aberp.contactactivity.tabs/sql/95-verify-vehicle-activity-tab.sql
```

No JAR, OSGi console action, or service restart is required. Log out/in or run Cache Reset after apply.

The apply is idempotent and fails closed when Vehicle, Enquiry Activity, the five Activity Types, the Included Activities validation rule, or AbilityERP Admin is missing. It does not hardcode client `AD_*_ID` values or replace existing client UUIDs.

Rollback:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f idempiere-plugins/com.aberp.contactactivity.tabs/sql/99-rollback-vehicle-activity-tab.sql
```

The conservative rollback retains the link column so existing Activity data is preserved.

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
- **Parent link:** database join confirmed `C_ContactActivity.AbERP_Vehicle_ID=1000000` → Vehicle `S637CMD`
- **Cleanup:** the staging smoke Activity was deleted after verification

## Packs

- Staging: `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW026_vehicle_activity_tab-20260717\`
- Production: `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW026_vehicle_activity_tab-20260717\`
