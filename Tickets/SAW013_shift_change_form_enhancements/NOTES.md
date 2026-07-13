# SAW013 — Notes

## Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Auto Status | Physical `R_Status_ID` + AFTER trigger on `R_Request` | Virtual ColumnSQL caused **Timeout loading row 1** on 3.8k-row grid |
| Submitted visibility | Physical `AbERP_RequestSubmitted` + same sync trigger | Option A — clear on main window; grid-safe |
| Duplicate prevention | DisplayLogic hide Create + BEFORE INSERT trigger | Option B + hard block |
| JAR | None | Logilite process kept |
| Historical duplicates | Leave in place | Cleanup separate |
| Template popup match | New AbERP val rule on process para only | Shared `R_Request Template` rule also used by mapping tables — do not change it |

## HCO discovery (2026-07-13)

- Window **HCO Forms and Approvals** UU `b3919637-5125-4d2d-a9f7-6d751835f537`
- Ticket’s `AbERP_ShiftChange_ID = 1000008` is not the window ID on HCO (Relationship Type uses 1000008)
- ~1268 status mismatches before backfill; after backfill sample `1003753` = Pending - With Service Development / Submitted Y
- Virtual ColumnSQL first attempt failed AccessSqlParser / then 30s GridTable timeout

## Smoke results (HCO Test 2026-07-13)

| Check | Result |
|-------|--------|
| SQL install + verify | Pass |
| Dup INSERT trigger | Pass (blocked with clear message) |
| Cache Reset | Pass |
| WebUI grid load (no timeout) | Pass — 3826 rows / physical Status column |
| Status matches Requests child | Pass — Doc `1003753` Pending matches Requests tab |
| WITH request Create hidden | Pass — Submitted checked RO; Create not shown |
| WITHOUT request Create visible | Pass — Doc `1003729` Submitted unchecked; Status blank; Create shown; Requests 0 |
| WebUI save (no Status/Submitted corruption) | Pass — toggled Active on `1003753`, Record saved; DB `updated` advanced; Status/Submitted unchanged; Active restored |
| Create popup template matches window type | Pass — `1003729` Additional Shift → popup defaults/lists only Additional Shift; `1003444` HCO Unserviced → only HCO Unserviced |

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| SSH | `ubuntu@32.236.127.117` · key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| Window UU | `b3919637-5125-4d2d-a9f7-6d751835f537` |
| Table UU | `136fd0b7-e2b0-40a1-846f-1e198b8c232d` |
| Main tab UU | `a22481e4-c47f-43e3-ab9e-6c54a31ce2a1` |
| Requests tab UU | `f1d2db08-9c6a-4134-8dfc-6eeeb0cc67db` |
| Element UU (new) | `a0130001-5a01-4e13-a013-000000000001` |
| Column UU (new) | `a0130002-5a01-4e13-a013-000000000002` |
| Field UU (new) | `a0130003-5a01-4e13-a013-000000000003` |
| Create process Value | `CreateRequestFromTemplate` |
| Create process UU | `3a8e1690-80f7-41b5-9ed9-96f5f3796823` |
| Triggers | `aberp_shiftchange_sync_from_request_trg`, `aberp_shiftchange_prevent_dup_request_trg` |
