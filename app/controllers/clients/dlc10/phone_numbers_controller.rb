# frozen_string_literal: true

# app/controllers/clients/dlc10/phone_numbers_controller.rb
module Clients
  module Dlc10
    class PhoneNumbersController < Clients::Dlc10::BaseController
      # (GET) show phone numbers to match with 10DLC campaigns
      # /clients/dlc10/phone_numbers
      # clients_dlc10_phone_numbers_path
      # clients_dlc10_phone_numbers_url
      def index
        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_phone_numbers_index] }
      end

      # (PUT/PATCH) save Dlc10CampaignPhoneNumber connections
      # /clients/dlc10/phone_numbers/:client_id
      # clients_dlc10_phone_number_path(:client_id)
      # clients_dlc10_phone_number_url(:client_id)
      def update
        sanitized_params = params.permit(campaign_phone_numbers: {}).dig(:campaign_phone_numbers)

        if sanitized_params.present?
          campaign_phone_numbers = sanitized_params.keys.map(&:to_i).zip(sanitized_params.values.map(&:to_i)).to_h # {Twnumber.id => Clients::Dlc10::Campaign.id, ...}

          @client.twnumbers.where(id: campaign_phone_numbers.keys).find_each do |twnumber|
            Clients::Dlc10::Campaign.find_by(id: campaign_phone_numbers[twnumber.id])&.share_phone_number(twnumber) if campaign_phone_numbers[twnumber.id].positive?
          end
        end

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_phone_numbers_index] }
      end
    end
  end
end
