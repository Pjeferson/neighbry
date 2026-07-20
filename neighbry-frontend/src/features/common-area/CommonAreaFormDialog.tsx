import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  useCreateCommonArea,
  useUpdateCommonArea,
  type CommonArea,
} from "./useCommonAreas";

interface CommonAreaFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  commonArea?: CommonArea;
}

export function CommonAreaFormDialog({ open, onOpenChange, commonArea }: CommonAreaFormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        {/* key força remount ao trocar de "criar" pra "editar X" (ou entre
            X e Y) — reseta os campos sem precisar de useEffect+setState
            (efeito colateral síncrono, gera render em cascata). */}
        <CommonAreaForm
          key={commonArea?.id ?? "new"}
          commonArea={commonArea}
          onSaved={() => onOpenChange(false)}
        />
      </DialogContent>
    </Dialog>
  );
}

interface CommonAreaFormProps {
  commonArea?: CommonArea;
  onSaved: () => void;
}

function CommonAreaForm({ commonArea, onSaved }: CommonAreaFormProps) {
  const isEditing = !!commonArea;
  const create = useCreateCommonArea();
  const update = useUpdateCommonArea();
  const mutation = isEditing ? update : create;

  const [nome, setNome] = useState(commonArea?.nome ?? "");
  const [descricao, setDescricao] = useState(commonArea?.descricao ?? "");
  const [capacidade, setCapacidade] = useState(commonArea ? String(commonArea.capacidade) : "");
  const [horarioFuncionamento, setHorarioFuncionamento] = useState(commonArea?.horario_funcionamento ?? "");
  const [regrasUso, setRegrasUso] = useState(commonArea?.regras_uso ?? "");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const input = {
      nome,
      descricao: descricao || undefined,
      capacidade: Number(capacidade),
      horario_funcionamento: horarioFuncionamento || undefined,
      regras_uso: regrasUso || undefined,
    };

    if (isEditing) {
      update.mutate({ id: commonArea.id, ...input }, { onSuccess: onSaved });
    } else {
      create.mutate(input, { onSuccess: onSaved });
    }
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>{isEditing ? "Editar espaço" : "Novo espaço"}</DialogTitle>
      </DialogHeader>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-1">
          <Label htmlFor="ca-nome">Nome</Label>
          <Input id="ca-nome" required value={nome} onChange={(e) => setNome(e.target.value)} />
        </div>

        <div className="space-y-1">
          <Label htmlFor="ca-descricao">Descrição</Label>
          <Textarea id="ca-descricao" value={descricao} onChange={(e) => setDescricao(e.target.value)} />
        </div>

        <div className="space-y-1">
          <Label htmlFor="ca-capacidade">Capacidade</Label>
          <Input
            id="ca-capacidade"
            type="number"
            min={1}
            required
            value={capacidade}
            onChange={(e) => setCapacidade(e.target.value)}
          />
        </div>

        <div className="space-y-1">
          <Label htmlFor="ca-horario">Horário de funcionamento</Label>
          <Input
            id="ca-horario"
            value={horarioFuncionamento}
            onChange={(e) => setHorarioFuncionamento(e.target.value)}
            placeholder="ex: 8h às 22h"
          />
        </div>

        <div className="space-y-1">
          <Label htmlFor="ca-regras">Regras de uso</Label>
          <Textarea id="ca-regras" value={regrasUso} onChange={(e) => setRegrasUso(e.target.value)} />
        </div>

        {mutation.error && <p className="text-sm text-red-600">{mutation.error.message}</p>}

        <DialogFooter>
          <Button type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? "Salvando..." : "Salvar"}
          </Button>
        </DialogFooter>
      </form>
    </>
  );
}
