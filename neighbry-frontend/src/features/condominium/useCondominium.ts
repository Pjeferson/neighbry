import { useMutation, useQuery } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { api } from "@/lib/api";
import { normalizeSlug } from "@/lib/slugify";

interface OnboardCondominiumInput {
  condominiumName: string;
  condominiumSlug: string;
  adminName: string;
  adminEmail: string;
  adminPassword: string;
}

interface OnboardCondominiumResponse {
  condominium: { id: string; name: string; slug: string };
  admin: { id: string; email: string };
}

export function useOnboardCondominium() {
  return useMutation({
    mutationFn: async (input: OnboardCondominiumInput) => {
      try {
        const response = await api.post("api/v1/condominiums", {
          json: {
            condominium_name: input.condominiumName,
            condominium_slug: input.condominiumSlug,
            admin_name: input.adminName,
            admin_email: input.adminEmail,
            admin_password: input.adminPassword,
          },
        });
        return await response.json<OnboardCondominiumResponse>();
      } catch (error) {
        throw new Error(await extractErrorMessage(error), { cause: error });
      }
    },
  });
}

async function extractErrorMessage(error: unknown): Promise<string> {
  if (error instanceof HTTPError) {
    const body = await error.response.json<{ errors?: string[] }>().catch(() => null);
    if (body?.errors?.length) return body.errors.join(", ");
  }
  return "Não foi possível criar o condomínio. Verifique os dados.";
}

type CondominiumLookupResult =
  | { slug: string; exists: true; name: string }
  | { slug: string; exists: false };

export function useFindCondominium() {
  return useMutation({
    mutationFn: async (rawSlug: string): Promise<CondominiumLookupResult> => {
      const slug = normalizeSlug(rawSlug);

      try {
        const response = await api.get(`api/v1/condominiums/${slug}`);
        const body = await response.json<{ exists: true; name: string }>();
        return { slug, ...body };
      } catch (error) {
        if (error instanceof HTTPError && error.response.status === 404) {
          return { slug, exists: false };
        }
        throw error;
      }
    },
  });
}

// Usado pela tela de login (dentro do subdomínio do tenant) para exibir o
// nome do Condominium e detectar de forma amigável um subdomínio que não
// corresponde a nenhum Condominium — dispara sozinho ao montar, diferente
// de useFindCondominium (acionado pelo usuário no host genérico).
export function useCondominiumInfo(slug: string | null) {
  return useQuery({
    queryKey: ["condominium", slug],
    queryFn: async () => {
      const response = await api.get(`api/v1/condominiums/${slug}`);
      return response.json<{ exists: true; name: string }>();
    },
    enabled: slug !== null,
    retry: false,
  });
}
