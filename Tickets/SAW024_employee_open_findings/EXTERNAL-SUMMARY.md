# SAW024 — Employee Open Findings (external summary)

## What’s done

On **NDIS Audit Tool → Employee**, **Open Findings** sits as a **sub-tab under Employee**. Each row shows why the check failed, what to do, and **Open & Fix** opens the **Credential Assignment** so you can renew/update and clear the issue on the next Refresh.

## What changed

- Open Findings nested under Employee (Included tab + TabLevel 2)
- **Open & Fix Source** process (`AbERP_Compliance_OpenSource`) zooms to the Credential Assignment
- **Open Assignment** column zooms to the same source record so you can edit and save
- Physical parent link on compliance results for reliable nesting

## Impact

Workforce compliance issues are actionable from the Employee KPI view without leaving the audit hub.

## How to test

1. Admin → **NDIS Audit Tool** → **Employee**
2. Open the **Open Findings** sub-tab
3. Read **Why** and **What to resolve**
4. Click **Open & Fix** → Credential Assignment → update expiry → Save
5. **Refresh Compliance** and confirm the list updates

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix Source | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |
