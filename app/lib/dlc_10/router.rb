# frozen_string_literal: true

# app/lib/dlc_10/router.rb
module Dlc10
  class Router
    attr_reader :error, :message, :result, :success, :faraday_result

    # initialize Dlc10::Router object
    # dlc10_router_client = ::Dlc10::Router.new()
    #   (req) phone_vendor: (String)
    def initialize(phone_vendor)
      @phone_vendor = phone_vendor
      @result       = nil

      case @phone_vendor.to_s
      when 'bandwidth'
        @client = ::Dlc10::Bandwidth.new
      when 'sinch'
        @client = ::Dlc10::Sinch.new
      when 'twilio'
        @client = nil
      end

      reset_attributes
    end

    # request TCR campaign data from carrier
    # dlc10_router_client.campaign(tcr_campaign_id)
    def campaign(tcr_campaign_id)
      @result = @client&.campaign(tcr_campaign_id)
      reset_attributes

      @result
    end

    # apply a phone number to a TCR campaign in carrier
    # dlc10_router_client.campaign_phone_number(tcr_campaign_id, phone_number)
    def campaign_phone_number(tcr_campaign_id, phone_number)
      @result = @client&.campaign_phone_number(tcr_campaign_id, phone_number)
      reset_attributes

      @result
    end

    # share TCR campaign data with phone vendor
    # dlc10_router_client.campaign_share(tcr_campaign_id)
    def campaign_share(tcr_campaign_id)
      @result = @client&.campaign_share(tcr_campaign_id)
      reset_attributes

      @result
    end

    # request all campaigns defined in carrier
    # dlc10_router_client.campaigns
    def campaigns
      @result = @client&.campaigns
      reset_attributes

      @result
    end

    # request phone number options for a phone number in carrier
    # dlc10_router_client.phone_number_options(phone_number)
    def phone_number_options(phone_number)
      @result = @client&.phone_number_options(phone_number)
      reset_attributes

      @result
    end

    def success?
      @success
    end

    private

    def reset_attributes
      @error          = @client&.error || 0
      @message        = @client&.message || ''
      @success        = @client&.success? || false
      @faraday_result = @client&.faraday_result || nil
    end
  end
end
