import { createFileRoute, redirect } from "@tanstack/react-router";

// Redireciona pra primeira tela funcional. Enquanto só "Espaços" existir,
// esse destino é fixo — quando outros módulos ganharem tela, isso pode
// virar uma escolha por persona.
export const Route = createFileRoute("/_authenticated/")({
  beforeLoad: () => {
    throw redirect({ to: "/common-areas" });
  },
});
