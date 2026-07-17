# AbERP Activity Audit (SAW027)

Configurable keyword audit of `C_ContactActivity` with nightly incremental processing and review workflow.

## Build / deploy

```bash
cd /path/to/com.aberp.activityaudit
chmod +x build.sh deploy.sh
./deploy.sh
```

## Processes

| Value | Class |
|-------|--------|
| `AbERP_ActivityAudit_Nightly` | `ActivityAuditNightly` |
| `AbERP_ActivityAudit_Historical` | `ActivityAuditHistorical` |
| `AbERP_ActivityAudit_OpenActivity` | `OpenActivity` |
