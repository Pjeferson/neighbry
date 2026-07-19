import { createFileRoute, redirect } from "@tanstack/react-router";
import { FindCondominiumPage } from "@/features/condominium/FindCondominiumPage";
import { isGenericHost } from "@/lib/tenant";

export const Route = createFileRoute("/find")({
  beforeLoad: () => {
    if (localStorage.getItem("neighbry_token")) {
      throw redirect({ to: "/" });
    }
    if (!isGenericHost()) {
      throw redirect({ to: "/login" });
    }
  },
  component: FindCondominiumPage,
});
