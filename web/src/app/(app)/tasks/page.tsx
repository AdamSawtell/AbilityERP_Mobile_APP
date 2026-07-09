import TaskList, { type TaskItem } from "@/components/TaskList";
import { fetchWithSession } from "@/lib/server-data";

interface TasksResponse {
  items: TaskItem[];
}

export default async function TasksPage() {
  const data = await fetchWithSession<TasksResponse>("/api/requests");

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Tasks</h2>
      <p className="text-sm text-gray-600">
        Your requests and chats with rostering — same as AbilityVua Tasks.
      </p>
      <TaskList items={data?.items ?? []} />
    </section>
  );
}
