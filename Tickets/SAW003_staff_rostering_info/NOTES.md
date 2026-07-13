# SAW003 notes

- Deployment finished on staging; ticket marked **done** and agent-ready.
- Bundle: `com.aberp.rostering.staffinfo` — version **`1.1.0.2026071225`** (`build.sh` / `deploy.sh` / MANIFEST / Downloads packs).
- Info Window UU: `2b4ab146-0809-47c6-96f3-8b841d60a6bf`
- Not the same as SAW011 (Accept Shift Request) or SAW004 (Rostering Chat).

## Why this work existed

1. **Original problem:** Shift → Employee staff search was slow/heavy (fat FROM joins) and hard to filter leave / overlap / credential needs.
2. **Rewrite (SAW003):** Lean User+BP query, Java EXISTS filters, Related Info, clearer UX.
3. **HCO follow-ups:** ZK **non-negative only** popup (Multi Select `-1` + missing `c_bpartner_staff_id` on CredentialAssignment) — fixed in SQL `21`–`23` + Java sanitize / schema guard.
4. **Perf (2026-07-12 evening):** ReQuery felt very slow on HCO (~100k shifts). Root causes: needs-match SQL evaluated heavy `AbERP_Related_Rostering_Needs_V` per staff row; leave used `UPPER()` (blocked indexes); Gender/Position correlated subselects; Lookup by **Roster Period** loads ~2k shifts (use Document No for one shift). Fix: `24-perf-staff-info.sql` + JAR prefetches credential IDs.
5. **Unmatched credential filter (2026-07-13):** When **Show Unmatched Staff** is ticked, a multi-select Listbox appears. Shift Related Needs are ignored; selected credentials AND-filter the pool via the same `COUNT(DISTINCT)=N` assignment pattern (JAR `1222`; zul Listbox — not Chosenbox, which is not OSGi-exported to this bundle).

## Late UX (keep in packs)

| Script / Java | Behaviour |
|---------------|-----------|
| `18` | Result grid display-only when a row is selected |
| `19` | **Staff Name** label; Show Unmatched under Staff Name, Show Unavailable under Employee (Java layout) |
| `20` | Hide BP Name, Status, Business Partner, Agency Staff from **grid**; Agency Staff stays criteria |
| `21` | Deactivate Multi Select leftovers (Support Receiver Needs) that cause ZK **non-negative only** |
| `22` | Gender/Position as String names; deactivate leftover Search cols; Java strips Intbox `no negative` |
| `23` | Force no ID/Search/MultiSelect query criteria leftovers |
| `24` | Perf: cred/leave indexes; Gender/Position via joins; Java prefetches credential IDs |
| Java `1222` | Show Unmatched → credential multi-select Listbox (AND); empty = unmatched pool only |

`20` must run **after** `03`/`05`/`09` on every full redeploy or those scripts re-show columns.
`21`/`22`/`23` must run **after** `08` (Related Info) so Multi Select / Search leftovers stay off.
`24` is safe after `22` (replaces Gender/Position selectclauses with join columns).

**Empty results ≠ non-negative popup.** No staff matching needs → `0 Rows found` (tick **Show Unmatched Staff**). Popup is ZK `-1` Intbox validation.

## Packs

Refresh when the JAR or SQL order changes:

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`

**Pack rule:** JAR must be **~40 KB+**. Same version string at ~29 KB is a stale binary (no ticks).

## HCO Future Deployments variables

| Item | HCO value (2026-07-12) | Notes |
|------|------------------------|--------|
| Host | `32.236.127.117` | WebUI `http://32.236.127.117/webui/` |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` | Local `AD_InfoWindow_ID` = **1000034** (≠ seed `1000027`) |
| OLD IW (do not use) | UU `d0a2aeb5-…` local `1000042` | Leave alone |
| Shift (Rostered) window | UU `7c269a7e-…` local `1000082` | Employee tab `1000149` |
| Employee Search field | `AbERP_User_Contact_ID` → ref `1000215` | Already points at IW `1000034` |
| Admin IW access | Admin + AbilityERP Admin + Rostering (+TL) | Already granted |
| JAR | `…_1.1.0.2026071221.jar` | Unmatched credential multi-select |
| Org `*` shifts | ~39k of ~106k on HCO | Do **not** bulk-move; smoke on `ad_org_id > 0` |
| `06-fix-shift-org.sql` | Skips AbilityERP-only data move | Still sets AlwaysUpdateable on contact column |

### Scope review vs HCO (2026-07-12)

| Area | Status |
|------|--------|
| SQL `01`–`24`→`04` | Applied on HCO (through perf / non-negative hotfixes) |
| Lean FROM / Staff Name / hide clutter | OK |
| Related Info (7 links) | OK |
| BP/org triggers + AlwaysUpdateable | OK |
| Java ticks + needs/leave filters | OK after JAR rebuild |
| Unmatched credential AND multi-select | JAR `1221` (staging EC2); redeploy to HCO when ready |
| Downloads packs JAR | Refresh to `1221` |
| Non-negative only popup | Fixed: `08` no longer activates all `C_BPartner_ID`; `21` kills Multi Select; logout/in required |
| Full smoke from Shift → Employee Search | Re-test ReQuery with All/Any after logout/in |
