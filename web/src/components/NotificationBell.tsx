"use client";

import Link from "next/link";
import { NavIcons } from "./NavIcons";

export default function NotificationBell({ count = 0 }: { count?: number }) {
  return (
    <Link
      href="/notifications"
      className="relative rounded-lg p-2 text-gray-600 hover:bg-gray-50 hover:text-blue-600"
      aria-label={count > 0 ? `Notifications, ${count} unread` : "Notifications"}
    >
      <span className="leading-none" aria-hidden>
        {NavIcons.bell}
      </span>
      {count > 0 ? (
        <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-600 px-1 text-[10px] font-bold leading-none text-white">
          {count > 9 ? "9+" : count}
        </span>
      ) : null}
    </Link>
  );
}
