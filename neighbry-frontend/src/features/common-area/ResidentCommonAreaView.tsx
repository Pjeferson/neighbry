import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardContent, CardTitle } from "@/components/ui/card";
import { useCommonAreas } from "./useCommonAreas";

export function ResidentCommonAreaView() {
  const { data: commonAreas, isLoading } = useCommonAreas();

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-gray-900 mb-6">Espaços comuns</h1>

      {isLoading && <p className="text-sm text-gray-500">Carregando...</p>}

      {!isLoading && commonAreas?.length === 0 && (
        <p className="text-sm text-gray-500">Nenhum espaço cadastrado ainda.</p>
      )}

      {!isLoading && commonAreas && commonAreas.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {commonAreas.map((commonArea) => (
            <Card key={commonArea.id}>
              <CardHeader>
                <div className="flex items-start justify-between gap-2">
                  <CardTitle className="text-base">{commonArea.nome}</CardTitle>
                  <Badge variant={commonArea.ativo ? "default" : "secondary"}>
                    {commonArea.ativo ? "Ativo" : "Inativo"}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-2 text-sm text-gray-600">
                {commonArea.descricao && <p>{commonArea.descricao}</p>}
                <p>Capacidade: {commonArea.capacidade}</p>
                {commonArea.horario_funcionamento && (
                  <p>Horário: {commonArea.horario_funcionamento}</p>
                )}
                {commonArea.regras_uso && (
                  <p className="text-gray-500">{commonArea.regras_uso}</p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
