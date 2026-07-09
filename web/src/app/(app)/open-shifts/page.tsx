export default function OpenShiftsPage() {
  return (
    <section className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900">Available Shifts</h2>
      <p className="text-sm text-gray-600">
        Browse open shifts and apply. Data wiring comes in the next build phase.
      </p>
      <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-500">
        No open shifts loaded yet
      </div>
    </section>
  );
}
