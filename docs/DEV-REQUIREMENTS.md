# AbilityERP — Developer Requirements

Checklist for any new feature, window, process, button, or API surface in this project.

---

## iDempiere (Application Dictionary)

Every AD change must be scripted in SQL under `idempiere-plugins/*/sql/` (or `scripts/`) and applied to the target database. Do not rely on manual Dictionary edits in production.

### 1. Process access — mandatory

**All new `AD_Process` records must have `AD_Process_Access` rows for the roles that need to run them.**

Button fields (`AD_Reference_ID = 28`) and toolbar buttons that call a process inherit the same access — if the role cannot run the process, the button will not appear or will fail silently.

| Role | `AD_Role_ID` | `AD_Client_ID` | When to grant |
|------|--------------|----------------|---------------|
| **AbilityERP Admin** | `1000004` | `1000002` | **Always** — every new process, button, and feature |
| **System Administrator** | `0` | `0` | System-level maintenance / SuperUser testing |
| Operational roles | e.g. `1000012` Rostering Officer | `1000002` | When the feature is used by that role day-to-day |

Use the template in `idempiere-plugins/com.aberp.rosteredshift.process/sql/grant-process-access-roles.sql`.

After granting access, affected users must **log out and log back in** (or run **Role Access Update** in iDempiere) before buttons and Process menu entries appear.

### 2. Window / tab / field access

When adding a **new window or tab**:

- Grant **AbilityERP Admin** window access (`AD_Window_Access`) if the window is new.
- Confirm field visibility on the target tab (`AD_Field`: `IsDisplayed`, `IsDisplayedGrid`, seqno).
- For button fields, follow the **Shift Offer SMS** pattern on parent tabs or the **Accept Shift Request** pattern on child tabs (physical column + `IsToolbarButton = B` on the column).

### 3. Plugin deploy checklist

When shipping a Java/OSGi plugin:

1. Build JAR with valid `META-INF/MANIFEST.MF` (`jar cfm`, not `jar cf`).
2. Copy to `customization-jar/` and `plugins/`; register in `bundles.info` if new.
3. Run registration SQL (process, column, field, **process access**).
4. **`sudo systemctl restart idempiere`** — required after every JAR change.
5. Log out/in on web UI to refresh AD cache.
6. Smoke-test: open target window/tab, confirm no row-load timeout, confirm button/process visible for Admin role.

AD-only SQL (no JAR change) does **not** require restart; still requires logout/login for cache.

### 4. Common mistakes

| Symptom | Likely cause |
|---------|----------------|
| Button missing for Admin | No `AD_Process_Access` for AbilityERP Admin (`1000004`) |
| Button missing for rostering staff | Process access not granted to Rostering Officer |
| Process menu empty | Same — process access missing for logged-in role |
| Tab timeout on open | Virtual button field with complex `@DisplayLogic@` on child tab grid load |
| Change not visible after SQL | Stale session — close window, log out/in |

---

## Express API (PWA backend)

- New routes under `api/src/routes/`; JWT middleware on all worker endpoints.
- Gate by **Support Worker** role (or appropriate role) via `AD_User_Roles`.
- No secrets in repo — use `.env` / Amplify / EC2 env files.
- Document new endpoints in `ARCHITECTURE.md` module mapping when stable.

---

## PWA (Next.js / Amplify)

- App root: `web/`; monorepo build via root `amplify.yml`.
- Required Amplify env: `API_BASE_URL`, `NEXT_PUBLIC_APP_URL` (no trailing path).
- Regenerate PWA icons after org logo change (`scripts/generate-pwa-icons.js`).

---

## Git / deploy

- Commit SQL and plugin sources together with the feature.
- EC2 plugin deploy: `scripts/deploy-accept-shift-plugin.sh` or plugin `deploy.sh` on server.
- PWA: push to `main` triggers Amplify build.

---

## Reference IDs (AbilityERP client)

| Item | ID |
|------|-----|
| AbilityERP client | `1000002` |
| AbilityERP Admin role | `1000004` |
| Rostering Officer role | `1000012` |
| Shift (Rostered) window | `1000119` |
| Response Log tab | `1000366` |
| SHIFT_ACCEPT_REQUEST process | `1000709` |
