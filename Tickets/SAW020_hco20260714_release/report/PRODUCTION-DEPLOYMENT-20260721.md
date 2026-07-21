# HCO20260714 — Production deployment (2026-07-21)

**Release:** HCO20260714 · **Ticket:** SAW020  
**Host:** `13.239.162.141` (`HCOproduction`)  
**SSH:** `ubuntu@…` + `Documents\SSH Keys\HCO_Prod_KP.pem`  
**WebUI:** `https://abilityerp.hco.net.au/webui/` · SSO `superuser@hco.net.au` → **Admin**  
**Verdict:** **PASS** (install complete; read-only WebUI smoke)

Hard rule: **no existing HCO `*_UU` changed.** Support Location UU stayed `6ef3c558-3ec8-4f0c-be40-89f35d8acebf`.

---

## Ordered install

| # | Ticket | Result | Evidence |
|---|--------|--------|----------|
| 1 | SAW018 | PASS | PackIns `1001038`–`1001041` Completed; view `hco_cred_missing_staff_v` present |
| 2 | SAW001 | PASS | Paid criteria/display UUs present (count=2) |
| 3 | SAW003 | PASS | SQL through `26` + JAR `1.1.0.2026071517` (52603 B) in `bundles.info` |
| 4 | SAW007 | PASS | `01-APPLY.sql` |
| 5 | SAW009 | PASS | Kept existing day-column UUs (no overwrite) |
| 6 | SAW010 | PASS | Break Start/End applied |
| 7–8 | SAW013 | PASS | `01-APPLY.sql` |
| 9 | SAW015 | PASS | SQL + JAR `…202607131830` + restart |
| 10 | SAW014 | PASS | ColumnSQL Email/Phone |
| 11 | SAW017 | PASS | Generator stack + bulk `…160730` + SQL `00`–`04` + restart |
| 12 | SAW026 | PASS | Tab UU `7d14ac4f-…0002` · verify green |

Host stage: `/tmp/HCO20260714/`. Logs: `/tmp/HCO20260714-saw001-010.log`, `/tmp/HCO20260714-saw013-026.log`.

---

## SAW018 notes (Production-specific)

1. Uninstalled legacy OSGi `com.aberp.employee.infopanel` (inputstream) before remaining PackIns.  
2. Apply **one zip at a time** with main server fully stopped + equinox killed.  
3. `hco_client` needed a **cold** PackIn session (ClassCast `GenericPO`→`X_AD_Package_Imp` when chaining immediately after another PackIn).  
4. Final package_imp: credentials `1001038`, employee `1001039`, supportlocation `1001040`, client `1001041`.

---

## Read-only WebUI smoke (no business data saved)

Constraint: open/verify only — **no New / Save / Process / Generate**.

| Check | Result |
|-------|--------|
| SSO login → Admin | PASS |
| Vehicle `S637CMD` → **Activity** tab | PASS (types: Case Note, Email, Meeting, Phone call, Task) |
| Support Location open · Email/Phone labels present | PASS |
| Menu search **Bulk Generate Bookings** | PASS (item visible; process not run) |
| Vehicle activities linked (`aberp_vehicle_id`) | Still **0** (no smoke inserts) |
| Support Location UU | Unchanged |

---

## Bundles registered (`bundles.info`)

- `com.aberp.rostering.staffinfo,1.1.0.2026071517`
- `com.aberp.skipdates.copyfrom,7.1.0.202607131830`
- `com.aberp.servicebooking.generator,7.1.12.202602251048` (`*-no-opp-dep.jar`)
- `com.aberp.bookinggenerator.bulk,7.1.0.202607160730`
- (+ GenerateShifts / rosteredshift.model / generic.utilities stack lines)
