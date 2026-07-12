# SAW012 — External summary (customer / ticket paste)

## Status (HCO Test — 12 Jul 2026)

| Area | Status |
|------|--------|
| Window usability (Find-first / High Volume) | **Done and WebUI-tested** |
| 90-day HouseKeeping schedule | **Done** (configured; daily) |
| Supporting DB indexes | **Partial** — Session index valid; Issue/Process indexes still building or interrupted on large tables |
| One-time data purge (shrink 28 GB+ history) | **Not finished on HCO yet** — script ready; must run off-peak and re-run until complete |
| Formal before/after timing benchmark | **Not done** — see “Performance evidence” below |
| Prod update pack | **Ready to apply** (same SQL as HCO) |

**Bottom line for the ticket:** Session Audit and Process Audit are usable again on HCO Test (open → Find → search → capped results). Full disk/size recovery and peak query speed still depend on finishing indexes + the 90-day purge on each host (HCO then Prod).

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Session Audit | Window (core) | Find-first (High Volume); search fields; max 200 rows; sort Created DESC |
| Process Audit | Window (core) | Find-first (High Volume); search fields; max 200 rows; sort Created DESC |
| AD_PInstance, AD_Session, AD_Issue | Tables | Marked High Volume; Created indexes (in pack) |
| AD_ChangeLog | Table | Supporting session/Created index (in pack) |
| House Keeping | Config + daily schedule | 90-day retention for PInstance / ChangeLog / Session / Issue |
| DB helper functions | PostgreSQL | FK-safe purge (will not cascade-delete orders/shifts) |

## What’s done

On **HCO Test** (`32.236.127.117`):

1. **Usability fix (live):** Both audit windows open to a **Lookup / Find** screen instead of trying to load the whole table (Process Audit had ~71 million rows / ~28 GB).
2. **Search fields enabled:** Created, Process, User, Result, Processing (Process Audit); Created, Remote Addr, Processed, Login date (Session Audit).
3. **Result cap:** Max 200 rows per query (newest first).
4. **Retention:** Daily HouseKeeping configured for **90 days**.
5. **Prod pack prepared:** same steps recorded for later Prod install.

## What changed (behaviour)

- Opening Session Audit / Process Audit no longer attempts to load entire history.
- Users search first, then see up to 200 matching rows.
- After purge + ongoing HouseKeeping, history older than 90 days is removed.
- Rows still linked to orders / rostered shifts are **not** deleted.

## Performance evidence (tested vs not)

### Tested on HCO (WebUI)

| Test | Result |
|------|--------|
| Open **Process Audit** / **Session Audit** | Find (Lookup Record) appears — **pass** |
| Session Audit after Find | Loads with record cap (e.g. 1/200) — **pass** |
| **Next/Previous between records** | **Initially not tested** — user reported still slow. Root cause: child tabs (Change Audit / Parameter / Log) had unlimited MaxQueryRecords, and Process Audit still counted/loaded Document Validation flood. **Mitigations applied:** child tabs capped at 200; Process Audit default WhereClause excludes Document Validation processes; ChangeLog session index building. |

### Not yet proven

- Timed next/prev after ChangeLog index completes and Cache Reset.
- Table size reduction (purge still pending; ~28 GB AD_PInstance remains).

## Impact

Admins and support staff using Session Audit / Process Audit. No change to operational documents (orders, timesheets, rostering).

## How to test (any build after pack)

1. Cache Reset (or re-login).
2. Open **Process Audit** → Find must appear → set Created (e.g. last 7 days) → OK → results within seconds, ≤200 rows.
3. Open **Session Audit** → same Find behaviour.
4. After purge: confirm table sizes drop and Find remains fast for date-bounded searches.

## Access

AbilityERP Admin / System Admin keep access to these core windows. No new menu.

## Prod install (recorded)

| Pack | Path |
|------|------|
| Staging / full | `Downloads\AbilityERP-ClientUpdate-SAW012_session_process_audit_perf-20260712` |
| Thin Prod | `Downloads\AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-20260712` |

Follow `HOW-TO.txt` / `HOW-TO-UPDATE.md`: apply SQL → run indexes off-peak → Cache Reset → re-run batched purge until 0 deleted → verify.

## Caveats

- Finishing indexes and purge on Prod should be **off-peak** (large tables).
- Document Validation still writes many process-instance rows; 90-day retention bounds growth. Reducing that write volume is a separate follow-up.
- Do **not** run a naive `DELETE FROM AD_PInstance` — can cascade-delete orders. Use the pack scripts only.
