import { create } from "zustand";
import { persist } from "zustand/middleware";
import { clearToken } from "@/lib/api";

export type Role = "admin" | "manager" | "service_provider" | "resident";

interface User {
  id: string;
  email: string;
  name: string;
  role: Role;
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      isAuthenticated: !!localStorage.getItem("neighbry_token"),
      setUser: (user) => set({ user, isAuthenticated: true }),
      logout: () => {
        clearToken();
        set({ user: null, isAuthenticated: false });
      },
    }),
    {
      name: "neighbry_auth",
      partialize: (state) => ({ user: state.user, isAuthenticated: state.isAuthenticated }),
    }
  )
);
