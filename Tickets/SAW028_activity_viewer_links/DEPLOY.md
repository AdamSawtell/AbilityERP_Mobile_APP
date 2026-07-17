# SAW028 — Deploy

## Environment

| Tier | Host | Notes |
|------|------|--------|
| Dev | `3.27.207.215` | Audit Tool Build / HCO Test clone |
| SSH | `ubuntu@3.27.207.215` | Key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` | SuperUser / `HCOflamingo` · role **Admin** |

## Plugin

`idempiere-plugins/com.aberp.activityaudit/` (extends SAW027 bundle)

## JAR

Yes — `com.aberp.activityaudit_7.1.0.202607180900.jar`

## Ordered SQL

1. Prerequisites: SAW027 Activity Audit plugin already installed (or full `deploy.sh` which includes 00–17)
2. `sql/16-activity-viewer-links.sql` — field group, buttons, processes, access
3. `sql/17-activity-viewer-links-display.sql` — DisplayLogic / placement fix (real + virtual link IDs)

## Restart / cache

Install/start JAR. After SQL: restart iDempiere (or Cache Reset + logout/in).

## Smoke

1. Open **Activity Viewer** on an Activity with a Client BP (`IsCustomer=Y`, not employee)
2. Confirm **Activity Links** shows **Client** — click → **Client** window opens (not Business Partner)
3. On an Activity with staff/user employee link — **Employee** → **Employee** window (not User)
4. On an Activity with Support Location — **Support Location** → that window
5. Buttons hidden when no resolvable link

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Viewer | — |
| Window | Client | — |
| Window | Employee | — |
| Window | Support Location | — |
| Process | Open Client | `AbERP_ActivityViewer_OpenClient` |
| Process | Open Employee | `AbERP_ActivityViewer_OpenEmployee` |
| Process | Open Support Location | `AbERP_ActivityViewer_OpenSupportLocation` |
