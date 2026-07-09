"use client";

import AppShell from "@/components/AppShell";

export default function AppLayoutClient({
  children,
  userName,
}: {
  children: React.ReactNode;
  userName?: string;
}) {
  return <AppShell userName={userName}>{children}</AppShell>;
}
