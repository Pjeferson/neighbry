import { createFileRoute, redirect } from "@tanstack/react-router";
import { CondominiumSignupPage } from "@/features/condominium/CondominiumSignupPage";
import { isGenericHost } from "@/lib/tenant";

export const Route = createFileRoute("/register")({
  beforeLoad: () => {
    if (localStorage.getItem("neighbry_token")) {
      throw redirect({ to: "/" });
    }
    if (!isGenericHost()) {
      throw redirect({ to: "/login" });
    }
  },
  component: CondominiumSignupPage,
});
