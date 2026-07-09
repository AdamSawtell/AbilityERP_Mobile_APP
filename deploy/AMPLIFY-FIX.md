# Amplify fix — blank / 404 site

Your app ID (from the URL): **d2pmnegzhwkj4b**  
Region (likely): **ap-southeast-2**

Symptom: `Server: AmazonS3` + 404 = static hosting, not Next.js SSR.

---

## Step 1 — AWS CLI (required for existing static apps)

Run in **AWS CloudShell** or anywhere with AWS credentials:

```bash
aws amplify update-app \
  --app-id d2pmnegzhwkj4b \
  --platform WEB_COMPUTE \
  --region ap-southeast-2

aws amplify update-branch \
  --app-id d2pmnegzhwkj4b \
  --branch-name main \
  --framework "Next.js - SSR" \
  --region ap-southeast-2
```

This cannot be done with YAML alone if the app was created as static **Web**.

---

## Step 2 — Environment variables

Amplify Console → **Hosting** → **Environment variables** → add:

| Variable | Value |
|----------|--------|
| `AMPLIFY_MONOREPO_APP_ROOT` | `web` |
| `API_BASE_URL` | `http://ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com` |
| `NEXT_PUBLIC_APP_URL` | `https://main.d3ec4nkn82ouib.amplifyapp.com` |

`AMPLIFY_MONOREPO_APP_ROOT` is **required** for monorepos (repo has `web/` folder).

---

## Step 3 — Build spec (use repo, not empty default)

Amplify Console → **Hosting** → **Build settings** → **Edit**

**Option A (recommended):** Delete the custom override and use the repo file  
→ Check **"Use a buildspec file from the repository"** / remove the empty custom spec.

The repo root `amplify.yml` should contain:

```yaml
version: 1
applications:
  - appRoot: web
    platform: WEB_COMPUTE
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - "**/*"
      cache:
        paths:
          - node_modules/**/*
          - .next/cache/**/*
```

**Option B:** Paste the YAML above into the console editor if you cannot use the repo file.

**Delete** the broken spec you had:

```yaml
build:
  commands: []        # ← this does nothing
baseDirectory: /      # ← wrong
```

---

## Step 4 — Redeploy

**Hosting** → **Deployments** → **Redeploy this version**

Wait until status = **Deployed** (watch build log for `npm run build` success).

---

## Step 5 — Verify

```powershell
curl.exe -sI https://main.d2pmnegzhwkj4b.amplifyapp.com/login
```

| Bad (still broken) | Good (fixed) |
|--------------------|--------------|
| `Server: AmazonS3` + 404 | `200` and HTML with "Worker sign in" |

---

## EC2 / iDempiere server

No extra ports needed. Already working:

- API: localhost **3001** (PM2)
- Public: Apache **80** → `/api/` → 3001
- Test: `curl http://ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com/api/health`

---

## After login works

Test without SSO: username `ewilliam`, password `flamingo`.
