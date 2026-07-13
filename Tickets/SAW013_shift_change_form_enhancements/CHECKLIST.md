# SAW013 — Checklist

## Staging (HCO Test `32.236.127.117`)

- [x] Preflight SQL
- [x] Install status/submitted + sync trigger
- [x] Install dup-prevent trigger
- [x] Clear any leftover ColumnSQL (`03`)
- [x] Verify SQL (sample doc + triggers)
- [x] Cache Reset / re-login
- [x] WebUI: grid loads (no timeout) — 1–25/3826 OK after physical columns
- [x] WebUI: status mirrors request (grid + Requests tab) — Doc `1003753`
- [x] WebUI: WITH request — Submitted checked, Create button hidden
- [x] WebUI: WITHOUT request — Doc `1003729` Submitted unchecked, Status blank, Create visible, Requests 0
- [x] WebUI save E2E — toggle Active on `1003753`, Record saved; DB `updated` advanced; Status/Submitted unchanged
- [x] WebUI: Create popup Request Template matches window Request Type (`1003729`, `1003444`)
- [x] AD: Request Submitted field + Create DisplayLogic
- [x] AD: `05-match-request-template-type.sql` installed on HCO
- [x] Trigger: second insert blocked
- [x] Packs built
- [x] EXTERNAL-SUMMARY ready
- [x] Mark done when issue updated / pushed
