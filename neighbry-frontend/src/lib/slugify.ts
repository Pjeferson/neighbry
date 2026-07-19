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
