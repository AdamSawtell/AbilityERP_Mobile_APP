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

function startMinutes(value: string | null): number {
  if (!value) return Number.MAX_SAFE_INTEGER;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return Number.MAX_SAFE_INTEGER;
  return date.getHours() * 60 + date.getMinutes();
}

function groupByFortnightDay(items: MasterRosterLine[]): Map<number, MasterRosterLine[]> {
  const grouped = new Map<number, MasterRosterLine[]>();

  for (const line of items) {
    const day = line.roster_start_day;
    if (!day || day < 1 || day > 14) continue;
    const bucket = grouped.get(day) ?? [];
    bucket.push(line);
    grouped.set(day, bucket);
  }

  for (const [day, lines] of grouped) {
    lines.sort(
      (a, b) =>
        startMinutes(a.start_time) - startMinutes(b.start_time) ||
        a.id - b.id,
    );
    grouped.set(day, lines);
  }

  return grouped;
}

export default async function RosterPage() {
  const data = await fetchWithSession<MasterRosterResponse>("/api/roster/master");

  const templates = data?.templates ?? [];
  const items = data?.items ?? [];
  const byDay = groupByFortnightDay(items);

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">My Master Roster</h2>
      <p className="text-sm text-gray-600">
        Fortnight pattern — Day 1 to Day 14, sorted by start time.
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

      {byDay.size ? (
        <div className="space-y-4">
          {Array.from({ length: 14 }, (_, index) => index + 1).map((day) => {
            const lines = byDay.get(day);
            if (!lines?.length) return null;

            return (
              <section key={day} className="space-y-2">
                <h3 className="sticky top-0 z-10 rounded-lg bg-gray-100 px-3 py-2 text-sm font-semibold text-gray-800">
                  Day {day}
                </h3>
                <div className="space-y-2">
                  {lines.map((line) => (
                    <MasterRosterLineCard key={line.id} line={line} />
                  ))}
                </div>
              </section>
            );
          })}
        </div>
      ) : (
        <EmptyState message="No master roster is assigned to your profile yet." />
      )}
    </section>
  );
}
