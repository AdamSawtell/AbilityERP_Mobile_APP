# AbilityERP — Developer Requirements

Checklist for any new feature, window, process, button, or API surface in this project.

Also see: `.cursor/rules/ticket-ids.mdc`, `.cursor/rules/github-role-access-docs.mdc`, `Tickets/README.md` (`DEPLOY.md` + **`EXTERNAL-SUMMARY.md`**), `client-update-staging-loop.mdc`, **`hco-deployment.mdc`** + [`Tickets/HCO_Deployment/`](../Tickets/HCO_Deployment/) (HCO client installs — never change HCO UUIDs; append learnings).

---

## iDempiere (Application Dictionary)

Every AD change must be scripted in SQL under `idempiere-plugins/*/sql/` (or `scripts/`) and applied to the target database. Do not rely on manual Dictionary edits in production.

### 0. AbilityERP Admin access — mandatory (explainer)

**Every new or changed UI surface must be usable by AbilityERP Admin after install.**

Grant (in the migration / install SQL, not as a manual afterthought):

| Object | Access table | Rule |
|--------|--------------|------|
| **Window** (new) | `AD_Window_Access` | Always grant **AbilityERP Admin** |
| **Process** (new or newly bound to a button) | `AD_Process_Access` | Always grant **AbilityERP Admin** |
| **Info Window** (new, or newly menued) | `AD_InfoWindow_Access` (or equivalent role access used on the build) | Always grant **AbilityERP Admin** |
| **Form** (new) | `AD_Form_Access` | Always grant **AbilityERP Admin** |
| **Toolbar / button → process** | Same as process access | Button will not show/run without Admin process access |

| Role | Seed `AD_Role_ID` | `AD_Client_ID` | Rule |
|------|-------------------|----------------|------|
| **AbilityERP Admin** | `1000004` | `1000002` | **Always** — windows, processes, Info Windows, forms, buttons |
| **System Administrator** | `0` | `0` | Optional for SuperUser testing |
| Operational roles (e.g. Rostering Officer `1000012`) | client-specific | `1000002` | When that role uses the feature day-to-day |

**Portability:** resolve AbilityERP Admin by **role name** (and client) on other builds if IDs differ; still document seed IDs as hints only.

**HCO:** SuperUser’s role dialog often exposes operational **Admin**, not AbilityERP Admin. Grant Info Window / window / process access by **name** to both **Admin** and **AbilityERP Admin**. See `Tickets/HCO_Deployment/LEARNINGS.md`.

After granting access, users must **log out and log back in** (or run **Role Access Update**) before menus/buttons appear.

Use templates such as `idempiere-plugins/com.aberp.rosteredshift.process/sql/grant-process-access-roles.sql` and mirror the same pattern for window / info / form access.

**Ticket handoff:** `DEPLOY.md` must list Admin grants; `EXTERNAL-SUMMARY.md` must tell the customer that Admin can use the feature.

### 0a. Role access documentation — mandatory (GitHub + tickets)

When documenting windows/processes for roles (GitHub issue, `DEPLOY.md`, `EXTERNAL-SUMMARY.md`), always include this table so Role → Window / Process Access can be filled without digging in AD:

| Access | Name | Search key |
|--------|------|------------|
| Window | Invoice Capture | — |
| Process | Upload Invoice PDF | `AbERP_InvoiceCapture_UploadPdf` |
| Process | Process Selected Invoice | `AbERP_InvoiceCapture_ProcessSelected` |
| Process | Process Invoice Capture Batch | `AbERP_InvoiceCapture_ProcessBatch` |

| Column | Rule |
|--------|------|
| **Access** | `Window`, `Process`, `Info Window`, or `Form` |
| **Name** | AD display name (Role access picker / menu) |
| **Search key** | Process/Info `Value` when it exists; `—` for windows |

List **every** process the feature needs (including button/upload processes), not only the menu batch. Cursor rule: `.cursor/rules/github-role-access-docs.mdc`.

### 1. Process access

**All new `AD_Process` records must have `AD_Process_Access` for AbilityERP Admin** (and any operational roles that need them).

Button fields (`AD_Reference_ID = 28`) and toolbar buttons that call a process inherit the same access — if the role cannot run the process, the button will not appear or will fail silently.

### 2. Window / tab / field / Info Window access

When adding a **new window, tab, Info Window, or form**:

- Grant **AbilityERP Admin** the matching access row(s).
- Confirm field visibility on the target tab (`AD_Field`: `IsDisplayed`, `IsDisplayedGrid`, seqno).
- For button fields, follow the **Shift Offer SMS** pattern on parent tabs or the **Accept Shift Request** pattern on child tabs (physical column + `IsToolbarButton = B` on the column).

### 3. Plugin deploy checklist

When shipping a Java/OSGi plugin:

1. **Use a unique `Bundle-SymbolicName`** — never reuse an existing AbERP bundle name (e.g. do not deploy to `com.aberp.rosteredshift.process`; use `com.aberp.rosteredshift.acceptrequest` for add-on processes).
2. Build JAR with valid `META-INF/MANIFEST.MF` (`jar cfm`, not `jar cf`).
3. Copy to `customization-jar/` and `plugins/`; register in `bundles.info` if new.
4. Run registration SQL (process, column, field, **Admin + role access** for windows/processes/info/forms).
5. **`sudo systemctl restart idempiere`** — required after every JAR change. **Do not clear `configuration/org.eclipse.osgi`** — AbERP plugins are installed dynamically via OSGi telnet and live only in that cache; wiping it breaks login (missing model validator classes) until plugins are re-deployed via `logilite_deploy_plugins.sh`.
6. Log out/in on web UI to refresh AD cache.
7. Smoke-test **as AbilityERP Admin**: open target window/tab/Info, confirm no row-load timeout, confirm button/process visible, **click button and confirm process completes**.

AD-only SQL (no JAR change) does **not** require restart; still requires logout/login for cache.

### 4. Common mistakes

| Symptom | Likely cause |
|---------|----------------|
| Button missing for Admin | No `AD_Process_Access` for AbilityERP Admin |
| Window/Info missing for Admin | No `AD_Window_Access` / Info Window access for Admin |
| Button missing for rostering staff | Process access not granted to Rostering Officer |
| Process menu empty | Same — process access missing for logged-in role |
| Tab timeout on open | Virtual button field with complex `@DisplayLogic@` on child tab grid load |
| Change not visible after SQL | Stale session — close window, log out/in |

### 5. Ticket artefacts (idempiere / both)

| File | Audience | Purpose |
|------|----------|---------|
| `Tickets/SAW###_…/EXTERNAL-SUMMARY.md` | Customer / external ticket | Copy/paste: **Windows/processes affected** table, done, changed, impact, test, Admin access |
| `Tickets/SAW###_…/DEPLOY.md` | Agents / installers | Install on another build |
| `docs/TICKETS.md` | Everyone | Registry index |

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
- EC2 plugin deploy: plugin `deploy.sh` on server (or Downloads pack HOW-TO).
- PWA: push to `main` triggers Amplify build.

---

## Reference IDs (AbilityERP seed — hints only)

| Item | ID |
|------|-----|
| AbilityERP client | `1000002` |
| AbilityERP Admin role | `1000004` |
| Rostering Officer role | `1000012` |
| Shift (Rostered) window | `1000119` |
| Response Log tab | `1000366` |

Resolve by **name / UU** on other builds — numeric IDs may differ.
