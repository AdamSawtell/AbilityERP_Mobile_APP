# SAW033 — Notes

## Scope review (2026-07-23)

Reviewed Obsidian scope: **HCO iDempiere 7 Theme Plugin — Cursor Scope.md**.

### Host discovery (`3.27.122.147`)

- Hostname `ip-172-31-3-32` — HCO20260714 dry-run / Test001
- iDempiere 7.1 · ZK 8.6 · WebUI Jetty 9.4
- Prior theme `ZK_THEME=default`; logos were Flamingo S3 URLs

### Implementation decisions

1. Theme name **`hco`** (folder `/theme/hco`, sysconfig `ZK_THEME=hco`).
2. Overlay model: copy default theme at build time, add `custom.css.dsp` + images + login ZUL.
3. **Fragment alone insufficient on this host:** `Jetty-WarPrependFragmentResourcePath: /` did not serve `/theme/hco/preference.zul` (500 UiException). Staging deploy injects `theme/hco` into `org.adempiere.ui.zk` with `.pre-hco.bak` backup.
4. MANIFEST must be **LF-only** — `jar cfm` rewrites CRLF; build.sh post-processes ZIP.
5. Clear `ZK_LOGO_LARGE` / `ZK_LOGO_SMALL` so theme images are used.

### Staging smoke (2026-07-23)

| Check | Result |
|---|---|
| Login HCO brand + teal buttons | Pass |
| Desktop header `#151515`, Poppins, `#eaeaea` body | Pass |
| Tab underline `#25cad2` | Pass |
| Employee toolbar tiles `#25cad2` / 8px radius | Pass |
| Grid header `#00a2bd` | Pass |
| CSS URL `/webui/theme/hco/css/theme.css.dsp` ~80KB | Pass |
| Record nav word labels First/Previous/Next/Last (84×28) | Pass (`7.1.0.2026072306`) |
| Toolbar icon tiles equal-width rectangles (~40×26) | Pass |

Login: `SuperUser` / `HCOflamingo` · Role **Admin**.

### UI iteration — record nav labels (2026-07-23)

Breadcrumb buttons use icons `z-icon-FirstRecord` / `PreviousRecord` / `NextRecord` / `LastRecord` and titles like `First record    Alt+Home` (lowercase “record”). CSS scopes `.breadcrumb-toolbar-button`, hides glyphs, and injects word labels via `::before`.

### Toolbar grey icons — do not CSS-hide all disabled (2026-07-23)

Grey toolbar buttons are often **state** (Save when clean, First on record 1), not role deny. Hiding all `.z-toolbarbutton-disd` is wrong and flickery.

**Correct path:** `AD_ToolBarButtonRestrict` (Role Toolbar Button Access). Restricted buttons are not rendered — zero theme/JS cost.

#### Staging audit (HCO client `1000003`)

| Finding | Detail |
|---|---|
| Restrict already used | 74 rows; Support Worker (role UU `7c953364-…`) owns most |
| Duplicate role name | Two “Support Worker” roles; Restrict only on `1000012` |
| Tab-scoped gap | Many New/Attachment Restricts had `AD_Tab_ID` set. `getOfWindow()` **requires `AD_Tab_ID IS NULL`**, so window toolbar ignored them |
| Hardcoded Attachment/Chat | `ADWindowToolbar` has `btnAttachment` / `btnChat`; `enableAttachment` / `enableChat` can keep them visible even when Restrict exists |

#### Applied

`idempiere-plugins/org.hco.ui.theme/sql/02-toolbar-restrict-window-level.sql` — upserts **window-level** excludes for Support Worker on Client, Support Location, Incident Report, Animal, Login (New/Delete/Copy/Customize/AttributeForm/…; not Save/Ignore).

Smoke (Support Worker → Client after restart): **New gone**; Delete/Copy/Customize/AttributeForm gone; Save/Find/Refresh remain. Attachment/Chat/Requests still visible (hardcoded enable path) — follow-up if product wants those hidden too.

#### Follow-up tidy (`7.1.0.2026072308` + SQL `03-…`)

| Fix | Detail |
|---|---|
| ShowMore → main | `Attachment` / `Chat` / `Requests` set `IsShowMore=N` so Restrict removeChild works |
| Extra Restrict | Print, Document Explorer, PrintFormatEditor (+ Attachment/Chat/Requests) window-level for Support Worker |
| CSS hide disabled | Window toolbar + detail toolbar + record-nav chips when `[disabled]` / `-disd` (ZK often omits `-disd` on nav) |

Smoke (Support Worker → Client Aaron Agars): toolbar = Lookup / Grid / Zoom Across / Report / More; no Attachment/Chat/Print; disabled First/Previous hidden; Save/Ignore hidden until dirty.

#### Grid Select chip (`7.1.0.2026072309`)

Row indicator column (`title="Edit Record"`, was ~22px pencil) restyled to **88px** with ☑/☐ **Select** chips — current row filled teal, other rows outlined.

#### Document Status indicators (`7.1.0.2026072311`)

Home gadget `.activities-box` (e.g. **My Roster Statuses**) — drop Monospaced/PrintColor look; white rows, teal left accent, Poppins labels, teal count pills. CSS-only in theme plugin.

#### Favourites tree icons (`7.1.0.2026072313`)

**My People, Places and Actions** — compact **18px** soft-teal icons (`arrow-circle-right`) + tighter row padding (scoped to `.dashboard-widget`). Hard-refresh if old grey glyphs persist.

### HCO Future Deployments variables

| Variable | Value |
|---|---|
| Staging host | `3.27.122.147` (`ip-172-31-3-32`) |
| Staging SSH key | `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| Staging SSH user | `ubuntu` |
| Production host (later) | `13.239.162.141` (`HCOproduction`) |
| Production WebUI | `https://abilityerp.hco.net.au/webui/` |
| Plugin symbolic name | `org.hco.ui.theme` |
| Theme key | `hco` |
| Ship JAR | `org.hco.ui.theme_7.1.0.2026072313.jar` |
| Deploy method | Inject `theme/hco` into `org.adempiere.ui.zk` + sysconfig |
| ui.zk backup suffix | `.pre-hco.bak` |
