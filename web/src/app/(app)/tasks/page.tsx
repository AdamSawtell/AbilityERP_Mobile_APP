import TaskChat from "@/components/TaskChat";
import { fetchWithSession } from "@/lib/server-data";

interface ChatResponse {
  task: {
    id: number;
    summary: string | null;
    status: string | null;
    assigned_to_role: string | null;
    is_closed: boolean;
  } | null;
  messages: {
    id: number;
    body: string | null;
    author_name: string | null;
    is_mine: boolean;
    created_at: string | null;
  }[];
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
        {data?.task?.status ? (
          <span
            className={`mt-2 inline-block rounded-full px-2 py-1 text-xs ${
              data.task.is_closed
                ? "bg-gray-200 text-gray-700"
                : "bg-green-100 text-green-800"
            }`}
          >
            {data.task.status}
          </span>
        ) : null}
      </div>
      <TaskChat
        requestId={data?.task?.id ?? null}
        messages={data?.messages ?? []}
        isClosed={data?.task?.is_closed ?? false}
      />
    </section>
  );
}
