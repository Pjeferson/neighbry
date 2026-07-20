import { describe, it, expect } from "vitest";
import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { AdminCommonAreaView } from "@/features/common-area/AdminCommonAreaView";

const API = "http://localhost:3001";

function commonAreaResource(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: "ca-1",
    type: "common_area",
    attributes: {
      nome: "Salão de Festas",
      descricao: "Espaço para eventos",
      capacidade: 50,
      horario_funcionamento: "8h às 22h",
      regras_uso: "Proibido som alto",
      ativo: true,
      ...overrides,
    },
  };
}

describe("AdminCommonAreaView", () => {
  it("shows an empty state when there are no common areas", async () => {
    server.use(http.get(`${API}/api/v1/common_areas`, () => HttpResponse.json({ data: [] })));

    render(<AdminCommonAreaView />);

    await waitFor(() => {
      expect(screen.getByText(/nenhum espaço cadastrado ainda/i)).toBeInTheDocument();
    });
  });

  it("lists common areas in a table", async () => {
    server.use(
      http.get(`${API}/api/v1/common_areas`, () => HttpResponse.json({ data: [commonAreaResource()] }))
    );

    render(<AdminCommonAreaView />);

    await waitFor(() => {
      expect(screen.getByText("Salão de Festas")).toBeInTheDocument();
    });
    expect(screen.getByText("50")).toBeInTheDocument();
    expect(screen.getByText("Ativo")).toBeInTheDocument();
  });

  it("creates a new common area through the dialog", async () => {
    server.use(
      http.get(`${API}/api/v1/common_areas`, () => HttpResponse.json({ data: [] })),
      http.post(`${API}/api/v1/common_areas`, () =>
        HttpResponse.json({ data: commonAreaResource({ nome: "Piscina", capacidade: 30 }) }, { status: 201 })
      )
    );
    const user = userEvent.setup();
    render(<AdminCommonAreaView />);

    await waitFor(() => expect(screen.getByText(/nenhum espaço/i)).toBeInTheDocument());

    await user.click(screen.getByRole("button", { name: /novo espaço/i }));
    await user.type(screen.getByLabelText(/^nome$/i), "Piscina");
    await user.type(screen.getByLabelText(/capacidade/i), "30");
    await user.click(screen.getByRole("button", { name: /salvar/i }));

    await waitFor(() => {
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    });
  });

  it("toggles ativo inline without opening the dialog", async () => {
    let ativo = true;
    server.use(
      http.get(`${API}/api/v1/common_areas`, () =>
        HttpResponse.json({ data: [commonAreaResource({ ativo })] })
      ),
      http.patch(`${API}/api/v1/common_areas/ca-1`, () => {
        ativo = false;
        return HttpResponse.json({ data: commonAreaResource({ ativo }) });
      })
    );
    const user = userEvent.setup();
    render(<AdminCommonAreaView />);

    await waitFor(() => expect(screen.getByText("Salão de Festas")).toBeInTheDocument());

    const row = screen.getByText("Salão de Festas").closest("tr")!;
    await user.click(within(row).getByRole("switch"));

    await waitFor(() => {
      expect(within(row).getByText("Inativo")).toBeInTheDocument();
    });
  });
});
