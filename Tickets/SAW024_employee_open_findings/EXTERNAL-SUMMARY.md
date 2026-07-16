# SAW024 — Employee Open Findings (external summary)

## What’s done

On **NDIS Audit Tool → Employee**, admins can open **Open Findings**: each row shows why the check failed, what to do, and Zoom Across to the **Credential Assignment** to fix it.

## What changed

- New child tab **Open Findings** (Employee findings only)
- Rule resolve text on the three Employee credential rules
- Credential Assignment window bound on the credential-assignment table for Zoom

## Impact

Workforce compliance issues are actionable from the audit hub without hunting through Info Windows first.

## How to test

1. Admin → **NDIS Audit Tool** → **Employee** → **Open Findings**
2. Read **Why** and **What to resolve**
3. Select a row → **Open Assignment** field zoom → Credential Assignment
4. After a fix, **Refresh Compliance** and confirm the list updates

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Window | Credential Assignment | — |
