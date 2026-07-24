import { getWorkerTasks } from "./requests";

export interface NotificationItem {
  id: string;
  type: "chat";
  title: string;
  body: string;
  href: string;
  createdAt: string | null;
}

export interface NotificationSummary {
  unreadCount: number;
  chatNeedsReply: boolean;
  items: NotificationItem[];
}

/** Read-only notification summary — does not create chat threads. */
export async function getNotificationSummary(
  adUserId: number,
  cBPartnerId: number,
): Promise<NotificationSummary> {
  const tasks = await getWorkerTasks(adUserId, cBPartnerId);
  const items: NotificationItem[] = tasks
    .filter((task) => !task.is_closed && task.awaiting_reply_from === "worker")
    .map((task) => ({
      id: `chat-${task.id}`,
      type: "chat" as const,
      title: "Rostering replied",
      body: task.last_message
        ? String(task.last_message).slice(0, 140)
        : task.summary || "Open Chat to read and reply.",
      href: "/tasks",
      createdAt: task.last_message_at ?? task.updated_at,
    }));

  return {
    unreadCount: items.length,
    chatNeedsReply: items.length > 0,
    items,
  };
}
