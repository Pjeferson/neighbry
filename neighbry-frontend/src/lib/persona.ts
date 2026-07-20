import type { Role } from "@/store/authStore";

// Persona de UI — várias identidades de backend (role) podem cair na
// mesma persona. `admin` e `manager` compartilham a persona "admin" nesta
// fase do produto (mesmas telas), mesmo o backend distinguindo os dois em
// alguns pontos (ex: painel de confirmação de Aviso é admin-only — ver
// design.md de frontend-common-area-dashboard). Não inferir de `role` cru
// em componentes — sempre passar por getPersona, pra manter essa regra
// num único lugar.
export type Persona = "admin" | "service_provider" | "resident";

export function getPersona(role: Role): Persona {
  switch (role) {
    case "admin":
    case "manager":
      return "admin";
    case "service_provider":
      return "service_provider";
    case "resident":
      return "resident";
  }
}
