# SAW033 — HCO WebUI theme

**Status:** Staging complete on HCO Test001 dry-run host  
**Area:** iDempiere WebUI — visual theme  
**Internal ID:** `SAW033_hco_theme_plugin`

## Windows / processes / objects affected

| Type | Name | Change |
|---|---|---|
| Theme | HCO ZK Theme (`hco`) | New WebUI theme with HCO colours, Poppins, toolbar tiles, branded login |
| System configurator | `ZK_THEME` | Set to `hco` |
| System configurator | `ZK_LOGIN_LEFTPANEL_SHOWN` | Enabled for brand panel |
| System configurator | `ZK_LOGO_LARGE` / `ZK_LOGO_SMALL` | Cleared so theme logos are used |
| Window / Process / Menu | None | Visual only |

## What’s been done

HCO WebUI now has a dedicated theme: teal primary accents, dark navy text, dark header, rounded toolbar tiles, flat underline tabs, and a branded login screen with the HCO logo and tagline “Supporting people living with disability”.

## Impact

All WebUI users on a host with `ZK_THEME=hco` see the updated look and feel. No business-process behaviour changes.

## How to test

1. Open WebUI and confirm login shows HCO branding and teal OK/Help buttons.
2. Log in as Admin.
3. Confirm dark header, Poppins text, and teal active tab underline.
4. Open **Employee** (or any window) and confirm teal rounded toolbar tiles and teal grid headers.
5. Confirm Preferences still works (theme key `hco`).

## Test result

Validated on HCO Test001 (`3.27.122.147`) on 23 July 2026: login branding, desktop chrome, and Employee toolbar/tabs/grid colours all matched the HCO palette.

## Access

No new window or process access is required.

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME=hco` |
