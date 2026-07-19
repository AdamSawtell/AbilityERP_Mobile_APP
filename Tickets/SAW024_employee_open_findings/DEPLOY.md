# SAW024 — Deploy

## Hosts

| Env | Host |
|-----|------|
| Dev | `3.27.207.215` |

Prerequisite: SAW023 installed (NDIS Audit Tool + rules + Refresh).
SQL 40 also needs SAW025 population columns (`ActiveEmployees`, `ActiveClients`, `ActiveIncidents`, `PeriodShifts`, `TotalDocuments`) — apply SAW025 SQL 35–36 (or full 35–39) before or with this ticket.

## Ordered SQL

```bash
PLUGIN=idempiere-plugins/com.aberp.compliance
# …prior SAW023 + SAW024 18–23 if not already applied…
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/24-source-assignment-link.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/25-assignment-label-toolbar.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/26-rename-org-audit-menu.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/27-restore-org-audit-menu.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/32-physical-open-fix-button.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/33-open-findings-all-categories.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/34-rename-findings-tabs.sql
# After SAW025 population columns exist:
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f $PLUGIN/sql/40-findings-parent-only-navigation.sql
```

JAR (manual OSGi): `com.aberp.compliance_7.1.0.202607161600.jar` (or later OpenComplianceSource build).

Or: `bash $PLUGIN/deploy.sh` on the iDempiere host (builds + SQL including 40 + restart).

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

1. Menu → **Organisation Audit** → **Audit Hub** (Find if the dashboard row is empty)
2. On the **lead page**, confirm only five category tabs: Employee / Client / Incidents / Rostering / Documentation (no Findings tabs)
3. Select a category parent, then **Detail** (Alt+Down) into its findings sub-tab
4. Confirm only that category’s Findings tab/grid is available; rows are category-filtered
5. Click **Open & Fix** on a row
6. Update source → Save → Refresh Compliance

## Notes

- Open Findings is **TabLevel 2** under each category via `Included_Tab_ID` + physical `AbERP_ComplianceDashboard_ID`.
- `Open & Fix` must be a **physical** Button column (SQL 32) — virtual `ColumnSQL` left the button disabled.
- SQL 40: each Findings tab `DisplayLogic` uses the parent’s population field so the lead page does not list Findings siblings.
- Search Assignment on included tabs shows `-1`; grid shows Assignment **Value** string; process zooms by CA PK.
- Process loads WebUI `AEnv` via OSGi bundle lookup (plain `Class.forName` fails from the process bundle).
- Menu folder **Organisation Audit** holds **Audit Hub** (window), Compliance Rules, Compliance Results. Window leaf must not reuse the folder name or ZK hides it.
