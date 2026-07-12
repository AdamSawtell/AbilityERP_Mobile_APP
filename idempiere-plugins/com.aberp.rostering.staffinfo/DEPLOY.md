# Deploy — AbERP Rostering Staff Info

Canonical agent instructions: **`Tickets/SAW003_staff_rostering_info/DEPLOY.md`** in the AbilityERP repo.

```bash
chmod +x build.sh deploy.sh && ./deploy.sh
# then Cache Reset / logout-in (do not wipe OSGi configuration cache)
```

- Bundle version: **`1.1.0.2026071219`**
- SQL order is in `deploy.sh` (`01`→`20`→`04`). **`20-hide-clutter-columns.sql` must remain last** before `04-verify.sql`.
- Packs: `AbilityERP-*-SAW003_staff_rostering_info-20260712` (JAR + HOW-TO refreshed with 1219).
