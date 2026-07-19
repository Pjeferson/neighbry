import { useState } from "react";
import { Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { slugify } from "@/lib/slugify";
import { tenantUrl } from "@/lib/tenant";
import { useOnboardCondominium } from "./useCondominium";

export function CondominiumSignupPage() {
  const onboard = useOnboardCondominium();
  const [condominiumName, setCondominiumName] = useState("");
  const [condominiumSlug, setCondominiumSlug] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [adminName, setAdminName] = useState("");
  const [adminEmail, setAdminEmail] = useState("");
  const [adminPassword, setAdminPassword] = useState("");

  function handleNameChange(value: string) {
    setCondominiumName(value);
    if (!slugTouched) {
      setCondominiumSlug(slugify(value));
    }
  }

  function handleSlugChange(value: string) {
    setSlugTouched(true);
    setCondominiumSlug(slugify(value));
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    onboard.mutate(
      { condominiumName, condominiumSlug, adminName, adminEmail, adminPassword },
      {
        onSuccess: (data) => {
          window.location.href = tenantUrl(data.condominium.slug, "/login");
        },
      }
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <h1 className="text-2xl font-bold text-gray-900">Neighbry</h1>
          <p className="text-sm text-gray-500 mt-1">Cadastre seu condomínio</p>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1">
              <Label htmlFor="condominium-name">Nome do condomínio</Label>
              <Input
                id="condominium-name"
                required
                value={condominiumName}
                onChange={(e) => handleNameChange(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label htmlFor="condominium-slug">Identificador (subdomínio)</Label>
              <Input
                id="condominium-slug"
                required
                value={condominiumSlug}
                onChange={(e) => handleSlugChange(e.target.value)}
              />
              {condominiumSlug && (
                <p className="text-xs text-gray-500">
                  Seu endereço: {condominiumSlug}.neighbry.com
                </p>
              )}
            </div>

            <div className="space-y-1">
              <Label htmlFor="admin-name">Seu nome</Label>
              <Input
                id="admin-name"
                required
                value={adminName}
                onChange={(e) => setAdminName(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label htmlFor="admin-email">Seu email</Label>
              <Input
                id="admin-email"
                type="email"
                required
                value={adminEmail}
                onChange={(e) => setAdminEmail(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label htmlFor="admin-password">Senha</Label>
              <Input
                id="admin-password"
                type="password"
                required
                minLength={8}
                value={adminPassword}
                onChange={(e) => setAdminPassword(e.target.value)}
              />
            </div>

            {onboard.error && (
              <p className="text-sm text-red-600">{onboard.error.message}</p>
            )}

            <Button type="submit" disabled={onboard.isPending} className="w-full">
              {onboard.isPending ? "Criando condomínio..." : "Criar condomínio"}
            </Button>
          </form>

          <p className="text-sm text-center text-gray-500 mt-6">
            Já tem uma conta?{" "}
            <Link to="/find" className="text-blue-600 hover:underline">
              Acesse pelo identificador do seu condomínio
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
