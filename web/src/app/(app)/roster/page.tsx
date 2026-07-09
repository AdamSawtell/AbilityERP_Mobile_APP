import { EmptyState, ShiftCard } from "@/components/ShiftCard";
import type { ShiftItem } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";

interface RosterTemplate {
  id: number;
  name: string;
  value: string | null;
}

export default async function RosterPage() {
  const [current, master] = await Promise.all([
    fetchWithSession<{ items: ShiftItem[] }>("/api/roster/current"),
    fetchWithSession<{ items: RosterTemplate[] }>("/api/roster/master"),
  ]);

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">Roster</h2>
      <p className="text-sm text-gray-600">Master and current roster views (read-only).</p>

      <div>
        <h3 className="mb-2 font-medium text-gray-900">Current roster</h3>
        {current?.items?.length ? (
          <div className="space-y-3">
            {current.items.slice(0, 10).map((shift) => (
              <ShiftCard key={`current-${shift.id}-${shift.staff_name ?? "open"}`} shift={shift} />
            ))}
          </div>
        ) : (
          <EmptyState message="No current roster entries." />
        )}
      </div>

      <div>
        <h3 className="mb-2 font-medium text-gray-900">Master roster templates</h3>
        {master?.items?.length ? (
          <div className="space-y-2">
            {master.items.map((template) => (
              <div
                key={template.id}
                className="rounded-xl border border-gray-200 bg-white p-4"
              >
                <p className="font-medium text-gray-900">{template.name}</p>
                {template.value ? (
                  <p className="text-sm text-gray-500">{template.value}</p>
                ) : null}
              </div>
            ))}
          </div>
        ) : (
          <EmptyState message="No master roster templates." />
        )}
      </div>
    </section>
  );
}
