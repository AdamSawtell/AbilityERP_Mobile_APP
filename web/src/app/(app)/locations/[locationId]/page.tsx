import type { ReactNode } from "react";
import Link from "next/link";
import { notFound } from "next/navigation";
import { fetchWithSession } from "@/lib/server-data";

interface LocationAlert {
  id: number;
  type: string | null;
  name: string | null;
  description: string | null;
  isAlert: boolean;
}

interface LocationRoom {
  id: number;
  name: string | null;
  number: string | null;
  details: string | null;
  use: string | null;
}

interface LocationDetail {
  id: number;
  name: string;
  address: string | null;
  phone: string | null;
  keyboxCode: string | null;
  alarmCode: string | null;
  accessDetails: string | null;
  accessibilityFeatures: string | null;
  wheelchairAccessible: boolean | null;
  capacity: string | null;
  bushfireDangerArea: boolean;
  tenancyType: string | null;
  propertyManager: string | null;
  externalLink1: string | null;
  externalLink2: string | null;
  alerts: LocationAlert[];
  rooms: LocationRoom[];
}

function Field({ label, value }: { label: string; value: ReactNode }) {
  if (value === null || value === undefined || value === "") return null;
  return (
    <div>
      <dt className="text-gray-500">{label}</dt>
      <dd className="font-medium text-gray-900">{value}</dd>
    </div>
  );
}

function CodeField({ label, value }: { label: string; value: string | null }) {
  if (!value) return null;
  return (
    <div className="rounded-lg bg-gray-50 px-3 py-2">
      <dt className="text-xs text-gray-500">{label}</dt>
      <dd className="font-mono text-base font-semibold tracking-wide text-gray-900">{value}</dd>
    </div>
  );
}

export default async function LocationDetailPage({
  params,
}: {
  params: Promise<{ locationId: string }>;
}) {
  const { locationId } = await params;
  const data = await fetchWithSession<{ location: LocationDetail }>(
    `/api/locations/${locationId}`,
  );
  if (!data?.location) notFound();
  const location = data.location;

  return (
    <div className="space-y-3">
      <div>
        <Link href="/locations" className="text-sm font-medium text-blue-600">
          ← Locations
        </Link>
        <h2 className="mt-2 text-xl font-semibold text-gray-900">{location.name}</h2>
        {location.address ? (
          <p className="mt-1 text-sm text-gray-600">{location.address}</p>
        ) : null}
      </div>

      {location.alerts.length ? (
        <section className="rounded-xl border border-amber-300 bg-amber-50 p-4">
          <h3 className="text-sm font-semibold text-amber-950">Location alerts</h3>
          <ul className="mt-2 space-y-2">
            {location.alerts.map((alert) => (
              <li key={alert.id} className="text-sm text-amber-950">
                <p className="font-semibold">
                  {alert.isAlert ? "⚠ " : ""}
                  {[alert.type, alert.name].filter(Boolean).join(" · ") || "Alert"}
                </p>
                {alert.description ? (
                  <p className="mt-0.5 text-amber-900">{alert.description}</p>
                ) : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {(location.keyboxCode || location.alarmCode || location.accessDetails) && (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="text-sm font-semibold text-gray-900">Getting in</h3>
          <div className="mt-3 grid grid-cols-2 gap-2">
            <CodeField label="Key box" value={location.keyboxCode} />
            <CodeField label="Alarm" value={location.alarmCode} />
          </div>
          <dl className="mt-3 space-y-3 text-sm">
            <Field label="Access details" value={location.accessDetails} />
          </dl>
        </section>
      )}

      <section className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="text-sm font-semibold text-gray-900">Site info</h3>
        <dl className="mt-3 space-y-3 text-sm">
          <Field
            label="Phone"
            value={
              location.phone ? (
                <a href={`tel:${location.phone}`} className="text-blue-600">
                  {location.phone}
                </a>
              ) : null
            }
          />
          <Field
            label="Wheelchair accessible"
            value={
              location.wheelchairAccessible === null
                ? null
                : location.wheelchairAccessible
                  ? "Yes"
                  : "No"
            }
          />
          <Field label="Accessibility" value={location.accessibilityFeatures} />
          <Field label="Capacity" value={location.capacity} />
          <Field
            label="Bushfire danger area"
            value={location.bushfireDangerArea ? "Yes" : null}
          />
          <Field label="Tenancy" value={location.tenancyType} />
          <Field label="Property manager" value={location.propertyManager} />
          <Field
            label="Link"
            value={
              location.externalLink1 ? (
                <a
                  href={location.externalLink1}
                  target="_blank"
                  rel="noreferrer"
                  className="text-blue-600 break-all"
                >
                  {location.externalLink1}
                </a>
              ) : null
            }
          />
          <Field
            label="Link 2"
            value={
              location.externalLink2 ? (
                <a
                  href={location.externalLink2}
                  target="_blank"
                  rel="noreferrer"
                  className="text-blue-600 break-all"
                >
                  {location.externalLink2}
                </a>
              ) : null
            }
          />
        </dl>
      </section>

      {location.rooms.length ? (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="text-sm font-semibold text-gray-900">Rooms</h3>
          <ul className="mt-3 space-y-3">
            {location.rooms.map((room) => {
              const title =
                [room.number, room.name].filter(Boolean).join(" · ") || "Room";
              return (
                <li key={room.id} className="text-sm">
                  <p className="font-semibold text-gray-900">{title}</p>
                  {room.use ? <p className="text-xs text-blue-700">{room.use}</p> : null}
                  {room.details ? <p className="mt-0.5 text-gray-600">{room.details}</p> : null}
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
