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

Login: `SuperUser` / `HCOflamingo` · Role **Admin**.

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
| Ship JAR | `org.hco.ui.theme_7.1.0.2026072302.jar` |
| Deploy method | Inject `theme/hco` into `org.adempiere.ui.zk` + sysconfig |
| ui.zk backup suffix | `.pre-hco.bak` |
