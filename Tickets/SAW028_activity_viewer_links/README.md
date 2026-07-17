# SAW028 — Activity Viewer Links

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#28](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/28) |
| **Slug** | `SAW028_activity_viewer_links` |
| **Dev host** | `3.27.207.215` |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

On **Activity Viewer**, add field group **Activity Links** with three buttons — **Client**, **Employee**, **Support Location** — that zoom the named AbilityERP windows only (never generic Business Partner or User/Contact). Buttons show only when a resolvable link exists.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| SQL | `…/sql/16-activity-viewer-links.sql` |
| Processes | `OpenActivityClient` / `OpenActivityEmployee` / `OpenActivitySupportLocation` |
| JAR | `com.aberp.activityaudit_7.1.0.202607180900` |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Viewer | — |
| Window | Client | — |
| Window | Employee | — |
| Window | Support Location | — |
| Process | Open Client | `AbERP_ActivityViewer_OpenClient` |
| Process | Open Employee | `AbERP_ActivityViewer_OpenEmployee` |
| Process | Open Support Location | `AbERP_ActivityViewer_OpenSupportLocation` |
