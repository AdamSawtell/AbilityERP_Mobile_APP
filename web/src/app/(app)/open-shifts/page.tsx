import OpenShiftsList from "@/components/OpenShiftsList";
import type { ShiftItem } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";

export default async function OpenShiftsPage() {
  const data = await fetchWithSession<{ items: ShiftItem[] }>("/api/shifts/open");

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Available Shifts</h2>
      <p className="text-sm text-gray-600">Browse open shifts and apply.</p>
      <OpenShiftsList shifts={data?.items ?? []} />
    </section>
  );
}
