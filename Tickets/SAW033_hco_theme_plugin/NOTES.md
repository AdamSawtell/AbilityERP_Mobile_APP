# SAW033 — Notes

## Scope review (2026-07-23)

Reviewed Obsidian scope: **HCO iDempiere 7 Theme Plugin — Cursor Scope.md**.

### Accepted

- CSS / images / ZK theme definitions only
- Brand tokens: primary `#25cad2`, secondary `#00c3b3`, heading `#00a2bd`, body `#0f2554`, dark `#151515`, light `#eaeaea`, danger `#e63946`
- Poppins, 6–8px radii, subtle shadows
- Toolbar tiles, flat tabs, dialog polish, status bar accent, CSS spinner
- Branded login with HCO logo + tagline
- Theme registration for preference selector
- Staging before production promote

### AbilityERP adjustments

| Scope text | Adjustment |
|---|---|
| `plugins/org.hco.ui.theme/` | Repo path `idempiere-plugins/org.hco.ui.theme/` |
| “No database changes” | JAR-first; optional `ZK_THEME` / logo sysconfig for smoke only — document in DEPLOY; never rewrite HCO `*_UU` |
| Destructive toolbar `[icon="z-icon-times"]` | Validate against real iDempiere 7 toolbar DOM; fix selectors if needed |
| “Do not deploy directly” | This ticket stages on dry-run host; production is a later promote |

### Host discovery (`3.27.122.147`)

- Hostname `ip-172-31-3-32` — same box previously documented as HCO20260714 dry run at `54.253.165.194`
- SSH key works: `HCO_Prod_KP.pem`
- iDempiere 7.1 WebUI up (Jetty); `org.adempiere.ui.zk_7.1.0.202503110454.jar`
- `ZK_THEME=default`
- Logos still Flamingo S3; browser icon already HCO S3 URL
- Title: `AvERP HCO Test001 20260712`
- Existing theme-ish JARs: Logilite DMS themes only — no HCO UI theme yet

## HCO Future Deployments variables

| Variable | Value |
|---|---|
| Staging host | `3.27.122.147` (`ip-172-31-3-32`) |
| Staging SSH key | `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| Staging SSH user | `ubuntu` |
| Production host (later) | `13.239.162.141` (`HCOproduction`) |
| Production WebUI | `https://abilityerp.hco.net.au/webui/` |
| Plugin symbolic name | `org.hco.ui.theme` |
| Theme key | TBD after `plugin.xml` / theme registration |
| Prior dry-run IP | `54.253.165.194` (retired for this host) |

## Open risks

1. Toolbar destructive selectors may not match scope CSS as written.
2. Google Fonts CDN dependency for Poppins (offline/network policy).
3. Login branding may need image URL overrides in addition to theme CSS depending on how Flamingo logos are wired via `ZK_LOGO_*`.
4. Exact iDempiere 7 theme extension-point pattern must match installed `org.adempiere.ui.zk` (confirm during scaffold).
