# com.aberp.compliance — NDIS Audit Tool / Compliance & Audit Hub (SAW023)

## Phase status

| Phase | Status |
|-------|--------|
| 1 Skeleton (tables, AD, NDIS Audit Tool + tabs, Rules window) | done |
| 2 Refresh process + OSGi | in progress (stub) |
| 3 Category views + rule engine (Employee first) | deferred |
| 4 Info Window + packs | deferred |

## Build / deploy (dev host)

```bash
chmod +x build.sh deploy.sh
./deploy.sh
```

## Process

| Name | Search key | Class |
|------|------------|-------|
| Refresh Compliance | `AbERP_Compliance_Refresh` | `com.aberp.compliance.RefreshCompliance` |

## Ticket

[`Tickets/SAW023_compliance_audit_hub/`](../../Tickets/SAW023_compliance_audit_hub/)
