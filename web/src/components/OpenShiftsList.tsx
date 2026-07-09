"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import type { ShiftItem } from "@/components/ShiftCard";
import { EmptyState, ShiftCard } from "@/components/ShiftCard";

export default function OpenShiftsList({ shifts }: { shifts: ShiftItem[] }) {
  const router = useRouter();
  const [loadingId, setLoadingId] = useState<number | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function apply(shiftId: number) {
    setLoadingId(shiftId);
    setMessage(null);
    try {
      const response = await fetch(`/api/shifts/${shiftId}/apply`, { method: "POST" });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error ?? "Apply failed");
      setMessage(data.message ?? "Application submitted");
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Apply failed");
    } finally {
      setLoadingId(null);
    }
  }

  if (shifts.length === 0) {
    return <EmptyState message="No open shifts right now. Check back later." />;
  }

  return (
    <div className="space-y-3">
      {message ? <p className="text-sm text-blue-700">{message}</p> : null}
      {shifts.map((shift) => (
        <ShiftCard
          key={shift.id}
          shift={shift}
          action={
            <button
              type="button"
              disabled={loadingId === shift.id}
              onClick={() => apply(shift.id)}
              className="w-full rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
            >
              {loadingId === shift.id ? "Applying…" : "Apply for shift"}
            </button>
          }
        />
      ))}
    </div>
  );
}
