// Resolução de tenant no frontend, espelhando o backend (ResolvesTenant):
// dev usa *.localhost, que o navegador já resolve sozinho para loopback.
// Produção fica fora de escopo (ver design.md, frontend-auth-onboarding).
const APEX_HOST = "localhost";

export function getTenantSlug(): string | null {
  const { hostname } = window.location;

  if (hostname === APEX_HOST) return null;
  if (!hostname.endsWith(`.${APEX_HOST}`)) return null;

  return hostname.slice(0, -(APEX_HOST.length + 1));
}

export function isGenericHost(): boolean {
  return getTenantSlug() === null;
}

export function tenantUrl(slug: string, path: string): string {
  const { protocol, port } = window.location;
  const portSuffix = port ? `:${port}` : "";

  return `${protocol}//${slug}.${APEX_HOST}${portSuffix}${path}`;
}

// Simétrico a tenantUrl: monta uma URL de volta pro host genérico (sem
// subdomínio). Usado quando o subdomínio atual não corresponde a nenhum
// Condominium — não dá pra usar o router do SPA (troca de origin), nem dá
// pra confiar em isGenericHost() do lado de destino porque quem está
// chamando ainda está no subdomínio inválido.
export function genericHostUrl(path: string): string {
  const { protocol, port } = window.location;
  const portSuffix = port ? `:${port}` : "";

  return `${protocol}//${APEX_HOST}${portSuffix}${path}`;
}
