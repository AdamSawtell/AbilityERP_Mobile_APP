import Link from "next/link";
import { notFound } from "next/navigation";
import ClientTabs from "@/components/ClientTabs";
import { fetchWithSession } from "@/lib/server-data";

interface ClientDetail {
  id: number;
  name: string;
}

export default async function ClientLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ clientId: string }>;
}) {
  const { clientId } = await params;
  const data = await fetchWithSession<{ client: ClientDetail }>(
    `/api/clients/${clientId}`,
  );
  if (!data?.client) notFound();

  return (
    <section className="space-y-3">
      <div>
        <Link href="/clients" className="text-xs font-medium text-blue-600">
          ← Clients
        </Link>
        <h2 className="mt-1 text-xl font-semibold text-gray-900">{data.client.name}</h2>
      </div>
      <ClientTabs clientId={data.client.id} />
      {children}
    </section>
  );
}
