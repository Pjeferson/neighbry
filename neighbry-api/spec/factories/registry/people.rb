# frozen_string_literal: true

FactoryBot.define do
  factory :person, class: "Registry::Person" do
    association :condominium
    sequence(:name) { |n| "Pessoa #{n}" }
    type { "resident" }

    sequence(:cpf) do |n|
      base = format("%09d", n)
      digits = base.chars.map(&:to_i)

      d1_sum = digits.each_with_index.sum { |d, i| d * (10 - i) }
      d1 = (d1_sum % 11) < 2 ? 0 : 11 - (d1_sum % 11)

      d2_sum = (digits + [d1]).each_with_index.sum { |d, i| d * (11 - i) }
      d2 = (d2_sum % 11) < 2 ? 0 : 11 - (d2_sum % 11)

      "#{base}#{d1}#{d2}"
    end
  end
end
