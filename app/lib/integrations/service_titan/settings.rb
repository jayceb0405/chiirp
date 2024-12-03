# frozen_string_literal: true

# app/lib/integrations/service_titan/settings.rb
module Integrations
  module ServiceTitan
    module Settings
      # call ServiceTitan API for business units
      # st_client.business_units
      #   (opt) active_only: (Boolean / default: true)
      def business_units(args = {})
        reset_attributes
        @result  = []
        page     = 0
        response = @result
        params   = {
          active:   args.dig(:active_only).nil? ? true : args[:active_only].to_bool,
          pageSize: @max_page_size
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::Settings.business_units',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/business-units"
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

      # extract array of tags applied to an incoming webhook
      # st_client.parse_tags(data: Hash)
      #   (req) data: (Hash)
      def parse_tags(args = {})
        args.dig(:tags)&.map { |t| { id: t[:id], name: t[:name] } } || []
      end

      # call ServiceTitan API for tag types
      # st_client.tag_types
      #   (opt) active_only: (Boolean / default: true)
      def tag_types(args = {})
        reset_attributes
        @result  = []
        page     = 0
        response = @result
        params   = {
          active:   args.dig(:active_only).nil? ? true : args[:active_only].to_bool,
          pageSize: @max_page_size
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  {},
            error_message_prepend: 'Integrations::ServiceTitan::Settings.tag_types',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_settings}/#{api_version}/tenant/#{self.tenant_id}/tag-types"
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
