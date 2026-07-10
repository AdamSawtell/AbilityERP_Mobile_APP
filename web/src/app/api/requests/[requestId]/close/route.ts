import { NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function POST(
  _request: Request,
  context: { params: Promise<{ requestId: string }> },
) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { requestId } = await context.params;

  try {
    const data = await apiFetch(`/api/requests/${requestId}/close`, {
      method: "POST",
      token,
    });
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to close chat";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
