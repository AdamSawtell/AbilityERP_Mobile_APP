# SAW024 — Deploy

## Hosts

| Env | Host |
|-----|------|
| Dev | `3.27.207.215` |

Prerequisite: SAW023 installed (NDIS Audit Tool + Employee rules + Refresh).

## Deploy

```bash
PLUGIN=idempiere-plugins/com.aberp.compliance
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/18-employee-open-findings.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/19-employee-findings-subtab.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/20-fix-open-assignment-zoom.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/21-physical-open-assignment.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/22-zoom-condition-credential.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/23-source-record-zoom-field.sql
```

JAR (manual OSGi): `com.aberp.compliance_7.1.0.202607161320.jar`

Or: `bash $PLUGIN/deploy.sh` on the iDempiere host (builds + SQL + restart).

Then WebUI **Cache Reset**, **logout/in** as Admin (field overrides need a fresh session).

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix Source | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |

## Smoke

1. NDIS Audit Tool → **Employee** → breadcrumb shows **Open Findings** underneath
2. Confirm Why / What to resolve (~196 Employee open rows after Refresh)
3. **Open Assignment** column should show Credential Assignment **Value** (not `-1`)
4. Select row → form view → field **Zoom** on Open Assignment → Credential Assignment opens on that assignment
5. Or toolbar / grid **Open & Fix** (process `AbERP_Compliance_OpenSource`) → same zoom
6. Update expiry → Save → Refresh Compliance

## Notes

- Open Findings is **TabLevel 2** under Employee via `Included_Tab_ID` + physical `AbERP_ComplianceDashboard_ID`.
- Virtual ColumnSQL parent links fail; physical FK is required.
- `Record_ID` context name clashes with iDempiere `@Record_ID@` (PK) — Zoom Across is not the primary path; use Open Assignment field Zoom or Open & Fix.
- Host `AD_PInstance` can be very large; process starts may be slow.
