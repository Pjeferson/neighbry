import { createFileRoute, redirect } from "@tanstack/react-router";
import { LoginPage } from "@/features/auth/LoginPage";

export const Route = createFileRoute("/login")({
  beforeLoad: () => {
    if (localStorage.getItem("neighbry_token")) {
      throw redirect({ to: "/" });
    }
  },
  component: LoginPage,
});
