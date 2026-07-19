import ky from "ky";

// A API resolve o tenant pelo Host da requisição (subdomínio) — e não dá
// pra sobrescrever o header Host manualmente em fetch/XHR do navegador.
// Por isso a base da API é derivada do hostname atual do frontend (que já
// carrega o subdomínio certo), trocando só a porta. Funciona igual em
// localhost:5173→localhost:3001 e acme.localhost:5173→acme.localhost:3001,
// porque *.localhost já resolve sozinho no navegador. VITE_API_URL
// continua como escape hatch total (ex: produção, onde essa heurística
// não se aplica). Ver design.md (frontend-auth-onboarding).
const API_BASE =
  import.meta.env.VITE_API_URL ??
  `${window.location.protocol}//${window.location.hostname}:${import.meta.env.VITE_API_PORT ?? "3001"}`;

function getToken(): string | null {
  return localStorage.getItem("neighbry_token");
}

export function setToken(token: string): void {
  localStorage.setItem("neighbry_token", token);
}

export function clearToken(): void {
  localStorage.removeItem("neighbry_token");
}

export const api = ky.create({
  prefixUrl: API_BASE,
  hooks: {
    beforeRequest: [
      (request) => {
        const token = getToken();
        if (token) {
          request.headers.set("Authorization", `Bearer ${token}`);
        }
      },
    ],
    afterResponse: [
      async (request, _options, response) => {
        if (response.status === 401 && !request.url.includes("/auth/")) {
          clearToken();
          window.location.href = "/login";
        }
        return response;
      },
    ],
  },
});
