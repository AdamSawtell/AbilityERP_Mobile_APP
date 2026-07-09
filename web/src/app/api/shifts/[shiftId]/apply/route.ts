import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function POST(
  _request: NextRequest,
  context: { params: Promise<{ shiftId: string }> },
) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { shiftId } = await context.params;

  try {
    const data = await apiFetch<{ applied: boolean; message: string }>(
      `/api/shifts/${shiftId}/apply`,
      { method: "POST", token },
    );
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Apply failed";
    return NextResponse.json({ error: message }, { status: 409 });
  }
}
