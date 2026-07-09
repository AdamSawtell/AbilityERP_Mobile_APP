# Accept Shift Request — iDempiere Plugin

Adds an **Accept Shift Request** toolbar button on **Shift (Rostered) → Response Log**.

When a worker has replied **REQ** and the row is not yet reviewed, a rostering officer selects the response log line and clicks **Accept Shift Request**. The process:

1. Validates the response is `REQ`, active, not superseded, not reviewed
2. Resolves the worker's `C_BPartner` from `AbERP_User_Contact_ID`
3. Assigns them on `AbERP_Rostered_ShiftStaff` (updates an open staff line or creates one)
4. Sets `IsReviewed = Y` on the response log
5. Clears `AbERP_IsShowingAsAvailable` on the shift when assigned

## Build (on iDempiere server)

```bash
cd idempiere-plugins/com.aberp.rosteredshift.process
chmod +x build.sh deploy.sh
./build.sh
```

Requires Java 11 and iDempiere at `/opt/idempiere-server`.

## Deploy

```bash
./deploy.sh
```

This copies the JAR to `customization-jar/` and `plugins/`, registers the OSGi bundle, runs:

- `sql/register-accept-shift-request.sql` (process + **process access for Admin / Rostering Officer**)
- `sql/add-accept-button-field.sql`
- `sql/enable-accept-button-safe.sql` (if present)

See **`docs/DEV-REQUIREMENTS.md`** — every new process/button must grant `AD_Process_Access` to **AbilityERP Admin** (`AD_Role_ID = 1000004`).

Then:

```bash
sudo systemctl restart idempiere
```

**Every iDempiere plugin or JAR change needs a systemd restart** — OSGi does not hot-reload new bundles.

Check status after deploy:

```bash
sudo systemctl status idempiere
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/
```

AD-only SQL changes (no JAR) do not require a restart; toolbar/process metadata is picked up on next login.

## Manual test

1. Open **Shift (Rostered)** for a shift with a pending REQ in Response Log.
2. Select the REQ row → **Accept Shift Request**.
3. Confirm shift staff shows the worker and response log `IsReviewed = Y`.
