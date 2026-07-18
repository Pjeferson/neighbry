# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Cobranca, type: :model do
  subject(:cobranca) { build(:cobranca) }

  it { is_expected.to belong_to(:fatura) }
  it { is_expected.to belong_to(:taxa) }
  it { is_expected.to validate_numericality_of(:valor).is_greater_than(0) }
end
