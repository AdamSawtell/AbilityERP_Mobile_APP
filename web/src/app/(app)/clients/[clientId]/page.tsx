import type { ReactNode } from "react";
import Link from "next/link";
import { notFound } from "next/navigation";
import { fetchWithSession } from "@/lib/server-data";

interface ClientAlert {
  id: number;
  type: string | null;
  name: string | null;
  description: string | null;
  isAlert: boolean;
}

interface ClientKeyPerson {
  id: number;
  name: string;
  relationship: string | null;
  phone: string | null;
  email: string | null;
  notes: string | null;
}

interface ClientAddress {
  label: string | null;
  address: string;
  phone: string | null;
  isHome: boolean;
}

interface ShiftEssentials {
  allergiesFlag: boolean;
  fallRisk: boolean;
  medicationRequired: boolean;
  behaviourSupportRequired: boolean;
  interpreterRequired: boolean;
  swallowingRisk: boolean;
  importantToMe: string | null;
  communication: string | null;
  mobility: string | null;
  transport: string | null;
  dietaryAllergies: string | null;
  likes: string | null;
  dislikes: string | null;
}

interface ClientDetail {
  id: number;
  name: string;
  preferredName: string | null;
  value: string | null;
  email: string | null;
  phone: string | null;
  phone2: string | null;
  address: string | null;
  addresses: ClientAddress[];
  birthday: string | null;
  age: number | null;
  gender: string | null;
  disability: string | null;
  ndisNumber: string | null;
  about: string | null;
  alerts: ClientAlert[];
  keyPeople: ClientKeyPerson[];
  shiftEssentials: ShiftEssentials | null;
}

function Field({ label, value }: { label: string; value: ReactNode }) {
  if (value === null || value === undefined || value === "") return null;
  return (
    <div>
      <dt className="text-gray-500">{label}</dt>
      <dd className="font-medium text-gray-900">{value}</dd>
    </div>
  );
}

function PhoneLink({ phone }: { phone: string }) {
  return (
    <a href={`tel:${phone}`} className="text-blue-600">
      {phone}
    </a>
  );
}

function formatBirthday(value: string | null, age: number | null): string | null {
  if (!value && age === null) return null;
  if (!value) return age !== null ? `Age ${age}` : null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return age !== null ? `Age ${age}` : null;
  const born = date.toLocaleDateString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
  return age !== null ? `${born} (age ${age})` : born;
}

function essentialsFlags(essentials: ShiftEssentials): string[] {
  return [
    essentials.fallRisk ? "Fall risk" : null,
    essentials.allergiesFlag ? "Allergies" : null,
    essentials.medicationRequired ? "Medication required" : null,
    essentials.behaviourSupportRequired ? "Behaviour support" : null,
    essentials.interpreterRequired ? "Interpreter" : null,
    essentials.swallowingRisk ? "Swallowing / choking risk" : null,
  ].filter((item): item is string => Boolean(item));
}

