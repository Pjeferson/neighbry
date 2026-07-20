import { describe, it, expect } from "vitest";
import { getPersona } from "@/lib/persona";

describe("getPersona", () => {
  it("maps admin to the admin persona", () => {
    expect(getPersona("admin")).toBe("admin");
  });

  it("maps manager to the admin persona", () => {
    expect(getPersona("manager")).toBe("admin");
  });

  it("maps service_provider to the service_provider persona", () => {
    expect(getPersona("service_provider")).toBe("service_provider");
  });

  it("maps resident to the resident persona", () => {
    expect(getPersona("resident")).toBe("resident");
  });

  it("falls back to the resident persona for a stale/unknown role value", () => {
    // Simula sessão persistida no localStorage com um valor de role que
    // não existe mais (ex: "doorman", antes do rename) ou nenhum valor —
    // TypeScript garante o tipo em compile time, não em runtime.
    expect(getPersona("doorman" as never)).toBe("resident");
    expect(getPersona(undefined as never)).toBe("resident");
  });
});
