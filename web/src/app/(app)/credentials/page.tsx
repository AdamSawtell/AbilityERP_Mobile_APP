export default function CredentialsPage() {
  return (
    <section className="space-y-4">
      <div className="rounded-2xl bg-gradient-to-br from-blue-600 to-blue-800 p-5 text-white shadow">
        <p className="text-xs uppercase tracking-wide text-blue-100">Digital Worker ID</p>
        <h2 className="mt-1 text-2xl font-semibold">Support Worker</h2>
        <p className="mt-3 text-sm text-blue-100">Badge details load after profile sync.</p>
      </div>

      <div>
        <h3 className="text-lg font-semibold text-gray-900">Credentials</h3>
        <p className="text-sm text-gray-600">Qualifications, checks, and expiry dates.</p>
        <div className="mt-3 rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
          No credentials loaded yet
        </div>
      </div>
    </section>
  );
}
