# frozen_string_literal: true

module Api
  module V1
    class ReservationsController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def index
        unless ::Reservation::BookingPolicy.new(current_user, Tenancy::Current.condominium).list?
          return render json: { error: [:unauthorized] }, status: :unprocessable_content
        end

        bookings = ::Reservation::Booking.where(condominium_id: Tenancy::Current.condominium.id)
        render json: ::Reservation::BookingSerializer.new(bookings).serializable_hash
      end

      def create
        unit = Registry::Unit.find_by!(id: params[:unit_id], condominium_id: Tenancy::Current.condominium.id)
        common_area = ::CommonArea::CommonArea.find_by!(id: params[:common_area_id], condominium_id: Tenancy::Current.condominium.id)

        result = ::Reservation::CreateBooking.new.call(
          actor: current_user,
          unit: unit,
          common_area: common_area,
          data: params[:data],
          turno: params[:turno]
        )

        if result.success?
          render json: ::Reservation::BookingSerializer.new(result.value!).serializable_hash, status: :created
        else
          render json: { error: error_payload(result.failure) }, status: :unprocessable_content
        end
      end

      def destroy
        booking = ::Reservation::Booking.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

        result = ::Reservation::CancelBooking.new.call(actor: current_user, booking: booking)

        if result.success?
          render json: ::Reservation::BookingSerializer.new(result.value!).serializable_hash
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
