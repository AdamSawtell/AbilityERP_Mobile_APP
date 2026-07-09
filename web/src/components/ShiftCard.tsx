export type ApplicationStatus =
  | "open"
  | "requested"
  | "declined"
  | "assigned"
  | "unavailable";

export type ResponseCode = "REQ" | "DEC";
export type ReviewStatus = "pending" | "reviewed" | null;

export interface ShiftItem {
  id: number;
  document_no: string | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
  status: string | null;
  application_status?: ApplicationStatus;
  response_code?: ResponseCode | null;
  review_status?: ReviewStatus;
  pay_period_id?: number | null;
  request_status?: string | null;
  staff_name?: string | null;
  responded_at?: string | null;
}

const APPLICATION_BADGE: Record<
  ApplicationStatus,
  { label: string; className: string }
> = {
  open: { label: "Open", className: "bg-green-100 text-green-700" },
  requested: { label: "Requested", className: "bg-amber-100 text-amber-800" },
  declined: { label: "Declined", className: "bg-gray-100 text-gray-600" },
  assigned: { label: "Assigned", className: "bg-blue-100 text-blue-700" },
  unavailable: { label: "Unavailable", className: "bg-gray-100 text-gray-500" },
};

const REVIEW_BADGE: Record<
  NonNullable<ReviewStatus>,
  { label: string; className: string }
> = {
  pending: { label: "Pending review", className: "bg-amber-50 text-amber-700" },
  reviewed: { label: "Reviewed", className: "bg-emerald-50 text-emerald-700" },
};

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
      {message}
    </div>
  );
}

export function ShiftCard({
  shift,
  action,
}: {
  shift: ShiftItem;
  action?: React.ReactNode;
}) {
  return (
    <article className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
            {shift.document_no ?? `Shift ${shift.id}`}
          </p>
          <h3 className="mt-1 font-semibold text-gray-900">
            {shift.shift_type ?? "Shift"}
          </h3>
        </div>
        <div className="flex flex-col items-end gap-1">
          {shift.application_status ? (
            <span
              className={`rounded-full px-2 py-1 text-xs font-medium ${APPLICATION_BADGE[shift.application_status].className}`}
            >
              {APPLICATION_BADGE[shift.application_status].label}
            </span>
          ) : null}
          {shift.review_status ? (
            <span
              className={`rounded-full px-2 py-1 text-xs font-medium ${REVIEW_BADGE[shift.review_status].className}`}
            >
              {REVIEW_BADGE[shift.review_status].label}
            </span>
          ) : null}
          {shift.status ? (
            <span className="rounded-full bg-gray-100 px-2 py-1 text-xs text-gray-600">
              {shift.status}
            </span>
          ) : null}
        </div>
      </div>
      <dl className="mt-3 space-y-1 text-sm text-gray-600">
        <div>
          <dt className="inline font-medium text-gray-700">When: </dt>
          <dd className="inline">
            {formatShiftRange(shift.start_time, shift.end_time)}
          </dd>
        </div>
        {shift.location ? (
          <div>
            <dt className="inline font-medium text-gray-700">Where: </dt>
            <dd className="inline">{shift.location}</dd>
          </div>
        ) : null}
        {shift.staff_name ? (
          <div>
            <dt className="inline font-medium text-gray-700">Staff: </dt>
            <dd className="inline">{shift.staff_name}</dd>
          </div>
        ) : null}
      </dl>
      {action ? <div className="mt-4">{action}</div> : null}
    </article>
  );
}

export function formatShiftRange(start: string | null, end: string | null): string {
  if (!start && !end) return "—";
  const fmt = (value: string) =>
    new Date(value).toLocaleString("en-AU", {
      weekday: "short",
      day: "numeric",
      month: "short",
      hour: "2-digit",
      minute: "2-digit",
    });
  if (start && end) return `${fmt(start)} – ${fmt(end)}`;
  return start ? fmt(start) : end ? fmt(end) : "—";
}
