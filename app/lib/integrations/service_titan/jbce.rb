# frozen_string_literal: true

# app/lib/integrations/service_titan/crm.rb
module Integrations
  module ServiceTitan
    module Jbce
      # call ServiceTitan API for call reasons
      # st_client.call_reasons
      #   (opt) active_only: (Boolean)
      def call_reasons(args = {})
        reset_attributes
        @result  = []
        page     = 0
        response = @result

        params = {
          active:   args.dig(:active_only).nil? ? true : args[:active_only].to_bool,
          pageSize: @max_page_size
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Jbce.call_reasons',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_jbce}/#{api_version}/tenant/#{self.tenant_id}/call-reasons"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore).to_bool
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
