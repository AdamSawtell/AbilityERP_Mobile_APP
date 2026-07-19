# com.aberp.activityaudit — Activity Audit

AbilityERP **Activity Audit** (ticket **SAW027**): terms, nightly/historical engine, review queue, Activity Viewer links, review form groups.

## Deploy

```bash
chmod +x build.sh deploy.sh
./deploy.sh
```

Applies SQL `00`–`21`, installs JAR `7.1.0.202607191400`, restarts iDempiere.

Agent handoff: `Tickets/SAW027_activity_audit/DEPLOY.md`

## Processes

| Value | Role |
|-------|------|
| `AbERP_ActivityAudit_Nightly` | Incremental scan |
| `AbERP_ActivityAudit_Historical` | Date-range / new terms |
| `AbERP_ActivityAudit_OpenActivity` | Review → Activity Viewer |
| `AbERP_ActivityViewer_OpenClient` | Viewer → Client |
| `AbERP_ActivityViewer_OpenEmployee` | Viewer → Employee |
| `AbERP_ActivityViewer_OpenSupportLocation` | Viewer → Support Location |
