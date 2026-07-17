# SAW026 — Vehicle Activity tab update

This update is SQL/AD-only. It does not require a JAR or OSGi console work.
The normal refresh is Cache Reset plus logout/login; restart iDempiere only if
the target build continues to serve stale window metadata.

## Before installation

1. Back up the iDempiere database.
2. Confirm the target has:
   - the **Vehicle** window on `AbERP_Vehicle`;
   - the Enquiry **Activity** tab on `C_ContactActivity`;
   - Activity Types `EM`, `ME`, `PC`, `CN`, and `TA`;
   - the **AbilityERP Admin** role.
3. Use the target database name in place of `idempiere` if different.

## Install

From the repository root, run:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/01-APPLY.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/95-VERIFY.sql
```

The wrapper executes the plugin migration source. The apply is portable and
idempotent: it resolves existing objects by UUID or stable name, uses fixed
AbilityERP UUIDs only for new objects, and never replaces an existing client
`*_UU`.

## Refresh

1. Close the Vehicle window.
2. Run **Cache Reset**.
3. Log out and back in.
4. Reopen Vehicle.

If the old grid remains after these steps, restart the target's iDempiere
service during an approved staging maintenance window, then log in again.

## Smoke test

1. Log in as **AbilityERP Admin** or **Admin**.
2. Open **Vehicle** and select an existing vehicle.
3. Confirm the **Activity** tab appears.
4. Confirm the grid columns are Start Date, Activity Type, Description,
   Comments, End Date, and Complete.
5. Confirm User/Contact and Contact Activity are hidden from the form and grid.
6. Confirm Comments is four lines high.
7. Start a new Activity and confirm the list contains Email, Meeting, Phone
   call, Case Note, and Task.
8. Save a test Activity and confirm it remains attached to the selected Vehicle.
9. Delete the smoke-test Activity.

## Rollback

Run:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f Tickets/SAW026_vehicle_activity_tab/sql/99-ROLLBACK.sql
```

The conservative rollback deactivates the tab and fields and removes Vehicle from the Activity Type/window picker grants. It retains the physical and AD link column so existing activity data is not lost.

For expected verification output, role access, HCO-specific cautions, and
tested staging evidence, follow [`DEPLOY.md`](DEPLOY.md).
