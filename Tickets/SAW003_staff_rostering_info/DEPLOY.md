# SAW003 — Deploy to another build (agent)

**Ticket / slug:** `SAW003_staff_rostering_info`  
**Kind:** idempiere · **JAR:** Yes · **Status:** done  
**GitHub:** [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)

## Required host access

- SSH · `psql` · WebUI Admin · ability to restart iDempiere / install OSGi JAR  
- Java 11 + `$IDEMPIERE_HOME` (default `/opt/idempiere-server`) to **build** JAR on the host  
- Prerequisite: Info Window UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf` **must already exist**

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# build JAR 1.1.0.2026071237 → SQL 01→24→04 → restart → wait WebUI 200
# then Cache Reset / logout-in. Do NOT wipe OSGi configuration cache.
```

**JAR-only update** (SQL already applied on target): build with `./build.sh`, copy JAR to `plugins/` + `customization-jar/`, rewrite `bundles.info` line for `com.aberp.rostering.staffinfo`, restart, logout/in.

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Symbolic name | `com.aberp.rostering.staffinfo` |
| Version | **`1.1.0.2026071233`** (`build.sh` / `deploy.sh` / `META-INF/MANIFEST.MF`) |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` |
| UI class | `com.aberp.rostering.staffinfo.info.StaffRosteringInfoWindow` |
| Callout | `com.aberp.rostering.staffinfo.callout.CalloutStaffRosteringInfo` |

Prefer host `./build.sh` so the JAR matches MANIFEST. Ship only a known-good binary if you cannot build (`release/` may lag — verify size **≥ ~40 KB**; ~29 KB with the same version string is a **stale** banner-only build).

## Ordered SQL (`deploy.sh`)

`01-indexes` → `02-rewrite-infowindow` → `03-rewrite-infocolumns` → `05-hotfix-browser-smoke` → `06-fix-shift-org` → `07-eligibility-criteria` → `08-enable-related-info` → `09-find-fill-ux` → `10-java-ux-org` → `11-drop-redundant-criteria` → `12-needs-match-criteria` → `14-fix-show-unmatched-selectclause` → `15-fix-onapprovedleave-criteria` → `16-fix-nonnegative-id-criteria` → `17-fix-hidden-multiselect-criteria` → `18-fix-result-grid-readonly` → `19-rename-staff-name` → `20-hide-clutter-columns` → `21-fix-nonnegative-multiselect` → `22-harden-nonnegative-editors` → `23-force-no-id-criteria` → **`24-perf-staff-info`** → `04-verify`

- Do **not** use stub `sql/install-all.sql` as the install.  
- Skip `13-load-test-needs-match.sql` unless load-testing.  
- Rollback: `sql/99-rollback.sql` + remove JAR / `bundles.info` line + restart.

### SQL order constraints

| After | Must re-run |
|-------|-------------|
| `03` / `05` / `09` | `20` (or clutter columns reappear) |
| `08` (Related Info) | `21` / `22` / `23` (Multi Select / Search leftovers stay off) |
| `22` | `24` is safe (Gender/Position selectclauses → joins) |

## AbilityERP Admin access

Info Window is pre-existing — Admin / AbilityERP Admin / Rostering must already have (or be granted) access to Staff Rostering Info / Shift (Rostered). No new process. Smoke **as Admin**.

## Portability risks

- `sql/06-fix-shift-org.sql` only moves org=`*` data for the **AbilityERP** seed client; on HCO it skips data move and still sets AlwaysUpdateable on the Employee Search column.  
- `sql/08-enable-related-info.sql` resolves Related Info / parent columns by **owned UU only** (never activate every `ColumnName=C_BPartner_ID` — that reactivates Multi Select “Support Receiver Needs” → ZK **non-negative only**).  
- `sql/21-fix-nonnegative-multiselect.sql` deactivates Multi Select leftovers; keeps Agency Staff as filter-only criteria.  
- Credential filter UI uses **zul Listbox** (multi + checkmark). Do **not** switch to Chosenbox unless the OSGi bundle exports it.  
- Never `setDisabled(true)` on the credential Listbox — ZK drops `SelectEvent` and AND filter never applies.  
- Credential box is a sibling **below** `parameterGrid` (not inside a grid row) so `z-grid-body` overflow cannot clip it.

## WebUI smoke

**From Shift (Rostered) → Employee → staff Search** (preferred):

1. Title **Employee (User) / Agency Staff Rostering Info**; criteria **Staff Name**, Employee, Agency Staff.  
2. Banner shows shift context (not “No shift in context”).  
3. Leave/overlap hidden unless **Show Unavailable Staff**; needs mismatches hidden unless **Show Unmatched Staff**.  
4. Lean grid (no BP Name / Status / Business Partner / Agency Staff columns).  
5. Related Info tabs; contact pick fills BP.

**Show Unmatched + credential AND (JAR 1237):**

1. Unticked → Related Needs apply; credential picker hidden.  
2. Ticked → needs ignored; **Must have all of these credentials** appears below criteria with **Find** and **Selected (N)** summary.  
3. Use Find to narrow; select 2+ → summary lists names; ReQuery = AND. Empty selection → full unmatched pool.  
4. **Clear** resets selection; untick hides the picker.

Standalone menu **Employee (User) Staff Rostering Info Search** is fine for unmatched/AND smoke (“No shift in context” banner is expected).

## Known blocker on some hosts (not SAW003)

If opening Staff Info throws `org/zkoss/util/media/Media` / `ClassNotFoundException` attributed to **`com.aberp.leave.planning`**, that bundle needs `zcommon` on `Require-Bundle` (see SAW016 / issue [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16)). Staff Info itself does not use `AMedia`.

## Environments verified

| Env | Host | Bundle | Notes |
|-----|------|--------|-------|
| Staging EC2 | `ec2-54-206-120-32…:8080` | `1.1.0.2026071237` | Find + Selected summary UX |
| HCO Test | `http://13.210.248.141/webui/` | `1.1.0.2026071237` | Deployed 2026-07-14 |

HCO access / UUID rules: `Tickets/HCO_Deployment/` + `NOTES.md` **HCO Future Deployments variables**.

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`  
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`  

Refresh packs when JAR or SQL order changes; include **`1229`** JAR (≥ ~40 KB) and SQL through **`24`**. Prefer host `./deploy.sh` over stale packs.

## External ticket text

`Tickets/SAW003_staff_rostering_info/EXTERNAL-SUMMARY.md`
