"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { href: "/open-shifts", label: "Open", icon: "📋" },
  { href: "/shifts", label: "Schedule", icon: "📅" },
  { href: "/roster", label: "Roster", icon: "👥" },
  { href: "/credentials", label: "ID", icon: "🪪" },
  { href: "/leave", label: "Leave", icon: "🏖️" },
  { href: "/profile", label: "Profile", icon: "👤" },
];

function NavLink({
  href,
  label,
  icon,
}: {
  href: string;
  label: string;
  icon: string;
}) {
  const pathname = usePathname();
  const active = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      className={`flex flex-1 flex-col items-center gap-1 px-1 py-2 text-xs ${
        active ? "text-blue-600 font-semibold" : "text-gray-500"
      }`}
    >
      <span className="text-lg leading-none" aria-hidden>
        {icon}
      </span>
      <span>{label}</span>
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
  return (
    <div className="mx-auto flex min-h-screen w-full max-w-lg flex-col bg-gray-50">
      <header className="sticky top-0 z-10 border-b border-gray-200 bg-white px-4 py-3 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
              AbilityERP
            </p>
            <h1 className="text-lg font-semibold text-gray-900">Worker App</h1>
          </div>
          {userName ? (
            <p className="max-w-[40%] truncate text-right text-sm text-gray-600">{userName}</p>
          ) : null}
        </div>
      </header>

      <main className="flex-1 px-4 py-4 pb-24">{children}</main>

      <nav className="fixed bottom-0 left-1/2 z-10 w-full max-w-lg -translate-x-1/2 border-t border-gray-200 bg-white">
        <div className="flex items-stretch justify-between px-1">
          {navItems.map((item) => (
            <NavLink key={item.href} {...item} />
          ))}
        </div>
      </nav>
    </div>
  );
}
