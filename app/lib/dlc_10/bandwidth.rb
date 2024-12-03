# frozen_string_literal: true

# app/lib/dlc_10/bandwidth.rb
module Dlc10
  # process Campaign Registry (TCR) API calls to Bandwidth
  class Bandwidth
    class Dlc10BandwidthError < StandardError; end

    attr_reader :error, :message, :result, :success, :faraday_result

    # initialize Dlc10::Bandwidth object
    # dlc10_bandwidth_client = Dlc10::Bandwidth.new
    def initialize
      reset_attributes
      @result = nil
    end

    # call Bandwidth API for a specific TCR Campaign
    # dlc10_bandwidth_client.campaign(tcr_campaign_id)
    def campaign(tcr_campaign_id)
      Rails.logger.info "Dlc10::Bandwidth.campaign: #{{ tcr_campaign_id: }} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      reset_attributes
      @result         = {}
      tcr_campaign_id = tcr_campaign_id.to_s

      return @result if tcr_campaign_id.blank?

      bandwidth_request(
        body:                  nil,
        error_message_prepend: 'Dlc10::Bandwidth.campaign',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_dashboard_api_url}/#{account_api_path}/#{campaign_management_api_path}/campaigns/imports/#{tcr_campaign_id}"
      )

      @result = @result.presence&.dig(:LongCodeImportCampaignResponse, :ImportedCampaign).presence || {}
    end

    # call Bandwidth API to apply a phone number to a TCR campaign
    # dlc10_bandwidth_client.campaign_phone_number(tcr_campaign_id, phone_number)
    def campaign_phone_number(tcr_campaign_id, phone_number)
      Rails.logger.info "Dlc10::Bandwidth.campaign: #{{ tcr_campaign_id:, phone_number: }} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      reset_attributes
      @result         = {}
      tcr_campaign_id = tcr_campaign_id.to_s
      phone_number    = phone_number.to_s

      return @result unless tcr_campaign_id.present? && phone_number.present?

      data = {
        TnOptionGroups: {
          TnOptionGroup: {
            Sms:              'on',
            A2pSettings:      {
              Action:     'asSpecified',
              CampaignId: tcr_campaign_id
            },
            TelephoneNumbers: {
              TelephoneNumber: phone_number
            }
          }
        }
      }

      bandwidth_request(
        body:                  data.to_xml(skip_instruct: true, skip_types: true, root: 'TnOptionOrder', indent: 0),
        error_message_prepend: 'Dlc10::Bandwidth.campaign_phone_number',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_dashboard_api_url}/#{account_api_path}/tnoptions"
      )

      if @success && @result.presence&.dig(:TnOptionOrderResponse, :TnOptionOrder, :TnOptionGroups, :TnOptionGroup, :Sms).to_s.casecmp?('on') &&
         @result.presence&.dig(:TnOptionOrderResponse, :TnOptionOrder, :TnOptionGroups, :TnOptionGroup, :TelephoneNumbers)&.values&.include?(phone_number)
        @result = {
          downstreamCnpId: 'SBJAF5P',
          upstreamCnpId:   'BANDW',
          sharingStatus:   @result.presence&.dig(:TnOptionOrderResponse, :TnOptionOrder, :ProcessingStatus).to_s,
          explanation:     nil,
          sharedDate:      @result.presence&.dig(:TnOptionOrderResponse, :TnOptionOrder, :OrderCreateDate).to_s,
          statusDate:      @result.presence&.dig(:TnOptionOrderResponse, :TnOptionOrder, :LastModifiedDate).to_s
        }
        @success = true
      elsif @success
        @result  = {}
        @success = false
        @message = 'Phone number not accepted / not applied to TCR Campaign.'
      end

      @result
    end
    # example response
    # {
    #   :TnOptionOrderResponse=>{
    #     :TnOptionOrder=>{
    #       :OrderCreateDate=>"2023-01-23T22:20:07.816Z",
    #       :AccountId=>"5007421",
    #       :CreatedByUser=>"api_access@kevinneubert.com",
    #       :OrderId=>"4d06b974-ca19-45ff-a4ff-bd23e02c8743",
    #       :LastModifiedDate=>"2023-01-23T22:20:07.816Z",
    #       :ProcessingStatus=>"RECEIVED",
    #       :TnOptionGroups=>{
    #         :TnOptionGroup=>{
    #           :Sms=>"on",
    #           :A2pSettings=>{
    #             :CampaignId=>"CKODCJ7",
    #             :Action=>"asSpecified"
    #           },
    #           :TelephoneNumbers=>{
    #             :TelephoneNumber=>"8022554948"
    #           }
    #         }
    #       },
    #       :ErrorList=>nil,
    #       :Warnings=>nil
    #     }
    #   }
    # }

    # call Bandwidth API to import a TCR campaign into Bandwidth
    # dlc10_bandwidth_client.campaign_share(tcr_campaign_id)
    def campaign_share(tcr_campaign_id)
      Rails.logger.info "Dlc10::Bandwidth.campaign: #{{ tcr_campaign_id: }} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      reset_attributes
      @result = {}

      return @result if tcr_campaign_id.blank?

      data = { CampaignId: tcr_campaign_id }

      bandwidth_request(
        body:                  data.to_xml(skip_instruct: true, skip_types: true, root: 'ImportedCampaign', indent: 0),
        error_message_prepend: 'Dlc10::Bandwidth.campaign_share',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_dashboard_api_url}/#{account_api_path}/#{campaign_management_api_path}/campaigns/imports"
      )

      @result = {
        campaign_id: @result.dig(:LongCodeImportCampaignResponse, :ImportedCampaign, :CampaignId).to_s,
        description: @result.dig(:LongCodeImportCampaignResponse, :ImportedCampaign, :Description).to_s,
        created_at:  @result.dig(:LongCodeImportCampaignResponse, :ImportedCampaign, :CreateDate).to_s,
        status:      @result.dig(:LongCodeImportCampaignResponse, :ImportedCampaign, :Status).to_s
      }
    end
    # @result example:
    # {
    #   :CampaignId=>"CBTANC9",
    #   :Description=>"General Messaging with Contacts",
    #   :MessageClass=>"Campaign-T",
    #   :CreateDate=>"2021-10-26T13:45:54Z",
    #   :Status=>"ACTIVE",
    #   :MnoStatusList=>{:MnoStatus=>[{:MnoName=>"ATT", :MnoId=>"10017", :Status=>"APPROVED"}, {:MnoName=>"TMO", :MnoId=>"10035", :Status=>"APPROVED"}]}
    # }

    # call Bandwidth API for a list of Campaigns
    # dlc10_bandwidth_client.campaigns
    def campaigns
      reset_attributes
      result = []

      # begin
      page      = 0
      page_size = 25

      loop do
        bandwidth_request(
          body:                  nil,
          error_message_prepend: 'Dlc10::Bandwidth.campaigns',
          method:                'get',
          params:                { page:, size: page_size },
          default_result:        [],
          url:                   "#{base_dashboard_api_url}/#{account_api_path}/#{campaign_management_api_path}/campaigns/imports"
        )

        result     += @result.presence&.dig(:LongCodeImportCampaignsResponse, :ImportedCampaigns)&.map { |_imported_campaign, campaign| campaign } || []
        page       += 1
        page_count  = (@result.presence&.dig(:LongCodeImportCampaignsResponse, :TotalCount).to_f / page_size).ceil
        break if page >= page_count
      end

      @result = result || []
    end

    # call Bandwidth API for a specific TCR Campaign
    # dlc10_bandwidth_client.phone_number_options(phone_number)
    def phone_number_options(phone_number)
      reset_attributes
      @result = []
      phone_number = phone_number.to_s

      return @result if phone_number.blank?

      bandwidth_request(
        body:                  nil,
        error_message_prepend: 'Dlc10::Bandwidth.campaigns',
        method:                'get',
        params:                { tn: phone_number },
        default_result:        @result,
        url:                   "#{base_dashboard_api_url}/#{account_api_path}/tnoptions"
      )

      @result = @result.dig(:TnOptionOrders) || []
    end

    def success?
      @success
    end

    private

    def account_api_path
      "accounts/#{account_id}"
    end

    def account_id
      Rails.application.credentials[:bandwidth][:account_id]
    end

    def application_id
      ENV.fetch('BANDWIDTH_MESSAGING_APPLICATION_ID', nil)
    end

    # bandwidth_request(
    #   body:                  Hash,
    #   error_message_prepend: 'Dlc10::Bandwidth.bandwidth_request',
    #   method:                String,
    #   params:                Hash,
    #   default_result:        @result,
    #   url:                   String
    # )
    def bandwidth_request(args = {})
      reset_attributes
      body                  = args.dig(:body)
      error_message_prepend = args.dig(:error_message_prepend) || 'Dlc10::Bandwidth.bandwidth_request'
      faraday_method        = (args.dig(:method) || 'get').to_s
      params                = args.dig(:params)
      @result               = args.dig(:default_result)
      url                   = args.dig(:url).to_s

      if url.blank?
        @message = 'Bandwidth API URL is required.'
        return @result
      end

      loop do
        redos ||= 0

        @success, @error, @message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          error_message_prepend:,
          current_variables:     {
            parent_body:                  args.dig(:body),
            parent_error_message_prepend: args.dig(:error_message_prepend),
            parent_method:                args.dig(:method),
            parent_params:                args.dig(:params),
            parent_result:                args.dig(:default_result),
            parent_url:                   args.dig(:url),
            parent_file:                  __FILE__,
            parent_line:                  __LINE__
          }
        ) do
          @faraday_result = Faraday.send(faraday_method, url) do |req|
            req.headers['Authorization'] = "Basic #{basic_auth}"
            req.headers['Content-Type']  = 'application/xml;'
            req.params                   = params if params.present?
            req.body                     = body if body.present?
          end
        end

        case @faraday_result&.status
        when 200, 201
          @result  = Hash.from_xml(@faraday_result.body)
          @result  = if @result.respond_to?(:deep_symbolize_keys)
                       @result.deep_symbolize_keys
                     elsif @result.respond_to?(:map)
                       @result.map(&:deep_symbolize_keys)
                     else
                       @result
                     end
          @success = true
        when 401

          if (redos += 1) < 5
            sleep ProcessError::Backoff.full_jitter(redos:)
            redo
          end

          @error   = @faraday_result&.status
          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"

          error = Dlc10BandwidthError.new(@message)
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action(error_message_prepend)

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  @error
            )
            Appsignal.add_custom_data(
              faraday_result:         @faraday_result&.to_hash,
              faraday_result_methods: @faraday_result&.public_methods.inspect,
              result:                 @result,
              file:                   __FILE__,
              line:                   __LINE__
            )
          end
        when 404
          @error   = @faraday_result&.status
          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
        else
          @error   = @faraday_result&.status
          @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{@faraday_result&.body}"

          error = Dlc10BandwidthError.new(@message)
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action(error_message_prepend)

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  @error
            )
            Appsignal.add_custom_data(
              faraday_result:         @faraday_result&.to_hash,
              faraday_result_methods: @faraday_result&.public_methods.inspect,
              result:                 @result,
              file:                   __FILE__,
              line:                   __LINE__
            )
          end
        end

        break
      end

      Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

      @result
    end

    def base_dashboard_api_url
      'https://dashboard.bandwidth.com/api'
    end

    def basic_auth
      Base64.urlsafe_encode64("#{user_name}:#{password}").strip
    end

    def campaign_management_api_path
      'campaignManagement/10dlc'
    end

    def password
      Rails.application.credentials[:bandwidth][:password]
    end

    def reset_attributes
      @error   = 0
      @message = ''
      @success = false
    end

    def user_name
      Rails.application.credentials[:bandwidth][:user_name]
    end
  end
end
