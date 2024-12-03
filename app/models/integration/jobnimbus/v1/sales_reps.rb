# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/sales_reps.rb
module Integration
  module Jobnimbus
    module V1
      module SalesReps
        # delete a sales_rep from the list of JobNimbus sales reps collected from webhooks
        # jn_model.sales_rep_delete()
        #   (req) id: (String)
        def sales_rep_delete(**args)
          return {} unless args.dig(:id).to_s.present? && (client_api_integration_sales_reps = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'sales_reps'))

          client_api_integration_sales_reps.data.delete(args[:id].to_s)
          client_api_integration_sales_reps.save

          client_api_integration_sales_reps.data.with_indifferent_access
        end

        # find a sales_rep from the list of JobNimbus sales reps collected from webhooks
        # jn_model.sales_rep_find()
        #   (req) id: (String)
        def sales_rep_find(**args)
          return nil unless args.dig(:id).to_s.present? && (client_api_integration_sales_reps = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'sales_reps'))

          client_api_integration_sales_reps.data.dig(args[:id].to_s)&.symbolize_keys
        end

        # list all sales_reps from the list of JobNimbus sales reps collected from webhooks
        # jn_model.sales_rep_list
        def sales_rep_list
          return {} unless (client_api_integration_sales_reps = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'sales_reps'))

          client_api_integration_sales_reps.data.with_indifferent_access
        end

        # update list of JobNimbus sales reps collected from webhooks
        # jn_model.sales_rep_update()
        #   (req) id:    (String)
        #
        #   (opt) name:  (String / default nil)
        #   (opt) email: (String / default nil)
        def sales_rep_update(**args)
          return unless args.dig(:id).to_s.present? && (client_api_integration_sales_reps = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'sales_reps'))

          client_api_integration_sales_reps.data[args[:id].to_s] = {
            name:  args.dig(:name).nil? ? client_api_integration_sales_reps.data.dig(args[:id].to_s, 'name').to_s : args[:name].to_s,
            email: args.dig(:email).nil? ? client_api_integration_sales_reps.data.dig(args[:id].to_s, 'email').to_s : args[:email].to_s
          }

          client_api_integration_sales_reps.save

          client_api_integration_sales_reps.data.with_indifferent_access
        end
      end
    end
  end
end
