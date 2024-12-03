# frozen_string_literal: true

# app/presenters/integrations/searchlight/v1/presenter.rb
module Integrations
  module Searchlight
    module V1
      class Presenter
        attr_reader :client, :client_api_integration, :contact

        def initialize(args = {})
          self.client_api_integration = args.dig(:client_api_integration)
        end

        def options_for_campaigns
          ApplicationController.helpers.options_for_campaign(client: @client, grouped: true, selected_campaign_id: @client_api_integration.revenue_gen&.dig('campaign_ids'))
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'searchlight', name: '')
                                    end

          @client                 = @client_api_integration.client
        end

        def iframe_url(skin)
          if skin == 'dark'
            "#{iframe_url_base}/#{iframe_dark_guid}/page/#{iframe_dark_page}?params=#{iframe_url_params}"
          else
            "#{iframe_url_base}/#{iframe_light_guid}/page/#{iframe_light_page}?params=#{iframe_url_params}"
          end
        end

        def selected_campaign_ids
          @client_api_integration.revenue_gen&.dig('campaign_ids')
        end

        private

        def iframe_dark_guid
          '4b8bbd3b-485b-42cd-bc94-f92475cc836e'
        end

        def iframe_dark_page
          'p_4ofxb7n13c'
        end

        def iframe_light_guid
          'b473e90d-c61c-4421-bc3c-687574fce514'
        end

        def iframe_light_page
          'p_l6uhlj403c'
        end

        def iframe_url_base
          'https://lookerstudio.google.com/embed/reporting'
        end

        def iframe_url_params
          "%7B%22key%22%3A%22#{@client_api_integration.api_key}%22%7D"
        end
      end
    end
  end
end
