# frozen_string_literal: true

FactoryBot.define do
  factory :fatura, class: "Billing::Fatura" do
    # Sempre criado (não apenas build) porque Unit só ganha condominium_id
    # em before_validation — precisamos de uma Unit persistida para
    # referenciar um Condominium real no callback abaixo, independente da
    # estratégia (build/create) usada pelo chamador.
    unit { create(:unit) }
    condominium { unit.condominium }
    ciclo_cobranca { association :ciclo_cobranca, condominium: condominium }
    data_vencimento { Date.current + 10.days }

    # Fatura não é válida sem ao menos uma Cobrança (invariante do domínio),
    # então o factory sempre garante uma, a menos que o chamador já tenha
    # adicionado uma explicitamente.
    after(:build) do |fatura|
      next if fatura.cobrancas.any?

      taxa = FactoryBot.create(:taxa, condominium: fatura.condominium)
      fatura.cobrancas << FactoryBot.build(:cobranca, taxa: taxa, condominium: fatura.condominium, fatura: fatura)
    end
  end
end
