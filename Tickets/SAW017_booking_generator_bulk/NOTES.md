# SAW017 — Design notes & approach

## Requirements snapshot

Manual BG → SB loop (~206 lines): set dates → Generate Bookings → edit Description → check Invoice Rule Immediate → next. Pain: 3–4 hours uninterrupted. Prefer 2–3 months generated at a time.

Must support:

1. **Blocks + ticks** (SIL / DO / IHS / etc.) — not only “generate all”
2. **Irregular Hrs / Short Term Respite** off by default; generate when needed
3. **Run-level dates** (one period for the block) **and** per-BG date override
4. **Standards only** — exclude Quotes, POS, templates
5. **Invoice Rule** preserved / set (e.g. Immediate) on generate
6. Skip: waiting on plan; Day Options / Tri-States as appropriate; client exit in current month (no next-month SB)
7. Fallback: bulk Standards then deactivate/delete unwanted SBs

---

## How other generators work (repo + host evidence)

### Finding

**Invoice / roster / timesheet / Generate Bookings Java sources are not in this git repo.** They ship as proprietary Flamingo/Logilite OSGi JARs under the iDempiere host (`customization-jar/` / plugins). This repo has the data model, adjacent plugins, and AD discovery only.

### Confirmed bulk-style process (AD discovery)

| AD name | Value | Classname | Notes |
|---------|-------|-----------|--------|
| AbERP Generate Timesheets | `Timesheet_Generate` | `com.aberp.process.GenerateTimesheets` | Same `com.aberp.process.*` family expected for invoice/roster |

### Booking Generator → Service Booking (current)

| Piece | Detail |
|-------|--------|
| Window | Booking Generator (`de336034-bd4e-4445-b018-9c762c98d847` seed) |
| Header table | `AbERP_BookingGenerator` / `aberp_bookinggenerator` |
| Pattern tab | `AbERP_ServicePattern` |
| Audit tabs | Process Audit + Parameter Audit on BG → Generate Bookings is a **parameterized process** |
| Target | Service Booking = customised `C_Order` with `aberp_bookinggenerator_id` |
| Related JAR (line) | `com.aberp.createbooking.process` = **AbERP Create Booking** on `C_OrderLine` (not the header Generate Bookings) |
| Post-generate | SAW009: Generate Bookings sets `AbERP_ServicePattern_ID` on lines; support-day trigger can sync |

### Useful flags already on Service Booking / BG path

| Column | Use for bulk filters |
|--------|----------------------|
| `AbERP_IsTemplate` | Exclude templates |
| `AbERP_IsProgramOfSupports` | Exclude POS |
| `InvoiceRule` | Force / preserve Immediate where required |
| Skip Dates (`AbERP_Skip_Dates` / `AbERP_Dates`) | Exclusion calendars (SAW015) |

### In-repo patterns to copy (not the generators themselves)

| Pattern | Where | Apply to SAW017 |
|---------|--------|-----------------|
| `SvrProcess` + Search param + toolbar button `B` + Admin grants | SAW015 `com.aberp.skipdates.copyfrom` | New bulk process AD install |
| Info Window + multi-select process | SAW010 Timesheet Approval Info | Optional block picker / tick UI |
| UU-safe AD SQL, never hardcode `AD_*_ID` | Client update rules | All migrations |
| Delegate, don’t rewrite | Prefer calling existing Generate Bookings per selected BG | Stability + same SB shape |

---

## Recommended approach

### Phase 0 — Host discovery (blocking)

On a build that has Generate Bookings + Generate Timesheets JARs (seed or HCO Test):

1. Dump processes:
   ```sql
   SELECT value, name, classname, ad_process_uu
   FROM ad_process
   WHERE classname ILIKE '%Generate%'
      OR name ILIKE '%Generate%'
      OR name ILIKE '%Booking%'
   ORDER BY 1;
   ```
2. Dump paras for Generate Bookings + Generate Timesheets / Invoice / Roster.
3. List JARs: `*generate*`, `*booking*`, `*createbooking*` under plugins + customization-jar.
4. `javap` / decompile entry classes — find public API to invoke single-record generate from a bulk loop.
5. Capture how the live “Standards” query filters (Description keyword vs Activity vs DocType vs custom flag).

**Do not design the final filter set until this query logic is confirmed with ops.**

### Phase 1 — BG record attribute (likely)

Add a portable column on `AbERP_BookingGenerator`, e.g.:

- `AbERP_BG_Type` list: Standard / Quote / POS / Template / Irregular / ShortTermRespite / …, **or**
- `AbERP_IncludeInBulkGenerate` Yes/No (default Y for Standards only after data cleanup)

Prefer a **type/category** if POS/Quotes must stay active for other workflows but stay out of bulk. Confirm with Amber/Jason whether Description-keyword “Standard” is enough or too fragile.

### Phase 2 — Bulk process UX (align with Generate Timesheets)

**Preferred:** Info Window or window process on Booking Generator:

| Parameter | Behaviour |
|-----------|-----------|
| Date From / Date To (or Period) | Applied to all selected rows unless row override |
| Use BG dates if set | Optional: if BG start/end already set, keep them; else apply run dates |
| Activity / Block | Filter SIL, DO, IHS, … |
| Include Irregular / STR | Default N |
| Invoice Rule | Default Immediate (or “preserve from BG/SB template”) |
| Selection | Multi-tick rows **or** “all matching filter” |

**Process logic:**

1. Resolve candidate BG IDs (block + ticks + Standards filter + Include flag).
2. Apply exclusion rules (waiting on plan, exit date, Day Options/Tri-States guidance).
3. For each BG: temporarily apply run dates if needed → call **existing** Generate Bookings → restore dates if temporarily changed → set Invoice Rule on new SB.
4. Log success/skip/fail counts on `AD_PInstance` (reuse BG audit tabs pattern for per-record runs if still used).

### Phase 3 — Exclusions

| Scenario | Implementation idea |
|----------|---------------------|
| Non-Standards | Type flag / Standards query parity |
| Waiting on plan | Flag or status on BG / linked plan line — confirm field with discovery |
| Day Options / Tri-States | Exclude via type or inactive; process warning list |
| Client exit | Skip if `aberp_date_support_ceased` (or equivalent) falls in current month when generating next month |

### Phase 4 — Fallback

If multi-tick + blocks slips schedule: ship **Standards-only bulk with run dates + Invoice Rule**, plus documented deactivate/delete of unwanted SBs. Still deliver Include/type flag so POS/Quotes stay out.

### Phase 5 — Staging loop + packs

Follow client-update staging loop on reachable non-prod → WebUI smoke with ops → ClientUpdate + ProdUpdate packs named `SAW017_…`.

---

## Design decisions still open

1. Exact Standards filter (query SQL vs new BG column).
2. Block dimension: Activity, service line, location, or custom list?
3. Can Flamingo expose Generate Bookings as a callable API, or must we duplicate logic?
4. Invoice Rule: always force Immediate vs copy from BG?
5. Description month/year: leave manual vs optional post-process?
6. Vendor estimate / deploy cycle (Logilite capacity).

---

## Separate issues (not blocking)

- Invoice Partner on BG copy reverts to client name.
- Optional Description month/year automation.

---

## HCO Future Deployments variables

_(Fill after first HCO install — never change existing HCO `*_UU`.)_
