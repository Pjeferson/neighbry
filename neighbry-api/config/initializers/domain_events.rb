# frozen_string_literal: true

# Assinaturas de evento de domínio entre bounded contexts. Regra: só quem
# ESCUTA conhece quem PUBLICA — nunca o contrário. Tenancy não referencia
# nada daqui; Registry se inscreve no evento que Tenancy publica.
ActiveSupport::Notifications.subscribe("tenancy.invitation_accepted") do |*, payload|
  Registry::ReconcilePersonUser.new.call(invitation_id: payload[:invitation_id], user_id: payload[:user_id])
end

ActiveSupport::Notifications.subscribe("tenancy.condominium_onboarded") do |*, payload|
  Billing::CreateDefaultBillingSetting.new.call(condominium_id: payload[:condominium_id])
end
