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

## Design decisions (updated after HCO Phase 0)

1. **Standards filter:** use ops query parity — `IsActive=Y` AND `Description ILIKE 'STANDARD%'` (user query STANDARDS). Prefer also DocType **Service Booking - Standard**; exclude POS + Template + `*Do Not Use**` activities.
2. **Block dimension:** `C_Activity_ID` (Day Program = DO, etc.) + Description tokens (`STANDARD DO%`, `STANDARD SIL%`, `STANDARD IRR%`, `STANDARD STR%`).
3. **Callable API:** AD class is `com.aberp.servicebooking.generator.process.GenerateBookings` — **JAR missing on HCO Test and seed**. Must obtain from Flamingo/Logilite before bulk can delegate; do not reimplement blindly.
4. **Invoice Rule:** force/preserve `I` (Immediate) on generated SB; BG already stores InvoiceRule (331 Immediate / 222 After Delivery).
5. Description month/year: remain manual (out of scope).
6. Vendor: need generator JAR + estimate for bulk wrapper.

Full evidence: [`hco/DISCOVERY.md`](hco/DISCOVERY.md).

---

## Separate issues (not blocking)

- Invoice Partner on BG copy reverts to client name.
- Optional Description month/year automation.

---

## HCO Future Deployments variables

Recorded from HCO Test (`32.236.127.117`) on **2026-07-13**. **No HCO `*_UU` values changed**.

| Object | HCO value | Notes |
|--------|-----------|--------|
| Host (current Test) | `13.210.248.141` | Prefer this for ongoing SAW017 work |
| SSH | `ubuntu@13.210.248.141` · key `c:\Users\sawte\Documents\SSH Keys\HCObusiness.pem` | |
| WebUI | `http://13.210.248.141/webui/` · SuperUser / `HCOflamingo` · role **Admin** | |
| Host (prior E2E 2026-07-13) | `32.236.127.117` | Original SAW017 smoke host |
| DB | `idempiere` / `adempiere` / `flamingo` | |
| Window Booking Generator | UU `de336034-bd4e-4445-b018-9c762c98d847` · ID `1000163` (local) | Resolve by UU |
| Process Generate Bookings | UU `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b` · value `Generate Bookings` | Patched JAR `*-no-opp-dep.jar` |
| Process Bulk Generate Bookings | UU `17a01701-b017-4017-8017-000000000001` · value `AbERP_BG_BulkGenerateBookings` · local process ID `1000073` | |
| DocAction list | `BookingGen_DocList` UU `285220bc-9749-4c4b-978d-4674fad038cd` | **Required** — not core `_Document Action` (135) |
| Activity Short Term Accommodation | resolve by **name** · local ID `1000014` | STR smoke block |
| Activity Day Program | resolve by **name** · local ID `1000004` | DO |
| Bulk JAR | `com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` (per-row BP / Invoice Partner / Target DocType in summary; prior `…160715` / `…132235`) | |
| Generator JAR | `com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar` | |
| E2E single SB | `53324` / BG `1000910` (`2001124`) | Sep 2026 · InvoiceRule `I` · DR |
| E2E bulk SBs | `53325` (BG `1000393`), `53326` (BG `1000509`) | Bulk `ok=3` STR · InvoiceRule `I` |
| E2E evidence | [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md) | |

### Install order (future client / HCO)

Follow **[`DEPLOY.md`](DEPLOY.md)** (authoritative). Packs:

- `Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260714\`
- `Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260714\`

1. Install generator stack JARs (patched generator + deps) via OSGi console / `plugins` + `bundles.info` **only if** Generate Bookings not already ACTIVE
2. Install `com.aberp.bookinggenerator.bulk` JAR
3. SQL: `00-preflight.sql` → `01-install-bulk-generate.sql` → `02-fix-docaction-list.sql` → `03-fix-yesno-display.sql` → `04-verify.sql`
4. Cache Reset
5. Smoke per `hco/E2E-SMOKE-20260713.md` (use a clean future period)

---

## HCO smoke 2026-07-13 (E2E PASS)

- Single **Generate Bookings** on BG `2001124` (Sep 1–7) → SB **`53324`**, InvoiceRule Immediate, Draft.
- **Bulk Generate Bookings** STR Activity + Include STR + Sep 1–7 → `created/ok=3, failed=0`; SBs **`53325`**, **`53326`** InvoiceRule `I`.
- DocAction = `BookingGen_DocList`; temporary smoke AD defaults **reverted** after test.
