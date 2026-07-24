import Link from "next/link";
import { notFound } from "next/navigation";
import { fetchWithSession } from "@/lib/server-data";

interface ClientDetail {
  id: number;
  name: string;
  value: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
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

  return (
    <div className="space-y-3">
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <dl className="space-y-3 text-sm">
          <div>
            <dt className="text-gray-500">Name</dt>
            <dd className="font-medium text-gray-900">{client.name}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Phone</dt>
            <dd className="font-medium text-gray-900">
              {client.phone ? (
                <a href={`tel:${client.phone}`} className="text-blue-600">
                  {client.phone}
                </a>
              ) : (
                "—"
              )}
            </dd>
          </div>
          <div>
            <dt className="text-gray-500">Email</dt>
            <dd className="font-medium text-gray-900">{client.email ?? "—"}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Address</dt>
            <dd className="font-medium text-gray-900">{client.address ?? "—"}</dd>
          </div>
        </dl>
      </div>

      <div className="grid grid-cols-2 gap-2">
        <Link
          href={`/clients/${client.id}/care-plan`}
          className="rounded-xl bg-blue-600 px-3 py-3 text-center text-sm font-semibold text-white"
        >
          Care plan
        </Link>
        <Link
          href={`/clients/${client.id}/activities`}
          className="rounded-xl border border-blue-200 bg-blue-50 px-3 py-3 text-center text-sm font-semibold text-blue-800"
        >
          Add activity
        </Link>
      </div>
    </div>
  );
}
