import { useMutation } from "@tanstack/react-query";
import { useRouter } from "@tanstack/react-router";
import { HTTPError } from "ky";
import { api, setToken } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";

interface User {
  id: string;
  email: string;
  name: string;
}

interface AuthResponse {
  message: string;
  user: User;
}

const LOGIN_ERROR_MESSAGES: Record<string, string> = {
  condominium_not_found: "Condomínio não encontrado neste endereço.",
  invalid_credentials: "Email ou senha inválidos.",
  no_active_membership_for_tenant: "Você não tem acesso a este condomínio.",
};

export function useAuth() {
  const { setUser, logout: logoutStore } = useAuthStore();
  const router = useRouter();

  const signIn = useMutation({
    mutationFn: async (data: { email: string; password: string }) => {
      try {
        const response = await api.post("api/v1/auth/sign_in", { json: { user: data } });
        const token = response.headers.get("Authorization")?.replace("Bearer ", "");
        const body: AuthResponse = await response.json();
        return { token, user: body.user };
      } catch (error) {
        throw new Error(await extractLoginErrorMessage(error));
      }
    },
    onSuccess: ({ token, user }) => {
      if (token) setToken(token);
      setUser(user);
      router.navigate({ to: "/" });
    },
  });

  const signOut = useMutation({
    mutationFn: () => api.delete("api/v1/auth/sign_out").then(() => undefined),
    onSettled: () => {
      logoutStore();
      router.navigate({ to: "/login" });
    },
  });

  return { signIn, signOut };
}

async function extractLoginErrorMessage(error: unknown): Promise<string> {
  if (error instanceof HTTPError) {
    const body = await error.response.json<{ error?: string }>().catch(() => null);
    if (body?.error && body.error in LOGIN_ERROR_MESSAGES) {
      return LOGIN_ERROR_MESSAGES[body.error];
    }
  }
  return "Não foi possível entrar. Tente novamente.";
}
