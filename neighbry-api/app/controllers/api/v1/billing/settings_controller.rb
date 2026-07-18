# frozen_string_literal: true

module Api
  module V1
    module Billing
      class SettingsController < ApplicationController
        include ResolvesTenant

        before_action :authenticate_user!

        def update
          result = ::Billing::SetBillingDay.new.call(
            actor: current_user,
            condominium: Tenancy::Current.condominium,
            dia_cobranca: params[:dia_cobranca],
            dias_para_vencimento: params[:dias_para_vencimento]
          )

          if result.success?
            render json: ::Billing::CondominiumBillingSettingSerializer.new(result.value!).serializable_hash
          else
            render json: { error: error_payload(result.failure) }, status: :unprocessable_content
          end
        end

        private

        def error_payload(failure)
          failure.respond_to?(:full_messages) ? failure.full_messages : failure
        end
      end
    end
  end
end
