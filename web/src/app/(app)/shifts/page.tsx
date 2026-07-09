import { EmptyState, ShiftCard } from "@/components/ShiftCard";
import type { ShiftItem } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";

export default async function ShiftsPage() {
  const data = await fetchWithSession<{ items: ShiftItem[] }>("/api/shifts/mine");

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">My Schedule</h2>
      <p className="text-sm text-gray-600">Your rostered and requested shifts.</p>
      {data?.items?.length ? (
        <div className="space-y-3">
          {data.items.map((shift) => (
            <ShiftCard key={shift.id} shift={shift} />
          ))}
        </div>
      ) : (
        <EmptyState message="No scheduled shifts yet." />
      )}
    </section>
  );
}
