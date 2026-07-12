# SAW012 — Notes

## HCO discovery (2026-07-12)

### Table sizes (live / estimate)

| Table | n_live_tup | pg_class est | Size | IsHighVolume |
|-------|-----------:|-------------:|-----:|:------------:|
| AD_PInstance | 70,931,951 | ~69M | 28 GB | **N** |
| AD_ChangeLog | 2,354,796 | ~32M | 14 GB | Y |
| AD_Issue | 816,279 | ~13M | 12 GB | N |
| AD_Session | 13,384 | ~424k | 291 MB | **N** |
| AD_PInstance_Log | 105,144 | ~1M | 265 MB | N |
| AD_PInstance_Para | 9,462 | ~283k | 105 MB | N |

### Window AD (core UUs — do not change on HCO)

| Window | AD_Window_UU | Tab | Table | WhereClause | MaxQueryRecords | Search cols |
|--------|--------------|-----|-------|-------------|-----------------|-------------|
| Process Audit | `e91594d7-0b31-406b-9c35-8cb9ea2abc04` | Process Audit | AD_PInstance | *(empty)* | 0 | **none** |
| Session Audit | `b5043d5c-1741-4da0-b261-81936e28d9c5` | Session Audit | AD_Session | *(empty)* | 0 | **none** |

No indexes on `created` for `ad_pinstance` / `ad_session` / `ad_changelog`.

### Growth driver

Of the last ~50k `AD_PInstance` rows by ID, **49,991** were `ChuBoe_Validate_Document` (Document Validation — `com.chuboe.validation.base.process.ValidateDocument`). Duplicate Value also exists: `AbERP_Validate_Document`.

HouseKeeping jobs exist only for **T_*** report spool tables (last run 2026-07-09). Nothing purges AD_PInstance / AD_Session / AD_ChangeLog / AD_Issue.

`SYSTEM_INSERT_CHANGELOG` = `K` (keep).

## Recommended approach (core only — no ChuBoe JAR change in this ticket)

### Tier A — make windows usable immediately (AD)

1. Set **IsHighVolume = Y** on `AD_PInstance` and `AD_Session` (forces Find before query — same pattern as ChangeLog).
2. Set **MaxQueryRecords** = 200 (or 500) on Session Audit + Process Audit main tabs.
3. Set **OrderByClause** = `Created DESC`.
4. Enable **IsSelectionColumn** on useful Find fields:
   - Process Audit: Created, AD_Process_ID, AD_User_ID, Result, IsProcessing
   - Session Audit: Created, Remote_Addr, Processed, LoginDate (and AD_User_ID if present)
5. Optional default tab WhereClause: last 30 days only — **prefer High Volume Find** so older rows remain reachable.

### Tier B — query speed (DB)

1. `CREATE INDEX CONCURRENTLY` on `ad_pinstance (created DESC)`.
2. `CREATE INDEX CONCURRENTLY` on `ad_session (created DESC)`.
3. `CREATE INDEX CONCURRENTLY` on `ad_changelog (ad_session_id, created DESC)` if missing (child tab under session).

### Tier C — shrink and stop re-bloating (retention)

1. Add `AD_HouseKeeping` rows (System client) for:
   - AD_PInstance (+ cascade para/log via FK or explicit child delete) older than **N days**
   - AD_ChangeLog older than **N days**
   - AD_Session older than **N days** (after changelog purge)
   - AD_Issue older than **N days** (optional)
2. Schedule weekly HouseKeeping.
3. One-time **batched** DELETE on HCO/Prod for rows older than N (never one giant delete).

**Decision needed:** retention N (suggest **90 days** for Process Audit / ChangeLog; **180 days** for Session if login history matters longer).

### Out of scope / follow-up (not required for usable windows)

- Stop or throttle Document Validation writing an `AD_PInstance` on every document touch (ChuBoe plugin behaviour). Without this, Process Audit will refill after purge.
- Changing `SYSTEM_INSERT_CHANGELOG` from `K` (business decision — reduces Change Audit detail).

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| SSH | `ubuntu@32.236.127.117` · key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| Process Audit UU | `e91594d7-0b31-406b-9c35-8cb9ea2abc04` |
| Session Audit UU | `b5043d5c-1741-4da0-b261-81936e28d9c5` |
| AD_PInstance table_id (seed hint) | 282 — resolve by name |
| AD_Session table_id (seed hint) | 566 — resolve by name |
