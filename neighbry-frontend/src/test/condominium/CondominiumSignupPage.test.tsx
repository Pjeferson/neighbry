import { describe, it, expect, beforeEach } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { CondominiumSignupPage } from "@/features/condominium/CondominiumSignupPage";

const API = "http://localhost:3001";

beforeEach(() => {
  Object.defineProperty(window, "location", {
    writable: true,
    value: { protocol: "http:", hostname: "localhost", port: "5173", href: "" },
  });
});

describe("CondominiumSignupPage", () => {
  it("renders all fields", () => {
    render(<CondominiumSignupPage />);
    expect(screen.getByLabelText(/nome do condomínio/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/identificador/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/seu nome/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/seu email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/senha/i)).toBeInTheDocument();
  });

  it("auto-suggests the slug from the condominium name until manually edited", async () => {
    const user = userEvent.setup();
    render(<CondominiumSignupPage />);

    const nameInput = screen.getByLabelText(/nome do condomínio/i);
    const slugInput = screen.getByLabelText(/identificador/i) as HTMLInputElement;

    await user.type(nameInput, "Condomínio Açaí");
    expect(slugInput.value).toBe("condominio-acai");

    await user.clear(slugInput);
    await user.type(slugInput, "meu-slug-custom");
    expect(slugInput.value).toBe("meu-slug-custom");

    // Depois de editado manualmente, não volta a re-sincronizar com o nome
    await user.type(nameInput, " Novo");
    expect(slugInput.value).toBe("meu-slug-custom");
  });

  it("redirects to the tenant subdomain login after successful onboarding", async () => {
    server.use(
      http.post(`${API}/api/v1/condominiums`, () =>
        HttpResponse.json(
          { condominium: { id: "c-1", name: "Acme", slug: "acme" }, admin: { id: "u-1", email: "admin@acme.com" } },
          { status: 201 }
        )
      )
    );
    const user = userEvent.setup();
    render(<CondominiumSignupPage />);

    await user.type(screen.getByLabelText(/nome do condomínio/i), "Acme");
    await user.clear(screen.getByLabelText(/identificador/i));
    await user.type(screen.getByLabelText(/identificador/i), "acme");
    await user.type(screen.getByLabelText(/seu nome/i), "Admin");
    await user.type(screen.getByLabelText(/seu email/i), "admin@acme.com");
    await user.type(screen.getByLabelText(/senha/i), "password123");
    await user.click(screen.getByRole("button", { name: /criar condomínio/i }));

    await waitFor(() => {
      expect(window.location.href).toBe("http://acme.localhost:5173/login");
    });
  });

  it("shows the backend validation error (e.g. duplicate slug)", async () => {
    server.use(
      http.post(`${API}/api/v1/condominiums`, () =>
        HttpResponse.json({ errors: ["Slug has already been taken"] }, { status: 422 })
      )
    );
    const user = userEvent.setup();
    render(<CondominiumSignupPage />);

    await user.type(screen.getByLabelText(/nome do condomínio/i), "Acme");
    await user.type(screen.getByLabelText(/seu nome/i), "Admin");
    await user.type(screen.getByLabelText(/seu email/i), "admin@acme.com");
    await user.type(screen.getByLabelText(/senha/i), "password123");
    await user.click(screen.getByRole("button", { name: /criar condomínio/i }));

    await waitFor(() => {
      expect(screen.getByText(/slug has already been taken/i)).toBeInTheDocument();
    });
  });
});
