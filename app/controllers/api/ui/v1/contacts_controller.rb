# frozen_string_literal: true

# app/controllers/api/ui/v1/contacts_controller.rb
module Api
  module Ui
    module V1
      class ContactsController < Api::Ui::V1::BaseController
        before_action :user_settings, only: %i[index]

        # (GET) provide JSON data for a collection of Contacts
        # /api/ui/v1/contacts
        # api_ui_v1_contacts_path
        # api_ui_v1_contacts_url
        #   (opt) data             (Hash / default: last used Users::Setting for "contacts_newui")
        #   (opt) order_column:    (String / default: last used or "created_at")
        #   (opt) order_direction: (String / default: last used or "desc")
        #   (opt) page:            (Integer / default: 1)
        #   (opt) page_size:       (Integer / default: last used or 25)
        def index
          render json: {
            page:          [params.dig(:page).to_i, 1].max,
            page_size:     @user_settings.data.dig(:per_page),
            total_results: Contact.custom_search_query(
              user:                 current_user,
              my_contacts_settings: @user_settings,
              page_number:          [params.dig(:page).to_i, 1].max,
              order:                false
            ).count,
            results:       Contact.custom_search_query(
              user:                 current_user,
              my_contacts_settings: @user_settings,
              page_number:          [params.dig(:page).to_i, 1].max,
              order:                false
            )
                                  .select('contacts.id AS id, contacts.lastname AS lastname, contacts.firstname AS firstname, contacts.created_at AS created_at, COUNT(delayed_jobs.id) AS future_campaigns, COUNT(contact_campaigns.id) AS other_campaigns')
                                  .joins("LEFT OUTER JOIN delayed_jobs ON delayed_jobs.contact_id = contacts.id AND delayed_jobs.process = 'start_campaign'")
                                  .left_outer_joins(:contact_campaigns)
                                  .group('contacts.id')
                                  .limit(@user_settings.data.dig(:per_page))
                                  .offset(([params.dig(:page).to_i, 1].max - 1) * @user_settings.data.dig(:per_page))
                                  .order(@user_settings.data.dig(:sort, :col) => @user_settings.data.dig(:sort, :dir))
          }
        end

        private

        def user_settings
          @user_settings      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_newui', name: 'Last Used')
          @user_settings.data = Contacts::Search.new.sanitize_params(params:, user: current_user, user_settings: @user_settings)
          @user_settings.save
        end
      end
    end
  end
end
