export const authConfig = {
  tenantId: process.env.AZURE_TENANT_ID ?? "",
  clientId: process.env.AZURE_CLIENT_ID ?? "",
  clientSecret: process.env.AZURE_CLIENT_SECRET ?? "",
  redirectUri:
    process.env.AZURE_REDIRECT_URI ??
    `${process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000"}/api/auth/ms-callback`,
  scopes: ["openid", "profile", "email"],
};

export function isMicrosoftSsoConfigured(): boolean {
  return Boolean(authConfig.tenantId && authConfig.clientId && authConfig.clientSecret);
}

export function getMicrosoftLoginUrl(state: string): string {
  const params = new URLSearchParams({
    client_id: authConfig.clientId,
    response_type: "code",
    redirect_uri: authConfig.redirectUri,
    response_mode: "query",
    scope: authConfig.scopes.join(" "),
    state,
  });

  return `https://login.microsoftonline.com/${authConfig.tenantId}/oauth2/v2.0/authorize?${params.toString()}`;
}
