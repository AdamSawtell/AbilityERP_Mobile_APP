export interface MasterRosterLine {
  id: number;
  document_no: string | null;
  template_id: number | null;
  template_name: string | null;
  template_code: string | null;
  roster_start_day: number | null;
  roster_end_day: number | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
}

export interface MasterRosterTemplate {
  id: number;
  name: string;
  value: string | null;
}

function formatTime(value: string | null): string {
  if (!value) return "—";
  return new Date(value).toLocaleTimeString("en-AU", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatRosterDay(start: number | null, end: number | null): string {
  if (!start && !end) return "—";
  if (start && end && start !== end) return `Day ${start} – ${end}`;
  return `Day ${start ?? end}`;
}

export function MasterRosterLineCard({ line }: { line: MasterRosterLine }) {
  return (
    <article className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
            {formatRosterDay(line.roster_start_day, line.roster_end_day)}
          </p>
          <h3 className="mt-1 font-semibold text-gray-900">
            {line.shift_type ?? "Shift"}
          </h3>
        </div>
        {line.template_code ? (
          <span className="rounded-full bg-gray-100 px-2 py-1 text-xs text-gray-600">
            {line.template_code}
          </span>
        ) : null}
      </div>
      <dl className="mt-3 space-y-1 text-sm text-gray-600">
        <div>
          <dt className="inline font-medium text-gray-700">Time: </dt>
          <dd className="inline">
            {formatTime(line.start_time)} – {formatTime(line.end_time)}
          </dd>
        </div>
        {line.location ? (
          <div>
            <dt className="inline font-medium text-gray-700">Where: </dt>
            <dd className="inline">{line.location}</dd>
          </div>
        ) : null}
      </dl>
    </article>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
      {message}
    </div>
  );
}
