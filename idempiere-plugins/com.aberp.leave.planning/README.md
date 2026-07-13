# com.aberp.leave.planning

AbilityERP pack for **SAW016 Leave Planning**.

| Layer | Contents |
|-------|----------|
| SQL | Info Window + readonly grid + summary functions |
| JAR | `LeavePlanningInfoWindow` summary banner + criteria stay editable |

## Install order

1. Existing AD SQL (`00`…`13`) if not already applied  
2. `14-info-readonly.sql`  
3. `15-info-summary-functions.sql`  
4. Build/deploy JAR (`build.sh` / `deploy.sh`) — OSGi console or `plugins/` + `bundles.info`  
5. Cache Reset / re-login  

See `Tickets/SAW016_leave_planning/DEPLOY.md`.

## Fixed UUs (AbERP-owned)

| Object | UU |
|--------|-----|
| Info Window Leave Planning | `16a016iw-c0d4-4f01-8e15-000000000001` |
| Table AbERP_Leave_Planning | `16a01601-c0d4-4f01-8e15-000000000001` |
| Window (retired) | `16a01602-c0d4-4f01-8e15-000000000001` |
| Menu | `16a01605-c0d4-4f01-8e15-000000000001` |
| Report process | `16a01608-c0d4-4f01-8e15-000000000001` |
