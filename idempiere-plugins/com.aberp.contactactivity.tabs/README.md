# Contact Activity Tabs — iDempiere Plugin

Adds the standard **Activity** tab to AbilityERP windows:

| Window | AD_Window_ID | Link column |
|--------|--------------|-------------|
| **Booking Generator** | `1000193` | `AbERP_BookingGenerator_ID` |
| **Service Booking** | `1000077` | `C_Order_ID` |
| **Service Agreement (Project)** | `1000118` | `C_Project_ID` |
| **Vehicle** | portable lookup | `AbERP_Vehicle_ID` |

Activities use the standard `C_ContactActivity` table (same as Enquiry, Shift, Business Partner, etc.).

## How Activity works in AbilityERP

1. **Tab** — Level-1 child tab on `C_ContactActivity`, linked to the parent record via a foreign key column (e.g. `AbERP_Enquiry_ID` on Enquiry).
2. **Activity types by window** — The `ContactActivityType` column uses validation rule `AbERP_Ref_List`. Each entry in reference **C_ContactActivity Type** (`AD_Reference_ID = 53423`) has a **Description** field containing comma-separated `AD_Window_ID` values where that type is available.
3. **Activity types by role** — Use the **Included Activities** window (`AD_Window_ID = 1000137`, table `AbERP_IncludedActivities`) to map Role + Window + Reference List (activity type). Rows in this table further restrict which types each role sees on each window.

This plugin also extends `AbERP_IncludedActivityWindows` so the new windows appear in the Included Activities window picker.

## Build (on iDempiere server)

```bash
cd idempiere-plugins/com.aberp.contactactivity.tabs
chmod +x build.sh deploy.sh
./build.sh
```

## Deploy

```bash
./deploy.sh
```

Or from your dev machine:

```bash
scp -r idempiere-plugins/com.aberp.contactactivity.tabs ubuntu@<ec2>:/opt/ability-erp-pwa/idempiere-plugins/
ssh ubuntu@<ec2> "sudo /opt/ability-erp-pwa/idempiere-plugins/com.aberp.contactactivity.tabs/deploy.sh"
```

After deploy: **log out and log back in** on the WebUI to refresh the AD cache.

## SQL scripts (run in order)

1. `sql/01-add-link-columns.sql` — physical + AD columns on `C_ContactActivity`
2. `sql/02-add-activity-tabs.sql` — tabs and fields on the three windows
3. `sql/03-update-activity-type-windows.sql` — activity type list + Included Activities validation
4. `sql/05-add-vehicle-activity-tab.sql` — SAW026 portable Vehicle tab, fields, Activity Types, and Admin grants
5. `sql/95-verify-vehicle-activity-tab.sql` — SAW026 read-only verification
6. `sql/99-rollback-vehicle-activity-tab.sql` — SAW026 conservative rollback

## Manual test

1. Open **Booking Generator** → select a record → **Activity** tab → New → pick Activity Type, enter Description.
2. Repeat on **Service Booking** and **Service Agreement (Project)**.
3. For SAW026, repeat on **Vehicle** and confirm Email, Meeting, Phone call, Case Note, and Task.
4. Configure **Included Activities** for a role if you need role-specific type filtering.
