# SAW024 — Deploy

## Hosts

| Env | Host |
|-----|------|
| Dev | `3.27.207.215` |

Prerequisite: SAW023 installed (NDIS Audit Tool + Employee rules + Refresh).

## JAR

None — AD / SQL only.

## SQL

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f idempiere-plugins/com.aberp.compliance/sql/18-employee-open-findings.sql
```

Then WebUI **Cache Reset**, logout/in as Admin.

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Window | Credential Assignment | — |

No new window/process. Child tab inherits NDIS Audit Tool window access. Credential Assignment must remain role-accessible for Zoom Across.

## Smoke

1. NDIS Audit Tool → Refresh Compliance (if needed)
2. Employee → **Open Findings**
3. Confirm Why / What to resolve / Employee columns
4. Select a row → use **Open Assignment** field zoom (not toolbar Zoom Across) → Credential Assignment
5. Fix expiry (optional) → Refresh → finding clears or updates
