# SAW003 — Staff Rostering Info Window

| | |
|--|--|
| **Status** | done (ready for agent deploy) |
| **Kind** | idempiere |
| **GitHub** | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) |
| **Slug** | `SAW003_staff_rostering_info` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — agent one-liner, SQL order, packs, smoke.

## Goal

Rewrite **Employee (User) / Agency Staff Rostering Info** used on **Shift (Rostered) → Employee**: lean query, leave/overlap + needs-match in Java, UX wildcards, Related Info, org/BP callouts.

## Source of truth

- `idempiere-plugins/com.aberp.rostering.staffinfo/`

## Dependencies (app)

None.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`
