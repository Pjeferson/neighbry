# frozen_string_literal: true

module Api
  module V1
    class InvitationsController < ApplicationController
      include ResolvesTenant
      skip_before_action :resolve_tenant!, only: [:accept]

      before_action :authenticate_user!, only: [:create]

      def create
        authorize Tenancy::Membership.new(condominium: Tenancy::Current.condominium)

        result = Tenancy::InviteMember.new.call(
          condominium: Tenancy::Current.condominium,
          email: params[:email],
          role: params[:role]
        )

        if result.success?
          invitation = result.value!
          render json: {
            email: invitation.email,
            role: invitation.role,
            expires_at: invitation.expires_at,
            # Dev only: em produção isso vira envio de email, nunca resposta
            # da API. Ver design.md (add-tenancy) Decisão 4.
            invite_token: invitation.token
          }, status: :created
        else
          render json: { errors: result.failure.full_messages }, status: :unprocessable_content
        end
      end

      def accept
        result = Tenancy::AcceptInvitation.new.call(
          token: params[:token],
          password: params[:password],
          name: params[:name]
        )

        if result.success?
          render json: Tenancy::MembershipSerializer.new(result.value!).serializable_hash, status: :ok
        else
          render json: { error: result.failure }, status: :unprocessable_content
        end
      end
    end
  end
end
