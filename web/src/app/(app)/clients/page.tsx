import Link from "next/link";
import { EmptyState } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";

interface ClientItem {
  id: number;
  name: string;
  value: string | null;
  nextShiftAt: string | null;
  hasCarePlan: boolean;
}

function formatWhen(value: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleString(undefined, {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default async function ClientsPage() {
  const data = await fetchWithSession<{ items: ClientItem[] }>("/api/clients");
  const items = data?.items ?? [];

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Clients</h2>
      <p className="text-sm text-gray-600">
        People on your shifts — open for alerts, contacts, and shift essentials.
      </p>
      {items.length ? (
        <div className="space-y-2">
          {items.map((client) => {
            const next = formatWhen(client.nextShiftAt);
            return (
              <Link
                key={client.id}
                href={`/clients/${client.id}`}
                className="block rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="font-semibold text-gray-900">{client.name}</h3>
                    {next ? (
                      <p className="mt-1 text-xs text-gray-500">Next with you: {next}</p>
                    ) : (
                      <p className="mt-1 text-xs text-gray-500">Recent / upcoming support</p>
                    )}
                  </div>
                  {client.hasCarePlan ? (
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700">
                      Care plan
                    </span>
                  ) : null}
                </div>
              </Link>
            );
          })}
        </div>
      ) : (
        <EmptyState message="No clients on your shifts yet." />
      )}
    </section>
  );
}
