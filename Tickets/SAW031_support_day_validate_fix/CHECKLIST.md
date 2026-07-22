# SAW031 — Checklist

- [x] Root cause identified (`EEEE` overwrite in `MOrderLineAbERP.beforeSave`)
- [x] Reproduced `Invalid value - Thursday` on HCO Test
- [x] Patched generator JAR (stackmap-safe)
- [x] Cleanup SQL applied (weekday leftovers → 0)
- [x] Overlay plugin built/installed
- [ ] Manual WebUI smoke green (Validate + Save + Ready to Claim) after final restart
- [ ] Downloads staging + prod packs
- [ ] GitHub issue + registry + commit/push
- [ ] Mark done when smoke confirmed
