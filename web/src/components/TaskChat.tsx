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

function statusLabel(isClosed: boolean, awaiting?: "rostering" | "worker" | null): string {
  if (isClosed) return "Closed";
  if (awaiting === "rostering") return "Waiting for rostering";
  if (awaiting === "worker") return "Rostering replied — your turn";
  return "Open";
}

function statusClass(isClosed: boolean, awaiting?: "rostering" | "worker" | null): string {
  if (isClosed) return "bg-gray-200 text-gray-700";
  if (awaiting === "rostering") return "bg-amber-100 text-amber-900";
  return "bg-green-100 text-green-800";
}

export default function TaskChat({
  requestId: initialRequestId,
  messages: initialMessages,
  isClosed: initialIsClosed = false,
  awaitingReplyFrom: initialAwaiting = null,
}: {
  requestId: number | null;
  messages: TaskMessage[];
  isClosed?: boolean;
  awaitingReplyFrom?: "rostering" | "worker" | null;
}) {
  const router = useRouter();
  const [requestId, setRequestId] = useState(initialRequestId);
  const [isClosed, setIsClosed] = useState(initialIsClosed);
  const [awaitingReplyFrom, setAwaitingReplyFrom] = useState(initialAwaiting);
  const [messages, setMessages] = useState(initialMessages);
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [closing, setClosing] = useState(false);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refreshMessages = useCallback(async () => {
    try {
      const res = await fetch("/api/requests/chat", { cache: "no-store" });
      if (!res.ok) return;
      const data = await res.json();
      if (data.task?.id) {
        setRequestId(data.task.id);
        setIsClosed(Boolean(data.task.is_closed));
        setAwaitingReplyFrom(data.task.awaiting_reply_from ?? null);
      }
      if (data.messages) {
        setMessages(data.messages);
      }
    } catch {
      // ignore background refresh errors
    }
  }, []);

  useEffect(() => {
    setRequestId(initialRequestId);
    setIsClosed(initialIsClosed);
    setAwaitingReplyFrom(initialAwaiting);
    setMessages(initialMessages);
  }, [initialRequestId, initialIsClosed, initialAwaiting, initialMessages]);

  useEffect(() => {
    const timer = setInterval(refreshMessages, 10000);
    const onFocus = () => refreshMessages();
    window.addEventListener("focus", onFocus);
    return () => {
      clearInterval(timer);
      window.removeEventListener("focus", onFocus);
    };
  }, [refreshMessages]);

  async function startNewChat() {
    setStarting(true);
    setError(null);
    try {
      const res = await fetch("/api/requests/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ body: "Hello — I would like to get in touch with rostering." }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Could not start chat");

      setRequestId(data.task.id);
      setIsClosed(false);
      setAwaitingReplyFrom("rostering");
      setMessages(data.messages ?? []);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not start chat");
    } finally {
      setStarting(false);
    }
  }

  async function closeChat() {
    if (!requestId || isClosed) return;
    if (!window.confirm("Close this conversation? You can start a new one anytime.")) return;

    setClosing(true);
    setError(null);
    try {
      const res = await fetch(`/api/requests/${requestId}/close`, { method: "POST" });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Close failed");

      setIsClosed(true);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Close failed");
    } finally {
      setClosing(false);
    }
  }

  async function sendMessage(event: React.FormEvent) {
    event.preventDefault();
    if (!requestId || isClosed) return;
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
      setAwaitingReplyFrom("rostering");
      await refreshMessages();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Send failed");
    } finally {
      setSending(false);
    }
  }

  if (!requestId) {
    return (
      <div className="space-y-4 rounded-xl border border-gray-200 bg-white p-6 text-center">
        <p className="text-sm text-gray-600">No active conversation with rostering.</p>
        {error ? <p className="text-sm text-red-600">{error}</p> : null}
        <button
          type="button"
          onClick={startNewChat}
          disabled={starting}
          className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
        >
          {starting ? "Starting…" : "Start new conversation"}
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {!isClosed ? (
        <p className={`rounded-xl px-3 py-2 text-sm ${statusClass(isClosed, awaitingReplyFrom)}`}>
          {statusLabel(isClosed, awaitingReplyFrom)}
        </p>
      ) : null}

      {isClosed ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          This conversation is closed. Start a new one to message rostering again.
        </div>
      ) : null}

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
                    : "border border-gray-200 bg-gray-100 text-gray-900"
                }`}
              >
                {!msg.is_mine && msg.author_name ? (
                  <p className="mb-1 text-xs font-semibold text-gray-600">{msg.author_name}</p>
                ) : null}
                <p className="whitespace-pre-wrap text-inherit">{msg.body}</p>
                <p
                  className={`mt-1 text-[10px] ${msg.is_mine ? "text-blue-100" : "text-gray-500"}`}
                >
                  {formatWhen(msg.created_at)}
                </p>
              </div>
            </div>
          ))
        )}
      </div>

      {error ? <p className="text-sm text-red-600">{error}</p> : null}

      {isClosed ? (
        <button
          type="button"
          onClick={startNewChat}
          disabled={starting}
          className="w-full rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
        >
          {starting ? "Starting…" : "Start new conversation"}
        </button>
      ) : (
        <>
          <form onSubmit={sendMessage} className="space-y-2">
            <textarea
              rows={3}
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="Message rostering…"
              className="w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400"
            />
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={sending || !body.trim()}
                className="flex-1 rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
              >
                {sending ? "Sending…" : "Send"}
              </button>
              <button
                type="button"
                onClick={closeChat}
                disabled={closing}
                className="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 disabled:opacity-60"
              >
                {closing ? "Closing…" : "Close chat"}
              </button>
            </div>
          </form>
        </>
      )}
    </div>
  );
}
