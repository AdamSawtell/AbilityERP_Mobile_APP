"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";

export default function AddActivityForm({ clientId }: { clientId: number }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const focusNote = searchParams.get("note") === "1";
  const descRef = useRef<HTMLInputElement>(null);
  const [description, setDescription] = useState("");
  const [comments, setComments] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!focusNote) return;
    document.getElementById("add-note")?.scrollIntoView({ behavior: "smooth", block: "start" });
    descRef.current?.focus();
  }, [focusNote]);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/clients/${clientId}/activities`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          description,
          comments: comments.trim() || undefined,
          type: "PGNOTE",
        }),
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error ?? "Could not save activity");
      }
      setDescription("");
      setComments("");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not save activity");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form
      id="add-note"
      onSubmit={onSubmit}
      className="space-y-3 rounded-xl border border-blue-200 bg-blue-50 p-4"
    >
      <div>
        <p className="text-sm font-semibold text-gray-900">Add progress note</p>
        <p className="text-xs text-gray-600">Saved to the client’s Activity list in AbilityERP.</p>
      </div>
      <div>
        <label htmlFor="activity-desc" className="block text-sm font-medium text-gray-700">
          What happened
        </label>
        <input
          ref={descRef}
          id="activity-desc"
          required
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm"
          placeholder="Short summary"
        />
      </div>
      <div>
        <label htmlFor="activity-notes" className="block text-sm font-medium text-gray-700">
          Notes (optional)
        </label>
        <textarea
          id="activity-notes"
          value={comments}
          onChange={(e) => setComments(e.target.value)}
          rows={3}
          className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm"
          placeholder="Details for the team"
        />
      </div>
      {error ? <p className="text-sm text-red-600">{error}</p> : null}
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white disabled:opacity-60"
      >
        {loading ? "Saving…" : "Save activity"}
      </button>
    </form>
  );
}
