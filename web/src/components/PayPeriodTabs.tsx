"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";

export interface PayPeriodInfo {
  id: number;
  name: string;
  value: string | null;
  start_date: string;
  end_date: string;
  key: "current" | "next";
}

function formatPeriodLabel(period: PayPeriodInfo | null, fallback: string): string {
  if (!period) return fallback;
  const fmt = (value: string) =>
    new Date(value).toLocaleDateString("en-AU", { day: "numeric", month: "short" });
  return `${period.name} (${fmt(period.start_date)} – ${fmt(period.end_date)})`;
}

export default function PayPeriodTabs({
  current,
  next,
  active,
}: {
  current: PayPeriodInfo | null;
  next: PayPeriodInfo | null;
  active: "current" | "next";
}) {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function hrefFor(key: "current" | "next") {
    const params = new URLSearchParams(searchParams.toString());
    if (key === "current") {
      params.delete("period");
    } else {
      params.set("period", "next");
    }
    const query = params.toString();
    return query ? `${pathname}?${query}` : pathname;
  }

  const tabs: { key: "current" | "next"; label: string }[] = [
    { key: "current", label: formatPeriodLabel(current, "This fortnight") },
    { key: "next", label: formatPeriodLabel(next, "Next fortnight") },
  ];

  return (
    <div className="flex gap-2 overflow-x-auto rounded-xl bg-gray-100 p-1">
      {tabs.map((tab) => {
        const selected = active === tab.key;
        return (
          <Link
            key={tab.key}
            href={hrefFor(tab.key)}
            className={`min-w-0 flex-1 rounded-lg px-3 py-2 text-center text-xs font-medium transition-colors ${
              selected
                ? "bg-white text-blue-700 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        );
      })}
    </div>
  );
}
