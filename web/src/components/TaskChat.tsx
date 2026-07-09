"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

export interface TaskMessage {
  id: number;
  body: string | null;
  author_name: string | null;
  is_mine: boolean;
  created_at: string | null;
}

function formatWhen(value: string | null): string {
  if (!value) return "";
  return new Date(value).toLocaleString("en-AU", {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function TaskChat({
  requestId,
  messages: initialMessages,
}: {
  requestId: number;
  messages: TaskMessage[];
}) {
  const router = useRouter();
  const [messages, setMessages] = useState(initialMessages);
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refreshMessages = useCallback(async () => {
    try {
      const res = await fetch("/api/requests/chat", { cache: "no-store" });
      if (!res.ok) return;
      const data = await res.json();
      if (data.messages) {
        setMessages(data.messages);
      }
    } catch {
      // ignore background refresh errors
    }
  }, []);

  useEffect(() => {
    setMessages(initialMessages);
  }, [initialMessages]);

  useEffect(() => {
    const timer = setInterval(refreshMessages, 15000);
    const onFocus = () => refreshMessages();
    window.addEventListener("focus", onFocus);
    return () => {
      clearInterval(timer);
      window.removeEventListener("focus", onFocus);
    };
  }, [refreshMessages]);

  async function sendMessage(event: React.FormEvent) {
    event.preventDefault();
    const trimmed = body.trim();
    if (!trimmed) return;

    setSending(true);
    setError(null);
    try {
      const res = await fetch(`/api/requests/${requestId}/messages`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ body: trimmed }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Send failed");

      setBody("");
      await refreshMessages();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Send failed");
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="space-y-3 rounded-xl border border-gray-200 bg-white p-4 min-h-[280px]">
        {messages.length === 0 ? (
          <p className="text-center text-sm text-gray-500">No messages yet. Say hello to rostering.</p>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex ${msg.is_mine ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[85%] rounded-2xl px-3 py-2 text-sm ${
                  msg.is_mine
                    ? "bg-blue-600 text-white"
                    : "bg-gray-100 text-gray-800"
                }`}
              >
                {!msg.is_mine && msg.author_name ? (
                  <p className="mb-1 text-xs font-medium opacity-70">{msg.author_name}</p>
                ) : null}
                <p className="whitespace-pre-wrap">{msg.body}</p>
                <p
                  className={`mt-1 text-[10px] ${msg.is_mine ? "text-blue-100" : "text-gray-400"}`}
                >
                  {formatWhen(msg.created_at)}
                </p>
              </div>
            </div>
          ))
        )}
      </div>

      <form onSubmit={sendMessage} className="space-y-2">
        {error ? <p className="text-sm text-red-600">{error}</p> : null}
        <textarea
          rows={3}
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Message rostering…"
          className="w-full rounded-xl border border-gray-300 px-3 py-2 text-sm"
        />
        <button
          type="submit"
          disabled={sending || !body.trim()}
          className="w-full rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
        >
          {sending ? "Sending…" : "Send"}
        </button>
      </form>
    </div>
  );
}
