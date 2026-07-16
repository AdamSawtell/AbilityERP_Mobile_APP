# SAW024 — Employee Open Findings (external summary)

## What’s done

On **Organisation Audit → Employee**, **Open Findings** sits as a **sub-tab under Employee**. Each row shows why the check failed, what to do, the related Credential Assignment **Value**, and **Open & Fix Source** opens that assignment so you can renew/update and clear the issue on the next Refresh.

## What changed

- Open Findings nested under Employee (Included tab + TabLevel 2)
- **Assignment** column shows the Credential Assignment Value
- **Open & Fix Source** process (`AbERP_Compliance_OpenSource`) opens that Credential Assignment
- Menu folder **Organisation Audit** → **Audit Hub** opens the NDIS Audit Tool window (plus Compliance Rules / Results)

## Impact

Workforce compliance issues are actionable from the Employee KPI view without leaving the audit hub.

## How to test

1. Admin → menu **Organisation Audit** → **Audit Hub** → **Employee**
2. Open the **Open Findings** sub-tab
3. Confirm **Assignment** shows a Value (not blank / not `-1`)
4. Select a row → toolbar **Process** → **Open & Fix Source** → Credential Assignment opens
5. Update expiry → Save → **Refresh Compliance** and confirm the list updates

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit (folder) | — |
| Menu | Audit Hub | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix Source | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |
