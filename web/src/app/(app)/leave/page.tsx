import LeaveRequestForm from "@/components/LeaveRequestForm";
import { EmptyState } from "@/components/ShiftCard";
import { fetchWithSession, formatDateTime } from "@/lib/server-data";

interface LeaveItem {
  id: number;
  start_date: string | null;
  end_date: string | null;
  note: string | null;
  leave_type: string | null;
  submitter_status: string | null;
  approver_status: string | null;
}

type LeaveTone = "approved" | "declined" | "reviewing" | "draft" | "default";

function leaveTone(item: LeaveItem): LeaveTone {
  const approver = (item.approver_status ?? "").toLowerCase();
  const submitter = (item.submitter_status ?? "").toLowerCase();

  if (approver === "approved" || approver === "ap") return "approved";
  if (approver === "declined" || approver === "dc") return "declined";
  if (approver === "reviewing" || approver === "rv" || submitter === "submitted" || submitter === "sb") {
    return "reviewing";
  }
  if (submitter === "draft" || submitter === "dr") return "draft";
  return "default";
}

const TONE_STYLES: Record<
  LeaveTone,
  { card: string; badge: string; label: string }
> = {
  approved: {
    card: "border-emerald-200 bg-emerald-50/70",
    badge: "bg-emerald-100 text-emerald-800",
    label: "Approved",
  },
  declined: {
    card: "border-red-200 bg-red-50/60",
    badge: "bg-red-100 text-red-700",
    label: "Declined",
  },
  reviewing: {
    card: "border-amber-200 bg-amber-50/50",
    badge: "bg-amber-100 text-amber-800",
    label: "Awaiting approval",
  },
  draft: {
    card: "border-gray-200 bg-white",
    badge: "bg-gray-100 text-gray-600",
    label: "Draft",
  },
  default: {
    card: "border-gray-200 bg-white",
    badge: "bg-gray-100 text-gray-600",
    label: "Leave",
  },
};

export default async function LeavePage() {
  const data = await fetchWithSession<{ items: LeaveItem[] }>("/api/leave");

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">Leave & Availability</h2>
      <p className="text-sm text-gray-600">View and request leave or unavailability.</p>

      <LeaveRequestForm />

      <div>
        <h3 className="mb-2 font-medium text-gray-900">Your leave</h3>
        {data?.items?.length ? (
          <div className="space-y-3">
            {data.items.map((item) => {
              const tone = leaveTone(item);
              const style = TONE_STYLES[tone];
              return (
                <article
                  key={item.id}
                  className={`rounded-xl border p-4 ${style.card}`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium text-gray-900">
                        {item.leave_type ?? "Leave"}
                      </p>
                      <p className="text-sm text-gray-600">
                        {formatDateTime(item.start_date)} – {formatDateTime(item.end_date)}
                      </p>
                    </div>
                    <span
                      className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-medium ${style.badge}`}
                    >
                      {style.label}
                    </span>
                  </div>
                  {item.note ? (
                    <p className="mt-2 text-sm text-gray-500">{item.note}</p>
                  ) : null}
                  {tone === "approved" ? (
                    <p className="mt-2 text-xs font-medium text-emerald-700">
                      Approved — this leave is confirmed on your roster.
                    </p>
                  ) : null}
                </article>
              );
            })}
          </div>
        ) : (
          <EmptyState message="No leave records yet." />
        )}
      </div>
    </section>
  );
}
