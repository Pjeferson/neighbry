# frozen_string_literal: true

module Api
  module V1
    # Revogação manual — a automação via evento de domínio (OccupancyEnded,
    # quando Registry existir) é trabalho de uma change futura.
    # Ver design.md (add-tenancy) Decisão 7.
    class MembershipsController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def revoke
        membership = Tenancy::Membership.find_by!(id: params[:id], condominium: Tenancy::Current.condominium)
        authorize membership

        membership.update!(status: "revoked")

        render json: Tenancy::MembershipSerializer.new(membership).serializable_hash, status: :ok
      end
    end
  end
end
