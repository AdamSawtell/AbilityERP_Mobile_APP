# org.hco.ui.theme — HCO ZK Theme (SAW033)

iDempiere 7 ZK theme for HCO brand styling (CSS / images / login ZUL). No core Java changes.

## Layout

| Path | Purpose |
|---|---|
| `overlay/css/fragment/custom.css.dsp` | HCO brand overrides (loaded via theme custom.css hook) |
| `overlay/images/` | login-logo, header-logo, icon, favicon, logo-mobile |
| `overlay/zul/login/` | Branded login left panel |
| `metainfo/zk/lang-addon.xml` | Theme module version stamp |
| `build.sh` | Extract `theme/default` from `org.adempiere.ui.zk`, rename to `hco`, apply overlay, package JAR |
| `deploy-hco-staging.sh` | Staging install on HCO dry-run host |

## Theme key

`ZK_THEME=hco`

## Deploy note (iDempiere 7.1 / Jetty 9.4)

An OSGi fragment with `Jetty-WarPrependFragmentResourcePath` did **not** serve `/theme/hco/*` pages on the HCO Test001 host. Staging deploy therefore:

1. Builds `theme/hco` into the fragment JAR (source artifact)
2. Injects `theme/hco` into `org.adempiere.ui.zk_*.jar` (backup `*.pre-hco.bak`)
3. Sets `ZK_THEME=hco` and clears Flamingo `ZK_LOGO_*` URL overrides

Rollback: restore `org.adempiere.ui.zk_*.pre-hco.bak` and set `ZK_THEME=default`.

## Build

```bash
# on host with IDEMPIERE_HOME=/opt/idempiere-server
./build.sh
./deploy-hco-staging.sh
```
