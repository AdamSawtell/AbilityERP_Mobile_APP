import { getSessionToken } from "./session";
import { apiFetch } from "./api-client";

export async function fetchWithSession<T>(path: string, init?: RequestInit): Promise<T | null> {
  const token = await getSessionToken();
  if (!token) return null;
  try {
    return await apiFetch<T>(path, { ...init, token });
  } catch {
    return null;
  }
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-AU", {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });
}
