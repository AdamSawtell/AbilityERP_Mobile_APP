import Link from "next/link";
import { redirect } from "next/navigation";
import ProfileForm from "@/components/ProfileForm";
import { fetchWithSession } from "@/lib/server-data";
import { getSessionToken } from "@/lib/session";
import { apiFetch } from "@/lib/api-client";
import type { WorkerUser } from "@/lib/types";

interface ProfileData {
  profile: {
    adUserId: number;
    name: string;
    email: string | null;
    phone: string | null;
    employeeNo: string | null;
    firstName: string | null;
    lastName: string | null;
    preferredName: string | null;
    address: {
      line1: string | null;
      city: string | null;
      postal: string | null;
      region: string | null;
    };
  };
}

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
  const [user, profileData] = await Promise.all([
    getCurrentUser(),
    fetchWithSession<ProfileData>("/api/profile"),
  ]);

  if (!user) redirect("/login");

  const profile = profileData?.profile;

  return (
    <section className="space-y-4">
      <h2 className="text-xl font-semibold text-gray-900">More</h2>

      <div className="grid grid-cols-3 gap-2">
        {[
          { href: "/leave", label: "Leave" },
          { href: "/credentials", label: "ID card" },
          { href: "/roster", label: "Roster" },
        ].map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="rounded-xl border border-gray-200 bg-white px-3 py-3 text-center text-sm font-semibold text-gray-800"
          >
            {item.label}
          </Link>
        ))}
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <dl className="space-y-3 text-sm">
          <div>
            <dt className="text-gray-500">Name</dt>
            <dd className="font-medium text-gray-900">{profile?.name ?? user.name}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Preferred name</dt>
            <dd className="font-medium text-gray-900">{profile?.preferredName ?? "—"}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Employee #</dt>
            <dd className="font-medium text-gray-900">{profile?.employeeNo ?? user.cBPartnerId}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Roles</dt>
            <dd className="font-medium text-gray-900">{user.roles.join(", ")}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Address</dt>
            <dd className="font-medium text-gray-900">
              {[
                profile?.address.line1,
                profile?.address.city,
                profile?.address.region,
                profile?.address.postal,
              ]
                .filter(Boolean)
                .join(", ") || "—"}
            </dd>
          </div>
        </dl>
      </div>

      <ProfileForm
        initialEmail={profile?.email ?? user.email}
        initialPhone={profile?.phone ?? ""}
      />

      <div className="rounded-xl border border-gray-200 bg-white px-4 py-3 text-sm text-gray-600">
        <p className="font-medium text-gray-900">Install on your phone</p>
        <p className="mt-1">
          Use your browser’s <span className="font-medium">Install</span> or{" "}
          <span className="font-medium">Add to Home Screen</span> so AbilityERP opens like an app.
        </p>
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
