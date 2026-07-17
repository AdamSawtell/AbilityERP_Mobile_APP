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
| Vehicle Activity tab | ID `1000364`; UU `7d14ac4f-5fef-4f1f-b917-026000000002` | 18 active fields; sequence 45 |
| Activity Types | `EM`, `ME`, `PC`, `CN`, `TA` | All enabled for Vehicle |
| Role access | AbilityERP Admin + Admin | Existing grants confirmed active/read-write |
| Smoke result | Pass | Admin created Email activity against Vehicle `S637CMD`; DB parent join passed; smoke row deleted |

No JAR or restart is required. Apply `sql/05-add-vehicle-activity-tab.sql`, log out/in, and run `sql/95-verify-vehicle-activity-tab.sql`.
