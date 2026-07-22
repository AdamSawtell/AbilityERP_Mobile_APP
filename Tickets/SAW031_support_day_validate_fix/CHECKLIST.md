# SAW031 — Checklist

- [x] Root cause identified (`EEEE` overwrite in `MOrderLineAbERP.beforeSave`)
- [x] Reproduced `Invalid value - Thursday` on HCO Test
- [x] Patched generator JAR (stackmap-safe) — now `…2026072205-saw031` (EEEE discarded + typed setters no-op + Export-Package model)
- [x] Cleanup SQL applied (weekday leftovers → 0)
- [x] Overlay plugin built/installed — `…2026072203` (restore days + callout without loading MOrderLineAbERP)
- [x] Manual WebUI smoke green (Validate + Save + Ready to Claim) after final restart — 53179 / 53175
- [ ] Downloads staging + prod packs
- [x] GitHub issue + registry + commit/push
- [ ] Mark done when packs shipped
