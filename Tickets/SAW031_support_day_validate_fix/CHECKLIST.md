# SAW031 — Checklist

- [x] Root cause identified (`EEEE` overwrite in `MOrderLineAbERP.beforeSave`)
- [x] Reproduced `Invalid value - Thursday` on HCO Test
- [x] Patched generator JAR (stackmap-safe) — now `…2026072205-saw031` (EEEE discarded + typed setters no-op + Export-Package model)
- [x] Cleanup SQL applied (weekday leftovers → 0)
- [x] Overlay plugin built/installed — `…2026072205` (restore days + blank-day ghost clear + callout without loading MOrderLineAbERP)
- [x] Full WebUI E2E green on HCO Test (2026-07-22):
  - 53179 Simon L60 `1078297` — days `3`/`3` stay; Validated + Ready to Claim
  - 53179 Tania L20 `1083753` — blank Support days (Friday start); Validated + Ready to Claim; no `Invalid value - Friday`
  - 53175 Tamika L130 `1078205` — days `2`/`2` stay; Record saved
- [x] Downloads staging + prod packs (`Downloads\AbilityERP-*-SAW031_support_day_validate_fix-20260722`)
- [x] GitHub issue + registry + commit/push
- [x] Deploy scripts aligned to verified jar versions (`2205` generator / `2205` overlay)
- [x] Production pack ready (JARs SHA256-match Test + HOW-TO + SQL); HCO Prod preflight logged
- [ ] Install on HCO Production (`13.239.162.141`) + smoke + LEARNINGS append
- [ ] Mark GitHub issue `done` after prod install
