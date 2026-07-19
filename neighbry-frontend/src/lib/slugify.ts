// Remove marcas diacríticas (acentos, til, cedilha) após separá-las da letra
// base via normalize("NFD") — ex: "ç" -> "c" + marca de cedilha isolada.
export function slugify(value: string): string {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// Diferente de slugify(): não reconstrói o valor (não troca espaços por
// hífen nem remove caracteres) — só normaliza caixa/espaço em branco de um
// slug que o usuário já deveria estar digitando corretamente, pra não
// falhar a checagem de existência por diferença de maiúscula/minúscula
// (Postgres compara slug como string exata).
export function normalizeSlug(value: string): string {
  return value.trim().toLowerCase();
}
