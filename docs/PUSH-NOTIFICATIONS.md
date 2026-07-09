# Push Notifications — Implementation Plan

Status: **Not implemented** (Phase 3). The app is a installable web app with manifest only — no service worker or push yet.

---

## Current PWA state

| Feature | Status |
|---------|--------|
| `manifest.json` | Yes — name, theme, standalone display |
| App icons | Missing (empty `icons[]`) — hurts install UX |
| Service worker | No |
| Web Push | No |
| Offline cache | No |

---

## What push would cover (worker app)

| Event | Example message |
|-------|-----------------|
| New open shift | "Saturday shift available at Rover Road — tap to apply" |
| Application approved | "Your shift on 14 Jul is confirmed" |
| Application declined / superseded | "Shift request update — check Schedule" |
| Roster change | "Your schedule for next fortnight has changed" |
| Leave approved / rejected | "Leave request updated" |

---

## Architecture (recommended)

```
iDempiere event / cron on EC2
        ↓
Express API — notification job
        ↓
web-push (VAPID) → browser push service (FCM/Mozilla)
        ↓
Service worker on worker phone → notification tap → open app route
```

### Components to build

1. **Service worker** (`web/public/sw.js` or `next-pwa`)
   - `push` event handler
   - `notificationclick` → deep link to `/open-shifts`, `/shifts`, etc.

2. **Subscription API** (Express)
   - `POST /api/notifications/subscribe` — store `{ ad_user_id, endpoint, keys }`
   - Table: `aberp_worker_push_subscription` (new) or JSON in AD_SysConfig per env

3. **VAPID keys** (generate once per environment)
   - Env: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT=mailto:...`
   - Amplify: expose public key to client

4. **Client opt-in** (Profile or first-login prompt)
   - `Notification.requestPermission()`
   - `pushManager.subscribe()` → send to API

5. **Send triggers** (pick one to start)
   - **Cron on EC2** — poll new open shifts / responselog changes every N minutes
   - **iDempiere plugin hook** — ideal long-term, contradicts “no Java plugins” constraint for Phase 1
   - **Manual admin send** — for testing

6. **PWA polish (do first)**
   - Add 192×192 and 512×512 icons to `manifest.json`
   - Register service worker on app load
   - Apple touch icon + meta tags

---

## Effort estimate

| Phase | Work | Depends on |
|-------|------|------------|
| **3a — Installable PWA** | Icons + service worker shell | Design assets |
| **3b — Push infrastructure** | VAPID, subscribe API, SW handler | 3a |
| **3c — Shift notifications** | Cron + open shift detector | 3b, seeded/live shift data |
| **3d — Full roster/leave push** | More triggers + iDempiere integration | Business rules sign-off |

---

## Quick wins before push

1. Add app icons (required for credible “Add to Home Screen”).
2. Link **Worker Guide** from Profile or login footer (`docs/WORKER-GUIDE.md`).
3. Optional: “Install app” hint banner on first mobile visit.

---

## References

- [Web Push API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Push_API)
- [web-push npm](https://www.npmjs.com/package/web-push)
- Worker usage: [WORKER-GUIDE.md](./WORKER-GUIDE.md)
