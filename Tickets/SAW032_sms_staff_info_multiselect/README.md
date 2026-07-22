# SAW032 — SMS Staff Rostering Info (multi-select)

**Status:** Ready for HCO Production push  
**GitHub:** [#32](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/32)

Clone of Find & Fill Staff Rostering Info for SMS / bulk contact selection.

| | |
|--|--|
| Find & Fill UU (single) | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` — **do not change** |
| SMS UU (multi) | `7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11` |
| Plugin | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Bundle | `1.1.0.2026072218` |
| SQL | `28-clone-sms-multiselect-info.sql` |
| Prod runbook | [`DEPLOY.md`](DEPLOY.md) · [`CHECKLIST.md`](CHECKLIST.md) · [`AGENT-READY.md`](AGENT-READY.md) |

Same filters and columns as Find & Fill. Selection mode is fixed in Java by UU (this AD build has no `IsMultipleSelection` on `ad_infowindow`).

Menu UU (optional open without SMS process): `a8f3c2d1-5e6b-4a7c-9d0e-1f2a3b4c5d6e`

**Verified:** HCO Test user-tested. **Production** still on JAR `1517` with Find & Fill UU only — ready for SQL `28` + JAR `2218`.

**Operator step after prod install:** point the SMS process / search at the SMS UU. Leave Find & Fill on the original UU.
