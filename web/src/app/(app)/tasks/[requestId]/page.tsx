import TaskChat from "@/components/TaskChat";
import type { TaskItem } from "@/components/TaskList";
import { fetchWithSession } from "@/lib/server-data";
import Link from "next/link";
import { notFound } from "next/navigation";

interface TaskDetailResponse {
  task: TaskItem;
  messages: {
    id: number;
    body: string | null;
    author_name: string | null;
    is_mine: boolean;
    created_at: string | null;
  }[];
}

export default async function TaskDetailPage({
  params,
}: {
  params: Promise<{ requestId: string }>;
}) {
  const { requestId } = await params;
  const data = await fetchWithSession<TaskDetailResponse>(`/api/requests/${requestId}`);
  if (!data?.task) notFound();

  return (
    <section className="space-y-3">
      <Link href="/tasks" className="text-sm text-blue-600">
        ← Back to Tasks
      </Link>
      <div>
        <h2 className="text-xl font-semibold text-gray-900">
          {data.task.summary ?? "Shift request"}
        </h2>
        <p className="text-sm text-gray-600">
          Chat with {data.task.assigned_to_role ?? "Rostering"}
          {data.task.shift_document_no ? ` · Shift ${data.task.shift_document_no}` : ""}
        </p>
        {data.task.status ? (
          <span className="mt-2 inline-block rounded-full bg-gray-100 px-2 py-1 text-xs text-gray-600">
            {data.task.status}
          </span>
        ) : null}
      </div>
      <TaskChat requestId={Number(requestId)} messages={data.messages} />
    </section>
  );
}
