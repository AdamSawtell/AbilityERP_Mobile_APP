import { notFound } from "next/navigation";
import { EmptyState } from "@/components/ShiftCard";
import { fetchWithSession } from "@/lib/server-data";

interface CarePlan {
  id: number;
  documentNo: string | null;
  name: string | null;
  validFrom: string | null;
  validTo: string | null;
  importantToMe: string | null;
  likes: string | null;
  dislikes: string | null;
  hobbies: string | null;
  culturalNeeds: string | null;
  amRoutine: string | null;
  dayRoutine: string | null;
  pmRoutine: string | null;
  nightRoutine: string | null;
  weeklyRoutine: string | null;
  allergiesFlag: boolean;
  fallRisk: boolean;
  medicationRequired: boolean;
  behaviourSupportRequired: boolean;
  strategies: string | null;
  behaviourDescription: string | null;
  details: string | null;
}

function Block({ title, body }: { title: string; body: string | null }) {
  if (!body?.trim()) return null;
  return (
    <div>
      <h3 className="text-xs font-semibold uppercase tracking-wide text-blue-600">{title}</h3>
      <p className="mt-1 whitespace-pre-wrap text-sm text-gray-900">{body}</p>
    </div>
  );
}

function formatDate(value: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleDateString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export default async function CarePlanPage({
  params,
}: {
  params: Promise<{ clientId: string }>;
}) {
  const { clientId } = await params;
  const data = await fetchWithSession<{ carePlan: CarePlan | null }>(
    `/api/clients/${clientId}/care-plan`,
  );
  if (!data) notFound();

  const plan = data.carePlan;
  if (!plan) {
    return <EmptyState message="No support / care plan on file for this client." />;
  }

  const flags = [
    plan.fallRisk ? "Fall risk" : null,
    plan.allergiesFlag ? "Allergies" : null,
    plan.medicationRequired ? "Medication required" : null,
    plan.behaviourSupportRequired ? "Behaviour support" : null,
  ].filter(Boolean);

  const from = formatDate(plan.validFrom);
  const to = formatDate(plan.validTo);

  return (
    <div className="space-y-3 rounded-xl border border-gray-200 bg-white p-4">
      <div>
        <p className="text-xs font-medium uppercase tracking-wide text-blue-600">
          {plan.documentNo ?? `Plan ${plan.id}`}
        </p>
        <h3 className="mt-1 font-semibold text-gray-900">{plan.name ?? "Support plan"}</h3>
        {(from || to) && (
          <p className="mt-1 text-xs text-gray-500">
            Valid {from ?? "—"} → {to ?? "—"}
          </p>
        )}
      </div>

      {flags.length ? (
        <div className="flex flex-wrap gap-1">
          {flags.map((flag) => (
            <span
              key={flag}
              className="rounded-full bg-amber-50 px-2 py-1 text-xs font-medium text-amber-800"
            >
              {flag}
            </span>
          ))}
        </div>
      ) : null}

      <div className="space-y-4">
        <Block title="Important to me" body={plan.importantToMe} />
        <Block title="Likes" body={plan.likes} />
        <Block title="Dislikes" body={plan.dislikes} />
        <Block title="Hobbies" body={plan.hobbies} />
        <Block title="Cultural needs" body={plan.culturalNeeds} />
        <Block title="Morning routine" body={plan.amRoutine} />
        <Block title="Day routine" body={plan.dayRoutine} />
        <Block title="Afternoon routine" body={plan.pmRoutine} />
        <Block title="Night routine" body={plan.nightRoutine} />
        <Block title="Weekly routine" body={plan.weeklyRoutine} />
        <Block title="Behaviour" body={plan.behaviourDescription} />
        <Block title="Strategies" body={plan.strategies} />
        <Block title="Details" body={plan.details} />
      </div>
    </div>
  );
}
