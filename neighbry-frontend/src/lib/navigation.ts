import type { Persona } from "@/lib/persona";

export interface NavItem {
  label: string;
  href?: string; // ausente = módulo ainda não implementado (placeholder)
}

// Ordem de prioridade e conjunto por persona definidos em design.md
// (frontend-common-area-dashboard). Só "Espaços" tem rota funcional nesta
// change — os demais aparecem como placeholder até cada módulo nascer.
export const NAV_ITEMS_BY_PERSONA: Record<Persona, NavItem[]> = {
  admin: [
    { label: "Unidades" },
    { label: "Avisos" },
    { label: "Faturas" },
    { label: "Espaços", href: "/common-areas" },
    { label: "Reservas" },
  ],
  resident: [
    { label: "Minha Unidade" },
    { label: "Avisos" },
    { label: "Faturas" },
    { label: "Espaços", href: "/common-areas" },
    { label: "Reservas" },
  ],
  service_provider: [
    { label: "Avisos" },
    { label: "Espaços", href: "/common-areas" },
  ],
};
