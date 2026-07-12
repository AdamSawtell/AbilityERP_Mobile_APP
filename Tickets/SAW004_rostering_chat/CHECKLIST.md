# SAW004 checklist

- [x] Window clone from Requests + Rostering Chat type filter
- [x] Reply / close processes + WebUI UX series on main
- [x] App chat sync compatible (Kind both)
- [x] Process search keys `AbERP_RosteringChat_Send` / `AbERP_RosteringChat_Close`
- [x] Shared grid via AD_Field + inbox default Response required
- [x] Agent deploy pack: `idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md` + `verify-install.sql`
- [ ] Re-verify on staging / other client build (`sudo ./deploy.sh` then WebUI smoke in DEPLOY.md)
- [ ] Confirm target `Rostering Officer` `ad_role_id` (warn if != 1000012)
- [ ] Client packs named **SAW004**
- [ ] Dependency smoke (app ↔ WebUI) when re-shipping
