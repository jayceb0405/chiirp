# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/pricebook/base.rb
module Integration
  module Servicetitan
    module V2
      module Pricebook
        module Base
          include Servicetitan::V2::Pricebook::Categories
          include Servicetitan::V2::Pricebook::Equipment
          include Servicetitan::V2::Pricebook::Materials
          include Servicetitan::V2::Pricebook::Services

          def collect_line_items_from_servicetitan
            line_items = {}
            line_items.merge!(self.line_items_by_type('equipment'))
            line_items.merge!(self.line_items_by_type('materials'))
            line_items.merge!(self.line_items_by_type('services'))

            line_items
          end

          def line_items_by_type(line_item_type)
            return {} unless %w[equipment materials services].include?(line_item_type)
            return {} unless client_api_integration_line_items.send(line_item_type)

            category_ids = []
            pricebook_categories(raw: true).select { |category| ([category[:id]] + category.dig(:subcategories).pluck(:id)).intersect?(client_api_integration_line_items.categories) }.each { |c| category_ids += [c[:id]] + c.dig(:subcategories).map { |sc| [sc[:id]] + (sc.dig(:subcategories) || []).pluck(:id) } }

            @st_client.send(:"pb_#{line_item_type}")

            return {} unless @st_client.success?

            line_items = {}

            @st_client.result.each do |r|
              line_items[r.dig(:id).to_i] = r.dig(:displayName).to_s.truncate(50) if r.dig(:categories).map { |c| c.is_a?(Hash) ? c.dig(:id) : c }.intersect?(category_ids)
            end

            line_items
          end
        end
      end
    end
  end
end
