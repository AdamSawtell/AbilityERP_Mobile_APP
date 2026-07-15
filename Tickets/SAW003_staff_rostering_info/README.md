# SAW003 — Staff Rostering Info Window

| | |
|--|--|
| **Status** | done (ready for agent deploy) |
| **Kind** | idempiere |
| **GitHub** | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) |
| **Slug** | `SAW003_staff_rostering_info` |
| **JAR** | `com.aberp.rostering.staffinfo_1.1.0.2026071510.jar` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — full `./deploy.sh` or **JAR-only** update to `1510`, SQL order, smoke, pitfalls.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — paste into the customer/external ticket (not for agents).

## Goal

Rewrite **Employee (User) / Agency Staff Rostering Info** used on **Shift (Rostered) → Employee**: lean query, leave/overlap + needs-match in Java, UX wildcards, Related Info, org/BP callouts, decluttered result grid, **Show Unmatched** credential multi-select (AND) with Find + two-column layout.

## Source of truth

- `idempiere-plugins/com.aberp.rostering.staffinfo/`

## Dependencies (app)

None.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`
