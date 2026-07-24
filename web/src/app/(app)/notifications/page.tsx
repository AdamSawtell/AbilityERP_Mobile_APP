import Link from "next/link";
import { fetchWithSession } from "@/lib/server-data";

interface NotificationItem {
  id: string;
  type: string;
  title: string;
  body: string;
  href: string;
  createdAt: string | null;
}

interface NotificationSummary {
  unreadCount: number;
  items: NotificationItem[];
}

function formatWhen(value: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleString(undefined, {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  });
}

export default async function NotificationsPage() {
  const data = await fetchWithSession<NotificationSummary>("/api/notifications");
  const items = data?.items ?? [];

  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-xl font-semibold text-gray-900">Notifications</h2>
        <p className="mt-1 text-sm text-gray-600">
          Things that need your attention — rostering replies first.
        </p>
      </div>

      {!items.length ? (
        <div className="rounded-xl border border-gray-200 bg-white p-4 text-sm text-gray-600">
          <p className="font-medium text-gray-900">You&apos;re up to date</p>
          <p className="mt-1">No replies waiting. Check Open for available shifts anytime.</p>
          <div className="mt-3 flex gap-2">
            <Link
              href="/open-shifts"
              className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white"
            >
              Open shifts
            </Link>
            <Link
              href="/tasks"
              className="rounded-lg border border-gray-200 px-3 py-2 text-xs font-semibold text-gray-800"
            >
              Chat
            </Link>
          </div>
        </div>
      ) : (
        <ul className="space-y-2">
          {items.map((item) => (
            <li key={item.id}>
              <Link
                href={item.href}
                className="block rounded-xl border border-amber-200 bg-amber-50 p-4 shadow-sm"
              >
                <p className="text-sm font-semibold text-amber-950">{item.title}</p>
                <p className="mt-1 text-sm text-amber-900">{item.body}</p>
                {formatWhen(item.createdAt) ? (
                  <p className="mt-2 text-xs text-amber-800/80">{formatWhen(item.createdAt)}</p>
                ) : null}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
