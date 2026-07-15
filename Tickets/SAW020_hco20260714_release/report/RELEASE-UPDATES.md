# HCO20260714 — Post dry-run release updates

Apply these **after** (or folded into) the baseline dry-run install in [`DEPLOYMENT-REPORT.md`](DEPLOYMENT-REPORT.md) when preparing the next **HCO Production** release.

**Dry-run host:** `54.253.165.194`  
**Baseline dry run:** 2026-07-14 (SAW018 → SAW017 initial)

---

## Update order (Production fold-in)

| Seq | Ticket | Type | From → To | Host evidence |
| ---: | ------ | ---- | --------- | ------------- |
| U1 | SAW003 | JAR-only | staffinfo `1237` → **`1.1.0.2026071516`** (~60 KB) | Applied 2026-07-15 on `54.253.165.194` |
| U2 | SAW017 | JAR-only | bulk `…132235` → **`7.1.0.202607160730`** (9039 bytes) | Applied 2026-07-16 on `54.253.165.194` |

Generator stack for SAW017 is unchanged from the dry run (keep patched generator):

1. `com.aberp.rosteredshift.model_7.1.11.202509171959.jar`
2. `com.aberp.process.GenerateShifts_1.1.7.202508141623.jar`
3. `com.aberp.generic.utilities_7.1.4.202510091525.jar`
4. `com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar`

---

## U1 — SAW003 Staff Rostering Info

| | |
|--|--|
| Runbook | `Tickets/SAW003_staff_rostering_info/DEPLOY.md` § JAR-only |
| Ship JAR | `com.aberp.rostering.staffinfo_1.1.0.2026071516.jar` |
| Repo copy | `idempiere-plugins/com.aberp.rostering.staffinfo/release/…1516.jar` |
| SQL | **Skip** if `01`–`24`→`04` already applied |
| Restart | Yes (stop → kill leftover equinox if needed → start) |
| What changed | Four default-on filter ticks (Matched / Not Rostered / Not On Leave / Familiar); credential AND on Matched off; scoped North expand |

`bundles.info`:

```text
com.aberp.rostering.staffinfo,1.1.0.2026071516,plugins/com.aberp.rostering.staffinfo_1.1.0.2026071516.jar,4,true
```

---

## U2 — SAW017 Bulk Generate Bookings

| | |
|--|--|
| Runbook | `Tickets/SAW017_booking_generator_bulk/DEPLOY.md` § JAR-only upgrade |
| Ship JAR | `com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` |
| Ticket jar/ | `Tickets/SAW017_booking_generator_bulk/jar/…160730.jar` |
| Thin pack | `Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260716\` |
| Full pack | `Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260716\` |
| SQL | **Skip** if `00`–`04` already applied (re-run `04-verify` optional) |
| Restart | Yes |
| Dependencies | Generator stack above — install only if Generate Bookings not ACTIVE |
| What changed | Process dialog summary: run header + per-row **BP / Invoice Partner / Target DocType** + SB `DocumentNo` + totals |

`bundles.info`:

```text
com.aberp.bookinggenerator.bulk,7.1.0.202607160730,plugins/com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar,4,true
```

Remove any older `com.aberp.bookinggenerator.bulk,…` line before appending.

Do **not** install historical bulk JARs `…132235` or `…160715` on a new Production cut.

---

## Production checklist add-on

After baseline HCO20260714 install:

- [ ] Apply U1 SAW003 JAR `1516` + restart + WebUI smoke filters / Familiar  
- [ ] Apply U2 SAW017 JAR `160730` + restart + smoke Bulk summary columns  
- [ ] Confirm `bundles.info` has no stale staffinfo / bulk lines  
- [ ] Cache Reset or re-login  
- [ ] Append outcome to `Tickets/HCO_Deployment/LEARNINGS.md`

---

## Recorded on dry-run host `54.253.165.194`

| Date | Update | Result |
|------|--------|--------|
| 2026-07-15 | SAW003 → `1516` | PASS · WebUI 200 |
| 2026-07-16 | SAW017 → `160730` | PASS · `04-verify` green · WebUI 200 · generator stack unchanged |
