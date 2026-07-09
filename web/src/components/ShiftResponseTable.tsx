import Link from "next/link";
import type { ShiftItem } from "@/components/ShiftCard";
import { formatShiftRange } from "@/components/ShiftCard";

const RESPONSE_LABEL: Record<string, string> = {
  REQ: "Request",
  DEC: "Decline",
};

const REVIEW_LABEL: Record<string, string> = {
  pending: "Pending",
  reviewed: "Reviewed",
};

export default function ShiftResponseTable({ items }: { items: ShiftItem[] }) {
  if (items.length === 0) {
    return (
      <p className="text-sm text-gray-500">
        No shift requests or declines for this pay period yet.
      </p>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm">
      <table className="min-w-full text-left text-sm">
        <thead className="border-b border-gray-200 bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
          <tr>
            <th className="px-4 py-3 font-medium">Shift</th>
            <th className="px-4 py-3 font-medium">When</th>
            <th className="px-4 py-3 font-medium">Response</th>
            <th className="px-4 py-3 font-medium">Review</th>
            <th className="px-4 py-3 font-medium">Chat</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {items.map((item) => (
            <tr key={`${item.id}-${item.responded_at ?? ""}`}>
              <td className="px-4 py-3">
                <p className="font-medium text-gray-900">
                  {item.document_no ?? `#${item.id}`}
                </p>
                <p className="text-xs text-gray-500">{item.shift_type ?? "Shift"}</p>
              </td>
              <td className="px-4 py-3 text-gray-600">
                {formatShiftRange(item.start_time, item.end_time)}
              </td>
              <td className="px-4 py-3">
                <span
                  className={
                    item.response_code === "DEC"
                      ? "rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600"
                      : "rounded-full bg-amber-100 px-2 py-1 text-xs font-medium text-amber-800"
                  }
                >
                  {RESPONSE_LABEL[item.response_code ?? ""] ??
                    (item.application_status === "declined" ? "Decline" : "Request")}
                </span>
              </td>
              <td className="px-4 py-3">
                {item.response_code === "REQ" ? (
                  <span
                    className={
                      item.review_status === "reviewed"
                        ? "rounded-full bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700"
                        : "rounded-full bg-amber-50 px-2 py-1 text-xs font-medium text-amber-700"
                    }
                  >
                    {REVIEW_LABEL[item.review_status ?? "pending"] ?? "Pending"}
                  </span>
                ) : (
                  <span className="text-xs text-gray-400">—</span>
                )}
              </td>
              <td className="px-4 py-3">
                <Link
                  href={`/tasks/shift/${item.id}`}
                  className="text-xs font-medium text-blue-600 hover:underline"
                >
                  Open
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
