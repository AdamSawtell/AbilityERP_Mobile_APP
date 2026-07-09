"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function ProfileForm({
  initialEmail,
  initialPhone,
}: {
  initialEmail: string;
  initialPhone: string;
}) {
  const router = useRouter();
  const [email, setEmail] = useState(initialEmail);
  const [phone, setPhone] = useState(initialPhone);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setMessage(null);
    try {
      const response = await fetch("/api/profile", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, phone }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error ?? "Update failed");
      setMessage("Profile updated");
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Update failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-3 rounded-xl border border-gray-200 bg-white p-4">
      <h3 className="font-semibold text-gray-900">Update contact details</h3>
      <div>
        <label className="block text-sm font-medium text-gray-700">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">Phone</label>
        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          className="mt-1 w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
        />
      </div>
      {message ? <p className="text-sm text-blue-700">{message}</p> : null}
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {loading ? "Saving…" : "Save changes"}
      </button>
    </form>
  );
}
