import Link from "next/link";
import { fetchWithSession } from "@/lib/server-data";

interface LocationListItem {
  id: number;
  name: string;
  address: string | null;
  nextShiftAt: string | null;
  alertCount: number;
  wheelchairAccessible: boolean | null;
}

function formatNext(value: string | null): string {
  if (!value) return "Recent / upcoming support";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Upcoming shift";
  return `Next with you: ${date.toLocaleString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  })}`;
}

export default async function LocationsPage() {
  const data = await fetchWithSession<{ items: LocationListItem[] }>("/api/locations");
  const items = data?.items ?? [];

  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-xl font-semibold text-gray-900">Locations</h2>
        <p className="mt-1 text-sm text-gray-600">
          Support locations on your shifts — access codes, alerts, and rooms.
        </p>
      </div>

      {!items.length ? (
        <p className="rounded-xl border border-gray-200 bg-white p-4 text-sm text-gray-600">
          No support locations on your recent or upcoming shifts.
        </p>
      ) : (
        <ul className="space-y-2">
          {items.map((location) => (
            <li key={location.id}>
              <Link
                href={`/locations/${location.id}`}
                className="block rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
              >
                <div className="flex items-start justify-between gap-2">
                  <h3 className="font-semibold text-gray-900">{location.name}</h3>
                  {location.alertCount > 0 ? (
                    <span className="shrink-0 rounded-full bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-800">
                      {location.alertCount === 1 ? "1 alert" : `${location.alertCount} alerts`}
                    </span>
                  ) : null}
                </div>
                {location.address ? (
                  <p className="mt-1 text-sm text-gray-600">{location.address}</p>
                ) : null}
                <p className="mt-2 text-xs text-gray-500">{formatNext(location.nextShiftAt)}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
