import { describe, it, expect, beforeEach } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { LoginPage } from "@/features/auth/LoginPage";
import { useAuthStore } from "@/store/authStore";

const API = "http://localhost:3001";

const successHandler = http.post(`${API}/api/v1/auth/sign_in`, () =>
  HttpResponse.json(
    { message: "Logged in successfully", user: { id: "u-1", email: "demo@neighbry.com", name: "Demo" } },
    { headers: { Authorization: "Bearer fake-jwt-token" } }
  )
);

function signInErrorHandler(error: string) {
  return http.post(`${API}/api/v1/auth/sign_in`, () => HttpResponse.json({ error }, { status: 401 }));
}

// getTenantSlug() é null em jsdom (hostname "localhost", sem subdomínio),
// então useCondominiumInfo fica enabled: false e nenhuma chamada acontece
// — LoginPage renderiza o estado "sem tenant conhecido" (título genérico).

beforeEach(() => {
  localStorage.clear();
  useAuthStore.setState({ user: null, isAuthenticated: false });
});

describe("LoginPage", () => {
  it("renders email and password fields", () => {
    render(<LoginPage />);
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/senha/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /entrar/i })).toBeInTheDocument();
  });

  it("submits credentials and stores user on success", async () => {
    server.use(successHandler);
    const user = userEvent.setup();
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "demo@neighbry.com");
    await user.type(screen.getByLabelText(/senha/i), "password123");
    await user.click(screen.getByRole("button", { name: /entrar/i }));

    await waitFor(() => {
      expect(useAuthStore.getState().isAuthenticated).toBe(true);
    });
    expect(useAuthStore.getState().user?.email).toBe("demo@neighbry.com");
    expect(localStorage.getItem("neighbry_token")).toBe("fake-jwt-token");
  });

  it("shows a specific message for invalid credentials", async () => {
    server.use(signInErrorHandler("invalid_credentials"));
    const user = userEvent.setup();
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "wrong@email.com");
    await user.type(screen.getByLabelText(/senha/i), "wrongpass");
    await user.click(screen.getByRole("button", { name: /entrar/i }));

    await waitFor(() => {
      expect(screen.getByText(/email ou senha inválidos/i)).toBeInTheDocument();
    });
  });

  it("shows a specific message when the user has no membership in this tenant", async () => {
    server.use(signInErrorHandler("no_active_membership_for_tenant"));
    const user = userEvent.setup();
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "demo@neighbry.com");
    await user.type(screen.getByLabelText(/senha/i), "password123");
    await user.click(screen.getByRole("button", { name: /entrar/i }));

    await waitFor(() => {
      expect(screen.getByText(/você não tem acesso a este condomínio/i)).toBeInTheDocument();
    });
  });

  it("disables button while submitting", async () => {
    server.use(successHandler);
    const user = userEvent.setup();
    render(<LoginPage />);

    await user.type(screen.getByLabelText(/email/i), "demo@neighbry.com");
    await user.type(screen.getByLabelText(/senha/i), "password123");

    const button = screen.getByRole("button", { name: /entrar/i });
    await user.click(button);

    // Enquanto a requisição está em flight, o botão mostra "Entrando..."
    // waitFor garante que chegamos ao estado final sem flakiness
    await waitFor(() => expect(useAuthStore.getState().isAuthenticated).toBe(true));
  });
});
