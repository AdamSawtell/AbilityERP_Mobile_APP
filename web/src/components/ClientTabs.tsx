"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const tabs = [
  { key: "", label: "Details" },
  { key: "care-plan", label: "Care plan" },
  { key: "activities", label: "Activities" },
] as const;

export default function ClientTabs({ clientId }: { clientId: number }) {
  const pathname = usePathname();
  const base = `/clients/${clientId}`;

  return (
    <div className="flex gap-1 rounded-xl border border-gray-200 bg-white p-1">
      {tabs.map((tab) => {
        const href = tab.key ? `${base}/${tab.key}` : base;
        const active =
          tab.key === ""
            ? pathname === base
            : pathname === href || pathname.startsWith(`${href}/`);
        return (
          <Link
            key={tab.label}
            href={href}
            className={`flex-1 rounded-lg px-2 py-2 text-center text-xs font-semibold ${
              active ? "bg-blue-600 text-white" : "text-gray-600"
            }`}
          >
            {tab.label}
          </Link>
        );
      })}
    </div>
  );
}
