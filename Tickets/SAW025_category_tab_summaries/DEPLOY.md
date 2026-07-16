# SAW025 — Deploy

## Plugin

`idempiere-plugins/com.aberp.compliance/`

## JAR

Yes — `com.aberp.compliance_7.1.0.202607170530.jar` (writes `PopulationCount` on refresh). Live counts also work from SQL view alone.

## Ordered SQL

1. `sql/35-category-population-summary.sql` (after SAW023/024 base)

Or `deploy.sh` (includes 35).

## Restart / cache

OSGi install/start JAR if deploying engine change. Cache Reset or logout/in after AD field install.

## Smoke

1. Menu → Organisation Audit → Audit Hub → Find
2. **Employee**: Active Employees (~210 on HCO-like) + Change (90d) at top
3. Client / Incidents / Rostering / Documentation: matching summary pair at top
4. Refresh Compliance — snapshots gain `PopulationCount`

## AbilityERP Admin access

No new windows/processes. Existing grants cover NDIS Audit Tool + Refresh Compliance.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Definitions

| Tab | Count | Change (90d) |
|-----|-------|--------------|
| Employee | Active employees (`AD_User` + `C_BPartner.IsEmployee`) | current − members Created ≤ today−90 (or snapshot ≤90d) |
| Client | Active support receivers (`AbERP_IsSupport_Receiver=Y`) | same |
| Incidents | Open (non-closed) active incidents | same |
| Rostering | Shifts in current pay period | vs average of completed periods in last 90d |
| Documentation | Active credential assignments | same |

Apply `36-fix-population-client-90d.sql` after `35`. JAR `7.1.0.202607170545`.
