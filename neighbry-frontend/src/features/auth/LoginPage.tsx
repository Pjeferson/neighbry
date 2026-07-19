import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { getTenantSlug, genericHostUrl } from "@/lib/tenant";
import { useCondominiumInfo } from "@/features/condominium/useCondominium";
import { useAuth } from "./useAuth";

export function LoginPage() {
  const { signIn } = useAuth();
  const slug = getTenantSlug();
  const condominium = useCondominiumInfo(slug);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    signIn.mutate({ email, password });
  }

  if (condominium.isError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <Card className="w-full max-w-sm">
          <CardContent className="pt-6 text-center space-y-2">
            <h1 className="text-lg font-semibold text-gray-900">Condomínio não encontrado</h1>
            <p className="text-sm text-gray-500">
              Não existe nenhum condomínio nesse endereço.
            </p>
            {/* Navegação de página inteira, propositalmente: estamos num
                subdomínio que não corresponde a nenhum Condominium, então
                não dá pra usar o router do SPA (troca de origin) nem
                confiar em isGenericHost() do lado de destino. */}
            <a href={genericHostUrl("/find")} className="text-sm text-blue-600 hover:underline">
              Localizar meu condomínio
            </a>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <h1 className="text-2xl font-bold text-gray-900">Neighbry</h1>
          <p className="text-sm text-gray-500 mt-1">
            {condominium.data ? `Entrando em ${condominium.data.name}` : "Acesse sua conta"}
          </p>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label htmlFor="password">Senha</Label>
              <Input
                id="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            {signIn.error && (
              <p className="text-sm text-red-600">{signIn.error.message}</p>
            )}

            <Button type="submit" disabled={signIn.isPending} className="w-full">
              {signIn.isPending ? "Entrando..." : "Entrar"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
