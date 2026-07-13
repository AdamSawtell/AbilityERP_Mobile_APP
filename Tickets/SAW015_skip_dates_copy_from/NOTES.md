# SAW015 — Notes

## Requirements snapshot

- Window: `AbERP_Skip_Dates` · Dates tab: `AbERP_Dates`
- Process: **Copy Dates From** — pick existing Skip Dates header → copy all date lines to current header
- Pattern reference: Service Booking copy-lines (`copyfromprocess` / Copy From)
- Warning (suggested):

  > The copied records contain specific dates. Please review all copied dates and update the year or individual dates where required before using this Skip Dates record.

- Report number of rows successfully copied; source unchanged; new IDs on target lines

## Discovery (TODO)

| Item | Notes |
|------|--------|
| Service Booking Copy From process | Classname, params, how source doc is selected, messages |
| Skip Dates window / tab / table UUs | Resolve by name/`tablename`; never hardcode IDs across clients |
| `AbERP_Dates` columns to copy | Date + any descriptive fields; exclude PK / parent FK (set to target) / audit |
| Button placement | Header toolbar vs button field (prefer same pattern as Service Booking) |

## Design decisions (pending discovery)

- Prefer Java `SvrProcess` in a **new** OSGi bundle (do not reuse an existing AbERP bundle symbolic name) if Service Booking uses Java copy-from.
- Fixed `AD_Process_UU` / element UUs for AbERP-owned objects; upsert by UU.
- Process parameter: TableDir / Search on Skip Dates table, excluding current record if practical.
- `showhelp` / confirm dialog for the date-review warning; `@Success@` / process log for copy count.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` (when installing on HCO) |
| WebUI | `http://32.236.127.117/webui/` |
| SSH | `ubuntu@32.236.127.117` · key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| Skip Dates window UU | TBD |
| Skip Dates table UU | TBD |
| Dates table UU | TBD |
| Copy Dates From process UU | TBD (AbERP-owned) |

## Smoke / blockers

_(none yet — scaffold only)_
