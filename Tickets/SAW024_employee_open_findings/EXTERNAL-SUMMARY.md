# SAW024 — Findings navigation (external summary)

## What’s done

On **Organisation Audit**, Findings are reached through each category tab — not as sibling tabs on the lead page. **Open & Fix** jumps to the source record (Credential Assignment for Employee / Documentation).

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
- Lead page shows only the five category tabs; Findings appear after selecting the parent category
- Employee / Documentation show Assignment Value; other categories use Why / Resolve
- Menu **Organisation Audit → Audit Hub**

## Impact

Audit issues are actionable from each KPI area without leaving the hub. The lead page stays clear of Findings clutter.

## How to test

1. Admin → **Organisation Audit** → **Audit Hub**
2. On the lead page, confirm Findings tabs are not listed
3. For each of Employee / Client / Incidents / Rostering / Documentation: open the category, then its Findings sub-tab
4. Confirm rows match that category (not mixed)
5. On Employee or Documentation: **Open & Fix** → Credential Assignment opens
6. On other categories: **Open & Fix** opens the linked source window when one exists
7. Fix → Save → **Refresh Compliance** → list updates

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit (folder) | — |
| Menu | Audit Hub | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |

## Windows / processes / objects affected

| Object | Name | Notes |
|--------|------|-------|
| Window | NDIS Audit Tool | Findings tabs + Open & Fix |
| Process | Open & Fix | `AbERP_Compliance_OpenSource` |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Menu | Organisation Audit / Audit Hub | Folder + window leaf |
