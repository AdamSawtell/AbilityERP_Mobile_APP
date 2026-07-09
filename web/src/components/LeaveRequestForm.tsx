"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function LeaveRequestForm() {
  const router = useRouter();
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [note, setNote] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setMessage(null);
    try {
      const response = await fetch("/api/leave", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ startDate, endDate, note }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error ?? "Request failed");
      setMessage("Leave request submitted");
      setStartDate("");
      setEndDate("");
      setNote("");
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Request failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-3 rounded-xl border border-gray-200 bg-white p-4">
      <h3 className="font-semibold text-gray-900">Request leave</h3>
      <div>
        <label className="block text-sm font-medium text-gray-700">Start</label>
        <input
          type="datetime-local"
          required
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">End</label>
        <input
          type="datetime-local"
          required
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">Note</label>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
          rows={3}
        />
      </div>
      {message ? <p className="text-sm text-blue-700">{message}</p> : null}
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {loading ? "Submitting…" : "Submit request"}
      </button>
    </form>
  );
}
