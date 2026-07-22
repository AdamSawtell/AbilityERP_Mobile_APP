# SAW003 — Deploy to another build (agent)

**Ticket / slug:** `SAW003_staff_rostering_info`  
**Kind:** idempiere · **JAR:** Yes · **Status:** done (ready for agent deploy)  
**GitHub:** [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)  
**Current bundle:** **`1.1.0.2026072214`**

## Required host access

- SSH · `psql` · WebUI Admin · ability to restart iDempiere / install OSGi JAR  
- Java 11 + `$IDEMPIERE_HOME` (default `/opt/idempiere-server`) to **build** JAR on the host  
- Prerequisite: Info Window UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf` **must already exist**

## Agent one-liner (full install)

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# build JAR 1.1.0.2026072214 → SQL 01→26→04 → restart → wait WebUI 200
# then Cache Reset / logout-in. Do NOT wipe OSGi configuration cache.
```

## JAR-only update (typical later deploy)

Use when SQL `01`–`25`→`04` is **already** on the target. Still apply **`26-show-partner-location-suburb.sql`** if not yet run (Partner Location suburb column in results). For UX/filter JAR bumps:

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh
# Confirm VERSION=1.1.0.2026072214 in build.sh + META-INF/MANIFEST.MF
./build.sh
JAR=com.aberp.rostering.staffinfo_1.1.0.2026072214.jar
IDEMPIERE_HOME=${IDEMPIERE_HOME:-/opt/idempiere-server}
sudo rm -f $IDEMPIERE_HOME/plugins/com.aberp.rostering.staffinfo_*.jar
sudo rm -f $IDEMPIERE_HOME/customization-jar/com.aberp.rostering.staffinfo_*.jar
sudo cp build/dist/$JAR $IDEMPIERE_HOME/plugins/$JAR
sudo cp build/dist/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
sudo chown idempiere:idempiere $IDEMPIERE_HOME/plugins/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.staffinfo,/d' "$B"
echo "com.aberp.rostering.staffinfo,1.1.0.2026072214,plugins/$JAR,4,true" | sudo tee -a "$B" >/dev/null
# Restart (HCO: if stop leaves Java running, kill equinox launcher then start)
sudo systemctl restart idempiere   # or: sudo /etc/init.d/idempiere stop; sleep 3; sudo /etc/init.d/idempiere start
# Wait WebUI 200 — HCO check http://127.0.0.1/webui/ (not :8080)
# Logout/in or Cache Reset
```

Prebuilt JAR in git:  
`idempiere-plugins/com.aberp.rostering.staffinfo/release/com.aberp.rostering.staffinfo_1.1.0.2026072214.jar` (~72 KB) — scp + same install steps above.  
Also on staging after build: `/opt/idempiere-server/plugins/com.aberp.rostering.staffinfo_1.1.0.2026072214.jar`

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Symbolic name | `com.aberp.rostering.staffinfo` |
| Version | **`1.1.0.2026072214`** (`build.sh` / `deploy.sh` / `META-INF/MANIFEST.MF`) |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` |
| UI class | `com.aberp.rostering.staffinfo.info.StaffRosteringInfoWindow` |
| Callout | `com.aberp.rostering.staffinfo.callout.CalloutStaffRosteringInfo` / `CalloutShiftStaffContact` |

Prefer host `./build.sh` so the JAR matches MANIFEST. Known-good binary: **≥ ~70 KB** (release `2214` ≈72 KB). ~29 KB with a version stamp is a **stale** banner-only build.

## What JAR `2214` includes (filters)

Second criteria row (starts **column 2**), all default **On**:

| Tick | On (default) | Off |
|------|--------------|-----|
| **Show Matched Staff** | Related Rostering Needs | Unmatched pool + credential Find / Select (AND) |
| **Employee Not Rostered at this Time** | Exclude overlapping roster | Include overlapping |
| **Employees Not On Leave** | Exclude approved leave overlap | Include leave |
| **Show Familiar Staff** | Prior non-template roster at same Support Location within **12 months** | All staff |

Familiarity: shift → `AbERP_MasterLocation` → `C_BPartner_Location_ID` (fallback Master Location id). Exclude templates + current shift. No location on shift → Familiar filter skipped (does not empty list).

Also: scoped North expand for credential picker (never `jq('.z-north').get(0)` — that gaps the parent Shift window).

**Results grid = single-select** (JAR `2214`+): Related Information tabs key off one selected row.

**Overlap / leave filter timestamps** (JAR `2214`): `Employee Not Rostered` and leave exclusion use `TO_TIMESTAMP` (not `DB.TO_DATE`). Day-only `TO_DATE` collapsed afternoon windows to midnight and failed to exclude overlapping staff (incl. overnight).

**Partner Location** (SQL `26`): suburb text (`City`, else location name) in search results only — not a filter.

## Ordered SQL (`deploy.sh`) — greenfield / full reinstall only

