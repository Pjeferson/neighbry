import { createFileRoute } from "@tanstack/react-router";

function DashboardPlaceholder() {
  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-gray-900">Neighbry</h1>
      <p className="text-sm text-gray-500 mt-1">
        Nenhum módulo de domínio implementado ainda.
      </p>
    </div>
  );
}

export const Route = createFileRoute("/_authenticated/")({
  component: DashboardPlaceholder,
});
