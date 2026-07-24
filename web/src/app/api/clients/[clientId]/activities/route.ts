import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";

export const runtime = "nodejs";

export async function GET(
  _request: Request,
  context: { params: Promise<{ clientId: string }> },
) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { clientId } = await context.params;

  try {
    const data = await apiFetch<{ items: unknown[] }>(
      `/api/clients/${clientId}/activities`,
      { token },
    );
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to load activities";
    return NextResponse.json({ error: message }, { status: 404 });
  }
}

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ clientId: string }> },
) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { clientId } = await context.params;

  try {
    const body = await request.json();
    const data = await apiFetch<{ activity: unknown }>(
      `/api/clients/${clientId}/activities`,
      {
        method: "POST",
        body: JSON.stringify(body),
        token,
      },
    );
    return NextResponse.json(data, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to save activity";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
