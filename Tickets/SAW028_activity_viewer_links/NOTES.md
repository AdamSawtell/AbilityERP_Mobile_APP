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
