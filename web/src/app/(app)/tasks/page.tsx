import TaskChat from "@/components/TaskChat";
import { fetchWithSession } from "@/lib/server-data";

interface ChatResponse {
  task: {
    id: number;
    summary: string | null;
    status: string | null;
    assigned_to_role: string | null;
    is_closed: boolean;
    awaiting_reply_from: "rostering" | "worker" | null;
  } | null;
  messages: {
    id: number;
    body: string | null;
    author_name: string | null;
    is_mine: boolean;
    created_at: string | null;
  }[];
}

function statusLabel(task: ChatResponse["task"]): string | null {
  if (!task) return null;
  if (task.is_closed) return "Closed";
  if (task.awaiting_reply_from === "rostering") return "Waiting for rostering";
  if (task.awaiting_reply_from === "worker") return "Rostering replied";
  return task.status;
}

function statusClass(task: ChatResponse["task"]): string {
  if (!task || task.is_closed) return "bg-gray-200 text-gray-700";
  if (task.awaiting_reply_from === "rostering") return "bg-amber-100 text-amber-900";
  return "bg-green-100 text-green-800";
}

export default async function TasksPage() {
  const data = await fetchWithSession<ChatResponse>("/api/requests/chat");

  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-xl font-semibold text-gray-900">Rostering chat</h2>
        <p className="text-sm text-gray-600">
          Message your rostering team. Each conversation is a separate record in AbilityERP.
        </p>
        {statusLabel(data?.task ?? null) ? (
          <span
            className={`mt-2 inline-block rounded-full px-2 py-1 text-xs ${statusClass(data?.task ?? null)}`}
          >
            {statusLabel(data?.task ?? null)}
          </span>
        ) : null}
      </div>
      <TaskChat
        requestId={data?.task?.id ?? null}
        messages={data?.messages ?? []}
        isClosed={data?.task?.is_closed ?? false}
        awaitingReplyFrom={data?.task?.awaiting_reply_from ?? null}
      />
    </section>
  );
}
