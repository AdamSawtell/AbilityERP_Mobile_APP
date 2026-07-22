# SAW003 — Staff Rostering Info Window

| | |
|--|--|
| **Status** | done (ready for agent deploy) |
| **Kind** | idempiere |
| **GitHub** | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) |
| **Slug** | `SAW003_staff_rostering_info` |
| **JAR** | `com.aberp.rostering.staffinfo_1.1.0.2026072214.jar` (~52 KB) |
| **SQL** | through **`26`** |

## Deploy (other builds)

**→ [`AGENT-READY.md`](AGENT-READY.md)** — short handoff for another agent  
**→ [`DEPLOY.md`](DEPLOY.md)** — full `./deploy.sh` or JAR-only + SQL order, smoke, pitfalls

Prebuilt JAR in git:  
`idempiere-plugins/com.aberp.rostering.staffinfo/release/com.aberp.rostering.staffinfo_1.1.0.2026072214.jar`

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — paste into the customer/external ticket (not for agents).

## Goal

Rewrite **Employee (User) / Agency Staff Rostering Info** (Shift → Employee Find & Fill): lean query; filter ticks — **Show Matched**, **Not Rostered**, **Not On Leave**, **Show Familiar Staff** (all default on); credential AND when Matched unticked; Related Info on single-select; Partner Location suburb; lean grid.

## Source of truth

- `idempiere-plugins/com.aberp.rostering.staffinfo/`

## Dependencies (app)

None.

## Packs

- Git release JAR: `idempiere-plugins/com.aberp.rostering.staffinfo/release/…2214.jar`
- Optional zip folders: `Downloads\AbilityERP-*-SAW003_staff_rostering_info-*/` (refresh to `2214` + SQL `26` when shipping)
