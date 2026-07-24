import { NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function GET() {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  try {
    const data = await apiFetch<{ items: unknown[] }>("/api/clients", { token });
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to load clients";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
