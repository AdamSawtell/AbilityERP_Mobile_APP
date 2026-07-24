import { NextRequest, NextResponse } from "next/server";
import { apiFetch } from "@/lib/api-client";
import { authConfig, isMicrosoftSsoConfigured } from "@/lib/auth-config";
import { setSessionToken } from "@/lib/session";
import type { AuthResponse } from "@/lib/types";

interface MicrosoftTokenResponse {
  id_token?: string;
  access_token?: string;
  error?: string;
  error_description?: string;
}

function decodeJwtPayload(token: string): Record<string, unknown> {
  const payload = token.split(".")[1];
  if (!payload) throw new Error("Invalid ID token");
  return JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
}

export async function GET(request: NextRequest) {
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  if (!isMicrosoftSsoConfigured()) {
    return NextResponse.redirect(new URL("/login?error=sso_not_configured", appUrl));
  }

  const code = request.nextUrl.searchParams.get("code");
  const state = request.nextUrl.searchParams.get("state");
  const cookieState = request.cookies.get("ms_oauth_state")?.value;

  if (!code || !state || !cookieState || state !== cookieState) {
    return NextResponse.redirect(new URL("/login?error=sso_state_mismatch", appUrl));
  }

  const tokenParams = new URLSearchParams({
    client_id: authConfig.clientId,
    client_secret: authConfig.clientSecret,
    grant_type: "authorization_code",
    code,
    redirect_uri: authConfig.redirectUri,
    scope: authConfig.scopes.join(" "),
  });

  const tokenResponse = await fetch(
    `https://login.microsoftonline.com/${authConfig.tenantId}/oauth2/v2.0/token`,
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: tokenParams.toString(),
    },
  );

  const tokenData = (await tokenResponse.json()) as MicrosoftTokenResponse;
  if (!tokenResponse.ok || !tokenData.id_token) {
    return NextResponse.redirect(new URL("/login?error=sso_token_exchange_failed", appUrl));
  }

  const claims = decodeJwtPayload(tokenData.id_token);
  const email =
    (typeof claims.preferred_username === "string" && claims.preferred_username) ||
    (typeof claims.email === "string" && claims.email) ||
    (typeof claims.upn === "string" && claims.upn);

  if (!email) {
    return NextResponse.redirect(new URL("/login?error=sso_email_missing", appUrl));
  }

  try {
    const data = await apiFetch<AuthResponse>("/api/auth/sso", {
      method: "POST",
      body: JSON.stringify({ email }),
    });

    await setSessionToken(data.token);

    const response = NextResponse.redirect(new URL("/shifts", appUrl));
    response.cookies.delete("ms_oauth_state");
    return response;
  } catch {
    return NextResponse.redirect(new URL("/login?error=sso_user_not_found", appUrl));
  }
}
