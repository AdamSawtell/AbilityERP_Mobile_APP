# Response Log Find and Fill — external summary

## Windows / processes / objects affected

| Object | Type | Notes |
|--------|------|--------|
| Shift (Rostered) | Window | Response Log tab |
| Response Log | Tab | New **Find and Fill** button next to Reviewed |
| Employee (User) / Agency Staff Rostering Info | Info Window | Existing Find & Fill (SAW003) |
| Find and Fill | Process (button) | Opens Info; OK fills vacant Employee |

## What’s done

Rostering officers can review a response worker against the shift using the same Find and Fill screen they use on the Employee tab, with that worker prefilled. Confirming OK puts them on a vacant Employee line and marks the response reviewed.

## What changed (behaviour)

- New **Find and Fill** button on Response Log (hidden when already Reviewed)
- Opens Staff Rostering Info with shift checks (leave, already rostered, familiar, matched)
- Worker name prefilled from the response row
- OK fills the first vacant Employee slot and marks Reviewed (and publishes the shift when that path applies)

## Impact / who is affected

Rostering officers using Shift (Rostered) → Response Log. AbilityERP Admin can use it after install and Cache Reset / re-login.

## How to test

1. Open a rostered shift that has a vacant Employee line
2. On Response Log, select an unreviewed row with a worker
3. Click **Find and Fill** — Info opens with that worker and shift context
4. Confirm / select the worker → OK
5. Check Employee tab is filled and Response Log is Reviewed

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Shift (Rostered) | — |
| Info Window | Employee (User) / Agency Staff Rostering Info | — |
| Process | Find and Fill | `AbERP_ResponseLog_FindFill` |
