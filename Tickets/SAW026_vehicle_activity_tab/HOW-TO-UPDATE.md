# SAW026 — Vehicle Activity tab update

This update is SQL/AD-only. It does not require a JAR, OSGi console work, or an iDempiere service restart.

## Before installation

1. Back up the iDempiere database.
2. Confirm the target has:
   - the **Vehicle** window on `AbERP_Vehicle`;
   - the Enquiry **Activity** tab on `C_ContactActivity`;
   - Activity Types `EM`, `ME`, `PC`, `CN`, and `TA`;
   - the **AbilityERP Admin** role.
3. Use the target database name in place of `idempiere` if different.

## Install

Run:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/01-APPLY.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/95-VERIFY.sql
```

The apply script is portable and idempotent. It resolves the parent window/table and template by stable names, uses fixed AbilityERP UUIDs for new objects, and never changes an existing `*_UU`.

## Refresh

No restart is required. Log out of WebUI and log back in, or run Cache Reset.

## Smoke test

1. Log in as **AbilityERP Admin** or **Admin**.
2. Open **Vehicle** and select an existing vehicle.
3. Confirm the **Activity** tab appears.
4. Start a new Activity and confirm the list contains Email, Meeting, Phone call, Case Note, and Task.
5. Save a test activity and confirm it remains attached to the selected Vehicle.

## Rollback

Run:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-ROLLBACK.sql
```

The conservative rollback deactivates the tab and fields and removes Vehicle from the Activity Type/window picker grants. It retains the physical and AD link column so existing activity data is not lost.
