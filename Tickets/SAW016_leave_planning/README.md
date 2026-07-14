# SAW016 — Leave Planning

| | |
|--|--|
| **Status** | in-progress — use [`DEPLOY.md`](DEPLOY.md) for HCO / client redeploy |
| **Kind** | idempiere |
| **GitHub** | [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16) |
| **Slug** | `SAW016_leave_planning` |
| **JAR** | `com.aberp.leave.planning_1.0.0.2026071402.jar` |
| **Environment** | HCO Test `32.236.127.117` |

## Deploy (agents)

**[`DEPLOY.md`](DEPLOY.md)** is the full handoff. On HCO after a server rebuild:

```bash
# upload plugin, then:
bash /opt/idempiere-server/AbERP/com.aberp.leave.planning/redeploy-hco.sh
# Cache Reset → Leave Planning smoke
```

## External ticket

See [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md).

## Goal

Workforce **Leave Planning** Info Window: planning period + optional **Support Location** (rostered site, not home address), overlapping leave from `AbERP_Unavailability_Leave`, status banner + colours, Zoom to existing submit/approve, Export CSV.

## Source of truth

- `idempiere-plugins/com.aberp.leave.planning/`

## Dependencies (app)

None.
