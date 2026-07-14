# com.aberp.leave.planning

AbilityERP pack for **SAW016 Leave Planning**.

| Layer | Contents |
|-------|----------|
| SQL | Info Window + Support Location (roster) + summary funcs + Search non-neg harden |
| JAR | Banner, Export CSV, status colours, Support Location EXISTS filter, Intbox sanitize |

## Install

```bash
# On host (preferred after rebuild):
bash redeploy-hco.sh
```

See `Tickets/SAW016_leave_planning/DEPLOY.md` for first-time vs incremental SQL order and smoke.

## Fixed UUs (AbERP-owned)

| Object | UU |
|--------|-----|
| Info Window Leave Planning | `16a016iw-c0d4-4f01-8e15-000000000001` |
| Support Location val rule | `16a01606-c0d4-4f01-8e15-000000000001` |
| Table AbERP_Leave_Planning | `16a01601-c0d4-4f01-8e15-000000000001` |
| Window (retired) | `16a01602-c0d4-4f01-8e15-000000000001` |
| Menu | `16a01605-c0d4-4f01-8e15-000000000001` |
| Report process | `16a01608-c0d4-4f01-8e15-000000000001` |

## Current bundle

`1.0.0.2026071402` — Support Location Search (no Table Direct Intbox `-1` popup).
