import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  try {
    const body = await request.json();
    const data = await apiFetch<{ id: number }>("/api/leave", {
      method: "POST",
      body: JSON.stringify(body),
      token,
    });
    return NextResponse.json(data, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Leave request failed";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
