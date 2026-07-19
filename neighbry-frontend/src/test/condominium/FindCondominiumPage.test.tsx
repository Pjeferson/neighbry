import { describe, it, expect, beforeEach } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { FindCondominiumPage } from "@/features/condominium/FindCondominiumPage";

const API = "http://localhost:3001";

beforeEach(() => {
  Object.defineProperty(window, "location", {
    writable: true,
    value: { protocol: "http:", hostname: "localhost", port: "5173", href: "" },
  });
});

describe("FindCondominiumPage", () => {
  it("renders the identifier field", () => {
    render(<FindCondominiumPage />);
    expect(screen.getByLabelText(/identificador do condomínio/i)).toBeInTheDocument();
  });

  it("redirects to the tenant subdomain login when the condominium is found", async () => {
    server.use(
      http.get(`${API}/api/v1/condominiums/acme`, () =>
        HttpResponse.json({ exists: true, name: "Acme" }, { status: 200 })
      )
    );
    const user = userEvent.setup();
    render(<FindCondominiumPage />);

    await user.type(screen.getByLabelText(/identificador do condomínio/i), "acme");
    await user.click(screen.getByRole("button", { name: /continuar/i }));

    await waitFor(() => {
      expect(window.location.href).toBe("http://acme.localhost:5173/login");
    });
  });

  it("normalizes case and whitespace before checking existence", async () => {
    server.use(
      http.get(`${API}/api/v1/condominiums/acme`, () =>
        HttpResponse.json({ exists: true, name: "Acme" }, { status: 200 })
      )
    );
    const user = userEvent.setup();
    render(<FindCondominiumPage />);

    await user.type(screen.getByLabelText(/identificador do condomínio/i), "  ACME  ");
    await user.click(screen.getByRole("button", { name: /continuar/i }));

    await waitFor(() => {
      expect(window.location.href).toBe("http://acme.localhost:5173/login");
    });
  });

  it("shows an inline error when the condominium is not found", async () => {
    server.use(
      http.get(`${API}/api/v1/condominiums/does-not-exist`, () =>
        HttpResponse.json({ exists: false }, { status: 404 })
      )
    );
    const user = userEvent.setup();
    render(<FindCondominiumPage />);

    await user.type(screen.getByLabelText(/identificador do condomínio/i), "does-not-exist");
    await user.click(screen.getByRole("button", { name: /continuar/i }));

    await waitFor(() => {
      expect(screen.getByText(/não encontramos nenhum condomínio/i)).toBeInTheDocument();
    });
    expect(window.location.href).toBe("");
  });
});
