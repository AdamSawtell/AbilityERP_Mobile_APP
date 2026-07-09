import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function PUT(request: NextRequest) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  try {
    const body = await request.json();
    const data = await apiFetch("/api/profile", {
      method: "PUT",
      body: JSON.stringify(body),
      token,
    });
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Update failed";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
