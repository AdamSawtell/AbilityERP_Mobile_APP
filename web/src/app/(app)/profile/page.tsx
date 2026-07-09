import { redirect } from "next/navigation";
import { apiFetch } from "@/lib/api-client";
import { getSessionToken } from "@/lib/session";
import type { WorkerUser } from "@/lib/types";

async function getCurrentUser(): Promise<WorkerUser | null> {
  const token = await getSessionToken();
  if (!token) return null;

  try {
    const data = await apiFetch<{ user: WorkerUser }>("/api/auth/me", { token });
    return data.user;
  } catch {
    return null;
  }
}

export default async function ProfilePage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">Profile</h2>
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <dl className="space-y-3 text-sm">
          <div>
            <dt className="text-gray-500">Name</dt>
            <dd className="font-medium text-gray-900">{user.name}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Email</dt>
            <dd className="font-medium text-gray-900">{user.email || "—"}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Employee ID</dt>
            <dd className="font-medium text-gray-900">{user.cBPartnerId}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Roles</dt>
            <dd className="font-medium text-gray-900">{user.roles.join(", ")}</dd>
          </div>
        </dl>
      </div>

      <form action="/api/auth/logout" method="post">
        <button
          type="submit"
          className="w-full rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700"
        >
          Sign out
        </button>
      </form>
    </section>
  );
}
