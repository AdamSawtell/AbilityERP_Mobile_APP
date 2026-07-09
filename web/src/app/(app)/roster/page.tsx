export default function RosterPage() {
  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Roster</h2>
      <p className="text-sm text-gray-600">Master and current roster views (read-only).</p>
      <div className="grid gap-3">
        <div className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="font-medium text-gray-900">Current roster</h3>
          <p className="mt-1 text-sm text-gray-500">Coming soon</p>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="font-medium text-gray-900">Master roster</h3>
          <p className="mt-1 text-sm text-gray-500">Coming soon</p>
        </div>
      </div>
    </section>
  );
}
