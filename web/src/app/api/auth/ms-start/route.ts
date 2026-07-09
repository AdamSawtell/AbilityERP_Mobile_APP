import { randomBytes } from "crypto";
import { NextResponse } from "next/server";
import { getMicrosoftLoginUrl, isMicrosoftSsoConfigured } from "@/lib/auth-config";

export async function GET() {
  if (!isMicrosoftSsoConfigured()) {
    return NextResponse.redirect(new URL("/login?error=sso_not_configured", process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000"));
  }

  const state = randomBytes(16).toString("hex");
  const response = NextResponse.redirect(getMicrosoftLoginUrl(state));
  response.cookies.set("ms_oauth_state", state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 600,
  });

  return response;
}
