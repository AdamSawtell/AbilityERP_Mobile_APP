import Link from "next/link";

export interface TaskItem {
  id: number;
  document_no: string | null;
  summary: string | null;
  request_type: string | null;
  status: string | null;
  shift_id: number | null;
  shift_document_no: string | null;
  assigned_to_role: string | null;
  created_at: string | null;
  updated_at: string | null;
  last_message: string | null;
  last_message_at: string | null;
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

export default function TaskList({ items }: { items: TaskItem[] }) {
  if (items.length === 0) {
    return (
      <p className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
        No requests yet. When you request or decline a shift, a chat with rostering will appear here.
      </p>
    );
  }

  return (
    <div className="space-y-3">
      {items.map((task) => (
        <Link
          key={task.id}
          href={`/tasks/${task.id}`}
          className="block rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition hover:border-blue-300"
        >
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
                {task.document_no ?? `Request ${task.id}`}
              </p>
              <h3 className="mt-1 truncate font-semibold text-gray-900">
                {task.summary ?? "Shift request"}
              </h3>
              {task.shift_document_no ? (
                <p className="mt-1 text-xs text-gray-500">Shift {task.shift_document_no}</p>
              ) : null}
            </div>
            {task.status ? (
              <span className="shrink-0 rounded-full bg-gray-100 px-2 py-1 text-xs text-gray-600">
                {task.status}
              </span>
            ) : null}
          </div>
          {task.last_message ? (
            <p className="mt-3 line-clamp-2 text-sm text-gray-600">{task.last_message}</p>
          ) : null}
          <div className="mt-2 flex items-center justify-between text-xs text-gray-400">
            <span>{task.assigned_to_role ?? "Rostering"}</span>
            <span>{formatWhen(task.last_message_at ?? task.updated_at)}</span>
          </div>
        </Link>
      ))}
    </div>
  );
}
