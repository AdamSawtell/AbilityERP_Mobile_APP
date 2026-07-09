import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

type ResponseCode = "REQ" | "DEC";

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ shiftId: string }> },
) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { shiftId } = await context.params;

  let body: { response?: ResponseCode };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
  }

  if (body.response !== "REQ" && body.response !== "DEC") {
    return NextResponse.json(
      { error: "Response must be REQ (request) or DEC (decline)" },
      { status: 400 },
    );
  }

  try {
    const data = await apiFetch<{ recorded: boolean; message: string; response: ResponseCode }>(
      `/api/shifts/${shiftId}/response`,
      {
        method: "POST",
        token,
        body: JSON.stringify({ response: body.response }),
      },
    );
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Response failed";
    return NextResponse.json({ error: message }, { status: 409 });
  }
}
