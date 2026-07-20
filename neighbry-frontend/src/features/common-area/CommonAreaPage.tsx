import { useAuthStore } from "@/store/authStore";
import { getPersona } from "@/lib/persona";
import { AdminCommonAreaView } from "./AdminCommonAreaView";
import { ResidentCommonAreaView } from "./ResidentCommonAreaView";

export function CommonAreaPage() {
  const user = useAuthStore((s) => s.user);
  const persona = user ? getPersona(user.role) : null;

  if (persona === "admin") return <AdminCommonAreaView />;

  // "resident" e "service_provider" compartilham a mesma visão de catálogo
  // somente-leitura — ver design.md (frontend-common-area-dashboard).
  return <ResidentCommonAreaView />;
}
