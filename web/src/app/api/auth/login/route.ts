import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { setSessionToken } from "@/lib/session";
import type { AuthResponse } from "@/lib/types";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const data = await apiFetch<AuthResponse>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify(body),
    });

    await setSessionToken(data.token);
    return NextResponse.json({ user: data.user });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Login failed";
    return NextResponse.json({ error: message }, { status: 401 });
  }
}
