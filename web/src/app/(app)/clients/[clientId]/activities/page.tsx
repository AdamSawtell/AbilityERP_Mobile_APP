import AddActivityForm from "@/components/AddActivityForm";
import { EmptyState } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";
import { notFound } from "next/navigation";
import { Suspense } from "react";

interface ActivityItem {
  id: number;
  typeLabel: string | null;
  description: string | null;
  comments: string | null;
  startDate: string | null;
  isComplete: boolean;
}

function formatWhen(value: string | null): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleString(undefined, {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default async function ClientActivitiesPage({
  params,
}: {
  params: Promise<{ clientId: string }>;
}) {
  const { clientId } = await params;
  const id = Number(clientId);
  if (!Number.isFinite(id)) notFound();

  const data = await fetchWithSession<{ items: ActivityItem[] }>(
    `/api/clients/${clientId}/activities`,
  );
  if (!data) notFound();

  const items = data.items ?? [];

  return (
    <div className="space-y-4">
      <Suspense fallback={null}>
        <AddActivityForm clientId={id} />
      </Suspense>

      {items.length ? (
        <div className="space-y-2">
          {items.map((item) => (
            <article
              key={item.id}
              className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
            >
              <div className="flex items-start justify-between gap-2">
                <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
                  {item.typeLabel ?? "Activity"}
                </p>
                <p className="text-xs text-gray-500">{formatWhen(item.startDate)}</p>
              </div>
              <h3 className="mt-1 font-semibold text-gray-900">
                {item.description ?? "Untitled"}
              </h3>
              {item.comments ? (
                <p className="mt-2 whitespace-pre-wrap text-sm text-gray-600">{item.comments}</p>
              ) : null}
            </article>
          ))}
        </div>
      ) : (
        <EmptyState message="No activities yet. Add a progress note above." />
      )}
    </div>
  );
}
