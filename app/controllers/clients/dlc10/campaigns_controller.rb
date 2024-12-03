# frozen_string_literal: true

# app/controllers/clients/dlc10/campaigns_controller.rb
module Clients
  module Dlc10
    class CampaignsController < Clients::Dlc10::BaseController
      before_action :dlc10_campaign, only: %i[destroy edit update]

      # (POST) create a new 10DLC Campaign
      # /clients/dlc10/campaigns
      # clients_dlc10_campaigns_path(client_id: Integer)
      # clients_dlc10_campaigns_url(client_id: Integer)
      def create
        @dlc10_campaign = @client.dlc10_brand.campaigns.create(params_dlc10_campaign)

        @dlc10_campaign.charge_and_register if params.permit(:commit).dig(:commit).to_s.casecmp?('Save Use Case & Submit to TCR')

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaigns_index dlc10_campaign_show] }
      end

      # (DELETE) delete a 10DLC Campaign
      # /clients/dlc10/campaigns/:client_id
      # clients_dlc10_campaign_path(:client_id, id: Integer)
      # clients_dlc10_campaign_url(:client_id, id: Integer)
      def destroy
        @dlc10_campaign.destroy

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaigns_index] }
      end

      # (GET) edit a 10DLC Campaign
      # /clients/dlc10/campaigns/:client_id/edit?id=Integer
      # edit_clients_dlc10_campaign_path(:client_id, id: Integer)
      # edit_clients_dlc10_campaign_url(:client_id, id: Integer)
      def edit
        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaign_edit] }
      end

      # (GET) edit 10DLC Brand data
      # /clients/dlc10/campaigns
      # clients_dlc10_campaigns_path(client_id: Integer)
      # clients_dlc10_campaigns_url(client_id: Integer)
      def index
        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaigns_index] }
      end

      # (GET) initialize a new 10DLC Campaign
      # /clients/dlc10/campaigns/new?client_id=Integer
      # new_clients_dlc10_campaign_path(client_id: Integer)
      # new_clients_dlc10_campaign_url(client_id: Integer)
      def new
        @dlc10_campaign = @client.dlc10_brand.campaigns.new(Clients::Dlc10::Campaign.default_options(@client.name))

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_campaign_new] }
      end

      # (GET) get Sub Usecases for a 10DLC Use Case
      # /clients/dlc10/campaign/:client_id/sub_use_cases?use_case=String
      # clients_dlc10_campaign_sub_use_cases_path(:client_id, use_case: String)
      # clients_dlc10_campaign_sub_use_cases_url(:client_id, use_case: String)
      def sub_use_cases
        sub_use_case = @client.dlc10_brand.available_sub_use_cases(params.permit(:use_case).dig(:use_case).to_s)
        render json: sub_use_case, status: (sub_use_case.present? ? :ok : 415)
      end

      # (PUT/PATCH) save updated 10DLC Campaign
      # /clients/dlc10/campaigns/:client_id?id=Integer
      # clients_dlc10_campaign_path(:client, id: Integer)
      # clients_dlc10_campaign_url(:client, id: Integer)
      def update
        @dlc10_campaign.update(params_dlc10_campaign)

        if params.permit(:commit).dig(:commit).to_s.casecmp?('Save Use Case & Submit to TCR')
          errors = @dlc10_campaign.charge_and_register

          cards = errors.present? ? %w[dlc10_campaigns_index dlc10_campaign_show] : %w[dlc10_campaigns_index]
        elsif params.permit(:commit).dig(:commit).to_s.casecmp?('Save Use Case & Re-Submit to Phone Vendor')
          @dlc10_campaign.share(@client.phone_vendor) if @dlc10_campaign.tcr_campaign_id.present?

          cards = %w[dlc10_campaigns_index]
        elsif @dlc10_campaign.verified?
          tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new
          tcr_client.campaign_update(campaign: JSON.parse(@dlc10_campaign.to_json).symbolize_keys)
          cards = %w[dlc10_campaigns_index]
        else
          cards = %w[dlc10_campaigns_index]
        end

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: }
      end

      private

      def params_dlc10_campaign
        sanitized_params = params.require(:clients_dlc10_campaign).permit(:name, :use_case, :vertical, :description, :message_flow, :sample1, :sample2, :sample3, :sample4, :sample5, :embedded_link, :embedded_phone, :affiliate_marketing, :direct_lending, :age_gated, :number_pool, :auto_renewal, :mo_charge, sub_use_cases: [])

        sanitized_params[:sub_use_cases].reject!(&:empty?) if sanitized_params.dig(:sub_use_cases)
        sanitized_params[:mo_charge] = sanitized_params[:mo_charge].to_d if sanitized_params.dig(:mo_charge)

        sanitized_params
      end

      def dlc10_campaign
        return if (@dlc10_campaign = @client.dlc10_brand.campaigns.find_by(id: params.permit(:id).dig(:id).to_i))

        sweetalert_error('10DLC Campaign NOT found!', 'We were not able to access the 10DLC campaign you requested.', '', { persistent: 'OK' }) if current_user.team_member?

        respond_to do |format|
          format.js { render js: "window.location = '#{clients_dlc10_brand_path(@client.id)}'" and return false }
          format.html { redirect_to clients_dlc10_brand_path(@client.id) and return false }
        end
      end
    end
  end
end
