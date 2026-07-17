# SAW026 notes

## Design

- Reuse the portable SAW007 Contact Activity tab structure.
- Resolve the Vehicle window and `AbERP_Vehicle` table without client-specific numeric IDs.
- Preserve existing client-owned UUID values.
- Use the standard Activity Types: `EM`, `ME`, `PC`, `CN`, and `TA`.

## Staging

- Host: `54.153.138.216`
- SSH key: supplied separately; do not copy into the repository or update packs.

## HCO Future Deployments variables

| Item | HCO Test001 value (2026-07-17) | Notes |
|---|---|---|
| Host | `54.153.138.216` | WebUI title `AvERP HCO Test001 20260712` |
| Vehicle window | ID `1000066`; UU `e6974bff-4ee3-4b8c-81b7-38936c74d93c` | Resolve by name + root table, never hardcode |
| `AbERP_Vehicle` table | ID `1000091`; UU `fb3e84bc-6a28-420c-92e8-97398479f9a6` | Resolve by table name |
| `C_ContactActivity` link column | ID `1007467`; UU `7d14ac4f-5fef-4f1f-b917-026000000001` | Physical column `aberp_vehicle_id` |
| Vehicle Search reference | ID `1000220`; UU `51ee0d93-0d9d-4d34-8b5b-e62a766c21fc` | Required so WebUI renders the vehicle licence instead of `~-1~` |
| Vehicle Activity tab | ID `1000364`; UU `7d14ac4f-5fef-4f1f-b917-026000000002` | 18 active fields; sequence 45 |
| Activity Types | `EM`, `ME`, `PC`, `CN`, `TA` | All enabled for Vehicle |
| Role access | AbilityERP Admin + Admin | Existing grants confirmed active/read-write |
| Vehicle Activity layout | Base `AD_Field` plus existing `AD_Tab_Customization` rows | User/Contact and Contact Activity hidden; Comments four lines; six-column operational grid |
| SuperUser tab customization | ID `1000834`; user ID `100` | Local hint only; migration resolves the tab and field IDs dynamically |
| Smoke result | Pass | Vehicle rendered as `S637 CMD`; grid showed Start Date, Activity Type, Description, Comments, End Date, and Complete |

No JAR is required. Apply `sql/05-add-vehicle-activity-tab.sql`, run Cache
Reset or log out/in, and run `sql/95-verify-vehicle-activity-tab.sql`. HCO
Test001 required one service restart because its global window-definition cache
survived Cache Reset; this is not normally required.

## Next-environment handoff

- Start with [`DEPLOY.md`](DEPLOY.md).
- Run the ordered wrappers under `Tickets/SAW026_vehicle_activity_tab/sql/`.
- Do not copy HCO numeric IDs or alter existing target UUIDs.
- Treat the Downloads packs as optional copies; the repository artifacts are
  complete for another agent.
- If the target has a saved `AD_Tab_Customization`, the apply normalizes its
  grid field IDs and widths using that environment's local `AD_Field` records.
- The HCO20260714 host `54.253.165.194` had `AD_Tab.currentnext=1000359`
  while `MAX(AD_Tab_ID)=1000361`. The migration now advances the affected
  `AD_Column`, `AD_Tab`, and `AD_Field` sequences before using `nextid`.

## HCO20260714 release evidence

| Item | HCO Test value (2026-07-17) | Notes |
|---|---|---|
| Host | `54.253.165.194` | Release HCO20260714 test environment |
| Vehicle Activity tab | ID `1000362`; UU `7d14ac4f-5fef-4f1f-b917-026000000002` | 18 active fields |
| Link column | `AbERP_Vehicle_ID`; Search reference UU `51ee0d93-0d9d-4d34-8b5b-e62a766c21fc` | Vehicle rendered `S637 CMD` |
| Role access | AbilityERP Admin + Admin | Active/read-write |
| Smoke result | Pass | Activity `1641178` saved against Vehicle `1000000` / `S637CMD`, then removed |
