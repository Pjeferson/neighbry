import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { api } from "@/lib/api";
import { unwrapCollection, unwrapResource } from "@/lib/jsonapi";

export interface CommonArea {
  id: string;
  nome: string;
  descricao: string | null;
  capacidade: number;
  horario_funcionamento: string | null;
  regras_uso: string | null;
  ativo: boolean;
}

type CommonAreaAttributes = Omit<CommonArea, "id">;

const QUERY_KEY = ["common-areas"];

export function useCommonAreas() {
  return useQuery({
    queryKey: QUERY_KEY,
    queryFn: async () => {
      const response = await api.get("api/v1/common_areas");
      return unwrapCollection<CommonAreaAttributes>(await response.json());
    },
  });
}

export interface CommonAreaInput {
  nome: string;
  descricao?: string;
  capacidade: number;
  horario_funcionamento?: string;
  regras_uso?: string;
}

export function useCreateCommonArea() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CommonAreaInput) => {
      try {
        const response = await api.post("api/v1/common_areas", { json: input });
        return unwrapResource<CommonAreaAttributes>(await response.json());
      } catch (error) {
        throw new Error(await extractErrorMessage(error), { cause: error });
      }
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
  });
}

export interface CommonAreaUpdateInput extends Partial<CommonAreaInput> {
  id: string;
  ativo?: boolean;
}

export function useUpdateCommonArea() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: CommonAreaUpdateInput) => {
      try {
        const response = await api.patch(`api/v1/common_areas/${id}`, { json: input });
        return unwrapResource<CommonAreaAttributes>(await response.json());
      } catch (error) {
        throw new Error(await extractErrorMessage(error), { cause: error });
      }
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
  });
}

async function extractErrorMessage(error: unknown): Promise<string> {
  if (error instanceof HTTPError) {
    const body = await error.response.json<{ error?: string[] | string }>().catch(() => null);
    if (Array.isArray(body?.error)) return body.error.join(", ");
  }
  return "Não foi possível salvar o espaço. Verifique os dados.";
}
