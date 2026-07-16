# SAW024 — Open Findings (external summary)

## What’s done

On **Organisation Audit**, every category tab has a findings sub-tab with open issues from Refresh Compliance. **Open & Fix** jumps to the source record (Credential Assignment for Employee / Documentation).

| Category | Findings tab | Open findings (dev) |
|----------|--------------|---------------------|
| Employee | Open Findings | Workforce / credentials |
| Client | Client Findings | Risks / service agreements |
| Incidents | Incident Findings | Investigations / actions |
| Rostering | Rostering Findings | Unfilled / credential gaps |
| Documentation | Documentation Findings | Onboarding documents |

## What changed

- Findings nested under all five category tabs (Included tab + TabLevel 2)
- Category-filtered lists (`W` / `P` / `I` / `R` / `D`)
- **Open & Fix** (`AbERP_Compliance_OpenSource`) opens the linked source
- Employee / Documentation show Assignment Value; other categories use Why / Resolve
- Menu **Organisation Audit → Audit Hub**

## Impact

Audit issues are actionable from each KPI area without leaving the hub.

## How to test

1. Admin → **Organisation Audit** → **Audit Hub**
2. For each of Employee / Client / Incidents / Rostering / Documentation: open the Findings sub-tab
3. Confirm rows match that category (not mixed)
4. On Employee or Documentation: **Open & Fix** → Credential Assignment opens
5. On other categories: **Open & Fix** opens the linked source window when one exists
6. Fix → Save → **Refresh Compliance** → list updates

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit (folder) | — |
| Menu | Audit Hub | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |
