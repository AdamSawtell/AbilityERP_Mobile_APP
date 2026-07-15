# SAW003 — Deploy to another build (agent)

**Ticket / slug:** `SAW003_staff_rostering_info`  
**Kind:** idempiere · **JAR:** Yes · **Status:** done  
**GitHub:** [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)  
**Current bundle:** **`1.1.0.2026071510`**

## Required host access

- SSH · `psql` · WebUI Admin · ability to restart iDempiere / install OSGi JAR  
- Java 11 + `$IDEMPIERE_HOME` (default `/opt/idempiere-server`) to **build** JAR on the host  
- Prerequisite: Info Window UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf` **must already exist**

## Agent one-liner (full install)

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# build JAR 1.1.0.2026071510 → SQL 01→24→04 → restart → wait WebUI 200
# then Cache Reset / logout-in. Do NOT wipe OSGi configuration cache.
```

## JAR-only update (UX refresh — typical later deploy)

Use when SQL `01`–`24`→`04` is **already** on the target (HCO Test / staging already are):

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh
# Confirm VERSION=1.1.0.2026071510 in build.sh + META-INF/MANIFEST.MF
./build.sh
JAR=com.aberp.rostering.staffinfo_1.1.0.2026071510.jar
IDEMPIERE_HOME=${IDEMPIERE_HOME:-/opt/idempiere-server}
sudo rm -f $IDEMPIERE_HOME/plugins/com.aberp.rostering.staffinfo_*.jar
sudo rm -f $IDEMPIERE_HOME/customization-jar/com.aberp.rostering.staffinfo_*.jar
sudo cp build/dist/$JAR $IDEMPIERE_HOME/plugins/$JAR
sudo cp build/dist/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
sudo chown idempiere:idempiere $IDEMPIERE_HOME/plugins/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.staffinfo,/d' "$B"
echo "com.aberp.rostering.staffinfo,1.1.0.2026071510,plugins/$JAR,4,true" | sudo tee -a "$B" >/dev/null
# Restart (HCO: if stop leaves Java running, kill equinox launcher then start)
sudo systemctl restart idempiere   # or: sudo /etc/init.d/idempiere stop; sleep 3; sudo /etc/init.d/idempiere start
# Wait WebUI 200 — HCO check http://127.0.0.1/webui/ (not :8080)
# Logout/in or Cache Reset
```

Prebuilt JAR may exist on staging after a build:  
`/opt/idempiere-server/plugins/com.aberp.rostering.staffinfo_1.1.0.2026071510.jar` — scp + same install steps above.

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Symbolic name | `com.aberp.rostering.staffinfo` |
| Version | **`1.1.0.2026071510`** (`build.sh` / `deploy.sh` / `META-INF/MANIFEST.MF`) |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` |
| UI class | `com.aberp.rostering.staffinfo.info.StaffRosteringInfoWindow` |
| Callout | `com.aberp.rostering.staffinfo.callout.CalloutStaffRosteringInfo` |

Prefer host `./build.sh` so the JAR matches MANIFEST. Known-good binary: **≥ ~40 KB** (≈57 KB for `1510`). ~29 KB with a version stamp is a **stale** banner-only build.

## Ordered SQL (`deploy.sh`) — greenfield / full reinstall only

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
- Credential box is a sibling **below** `parameterGrid` (not inside a grid row). Show Unmatched expands **only this Info Window’s** North (by uuid) — never `jq('.z-north').get(0)` (that inflates the parent Shift window and leaves a white gap after close). Restore North height on close / hide unmatched (`1510`).

## WebUI smoke

**From Shift (Rostered) → Employee → staff Search** (preferred):

1. Title **Employee (User) / Agency Staff Rostering Info**; criteria **Staff Name**, Employee, Agency Staff.  
2. Banner shows shift context (not “No shift in context”).  
3. Leave/overlap hidden unless **Show Unavailable Staff**; needs mismatches hidden unless **Show Unmatched Staff**.  
4. Lean grid (no BP Name / Status / Business Partner / Agency Staff columns).  
5. Related Info tabs; contact pick fills BP.

**Show Unmatched + credential AND (JAR `1510`):**

1. Unticked → Related Needs apply; credential picker hidden.  
2. Ticked → needs ignored; **two columns** under criteria (aligned with Staff Name / Employee):  
   - **Left:** **Must have all of these credentials** · Find · Selected (N) / Clear  
   - **Right:** **Select (AND)** checklist  
3. Find narrows the list; select 2+ → summary lists names; ReQuery = AND. Empty selection → full unmatched pool.  
4. **Clear** resets selection; untick hides the picker. Criteria North pane should expand (~280px) so the checklist is visible.

Standalone menu **Employee (User) Staff Rostering Info Search** is fine for unmatched/AND smoke (“No shift in context” banner is expected).

## Known blocker on some hosts (not SAW003)

If opening Staff Info throws `org/zkoss/util/media/Media` / `ClassNotFoundException` attributed to **`com.aberp.leave.planning`**, that bundle needs `zcommon` on `Require-Bundle` (see SAW016 / issue [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16)). Staff Info itself does not use `AMedia`.

## Environments verified

| Env | Host | Bundle | Notes |
|-----|------|--------|-------|
| Staging EC2 | `ec2-54-206-120-32…:8080` | `1.1.0.2026071510` | SSH key `AbilityERP_Development_Keypair_Shared.pem` |
| HCO Test | `http://13.210.248.141/webui/` | `1.1.0.2026071510` | SSH `ubuntu@13.210.248.141` · `HCObusiness.pem` (old IP `32.236.127.117` retired) |

HCO access / UUID rules: `Tickets/HCO_Deployment/` + `NOTES.md` **HCO Future Deployments variables**.

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`  
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`  

Refresh packs when shipping a client zip: JAR **`1510`** (≥ ~40 KB) + SQL through **`24`**. Prefer host `./deploy.sh` / JAR-only steps over stale packs.

## Agent prompt (copy)

> Deploy SAW003 per `Tickets/SAW003_staff_rostering_info/DEPLOY.md`. Prefer JAR-only update to `1.1.0.2026071510` if SQL is already applied. Run WebUI smoke: Show Unmatched → two-column Find + Select (AND); report pass/fail.

## External ticket text

`Tickets/SAW003_staff_rostering_info/EXTERNAL-SUMMARY.md`
