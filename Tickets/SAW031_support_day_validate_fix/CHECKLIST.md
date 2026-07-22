# SAW031 — Checklist

- [x] Root cause identified (`EEEE` overwrite in `MOrderLineAbERP.beforeSave`)
- [x] Reproduced `Invalid value - Thursday` on HCO Test
- [x] Patched generator JAR (stackmap-safe) — now `…2026072204-saw031` (EEEE discarded + typed setters no-op)
- [x] Cleanup SQL applied (weekday leftovers → 0)
- [x] Overlay plugin built/installed — `…2026072202` (restore days + Validated callout)
- [ ] Manual WebUI smoke green (Validate + Save + Ready to Claim) after final restart
- [ ] Downloads staging + prod packs
- [x] GitHub issue + registry + commit/push
- [ ] Mark done when smoke confirmed
