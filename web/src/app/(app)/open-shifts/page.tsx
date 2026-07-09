import OpenShiftsList from "@/components/OpenShiftsList";
import PayPeriodTabs, { type PayPeriodInfo } from "@/components/PayPeriodTabs";
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

function parsePeriod(value: string | undefined): "current" | "next" {
  return value === "next" ? "next" : "current";
}

export default async function OpenShiftsPage({
  searchParams,
}: {
  searchParams: Promise<{ period?: string }>;
}) {
  const { period: periodParam } = await searchParams;
  const periodKey = parsePeriod(periodParam);

  const [periods, data] = await Promise.all([
    fetchWithSession<PeriodsResponse>("/api/shifts/periods"),
    fetchWithSession<ShiftsResponse>(`/api/shifts/open?period=${periodKey}`),
  ]);

  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Available Shifts</h2>
      <p className="text-sm text-gray-600">
        Open shifts for this and next pay fortnight.
      </p>
      <Suspense fallback={null}>
        <PayPeriodTabs
          current={periods?.current ?? null}
          next={periods?.next ?? null}
          active={periodKey}
        />
      </Suspense>
      <OpenShiftsList shifts={data?.items ?? []} />
    </section>
  );
}
