# SAW015 — Skip Dates: Copy Dates From

| | |
|--|--|
| **Status** | in-progress (HCO Test installed + WebUI smoke pass; **agent deploy-ready**; UAT pending) |
| **Kind** | idempiere |
| **GitHub** | [#15](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/15) — issue body has full Deploy section |
| **Slug** | `SAW015_skip_dates_copy_from` |
| **HCO host** | `32.236.127.117` (same as SAW012) |

## Deploy (other builds) — start here

**→ [`DEPLOY.md`](DEPLOY.md)** — complete agent install runbook (JAR + ordered SQL + Admin grants + smoke + packs).

GitHub issue **Deploy** section mirrors that runbook.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

On **Skip Dates** (`AbERP_Skip_Dates`), **Copy Dates From** copies all `AbERP_Dates` lines from a selected source header into the current header — with a date-review warning and a copy count. Same UX approach as Service Booking **Copy Lines**.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.skipdates.copyfrom/`
- Class: `com.aberp.skipdates.copyfrom.CopyDatesFrom`
- AD: `sql/01-install-copy-dates-from.sql`

## Dependencies (app)

None.

## Packs

- `AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-20260713`
- Thin prod: `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-20260713`
