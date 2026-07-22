# SAW033 — HCO WebUI theme

**Status:** In progress (plugin build + staging)  
**Area:** iDempiere WebUI — visual theme  
**Internal ID:** `SAW033_hco_theme_plugin`

## Windows / processes / objects affected

| Type | Name | Change |
|---|---|---|
| Theme plugin | HCO ZK Theme (`org.hco.ui.theme`) | New CSS/image theme for WebUI |
| Login page | WebUI login | HCO logo, colours, tagline |
| System preference | Theme / `ZK_THEME` | HCO theme available to select |
| Window / Process / Menu | None | Visual only — no new windows or processes |

## What’s been done

Work in progress: build a dedicated HCO theme plugin for iDempiere 7 so the WebUI matches HCO brand colours, typography (Poppins), rounded toolbar tiles, cleaner tabs/dialogs, and a branded login screen.

## Impact

All WebUI users on a host that installs and selects the HCO theme will see the updated look and feel. No business-process behaviour changes.

## How to test

1. Log in to WebUI on the staging host.
2. Confirm login shows HCO branding.
3. Open a common window (for example Shift or Employee).
4. Confirm teal headers, rounded toolbar tiles, flat tabs, and navy body text.
5. Open Preferences and confirm the HCO theme is listed / selected.
6. Confirm Delete (and similar) destructive toolbar actions remain clearly marked.

## Access

No new window or process access is required. Theme selection is via Preferences / system theme setting.

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME` |
