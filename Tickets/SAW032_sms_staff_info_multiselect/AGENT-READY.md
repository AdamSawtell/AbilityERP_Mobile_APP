# SAW032 — Agent ready (Production push)

**Status:** Ready for HCO Production  
**Source of truth:** [`DEPLOY.md`](DEPLOY.md)  
**GitHub:** [#32](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/32)

| | |
|--|--|
| Plugin | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Bundle | `1.1.0.2026072218` (~77 KB release JAR) |
| SQL | `28-clone-sms-multiselect-info.sql` only |
| Prod host | `13.239.162.141` · `https://abilityerp.hco.net.au/webui/` |
| SSH | `ubuntu@13.239.162.141` · `HCO_Prod_KP.pem` |
| SMS UU | `7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11` |
| Find & Fill UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` (**do not change**) |

## Do

1. scp SQL `28` + release JAR `2218` to `/tmp/` on Production.  
2. Apply SQL `28` (`ON_ERROR_STOP=1`).  
3. Swap JAR / `bundles.info` to `2218` (remove `1517`).  
4. Restart iDempiere; wait WebUI; Cache Reset.  
5. Smoke Find & Fill single-select + SMS multi-select.  
6. Leave SMS process UU assignment to the operator if not already set.

## Do not

- Run full `./deploy.sh` on Production.  
- Change existing Find & Fill UU or other HCO `*_UU`s.  
- Wipe OSGi configuration cache.

## Agent prompt (copy)

> Deploy SAW032 to HCO Production per `Tickets/SAW032_sms_staff_info_multiselect/DEPLOY.md` and `CHECKLIST.md`. SQL `28` + JAR `1.1.0.2026072218` only (from `release/`). Replace prod `1517`. Restart + Cache Reset. Smoke: Find & Fill single-select; SMS Info multi-select. Report pass/fail with `bundles.info` line and both Info Window UUs.
