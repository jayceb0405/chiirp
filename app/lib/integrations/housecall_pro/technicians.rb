# frozen_string_literal: true

# app/lib/integrations/housecall_pro/technicians.rb
module Integrations
  module HousecallPro
    module Technicians
      # get a Housecall Pro technician
      # hcp_client.technician
      #   (req) ext_tech_id: (String)
      def technician(ext_tech_id)
        reset_attributes
        page           = 1
        page_size      = 50
        default_result = {}

        if ext_tech_id.blank?
          @message = 'Housecall Pro technician (Pro) ID is required.'
          return default_result
        end

        total_page_count = 1

        while page <= total_page_count
          self.housecallpro_request(
            body:                  nil,
            error_message_prepend: 'Integrations::HousecallPro::Technicians.technician',
            method:                'get',
            params:                { page:, page_size: },
            default_result:,
            url:                   "#{base_url}/employees"
          )

          if @success && @result.is_a?(Hash)
            total_page_count = @result.dig(:total_pages).to_i if page_size > 1

            if (technicians = @result.dig(:employees)) && (technician = technicians.find { |tech| tech.dig(:id) == ext_tech_id })
              @success = true
              @result  = technician
              break
            end

            page += 1
          else
            @result = {}
            break
          end
        end

        @result
      end

      # get Housecall Pro technicians
      # hcp_client.technicians
      def technicians(**args)
        reset_attributes
        page           = args.dig(:page).to_i.positive? ? args.dig(:page).to_i : 1
        page_size      = (args.dig(:page_size) || 50).to_i
        default_result = []
        response       = []

        total_page_count = 1

        while page <= total_page_count
          self.housecallpro_request(
            body:                  nil,
            error_message_prepend: 'Integrations::HousecallPro::Technicians.technicians',
            method:                'get',
            params:                { page:, page_size: },
            default_result:,
            url:                   "#{base_url}/employees"
          )

          if @success && @result.is_a?(Hash)
            total_page_count = @result.dig(:total_pages).to_i if page_size > 1

            if (technicians = @result.dig(:employees))
              @success  = true
              response += technicians
            end

            page += 1
          else
            @success = false
            response = []
            break
          end
        end

        @result = response
      end

      # get count of all Housecall Pro employees
      # hcp_client.technicians_count
      def technicians_count
        reset_attributes
        @result = 0

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Technicians.technicians_count',
          method:                'get',
          params:                { page: 1, page_size: 1 },
          default_result:        @result,
          url:                   "#{base_url}/employees"
        )

        @result = (@result.is_a?(Hash) ? @result.dig(:total_items) : 0).to_i
      end

      alias employees technicians
    end
  end
end
