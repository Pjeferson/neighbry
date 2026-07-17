# frozen_string_literal: true

module Registry
  class Person < ApplicationRecord
    # "type" é nome reservado do Rails pra STI — desabilita esse
    # comportamento, a coluna aqui é só um enum comum.
    self.inheritance_column = nil

    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :user, optional: true

    enum :type, { resident: "resident", service_provider: "service_provider" }, validate: true

    validates :name, presence: true
    validates :cpf, presence: true,
      format: { with: /\A\d{11}\z/, message: "must have 11 digits" },
      uniqueness: { scope: :condominium_id }
    validate :cpf_must_be_valid

    private

    def cpf_must_be_valid
      return if cpf.blank? || cpf !~ /\A\d{11}\z/
      return if self.class.valid_cpf_checksum?(cpf)

      errors.add(:cpf, "is not a valid CPF")
    end

    class << self
      def valid_cpf_checksum?(cpf)
        digits = cpf.chars.map(&:to_i)
        return false if digits.uniq.length == 1

        first_check = check_digit(digits[0...9], 10)
        return false unless first_check == digits[9]

        second_check = check_digit(digits[0...10], 11)
        second_check == digits[10]
      end

      private

      def check_digit(digits, start_weight)
        sum = digits.each_with_index.sum { |d, i| d * (start_weight - i) }
        remainder = sum % 11
        remainder < 2 ? 0 : 11 - remainder
      end
    end
  end
end
