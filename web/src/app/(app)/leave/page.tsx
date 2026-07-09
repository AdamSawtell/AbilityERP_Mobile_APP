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
            {data.items.map((item) => (
              <article
                key={item.id}
                className="rounded-xl border border-gray-200 bg-white p-4"
              >
                <p className="font-medium text-gray-900">
                  {item.leave_type ?? "Leave"}
                </p>
                <p className="text-sm text-gray-600">
                  {formatDateTime(item.start_date)} – {formatDateTime(item.end_date)}
                </p>
                {item.note ? <p className="mt-2 text-sm text-gray-500">{item.note}</p> : null}
                <p className="mt-2 text-xs text-gray-400">
                  {[item.submitter_status, item.approver_status].filter(Boolean).join(" · ")}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <EmptyState message="No leave records yet." />
        )}
      </div>
    </section>
  );
}
