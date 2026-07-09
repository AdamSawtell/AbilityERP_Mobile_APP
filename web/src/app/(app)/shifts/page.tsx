import PayPeriodTabs, { type PayPeriodInfo } from "@/components/PayPeriodTabs";
import { EmptyState, ShiftCard } from "@/components/ShiftCard";
import type { ShiftItem } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";
import Link from "next/link";
import { Suspense } from "react";

interface ShiftsResponse {
  period: PayPeriodInfo | null;
  items: ShiftItem[];
}

interface PeriodsResponse {
  current: PayPeriodInfo | null;
  next: PayPeriodInfo | null;
}

function parsePeriod(value: string | undefined): "current" | "next" {
  return value === "next" ? "next" : "current";
}

export default async function ShiftsPage({
  searchParams,
}: {
  searchParams: Promise<{ period?: string }>;
}) {
  const { period: periodParam } = await searchParams;
  const periodKey = parsePeriod(periodParam);

  const [periods, data] = await Promise.all([
    fetchWithSession<PeriodsResponse>("/api/shifts/periods"),
    fetchWithSession<ShiftsResponse>(`/api/shifts/mine?period=${periodKey}`),
  ]);

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">My Schedule</h2>
      <p className="text-sm text-gray-600">Your confirmed rostered shifts.</p>
      <Suspense fallback={null}>
        <PayPeriodTabs
          current={periods?.current ?? null}
          next={periods?.next ?? null}
          active={periodKey}
        />
      </Suspense>
      {data?.items?.length ? (
        <div className="space-y-3">
          {data.items.map((shift) => (
            <ShiftCard
              key={shift.id}
              shift={shift}
              action={
                shift.request_id ? (
                  <Link
                    href={`/tasks/${shift.request_id}`}
                    className="block w-full rounded-xl border border-blue-200 bg-blue-50 px-4 py-2 text-center text-sm font-medium text-blue-700"
                  >
                    Chat with rostering
                  </Link>
                ) : null
              }
            />
          ))}
        </div>
      ) : (
        <EmptyState message="No scheduled shifts in this fortnight." />
      )}
    </section>
  );
}
