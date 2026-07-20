import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from "@/components/ui/table";
import { useCommonAreas, useUpdateCommonArea, type CommonArea } from "./useCommonAreas";
import { CommonAreaFormDialog } from "./CommonAreaFormDialog";

export function AdminCommonAreaView() {
  const { data: commonAreas, isLoading } = useCommonAreas();
  const updateCommonArea = useUpdateCommonArea();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<CommonArea | undefined>(undefined);

  function openCreate() {
    setEditing(undefined);
    setDialogOpen(true);
  }

  function openEdit(commonArea: CommonArea) {
    setEditing(commonArea);
    setDialogOpen(true);
  }

  function toggleAtivo(commonArea: CommonArea) {
    updateCommonArea.mutate({ id: commonArea.id, ativo: !commonArea.ativo });
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-xl font-semibold text-gray-900">Espaços comuns</h1>
        <Button onClick={openCreate}>Novo espaço</Button>
      </div>

      {isLoading && <p className="text-sm text-gray-500">Carregando...</p>}

      {!isLoading && commonAreas?.length === 0 && (
        <p className="text-sm text-gray-500">Nenhum espaço cadastrado ainda.</p>
      )}

      {!isLoading && commonAreas && commonAreas.length > 0 && (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Nome</TableHead>
              <TableHead>Capacidade</TableHead>
              <TableHead>Horário</TableHead>
              <TableHead>Status</TableHead>
              <TableHead />
            </TableRow>
          </TableHeader>
          <TableBody>
            {commonAreas.map((commonArea) => (
              <TableRow key={commonArea.id}>
                <TableCell>{commonArea.nome}</TableCell>
                <TableCell>{commonArea.capacidade}</TableCell>
                <TableCell>{commonArea.horario_funcionamento ?? "—"}</TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    <Switch
                      checked={commonArea.ativo}
                      onCheckedChange={() => toggleAtivo(commonArea)}
                      aria-label={`Ativo: ${commonArea.nome}`}
                    />
                    <Badge variant={commonArea.ativo ? "default" : "secondary"}>
                      {commonArea.ativo ? "Ativo" : "Inativo"}
                    </Badge>
                  </div>
                </TableCell>
                <TableCell>
                  <Button variant="outline" size="sm" onClick={() => openEdit(commonArea)}>
                    Editar
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}

      <CommonAreaFormDialog open={dialogOpen} onOpenChange={setDialogOpen} commonArea={editing} />
    </div>
  );
}
