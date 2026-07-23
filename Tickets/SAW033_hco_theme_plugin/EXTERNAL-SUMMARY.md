# SAW033 — HCO WebUI theme

**Status:** Ready for further environment deploy (staging complete)  
**Area:** iDempiere WebUI — visual theme  
**Internal ID:** `SAW033_hco_theme_plugin`

## Windows / processes / objects affected

| Type | Name | Change |
|---|---|---|
| Theme | HCO ZK Theme (`hco`) | New WebUI theme: HCO colours, Poppins, toolbar tiles, branded login, readable query fields in OS dark mode |
| System configurator | `ZK_THEME` | Set to `hco` |
| System configurator | `ZK_LOGIN_LEFTPANEL_SHOWN` | Enabled for brand panel |
| System configurator | `ZK_LOGO_LARGE` / `ZK_LOGO_SMALL` / `WEBUI_LOGOURL` | Point at theme logos |
| Toolbar (optional) | Support Worker Restrict | Hide unavailable chrome on key windows |
| Window / Process / Menu | None required | Visual only |

## What’s been done

HCO WebUI now has a dedicated theme: teal primary accents, navy text, dark header, rounded toolbar tiles, flat underline tabs, branded login (HCO logo + “Supporting people living with disability”), distinct Home favourites icons, and query/search fields that stay readable when the OS is in dark mode.

## Impact

All WebUI users on a host with `ZK_THEME=hco` see the updated look and feel. No business-process behaviour changes (optional toolbar Restrict only hides buttons the Support Worker role should not use).

## How to test

1. Open WebUI — login shows HCO branding and teal OK/Help.
2. Log in (e.g. Support Worker or Admin).
3. Confirm dark header, Poppins, teal active tab underline.
4. Type in the header search and in Client → Lookup query fields — text must be clearly visible (navy on white).
5. Confirm header username and Feedback / Preference / Change Role / Log Out are white on the dark bar.
6. Open any window — teal toolbar tiles and grid headers.

## Test result

Validated on HCO Test001 (`3.27.122.147`) on 23 July 2026, including OS dark- and light-mode contrast checks. Ship JAR `7.1.0.2026072317`.

## Access

No new window or process access is required. Admin can use the theme once installed (`ZK_THEME=hco`).

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME=hco` |
