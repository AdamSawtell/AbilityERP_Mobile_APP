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
```

JAR (manual OSGi): `com.aberp.compliance_7.1.0.202607161500.jar`

Or: `bash $PLUGIN/deploy.sh` on the iDempiere host (builds + SQL + restart).

Then WebUI **Cache Reset**, **logout/in** as Admin.

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix Source | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |

## Smoke

1. Menu → **Organisation Audit** (under Ability ERP / NDIS Audit Tool folder)
2. **Employee** → detail → **Open Findings**
3. **Assignment** column shows Credential Assignment **Value** (not `-1`)
4. Select row → toolbar **Process** → **Open & Fix Source** → Credential Assignment opens on that assignment
5. Update expiry → Save → Refresh Compliance

## Notes

- Open Findings is **TabLevel 2** under Employee via `Included_Tab_ID` + physical `AbERP_ComplianceDashboard_ID`.
- Table lookup on `Record_ID` / Open Assignment showed `-1` on included tabs (context clash). Display uses String ColumnSQL **Assignment** label; zoom uses process `AbERP_Compliance_OpenSource`.
- Process loads WebUI `AEnv` via OSGi bundle lookup (plain `Class.forName` fails from the process bundle).
- Window menu was renamed **Organisation Audit** so it is not hidden under a same-named summary folder.
- Host `AD_PInstance` can be very large; process starts may be slow.
