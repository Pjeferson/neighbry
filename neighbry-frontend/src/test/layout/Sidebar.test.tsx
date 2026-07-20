import { describe, it, expect, beforeEach } from "vitest";
import { screen } from "@testing-library/react";
import { render } from "@/test/utils";
import { Sidebar } from "@/components/layout/Sidebar";
import { useAuthStore } from "@/store/authStore";
import type { Role } from "@/store/authStore";

function setUser(role: Role) {
  useAuthStore.setState({
    user: { id: "u-1", email: "user@neighbry.com", name: "User", role },
    isAuthenticated: true,
  });
}

beforeEach(() => {
  useAuthStore.setState({ user: null, isAuthenticated: false });
});

describe("Sidebar", () => {
  it("shows the full staff item set for admin, in priority order", () => {
    setUser("admin");
    render(<Sidebar />);

    const nav = screen.getByRole("navigation");
    const labels = Array.from(nav.children).map((el) => el.textContent?.replace("em breve", "").trim());
    expect(labels).toEqual(["Unidades", "Avisos", "Faturas", "Espaços", "Reservas"]);
  });

  it("shows the same item set for manager as admin", () => {
    setUser("manager");
    render(<Sidebar />);

    expect(screen.getByText("Unidades")).toBeInTheDocument();
    expect(screen.getByText("Espaços")).toBeInTheDocument();
  });

  it("shows a resident-specific item set", () => {
    setUser("resident");
    render(<Sidebar />);

    expect(screen.getByText("Minha Unidade")).toBeInTheDocument();
    expect(screen.getByText("Avisos")).toBeInTheDocument();
    expect(screen.getByText("Faturas")).toBeInTheDocument();
    expect(screen.getByText("Espaços")).toBeInTheDocument();
    expect(screen.getByText("Reservas")).toBeInTheDocument();
    expect(screen.queryByText("Unidades")).not.toBeInTheDocument();
  });

  it("shows a minimal item set for service_provider", () => {
    setUser("service_provider");
    render(<Sidebar />);

    expect(screen.getByText("Avisos")).toBeInTheDocument();
    expect(screen.getByText("Espaços")).toBeInTheDocument();
    expect(screen.queryByText("Faturas")).not.toBeInTheDocument();
    expect(screen.queryByText("Reservas")).not.toBeInTheDocument();
  });

  it("renders items without a route as disabled placeholders", () => {
    setUser("admin");
    render(<Sidebar />);

    const unidades = screen.getByText("Unidades").closest("span");
    expect(unidades).toHaveTextContent("em breve");
  });

  it("renders Espaços as a real link", () => {
    setUser("admin");
    render(<Sidebar />);

    const espacos = screen.getByText("Espaços").closest("a");
    expect(espacos).toHaveAttribute("href", "/common-areas");
  });
});
