import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { api } from "@/lib/api";

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
        throw new Error(await extractErrorMessage(error));
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
