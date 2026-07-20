import { useNavigate } from "@tanstack/react-router";
import { IconLogout } from "@tabler/icons-react";
import { useAuthStore } from "@/store/authStore";
import { getPersona } from "@/lib/persona";
import { NAV_ITEMS_BY_PERSONA } from "@/lib/navigation";

export function Sidebar() {
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate({ to: "/login" });
  }

  const items = user ? NAV_ITEMS_BY_PERSONA[getPersona(user.role)] : [];

  return (
    <aside className="w-[220px] shrink-0 bg-[#F9FAFB] border-r border-[#E5E7EB] py-5 flex flex-col gap-0.5">
      <div className="px-4 pb-5 border-b border-[#E5E7EB] mb-2">
        <span className="text-lg font-bold text-gray-900">Neighbry</span>
      </div>

      <nav className="flex flex-col gap-0.5">
        {items.map((item) =>
          item.href ? (
            /* TODO(TASK-7): trocar por <Link> quando as rotas das demais
               abas existirem — hoje só "Espaços" tem rota de verdade. */
            <a
              key={item.label}
              href={item.href}
              className="flex w-full items-center px-4 py-[7px] text-[13px] text-[#374151] transition-colors hover:bg-white hover:text-[#111827]"
            >
              {item.label}
            </a>
          ) : (
            <span
              key={item.label}
              className="flex w-full items-center justify-between px-4 py-[7px] text-[13px] text-[#9CA3AF] cursor-not-allowed"
              title="Em breve"
            >
              {item.label}
              <span className="text-[11px]">em breve</span>
            </span>
          )
        )}
      </nav>

      <div className="mt-auto border-t border-[#E5E7EB] pt-2">
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-2.5 px-4 py-[7px] text-[13px] text-[#6B7280] transition-colors hover:bg-white hover:text-[#111827] cursor-pointer"
        >
          <span className="text-[16px] shrink-0"><IconLogout size={16} /></span>
          <span>Sair</span>
        </button>
      </div>
    </aside>
  );
}
