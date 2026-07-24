import PayPeriodTabs, { type PayPeriodInfo } from "@/components/PayPeriodTabs";
import { EmptyState, ShiftCard } from "@/components/ShiftCard";
import type { ShiftItem } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";
import { Suspense } from "react";

interface ShiftsResponse {
  period: PayPeriodInfo | null;
  items: ShiftItem[];
}

interface PeriodsResponse {
  current: PayPeriodInfo | null;
  next: PayPeriodInfo | null;
}

/** Worker app is AU — compare calendar day in Adelaide. */
const WORKER_TZ = "Australia/Adelaide";

function parsePeriod(value: string | undefined): "current" | "next" {
  return value === "next" ? "next" : "current";
}

function dayKey(value: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: WORKER_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(value);
}

function isTodayShift(shift: ShiftItem, today: string): boolean {
  if (!shift.start_time) return false;
  return dayKey(new Date(shift.start_time)) === today;
}

function formatTodayHeading(now: Date): string {
  return new Intl.DateTimeFormat("en-AU", {
    timeZone: WORKER_TZ,
    weekday: "long",
    day: "numeric",
    month: "short",
  }).format(now);
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

  const items = data?.items ?? [];
  const now = new Date();
  const today = dayKey(now);
  const todayShifts = items.filter((shift) => isTodayShift(shift, today));
  const upcomingShifts = items.filter((shift) => {
    if (!shift.start_time || isTodayShift(shift, today)) return false;
    return dayKey(new Date(shift.start_time)) > today;
  });
  const earlierShifts = items.filter((shift) => {
    if (!shift.start_time || isTodayShift(shift, today)) return false;
    return dayKey(new Date(shift.start_time)) < today;
  });

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">My Roster</h2>
      <p className="text-sm text-gray-600">
        Your shifts. Tap a client or location for details. Use Note to log progress.
      </p>
      <Suspense fallback={null}>
        <PayPeriodTabs
          current={periods?.current ?? null}
          next={periods?.next ?? null}
          active={periodKey}
        />
      </Suspense>

      {!items.length ? (
        <EmptyState message="No scheduled shifts in this fortnight." />
      ) : (
        <div className="space-y-4">
          <div className="space-y-3">
            <div className="rounded-xl bg-blue-600 px-4 py-3 text-white shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-wide text-blue-100">
                Today
              </p>
              <p className="text-lg font-semibold">{formatTodayHeading(now)}</p>
              <p className="mt-0.5 text-sm text-blue-100">
                {todayShifts.length === 0
                  ? "No shifts today"
                  : todayShifts.length === 1
                    ? "1 shift"
                    : `${todayShifts.length} shifts`}
              </p>
            </div>
            {todayShifts.length ? (
              todayShifts.map((shift) => (
                <ShiftCard
                  key={shift.id}
                  shift={shift}
                  quickClientActions
                  emphasize
                />
              ))
            ) : (
              <EmptyState message="Nothing rostered for today in this fortnight." />
            )}
          </div>

          {upcomingShifts.length ? (
            <div className="space-y-3">
              <h3 className="text-sm font-semibold uppercase tracking-wide text-gray-500">
                Coming up
              </h3>
              {upcomingShifts.map((shift) => (
                <ShiftCard key={shift.id} shift={shift} quickClientActions />
              ))}
            </div>
          ) : null}

          {earlierShifts.length ? (
            <div className="space-y-3">
              <h3 className="text-sm font-semibold uppercase tracking-wide text-gray-400">
                Earlier this fortnight
              </h3>
              {earlierShifts.map((shift) => (
                <ShiftCard key={shift.id} shift={shift} quickClientActions />
              ))}
            </div>
          ) : null}
        </div>
      )}
    </section>
  );
}
