# SAW015 — Skip Dates: Copy Dates From

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#15](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/15) |
| **Slug** | `SAW015_skip_dates_copy_from` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — process + AD SQL (+ JAR if Java class); Admin process access; Cache Reset / restart as required.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — update when ready for customer paste.

## Goal

On **AbERP_Skip_Dates**, let users run **Copy Dates From** to copy all `AbERP_Dates` lines from an existing Skip Dates header into the current (saved) header — with a clear warning to review/update years and individual dates, and a count of rows copied.

## Approach (planned)

1. Discover Service Booking copy-lines (`Copy From` / `copyfromprocess`) and Skip Dates window/table/column UUs.
2. Add `AD_Process` **Copy Dates From** (parameter = source Skip Dates record).
3. Implement copy (Java `SvrProcess` preferred for transactional insert + message, mirroring Service Booking) or equivalent AD pattern if pure SQL is sufficient.
4. Toolbar/button on Skip Dates header; grant **AbilityERP Admin** (+ HCO **Admin**) process access by role name.
5. Staging install → WebUI smoke → packs → test UAT.

## Source of truth (as implemented)

- Plugin / SQL: TBD after discovery (`idempiere-plugins/com.aberp.skipdates.copyfrom/` or ticket `sql/`)
- Ticket notes: `NOTES.md`, `CHECKLIST.md`

## Dependencies (app)

None.

## Packs

- `AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-<YYYYMMDD>`
- Thin prod: `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-<YYYYMMDD>`
