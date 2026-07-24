import { NextResponse } from "next/server";
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
    const data = await apiFetch<{ carePlan: unknown }>(
      `/api/clients/${clientId}/care-plan`,
      { token },
    );
    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to load care plan";
    return NextResponse.json({ error: message }, { status: 404 });
  }
}
