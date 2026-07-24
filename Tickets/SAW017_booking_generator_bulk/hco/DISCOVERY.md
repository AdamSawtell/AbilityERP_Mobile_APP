# SAW017 — HCO Phase 0 discovery results (2026-07-13)

Host: HCO Test `32.236.127.117` (same as SAW010). Raw outs under `hco/`.

## Verdict

| Item | Result |
|------|--------|
| Generate Bookings AD | **Present** — value `Generate Bookings`, UU `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b`, class `com.aberp.servicebooking.generator.process.GenerateBookings`, entitytype `U` |
| Generate Bookings JAR | **Missing** on HCO Test plugins + customization-jar (binary string search empty). Also **missing** on AbilityERP seed EC2. |
| Generate Timesheets / Shifts AD | Present (`com.aberp.process.GenerateTimesheets` / `GenerateShifts`, entitytype `Ab_ERP`) |
| Those JARs | **Also missing** on HCO Test + seed |
| Bulk can delegate today? | **No** — ClassNotFound until Flamingo/Logilite JAR is installed |
| Standards filter (ops) | User query **STANDARDS** on BG: `Description IN STANDARD` → in practice **~270** active rows with `description ILIKE 'STANDARD%'` |
| Block dimension | `C_Activity_ID` + Description tokens; monthly SB queries on `C_Order` (table 259) by Activity + DatePromised |

**Blocker for build/smoke:** obtain `com.aberp.servicebooking.generator.*` (and ideally `com.aberp.process.Generate*`) JARs from Flamingo/Logilite, install on HCO Test, then implement bulk wrapper.

---

## Peer generators (parameter patterns)

### Generate Bookings (single-record, window button)

| | |
|--|--|
| Button | `AbERP_GenerateBookings` on `AbERP_BookingGenerator` (`IsToolbarButton=B`) |
| Only process para | `DocAction` (mandatory, default `DR`) |
| Dates | Taken from BG `StartDate` / `EndDate` (no run-level date para today) |
| Invoice Rule | Column on BG: `InvoiceRule` (`I` Immediate 331 / `D` After Delivery 222) |
| Ready to Claim | `AbERP_Ready_Claim_Rule` — mostly `ATV` (Auto when Finished + Validated) |

### Generate Timesheets (menu-style bulk)

Paras: Client, DateFrom, DateTo, Roster Period, Status, Rostering Officer, Master Location (+ inactive BP/User paras).

### Generate Rostered Shifts (menu-style bulk)

Paras: Client, Status, Rostering Officer, Shift Template, **Roster Period** (mandatory), Target Shift Status.

**UX to copy for SAW017:** Timesheets/Shifts period-driven bulk (DateFrom/DateTo or Period) + selection filters — **not** the single DocAction dialog of Generate Bookings. Bulk process should set BG dates (or pass override) then invoke Generate Bookings per row.

No Info Window is bound to any Generate* process on HCO (`ad_infoprocess` empty for Generate*).

---

## BG filters already on HCO (no new column strictly required for v1)

| Column | Role |
|--------|------|
| `Description` | STANDARDS ≈ `ILIKE 'STANDARD%'`; Quotes ≈ `%Quote%`; block tokens `STANDARD DO`, `STANDARD SIL%`, `STANDARD IRR`, `STANDARD STR`, … |
| `C_Activity_ID` | Blocks: Day Program (DO), Programmed Supports, Demand-led, Board/Household, Short Term Accommodation (STR), … |
| `C_DocTypeTarget_ID` | `Service Booking - Standard` (288) vs `Non Binding Offer` (265) |
| `AbERP_IsProgramOfSupports` | POS flag (28 active) |
| `IsTemplate` | Template flag (0 active currently; descriptions still have `TEMPLATE 25/26`) |
| `InvoiceRule` | Preserve/force Immediate (`I`) on generate |
| `AbERP_Skip_Dates_ID` | Skip calendar link |
| `StartDate` / `EndDate` | Per-record period; bulk should overwrite for run then optionally restore |
| `Bill_BPartner_ID` | Invoice Partner (copy bug = out of scope) |

### Activity map (HCO IDs — resolve by **name** on other clients)

| Activity name | Value | Typical block |
|---------------|-------|----------------|
| Day Program | DP | DO |
| Programmed Supports | PRG | SIL / programmed |
| Demand-led Supports | DEM | Demand-led |
| Board / Household | HSH | SIL household |
| Short Term Accommodation | STA | STR |
| `*Do Not Use** …` | — | Exclude (Day Options / Tri-States / O&A / Weekenders / IHS legacy) |

### Ops saved queries (evidence)

| Query | Table | Intent |
|-------|-------|--------|
| **STANDARDS** | `AbERP_BookingGenerator` | Active + Description STANDARD* |
| DO / SIL / ADE / CP+IHS / STR … Bookings | `C_Order` (SB) | Month window + Activity / GroupSessions / Description — **post-generate SB views**, not BG select |

Irregular Hrs ≈ Description `STANDARD IRR%`. Short Term Respite / STA ≈ Activity Short Term Accommodation + `STANDARD STR`. Exclude from default bulk; opt-in flags on process.

---

## Recommended implementation (unchanged, sharpened)

1. **Install missing generator JAR(s)** on HCO Test (vendor deliverable). Confirm single-record Generate Bookings works.
2. New plugin `com.aberp.bookinggenerator.bulk`:
   - Paras: DateFrom, DateTo (or month), Activity (optional), Include Irregular (N), Include STR (N), Invoice Rule default `I`, optional tick list / “all matching”.
   - WHERE: active, `description ILIKE 'STANDARD%'`, not POS, not template, Activity not `*Do Not Use**%`, DocType Standard preferred.
   - Skip: BP `aberp_date_support_ceased` in current month when generating next month; optional inactive / waiting guidance.
   - Loop: set Start/End → `ProcessInfo` invoke `GenerateBookings` with DocAction DR → assert InvoiceRule on new `C_Order`.
3. Optional later: `AbERP_IncludeInBulkGenerate` if Description keyword proves fragile.
4. Staging loop + packs.

### Waiting on plan

No plan/wait columns on BG. Likely ops workflow (status/description/`STANDARD TRN (plan)`). Treat as **guidance + Description exclude list**, not a hard column, until ops names the field.

---

## HCO environment notes

- Window Booking Generator UU `de336034-bd4e-4445-b018-9c762c98d847` (local ID `1000163`).
- `ad_pinstance` queries by process name **time out** (huge table — SAW012); avoid full scans.
- WebUI menu tree showed “(Not available)” briefly after login (known flaky); SQL discovery used instead of button smoke.
- `bundles.info` on HCO Test only lists recent AbERP plugins (skipdates, staffinfo, leave.planning) — older customization JARs on disk are **not** all registered/active.

## Seed EC2 cross-check

`ec2-54-206-8-250…` (`54.206.8.250`) has `com.aberp.createbooking.process_*.jar` (line Create Booking) but **no** `servicebooking.generator` / `GenerateTimesheets` / `GenerateShifts` bytecode either.
