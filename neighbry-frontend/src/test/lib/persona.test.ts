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
});
