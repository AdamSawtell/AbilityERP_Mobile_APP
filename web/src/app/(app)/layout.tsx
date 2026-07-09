import { redirect } from "next/navigation";
import AppLayoutClient from "@/components/AppLayoutClient";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";
import type { WorkerUser } from "@/lib/types";

async function getCurrentUser(): Promise<WorkerUser | null> {
  const token = await getSessionToken();
  if (!token) return null;

  try {
    const data = await apiFetch<{ user: WorkerUser }>("/api/auth/me", { token });
    return data.user;
  } catch {
    return null;
  }
}

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user) {
    redirect("/login");
  }

  return <AppLayoutClient userName={user.name}>{children}</AppLayoutClient>;
}
