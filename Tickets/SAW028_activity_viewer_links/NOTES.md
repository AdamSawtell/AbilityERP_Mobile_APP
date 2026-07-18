# SAW028 — Notes

## Window targets (UU)

| Button | Window | UU | Key |
|--------|--------|-----|-----|
| Client | Client | `f1c9a83a-6589-49b8-a797-458f45e1b8e2` | `C_BPartner_ID` |
| Employee | Employee | `a826f1f8-3097-4d96-a83a-0bd9e1bb48ae` | `C_BPartner_ID` |
| Support Location | Support Location | `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` | `AbERP_Support_Location_ID` |

## Resolution rules

- **Client:** `AbERP_IsSupport_Receiver='Y'` when column exists; else `IsCustomer='Y'` and not `IsEmployee`
- **Employee:** Staff BP (`C_BPartner_Staff_ID`) → else User→BP → else `AbERP_User_BP_ID` (all require `IsEmployee='Y'`)
- **Support Location:** `AbERP_Support_Location_ID`

## Zoom

Uses `AEnv.zoom(windowId, MQuery)` only — no table/MQuery-only fallback (avoids BP/User windows).

## HCO Future Deployments variables

- Activity Viewer UU: `e5e62a4b-bd38-49d6-b2e7-e5a44e194b0e`
- Confirm Client / Employee / Support Location windows by UU/name before smoke
- Never change existing HCO `*_UU` values

## Full link / function test (2026-07-18, host `3.27.207.215`, Admin)

SQL matrix (`tmp-full-test-matrix.sql`): processes ACTIVE; Admin + AbilityERP Admin grants; resolution rows OK.

| Activity | Expected buttons | Zoom destinations | Result |
|----------|------------------|-------------------|--------|
| `1638777` (SAW027-SEED ambulance) | Client, Employee, Support Location | `Client: 000455 Lindsay Pau…`; `Employee: 421 Jack Elder`; `Support Location: Centennia…` | PASS |
| `1641172` (client only) | Client only | `Client: 000490 Peter Kielow` | PASS |
| `1617870` (client + SL) | Client, Support Location | `Support Location: 2 Ware Close` | PASS |
| `1641170` (employee + SL) | Employee, Support Location | `Employee: 656 Jasveerpal K…`; `Support Location: Gawler 73` | PASS |
| `1374218` (no links) | none | — | PASS |

No zoom opened generic Business Partner as the primary window.
