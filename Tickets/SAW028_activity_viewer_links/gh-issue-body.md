## Summary

Activity Viewer gets an **Activity Links** field group with Client / Employee / Support Location buttons that zoom the named AbilityERP windows only (never Business Partner or User).

## Deploy

See [`Tickets/SAW028_activity_viewer_links/DEPLOY.md`](Tickets/SAW028_activity_viewer_links/DEPLOY.md).

- Plugin: `idempiere-plugins/com.aberp.activityaudit/`
- JAR: `com.aberp.activityaudit_7.1.0.202607180900`
- SQL: `sql/16-activity-viewer-links.sql`

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

## Home

`Tickets/SAW028_activity_viewer_links/`
