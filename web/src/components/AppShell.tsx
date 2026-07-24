"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { useEffect, useState } from "react";
import NotificationBell from "./NotificationBell";
import { NavIcons } from "./NavIcons";

const navItems = [
  { href: "/open-shifts", label: "Open", icon: NavIcons.open },
  { href: "/shifts", label: "Roster", icon: NavIcons.schedule },
  { href: "/clients", label: "Clients", icon: NavIcons.clients },
  { href: "/locations", label: "Locations", icon: NavIcons.locations },
  { href: "/tasks", label: "Chat", icon: NavIcons.chat, badgeKey: "chat" as const },
  { href: "/profile", label: "More", icon: NavIcons.more },
];

function NavLink({
  href,
  label,
  icon,
  badge,
}: {
  href: string;
  label: string;
  icon: ReactNode;
  badge?: number;
}) {
  const pathname = usePathname();
  const active = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      className={`relative flex min-w-0 flex-1 flex-col items-center gap-0.5 px-0.5 py-2 text-[10px] leading-tight ${
        active ? "font-semibold text-blue-600" : "text-gray-500"
      }`}
    >
      <span className="relative leading-none" aria-hidden>
        {icon}
        {badge && badge > 0 ? (
          <span className="absolute -right-2 -top-1 flex h-3.5 min-w-3.5 items-center justify-center rounded-full bg-red-600 px-0.5 text-[9px] font-bold text-white">
            {badge > 9 ? "9+" : badge}
          </span>
        ) : null}
      </span>
      <span className="truncate">{label}</span>
    </Link>
  );
}

export default function AppShell({
  children,
  userName,
}: {
  children: React.ReactNode;
  userName?: string;
}) {
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      try {
        const res = await fetch("/api/notifications", { cache: "no-store" });
        if (!res.ok) return;
        const data = (await res.json()) as { unreadCount?: number };
        if (!cancelled) setUnreadCount(Number(data.unreadCount ?? 0));
      } catch {
        // quiet
      }
    }
    void load();
    const timer = window.setInterval(() => void load(), 60_000);
    const onFocus = () => void load();
    window.addEventListener("focus", onFocus);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
      window.removeEventListener("focus", onFocus);
    };
  }, []);

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-lg flex-col bg-gray-50">
      <header className="sticky top-0 z-10 border-b border-gray-200 bg-white px-4 py-3 shadow-sm">
        <div className="flex items-center justify-between gap-2">
          <div className="flex min-w-0 items-center gap-3">
            <Image
              src="/icons/favicon-32.png"
              alt="AbilityERP"
              width={32}
              height={32}
              className="h-8 w-8 shrink-0 rounded-lg"
            />
            <div className="min-w-0">
              <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
                AbilityERP
              </p>
              <h1 className="truncate text-lg font-semibold text-gray-900">Worker App</h1>
            </div>
          </div>
          <div className="flex shrink-0 items-center gap-1">
            <NotificationBell count={unreadCount} />
            {userName ? (
              <p className="max-w-[28vw] truncate text-right text-xs text-gray-600 sm:text-sm">
                {userName}
              </p>
            ) : null}
          </div>
        </div>
      </header>

      <main className="flex-1 px-4 py-4 pb-24">{children}</main>

      <nav className="fixed bottom-0 left-1/2 z-10 w-full max-w-lg -translate-x-1/2 border-t border-gray-200 bg-white">
        <div className="flex items-stretch justify-between px-0.5">
          {navItems.map((item) => (
            <NavLink
              key={item.href}
              href={item.href}
              label={item.label}
              icon={item.icon}
              badge={item.badgeKey === "chat" ? unreadCount : undefined}
            />
          ))}
        </div>
      </nav>
    </div>
  );
}
