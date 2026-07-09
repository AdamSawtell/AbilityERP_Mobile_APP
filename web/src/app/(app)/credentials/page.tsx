import { EmptyState } from "@/components/ShiftCard";
import { fetchWithSession, formatDateTime } from "@/lib/server-data";

interface CredentialItem {
  id: number;
  name: string;
  type_name: string | null;
  category_name: string | null;
  expiry_date: string | null;
  status: string;
}

interface IdCard {
  name: string;
  employeeNo: string;
  email: string;
  roles: string[];
  credentialCount: number;
}

export default async function CredentialsPage() {
  const [credentials, idCardData] = await Promise.all([
    fetchWithSession<{ items: CredentialItem[] }>("/api/credentials"),
    fetchWithSession<{ idCard: IdCard }>("/api/credentials/id-card"),
  ]);

  const idCard = idCardData?.idCard;

  return (
    <section className="space-y-4">
      <div className="rounded-2xl bg-gradient-to-br from-blue-600 to-blue-800 p-5 text-white shadow">
        <p className="text-xs uppercase tracking-wide text-blue-100">Digital Worker ID</p>
        <h2 className="mt-1 text-2xl font-semibold">{idCard?.name ?? "Support Worker"}</h2>
        <p className="mt-2 text-sm text-blue-100">Employee #{idCard?.employeeNo ?? "—"}</p>
        <p className="text-sm text-blue-100">{idCard?.email ?? ""}</p>
        <p className="mt-3 text-sm text-blue-100">
          {idCard?.credentialCount ?? 0} active credentials on file
        </p>
      </div>

      <div>
        <h3 className="text-lg font-semibold text-gray-900">Credentials</h3>
        <p className="text-sm text-gray-600">Qualifications, checks, and expiry dates.</p>
        {credentials?.items?.length ? (
          <div className="mt-3 space-y-3">
            {credentials.items.map((item) => (
              <article
                key={item.id}
                className="rounded-xl border border-gray-200 bg-white p-4"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h4 className="font-medium text-gray-900">{item.name}</h4>
                    <p className="text-sm text-gray-500">
                      {[item.type_name, item.category_name].filter(Boolean).join(" · ") || "Credential"}
                    </p>
                  </div>
                  <span
                    className={`rounded-full px-2 py-1 text-xs ${
                      item.status === "expired"
                        ? "bg-red-100 text-red-700"
                        : "bg-green-100 text-green-700"
                    }`}
                  >
                    {item.status}
                  </span>
                </div>
                <p className="mt-2 text-sm text-gray-600">
                  Expires: {item.expiry_date ? formatDateTime(item.expiry_date) : "—"}
                </p>
              </article>
            ))}
          </div>
        ) : (
          <div className="mt-3">
            <EmptyState message="No credentials on file yet." />
          </div>
        )}
      </div>
    </section>
  );
}
