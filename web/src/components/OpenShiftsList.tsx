"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import type { ResponseCode, ShiftItem } from "@/components/ShiftCard";
import { EmptyState, ShiftCard } from "@/components/ShiftCard";

export default function OpenShiftsList({ shifts }: { shifts: ShiftItem[] }) {
  const router = useRouter();
  const [loadingId, setLoadingId] = useState<number | null>(null);
  const [loadingAction, setLoadingAction] = useState<ResponseCode | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function respond(shiftId: number, response: ResponseCode) {
    setLoadingId(shiftId);
    setLoadingAction(response);
    setMessage(null);
    try {
      const res = await fetch(`/api/shifts/${shiftId}/response`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ response }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Response failed");
      setMessage(data.message ?? "Response recorded");
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Response failed");
    } finally {
      setLoadingId(null);
      setLoadingAction(null);
    }
  }

  if (shifts.length === 0) {
    return <EmptyState message="No open shifts right now. Check back later." />;
  }

  return (
    <div className="space-y-3">
      {message ? <p className="text-sm text-blue-700">{message}</p> : null}
      {shifts.map((shift) => {
        const isOpen = !shift.application_status || shift.application_status === "open";
        const isRequested = shift.application_status === "requested";
        const busy = loadingId === shift.id;

        return (
          <ShiftCard
            key={shift.id}
            shift={shift}
            action={
              isOpen ? (
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => respond(shift.id, "REQ")}
                    className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
                  >
                    {busy && loadingAction === "REQ" ? "Requesting…" : "Request"}
                  </button>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => respond(shift.id, "DEC")}
                    className="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 disabled:opacity-60"
                  >
                    {busy && loadingAction === "DEC" ? "Declining…" : "Decline"}
                  </button>
                </div>
              ) : isRequested ? (
                <div className="space-y-2">
                  <p className="text-center text-sm text-amber-700">
                    Request submitted — awaiting roster review
                  </p>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => respond(shift.id, "DEC")}
                    className="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 disabled:opacity-60"
                  >
                    {busy && loadingAction === "DEC" ? "Declining…" : "Change to decline"}
                  </button>
                </div>
              ) : null
            }
          />
        );
      })}
    </div>
  );
}