export default async function ClientDetailPage({
  params,
}: {
  params: Promise<{ clientId: string }>;
}) {
  const { clientId } = await params;
  const data = await fetchWithSession<{ client: ClientDetail }>(
    `/api/clients/${clientId}`,
  );
  if (!data?.client) notFound();
  const client = data.client;
  const essentials = client.shiftEssentials;
  const flags = essentials ? essentialsFlags(essentials) : [];
  const hasEssentialsText = Boolean(
    essentials &&
      (essentials.importantToMe ||
        essentials.communication ||
        essentials.mobility ||
        essentials.transport ||
        essentials.dietaryAllergies ||
        essentials.likes ||
        essentials.dislikes),
  );
  const birthday = formatBirthday(client.birthday, client.age);
  const displayName = client.preferredName
    ? `${client.name} (${client.preferredName})`
    : client.name;

  return (
    <div className="space-y-3">
      <div className="grid grid-cols-2 gap-2">
        <Link
          href={`/clients/${client.id}/care-plan`}
          className="rounded-xl bg-blue-600 px-3 py-3 text-center text-sm font-semibold text-white"
        >
          Full care plan
        </Link>
        <Link
          href={`/clients/${client.id}/activities?note=1`}
          className="rounded-xl border border-blue-200 bg-blue-50 px-3 py-3 text-center text-sm font-semibold text-blue-800"
        >
          Add note
        </Link>
      </div>

      {client.alerts.length ? (
        <section className="rounded-xl border border-amber-300 bg-amber-50 p-4">
          <h3 className="text-sm font-semibold text-amber-950">Safety alerts</h3>
          <ul className="mt-2 space-y-2">
            {client.alerts.map((alert) => (
              <li key={alert.id} className="text-sm text-amber-950">
                <p className="font-semibold">
                  {alert.isAlert ? "⚠ " : ""}
                  {[alert.type, alert.name].filter(Boolean).join(" · ") || "Alert"}
                </p>
                {alert.description ? (
                  <p className="mt-0.5 text-amber-900">{alert.description}</p>
                ) : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {essentials && (flags.length || hasEssentialsText) ? (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="text-sm font-semibold text-gray-900">Before you start</h3>
          {flags.length ? (
            <div className="mt-2 flex flex-wrap gap-1">
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
          <dl className="mt-3 space-y-3 text-sm">
            <Field label="Important to them" value={essentials.importantToMe} />
            <Field label="Communication" value={essentials.communication} />
            <Field label="Mobility" value={essentials.mobility} />
            <Field label="Transport" value={essentials.transport} />
            <Field label="Dietary / allergies" value={essentials.dietaryAllergies} />
            <Field label="Likes" value={essentials.likes} />
            <Field label="Dislikes" value={essentials.dislikes} />
          </dl>
        </section>
      ) : null}

      <section className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="text-sm font-semibold text-gray-900">Who they are</h3>
        <dl className="mt-3 space-y-3 text-sm">
          <Field label="Name" value={displayName} />
          <Field label="Preferred name" value={client.preferredName} />
          <Field label="Gender" value={client.gender} />
          <Field label="Date of birth" value={birthday} />
          <Field label="Disability" value={client.disability} />
          <Field label="NDIS / reference" value={client.ndisNumber} />
          <Field label="About" value={client.about} />
        </dl>
      </section>

      <section className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="text-sm font-semibold text-gray-900">Contact</h3>
        <dl className="mt-3 space-y-3 text-sm">
          <Field
            label="Phone"
            value={client.phone ? <PhoneLink phone={client.phone} /> : null}
          />
          <Field
            label="Phone 2"
            value={client.phone2 ? <PhoneLink phone={client.phone2} /> : null}
          />
          <Field label="Email" value={client.email} />
          {client.addresses.length ? (
            client.addresses.map((addr) => (
              <div key={`${addr.label}-${addr.address}`}>
                <dt className="text-gray-500">
                  {addr.label ?? "Address"}
                  {addr.isHome ? " (home / service)" : ""}
                </dt>
                <dd className="font-medium text-gray-900">
                  {addr.address}
                  {addr.phone ? (
                    <>
                      {" · "}
                      <PhoneLink phone={addr.phone} />
                    </>
                  ) : null}
                </dd>
              </div>
            ))
          ) : (
            <Field label="Address" value={client.address} />
          )}
        </dl>
      </section>

      {client.keyPeople.length ? (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="text-sm font-semibold text-gray-900">Key people</h3>
          <ul className="mt-3 space-y-3">
            {client.keyPeople.map((person) => (
              <li key={person.id} className="text-sm">
                <p className="font-semibold text-gray-900">{person.name}</p>
                {person.relationship ? (
                  <p className="text-xs text-blue-700">{person.relationship}</p>
                ) : null}
                {person.phone ? (
                  <p className="mt-0.5">
                    <PhoneLink phone={person.phone} />
                  </p>
                ) : null}
                {person.email ? <p className="text-gray-600">{person.email}</p> : null}
                {person.notes ? (
                  <p className="mt-1 text-gray-600">{person.notes}</p>
                ) : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
