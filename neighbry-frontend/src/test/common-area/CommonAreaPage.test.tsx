import { describe, it, expect, beforeEach } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { CommonAreaPage } from "@/features/common-area/CommonAreaPage";
import { useAuthStore } from "@/store/authStore";
import type { Role } from "@/store/authStore";

const API = "http://localhost:3001";

function setUser(role: Role) {
  useAuthStore.setState({
    user: { id: "u-1", email: "user@neighbry.com", name: "User", role },
    isAuthenticated: true,
  });
}

beforeEach(() => {
  useAuthStore.setState({ user: null, isAuthenticated: false });
  server.use(http.get(`${API}/api/v1/common_areas`, () => HttpResponse.json({ data: [] })));
});

describe("CommonAreaPage", () => {
  it("renders the admin view (with create action) for role admin", async () => {
    setUser("admin");
    render(<CommonAreaPage />);

    await waitFor(() => {
      expect(screen.getByRole("button", { name: /novo espaço/i })).toBeInTheDocument();
    });
  });

  it("renders the admin view for role manager too", async () => {
    setUser("manager");
    render(<CommonAreaPage />);

    await waitFor(() => {
      expect(screen.getByRole("button", { name: /novo espaço/i })).toBeInTheDocument();
    });
  });

  it("renders the read-only view for role resident", async () => {
    setUser("resident");
    render(<CommonAreaPage />);

    await waitFor(() => {
      expect(screen.getByText(/nenhum espaço cadastrado ainda/i)).toBeInTheDocument();
    });
    expect(screen.queryByRole("button", { name: /novo espaço/i })).not.toBeInTheDocument();
  });

  it("renders the read-only view for role service_provider too", async () => {
    setUser("service_provider");
    render(<CommonAreaPage />);

    await waitFor(() => {
      expect(screen.getByText(/nenhum espaço cadastrado ainda/i)).toBeInTheDocument();
    });
    expect(screen.queryByRole("button", { name: /novo espaço/i })).not.toBeInTheDocument();
  });
});
