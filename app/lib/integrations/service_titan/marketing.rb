# frozen_string_literal: true

# https://developer.servicetitan.io/api-details/#api=tenant-marketing-v2&operation=Campaigns_GetList
# app/lib/integrations/service_titan/marketing.rb
module Integrations
  module ServiceTitan
    module Marketing
      # call ServiceTitan API for campaigns
      # st_client.campaigns
      #   (opt) active_only: (Boolean / default: true)
      def campaigns(args = {})
        reset_attributes
        @result  = []
        response = @result
        page     = 0
        params   = { pageSize: @max_page_size }
        params[:active] = args.dig(:active_only).nil? ? true : args[:active_only].to_bool

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Marketing.campaigns',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_marketing}/#{api_version}/tenant/#{self.tenant_id}/campaigns"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end
    end
  end
end
