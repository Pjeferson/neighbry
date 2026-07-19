import { createFileRoute, redirect } from "@tanstack/react-router";
import { CondominiumSignupPage } from "@/features/condominium/CondominiumSignupPage";

export const Route = createFileRoute("/register")({
  beforeLoad: () => {
    if (localStorage.getItem("neighbry_token")) {
      throw redirect({ to: "/" });
    }
  },
  component: CondominiumSignupPage,
});
