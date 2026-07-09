import TaskChat from "@/components/TaskChat";
import { fetchWithSession } from "@/lib/server-data";

interface ChatResponse {
  task: {
    id: number;
    summary: string | null;
    status: string | null;
    assigned_to_role: string | null;
  };
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
        <h2 className="text-xl font-semibold text-gray-900">Tasks</h2>
        <p className="text-sm text-gray-600">
          Message rostering — standalone chat using the request system.
        </p>
        {data?.task?.status ? (
          <span className="mt-2 inline-block rounded-full bg-gray-100 px-2 py-1 text-xs text-gray-600">
            {data.task.status}
          </span>
        ) : null}
      </div>
      {data?.task ? (
        <TaskChat requestId={data.task.id} messages={data.messages ?? []} />
      ) : (
        <p className="text-sm text-gray-500">Unable to load chat. Try again shortly.</p>
      )}
    </section>
  );
}
