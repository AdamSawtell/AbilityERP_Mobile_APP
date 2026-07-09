import { fetchWithSession } from "@/lib/server-data";
import type { TaskItem } from "@/components/TaskList";
import { notFound, redirect } from "next/navigation";

export default async function TaskByShiftPage({
  params,
}: {
  params: Promise<{ shiftId: string }>;
}) {
  const { shiftId } = await params;
  const task = await fetchWithSession<TaskItem>(`/api/requests/by-shift/${shiftId}`);
  if (!task?.id) notFound();
  redirect(`/tasks/${task.id}`);
}
