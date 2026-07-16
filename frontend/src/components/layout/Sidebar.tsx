import { useNavigate } from "@tanstack/react-router";
import { IconLogout } from "@tabler/icons-react";
import { useAuthStore } from "@/store/authStore";

export function Sidebar() {
  const logout = useAuthStore((s) => s.logout);
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate({ to: "/login" });
  }

  return (
    <aside className="w-[220px] shrink-0 bg-[#F9FAFB] border-r border-[#E5E7EB] py-5 flex flex-col gap-0.5">
      <div className="px-4 pb-5 border-b border-[#E5E7EB] mb-2">
        <span className="text-lg font-bold text-gray-900">Neighbry</span>
      </div>

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
