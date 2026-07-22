# SAW031 — Notes

## Reproduction (HCO Test `3.25.213.143`, 2026-07-22)

- Docs cited: `53179`, `53175` (also smoked on `53361` line `1083751`).
- Before fix: Validate/Save → `Validate: AbERP_Support_Start_Day Invalid value - Thursday - Reference_ID=100021…`
- DB had ~5259 order lines with weekday text after SAW009 List change.

## Root cause evidence

`MOrderLineAbERP.beforeSave` (generator `7.1.12.202602251048`):

```text
SimpleDateFormat("EEEE")
setAbERPSupportStartDay(format(StartDate))
setAbERPSupportEndDay(format(EndDate))
```

Only when parent `isSOTrx` and both Start/End dates non-null.

## Fix approach

1. Stackmap-safe bytecode patch: replace setter `invokevirtual` with `pop; pop; nop` after EEEE format (keeps control flow / StackMapTable intact).
2. First attempt (`ifeq`→`goto`) caused `VerifyError: Inconsistent stackmap frames at branch target 708` — abandoned.
3. Data cleanup SQL nulls non-numeric support days; backfill from pattern.
4. Overlay ModelFactory kept as defense in depth (ranking 100 vs generator 10).

## HCO Future Deployments variables

| Variable | Value |
|----------|--------|
| Host used | `3.25.213.143` (AbERP HCO Test 20260721) |
| Patched generator | `com.aberp.servicebooking.generator_7.1.12.2026072205-saw031.jar` |
| Overlay | `com.aberp.servicebooking.supportdays_7.1.0.2026072205.jar` |
| Cleanup | 5259 start + 5259 end weekday rows nulled; leftover verify = 0 |
| Do not change HCO `*_UU` | N/A (no AD UU changes in SAW031) |

## E2E smoke (2026-07-22, Admin)

| Doc | Line | `c_orderline_id` | Days after Validate/Save | `aberp_isvalidated` | Result |
|-----|------|------------------|--------------------------|---------------------|--------|
| 53179 Simon Murphy | 60 | 1078297 | `3` / `3` (UI `03 - Wednesday`) | Y | Pass — Record saved; Ready to Claim auto |
| 53175 Tamika Bartlett | 130 | 1078205 | `2` / `2` (UI `02 - Tuesday`) | Y | Pass — Record saved; Ready to Claim auto |

Mid-fix: callout importing `MOrderLineSupportDays` caused `NoClassDefFoundError: MOrderLineAbERP` (generator MANIFEST had no `Export-Package`). Fixed by exporting `com.aberp.servicebooking.generator.model` and rewriting callout to DB-only restore (no generator class load).

Blank Support days + Validate: GridTab can hold a weekday-name ghost (UI shows blank) → `Invalid value - Friday`. Overlay `2026072205` clears ghosts on Validated and swallows that Support Day list Validate error in `beforeSave` so blank days are allowed.
