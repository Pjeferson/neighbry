import { useState } from "react";
import { Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { tenantUrl } from "@/lib/tenant";
import { useFindCondominium } from "./useCondominium";

export function FindCondominiumPage() {
  const find = useFindCondominium();
  const [slug, setSlug] = useState("");
  const [notFound, setNotFound] = useState(false);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setNotFound(false);
    find.mutate(slug, {
      onSuccess: (result) => {
        if (result.exists) {
          window.location.href = tenantUrl(result.slug, "/login");
        } else {
          setNotFound(true);
        }
      },
    });
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <h1 className="text-2xl font-bold text-gray-900">Neighbry</h1>
          <p className="text-sm text-gray-500 mt-1">
            Informe o identificador do seu condomínio
          </p>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1">
              <Label htmlFor="condominium-slug">Identificador do condomínio</Label>
              <Input
                id="condominium-slug"
                required
                value={slug}
                onChange={(e) => {
                  setSlug(e.target.value);
                  setNotFound(false);
                }}
                placeholder="ex: acme"
              />
            </div>

            {notFound && (
              <p className="text-sm text-red-600">
                Não encontramos nenhum condomínio com esse identificador.
              </p>
            )}
            {find.isError && (
              <p className="text-sm text-red-600">
                Não foi possível fazer a busca agora. Tente novamente.
              </p>
            )}

            <Button type="submit" disabled={find.isPending} className="w-full">
              {find.isPending ? "Buscando..." : "Continuar"}
            </Button>
          </form>

          <p className="text-sm text-center text-gray-500 mt-6">
            Ainda não tem conta?{" "}
            <Link to="/register" className="text-blue-600 hover:underline">
              Cadastre seu condomínio
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