`01-indexes` → `02-rewrite-infowindow` → `03-rewrite-infocolumns` → `05-hotfix-browser-smoke` → `06-fix-shift-org` → `07-eligibility-criteria` → `08-enable-related-info` → `09-find-fill-ux` → `10-java-ux-org` → `11-drop-redundant-criteria` → `12-needs-match-criteria` → `14-fix-show-unmatched-selectclause` → `15-fix-onapprovedleave-criteria` → `16-fix-nonnegative-id-criteria` → `17-fix-hidden-multiselect-criteria` → `18-fix-result-grid-readonly` → `19-rename-staff-name` → `20-hide-clutter-columns` → `21-fix-nonnegative-multiselect` → `22-harden-nonnegative-editors` → `23-force-no-id-criteria` → `24-perf-staff-info` → `25-hide-eligibility-display-columns` → **`26-show-partner-location-suburb`** → `04-verify`

- Do **not** use stub `sql/install-all.sql` as the install.  
- Skip `13-load-test-needs-match.sql` unless load-testing.  
- Rollback: `sql/99-rollback.sql` + remove JAR / `bundles.info` line + restart.

### SQL order constraints

| After | Must re-run |
|-------|-------------|
| `03` / `05` / `09` | `20` (or clutter columns reappear) |
| `08` (Related Info) | `21` / `22` / `23` (Multi Select / Search leftovers stay off) |
| `22` | `24` is safe (Gender/Position selectclauses → joins) |
| `07` / `15` | `25` (or On Approved Leave / Has Future Shift reappear in grid) |
| `22` (older) | `26` (or Partner Location suburb stays hidden) |

## AbilityERP Admin access

Info Window is pre-existing — Admin / AbilityERP Admin / Rostering must already have access to Staff Rostering Info / Shift (Rostered). No new process. Smoke **as Admin**.

## Portability risks

- Windows → Linux: LF-normalize `build.sh`/`deploy.sh`. Never `sed`/`tr` that eats trailing `r`.  
- HCO idempiere stop can leave Java running (“already running”) — kill equinox launcher if WebUI stays 503.  
- Credential UI uses **zul Listbox** (not Chosenbox). Never `setDisabled` on the credential Listbox.  
- North expand only on **this Info** North uuid; restore on close / re-tick Matched.  
- If open throws `org/zkoss/util/media/Media` → fix **leave.planning** `zcommon` (SAW016 / #16), not this JAR.

## WebUI smoke

**From Shift (Rostered) → Employee → staff Search:**

1. Four ticks on **one row** under criteria (start col 2), all default on.  
2. Banner shows shift context.  
3. Untick **Show Matched** → Find + Select (AND) credential columns; re-tick → hidden.  
4. Untick **Not Rostered** / **Not On Leave** independently and ReQuery.  
5. **Familiar:** on a shift with Support Location (e.g. Swinley 14), with Familiar on, staff with history (e.g. Anupam Choudhary, Damaris Harris on HCO) remain eligible; untick Familiar widens the pool.  
6. Close Info after dragging criteria splitter → parent Shift window has **no** blank band under header.  
7. Lean grid: **Partner Location** suburb shown; no On Approved Leave / Has Future Shift / BP Name / Status / Business Partner / Agency Staff.  
8. **Single-select** one row → Related Info matches that contact; pick fills BP.  
9. **Not Rostered** on a 15:00–22:00 shift: overlapping staff (e.g. Damaris overnight / afternoon, Erick, Navroop on another shift) must **not** appear.

## Environments verified

| Env | Host | Bundle | Notes |
|-----|------|--------|-------|
| Staging EC2 | `ec2-54-206-120-32…:8080` | `1.1.0.2026072214` + SQL `26` | SSH `AbilityERP_Development_Keypair_Shared.pem` |
| HCO Test | `https://3.25.213.143/webui/` | `1.1.0.2026072214` + SQL `26` | SSH `ubuntu@3.25.213.143` · `HCO_Prod_KP.pem` |
| HCO Test (HCO20260714 dry-run) | `http://54.253.165.194/webui/` | `1.1.0.2026072214` + SQL `25`/`26` | JAR+SQL redeploy 2026-07-16 (was `1516`) |

## Packs

- Prebuilt JAR (git): `idempiere-plugins/com.aberp.rostering.staffinfo/release/com.aberp.rostering.staffinfo_1.1.0.2026072214.jar`
- Client/prod zip folders (when used): `Downloads\AbilityERP-*-SAW003_staff_rostering_info-*/` — refresh to JAR **`2214`** + SQL through **`26`**

## Agent prompt (copy)

> Deploy SAW003 per `Tickets/SAW003_staff_rostering_info/DEPLOY.md` and `AGENT-READY.md`. Install JAR `1.1.0.2026072214` (host build or `release/com.aberp.rostering.staffinfo_1.1.0.2026072214.jar`). JAR-only if SQL through `26` is applied. Smoke: **Not Rostered** excludes afternoon/overnight overlaps; single-select; Partner Location suburb; four filter ticks; report pass/fail.

## External ticket text

`Tickets/SAW003_staff_rostering_info/EXTERNAL-SUMMARY.md`  
Also: `Tickets/SAW003_staff_rostering_info/AGENT-READY.md`
