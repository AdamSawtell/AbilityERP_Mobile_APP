# SAW024 — Deploy

## Hosts

| Env | Host |
|-----|------|
| Dev | `3.27.207.215` |

Prerequisite: SAW023 installed (NDIS Audit Tool + Employee rules + Refresh).

## Deploy

```bash
PLUGIN=idempiere-plugins/com.aberp.compliance
# …prior SAW023 + SAW024 18–23 if not already applied…
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/24-source-assignment-link.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/25-assignment-label-toolbar.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/26-rename-org-audit-menu.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/27-restore-org-audit-menu.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/32-physical-open-fix-button.sql
```

JAR (manual OSGi): `com.aberp.compliance_7.1.0.202607161500.jar`

Or: `bash $PLUGIN/deploy.sh` on the iDempiere host (builds + SQL + restart).

Then WebUI **Cache Reset**, **logout/in** as Admin.

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit (folder) | — |
| Menu | Audit Hub | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |

## Smoke

1. Menu → **Organisation Audit** → **Audit Hub** → **Employee** → **Open Findings**
2. Confirm **Assignment** shows a Credential Assignment Value (not `-1`)
3. Click **Open & Fix** on the row → **Credential Assignment** opens on that record
4. Update expiry → Save → Refresh Compliance

## Notes

- Open Findings is **TabLevel 2** under Employee via `Included_Tab_ID` + physical `AbERP_ComplianceDashboard_ID`.
- `Open & Fix` must be a **physical** Button column (SQL 32) — virtual `ColumnSQL` left the button disabled.
- Search Assignment on included tabs shows `-1`; grid shows Assignment **Value** string; process zooms by CA PK.
- Process loads WebUI `AEnv` via OSGi bundle lookup (plain `Class.forName` fails from the process bundle).
- Menu folder **Organisation Audit** holds **Audit Hub** (window), Compliance Rules, Compliance Results. Window leaf must not reuse the folder name or ZK hides it.
- Host `AD_PInstance` can be very large; process starts may be slow.
