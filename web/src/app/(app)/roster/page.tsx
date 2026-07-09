import {
  EmptyState,
  MasterRosterLineCard,
  type MasterRosterLine,
  type MasterRosterTemplate,
} from "@/components/MasterRosterLineCard";
import { fetchWithSession } from "@/lib/server-data";

interface MasterRosterResponse {
  templates: MasterRosterTemplate[];
  items: MasterRosterLine[];
}

export default async function RosterPage() {
  const data = await fetchWithSession<MasterRosterResponse>("/api/roster/master");

  const templates = data?.templates ?? [];
  const items = data?.items ?? [];

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">My Master Roster</h2>
      <p className="text-sm text-gray-600">
        Your recurring roster pattern from AbilityERP.
      </p>

      {templates.length ? (
        <div className="flex flex-wrap gap-2">
          {templates.map((template) => (
            <span
              key={template.id}
              className="rounded-full bg-blue-50 px-3 py-1 text-xs font-medium text-blue-700"
            >
              {template.name}
              {template.value ? ` (${template.value})` : ""}
            </span>
          ))}
        </div>
      ) : null}

      {items.length ? (
        <div className="space-y-3">
          {items.map((line) => (
            <MasterRosterLineCard key={line.id} line={line} />
          ))}
        </div>
      ) : (
        <EmptyState message="No master roster is assigned to your profile yet." />
      )}
    </section>
  );
}
