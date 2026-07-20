import { describe, it, expect } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { render } from "@/test/utils";
import { server } from "@/test/server";
import { ResidentCommonAreaView } from "@/features/common-area/ResidentCommonAreaView";

const API = "http://localhost:3001";

describe("ResidentCommonAreaView", () => {
  it("shows an empty state when there are no common areas", async () => {
    server.use(http.get(`${API}/api/v1/common_areas`, () => HttpResponse.json({ data: [] })));

    render(<ResidentCommonAreaView />);

    await waitFor(() => {
      expect(screen.getByText(/nenhum espaço cadastrado ainda/i)).toBeInTheDocument();
    });
  });

  it("lists common areas as read-only cards, without admin actions", async () => {
    server.use(
      http.get(`${API}/api/v1/common_areas`, () =>
        HttpResponse.json({
          data: [
            {
              id: "ca-1",
              type: "common_area",
              attributes: {
                nome: "Salão de Festas",
                descricao: "Espaço para eventos",
                capacidade: 50,
                horario_funcionamento: "8h às 22h",
                regras_uso: "Proibido som alto",
                ativo: true,
              },
            },
          ],
        })
      )
    );

    render(<ResidentCommonAreaView />);

    await waitFor(() => {
      expect(screen.getByText("Salão de Festas")).toBeInTheDocument();
    });
    expect(screen.getByText(/capacidade: 50/i)).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /novo espaço/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /editar/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("switch")).not.toBeInTheDocument();
  });

  it("shows inactive common areas with their status visible", async () => {
    server.use(
      http.get(`${API}/api/v1/common_areas`, () =>
        HttpResponse.json({
          data: [
            {
              id: "ca-2",
              type: "common_area",
              attributes: {
                nome: "Quadra",
                descricao: null,
                capacidade: 10,
                horario_funcionamento: null,
                regras_uso: null,
                ativo: false,
              },
            },
          ],
        })
      )
    );

    render(<ResidentCommonAreaView />);

    await waitFor(() => {
      expect(screen.getByText("Quadra")).toBeInTheDocument();
    });
    expect(screen.getByText("Inativo")).toBeInTheDocument();
  });
});
