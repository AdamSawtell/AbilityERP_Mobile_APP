import { NextResponse } from "next/server";
import { getApiBaseUrl } from "@/lib/api-client";

export const runtime = "nodejs";

export async function GET() {
  const apiBaseUrl = getApiBaseUrl();

  try {
    const response = await fetch(`${apiBaseUrl}/api/health`, { cache: "no-store" });
    const body = await response.json().catch(() => ({}));
    return NextResponse.json({
      apiBaseUrl,
      ec2Reachable: response.ok,
      ec2Status: response.status,
      ec2Body: body,
    });
  } catch (error) {
    return NextResponse.json({
      apiBaseUrl,
      ec2Reachable: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
