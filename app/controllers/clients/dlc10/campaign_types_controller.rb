# frozen_string_literal: true

# app/controllers/clients/dlc10/campaign_types_controller.rb
module Clients
  module Dlc10
    class CampaignTypesController < Clients::Dlc10::BaseController
      # (GET) show 10DLC Campaign types info
      # /clients/dlc10/campaign_types/:client_id
      # clients_dlc10_campaign_type_path(:client_id)
      # clients_dlc10_campaign_type_url(:client_id)
      def show
        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaign_types] }
      end
    end
  end
end
