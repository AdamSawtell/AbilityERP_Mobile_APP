import { NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";
import type { WorkerUser } from "@/lib/types";

export async function GET() {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  try {
    const data = await apiFetch<{ user: WorkerUser }>("/api/auth/me", { token });
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Session invalid";
    return NextResponse.json({ error: message }, { status: 401 });
  }
}
