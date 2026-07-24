# Push Notifications — Implementation Plan

Status: **Phase 3a done (SAW034)** — installable PWA shell. Web Push not implemented yet.

---

## Current PWA state

| Feature | Status |
|---------|--------|
| `manifest.json` | Yes — name, theme, standalone display |
| App icons | Yes — `web/public/icons/` (192 / 512 / Apple / favicon); regenerate via `scripts/generate-pwa-icons.js` |
| Service worker | Yes — shell only (`web/public/sw.js`, registered by `PwaClient`) |
| Install hint | Yes — Chromium `beforeinstallprompt` + iOS Share instructions |
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

1. **Service worker** (`web/public/sw.js`)
   - Shell registered (SAW034)
   - Still needed: `push` event handler + `notificationclick` → deep link to `/open-shifts`, `/shifts`, etc.

2. **Subscription API** (Express)
   - `POST /api/notifications/subscribe` — store `{ ad_user_id, endpoint, keys }`
   - Table: `aberp_worker_push_subscription` (new) or JSON in AD_SysConfig per env
   - Likely Kind **both** when AD/SQL ships with the app change

3. **VAPID keys** (generate once per environment)
   - Env: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT=mailto:...`
   - Amplify: expose public key to client

4. **Client opt-in** (Profile or first-login prompt)
   - `Notification.requestPermission()`
   - `pushManager.subscribe()` → send to API

5. **Send triggers** (pick one to start)
   - **Cron on EC2** — poll new open shifts / responselog changes every N minutes
   - **iDempiere plugin hook** — ideal long-term
   - **Manual admin send** — for testing

---

## Effort estimate

| Phase | Work | Depends on | Ticket |
|-------|------|------------|--------|
| **3a — Installable PWA** | Icons + SW shell + install hint | — | **SAW034** (this) |
| **3b — Push infrastructure** | VAPID, subscribe API, SW handler | 3a | next |
| **3c — Shift notifications** | Cron + open shift detector | 3b, seeded/live shift data | later |
| **3d — Full roster/leave push** | More triggers + iDempiere integration | Business rules sign-off | later |

---

## Quick wins (remaining)

1. Link **Worker Guide** from Profile or login footer (`docs/WORKER-GUIDE.md`) — content lives in repo; publish URL if/when docs are hosted.
2. Offline shell cache (optional; careful with Next.js asset hashing).

---

## References

- [Web Push API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Push_API)
- [web-push npm](https://www.npmjs.com/package/web-push)
- Worker usage: [WORKER-GUIDE.md](./WORKER-GUIDE.md)
