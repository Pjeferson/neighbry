import { describe, it, expect, beforeEach, vi } from "vitest";
import { http, HttpResponse } from "msw";
import { server } from "@/test/server";

function stubLocation(overrides: Partial<Location>) {
  Object.defineProperty(window, "location", {
    writable: true,
    value: { protocol: "http:", hostname: "localhost", port: "5173", href: "", ...overrides },
  });
}

describe("api base URL", () => {
  beforeEach(() => {
    vi.resetModules();
    vi.unstubAllEnvs();
  });

  it("derives the base from the current hostname, swapping only the port", async () => {
    stubLocation({ hostname: "acme.localhost" });

    server.use(
      http.get("http://acme.localhost:3001/api/v1/probe", () => HttpResponse.json({ ok: true }))
    );

    const { api } = await import("@/lib/api");
    const response = await api.get("api/v1/probe");

    expect(response.status).toBe(200);
  });

  it("works the same way on the generic host (no subdomain)", async () => {
    stubLocation({ hostname: "localhost" });

    server.use(
      http.get("http://localhost:3001/api/v1/probe", () => HttpResponse.json({ ok: true }))
    );

    const { api } = await import("@/lib/api");
    const response = await api.get("api/v1/probe");

    expect(response.status).toBe(200);
  });

  it("VITE_API_URL overrides the derived base entirely", async () => {
    stubLocation({ hostname: "acme.localhost" });
    vi.stubEnv("VITE_API_URL", "http://api.example.com");

    server.use(
      http.get("http://api.example.com/api/v1/probe", () => HttpResponse.json({ ok: true }))
    );

    const { api } = await import("@/lib/api");
    const response = await api.get("api/v1/probe");

    expect(response.status).toBe(200);
  });
});
