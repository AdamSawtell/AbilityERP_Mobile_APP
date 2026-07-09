export default function ShiftsPage() {
  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">My Schedule</h2>
      <p className="text-sm text-gray-600">Your rostered shifts will appear here.</p>
      <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
        No scheduled shifts loaded yet
      </div>
    </section>
  );
}
