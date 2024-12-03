# frozen_string_literal: true

# app/presenters/integrations/google/presenter.rb
module Integrations
  module Google
    # variables required by Google views
    class Presenter
      attr_accessor :account, :api_key, :location, :page, :per_page, :webhooks
      attr_reader   :client, :user_api_integration

      def initialize(args = {})
        self.user_api_integration = args.dig(:user_api_integration)
      end

      def actions_reviews
        (self.client_api_integration.actions_reviews || {}).deep_symbolize_keys
      end

      def action_reviews_group(stars)
        id = self.actions_reviews.dig(stars.to_s.to_sym, :group_id).to_i
        id.positive? ? Group.find_by(client_id: self.client.id, id:) : nil
      end

      def action_reviews_tag(stars)
        id = self.actions_reviews.dig(stars.to_s.to_sym, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: self.client.id, id:) : nil
      end

      def average_rating
        return 0.0 if @account.blank?
        return 0.0 if @location.blank?

        # self.ggl_client.average_reviews_rating(@account, @location)
        Review.where(client_id: @client.id, account: @account, location: @location).average(:star_rating) || 0.0
      end

      def campaigns_allowed?
        self.client.campaigns_count.positive?
      end

      def client_api_integration
        @client_api_integration ||= @client.client_api_integrations.find_by(target: 'google', name: '')
      end

      def connection_valid?
        Integration::Google.valid_token?(@user_api_integration)
      end

      def dashboard_calendar_colors
        self.google_calendar_list.map { |calendar| { id: calendar[:id], background_color: calendar[:background_color], foreground_color: calendar[:foreground_color] } }
      end

      def ggl_client
        if @ggl_client
          @ggl_client
        elsif @user_api_integration.user_id != self.client_api_integration.user_id && (user_api_integration = UserApiIntegration.find_by(user_id: self.client_api_integration.user_id, target: 'google', name: ''))
          @ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, I18n.t('tenant.id'))
        else
          @ggl_client = Integrations::Ggl::Base.new(@user_api_integration.token, I18n.t('tenant.id'))
        end
      end

      def google_account_admin
        self.client_api_integration.user_id.to_i.zero? ? self.client.def_user : self.client.users.find_by(id: self.client_api_integration.user_id)
      end

      def google_account_admin_potentials
        self.client.users.each_with_object([]) do |user, array|
          if user.integrations_controller.include?('google_messages') && user.integrations_controller.include?('google_reviews')
            array << user
            # array << [user.fullname, user.id]
          end
        end
      end

      def google_accounts
        @google_accounts ||= my_business_accounts.sort_by { |account| account[:accountName] }.map { |a| (@client_api_integration.active_accounts || []).include?(a.dig(:name).to_s) ? a : nil }.compact_blank
      end

      def google_calendar_list
        if @google_calendar_list.empty? && self.connection_valid?
          ggl_client = Integrations::Ggl::Calendar.new(self.user_api_integration.token, I18n.t('tenant.id'))
          @google_calendar_list = ggl_client.calendar_list
        else
          @google_calendar_list
        end
      end

      def google_calendar_select_array
        self.google_calendar_list.map { |calendar| [calendar[:summary], calendar[:id]] }
      end

      def google_messages_locations
        @google_messages_locations ||= google_accounts.map { |account| self.ggl_client.my_business_locations(account.dig(:name)).sort_by { |location| location[:title] }.map { |location| client_api_integration.active_locations_messages.dig(account.dig(:name))&.include?(location.dig(:name)) ? { account_name: account.dig(:name), account_title: account.dig(:accountName), name: location.dig(:name), title: location.dig(:title) } : nil }.compact_blank }.flatten
      end

      def google_reviews
        @google_reviews ||= ::Review.where(client_id: @client.id, target: 'google', account: @account, location: @location).order(target_updated_at: :desc).page(@page).per(@per_page)
      end

      def google_reviews_locations
        @google_reviews_locations ||= google_accounts.map { |account| self.ggl_client.my_business_locations(account.dig(:name)).sort_by { |location| location[:title] }.map { |location| client_api_integration.active_locations_reviews.dig(account.dig(:name))&.include?(location.dig(:name)) ? { account_name: account.dig(:name), account_title: account.dig(:accountName), name: location.dig(:name), title: location.dig(:title) } : nil }.compact_blank }.flatten
      end

      def groups_allowed?
        self.client.groups_count.positive?
      end

      def my_business_accounts
        @my_business_accounts ||= ggl_client.my_business_accounts
      end

      def options_for_contact_select(review)
        if review.contact_id.to_i.positive?
          [['Unmatch Contact', 0], [review.contact&.fullname, review.contact&.id]]
        else
          []
        end
      end

      def options_for_accounts
        @options_for_accounts ||= my_business_accounts&.map { |a| [a.dig(:accountName).to_s, a.dig(:name).to_s] } || []
      end

      def options_for_locations(account_id)
        @options_for_locations ||= self.ggl_client.my_business_locations(account_id)&.map { |l| [[l.dig(:title), l.dig(:storefrontAddress, :addressLines), l.dig(:storefrontAddress, :locality), l.dig(:storefrontAddress, :administrativeArea), l.dig(:phoneNumbers, :primaryPhone)].flatten.compact_blank.join(', '), l.dig(:name)] } || []
      end

      def options_for_selected_accounts
        self.options_for_accounts.map { |a| @client_api_integration.active_accounts&.include?(a[1]) ? [a[0], a[1]] : nil }.compact_blank
      end

      def options_for_selected_locations_messages(account_id)
        @client_api_integration.active_locations_messages.select { |account, _locations| account == account_id }.values.first&.map { |location, values| location if values&.dig('agent_launched') && values&.dig('location_launched') }&.compact_blank
      end

      def options_for_selected_locations_reviews(account)
        self.options_for_locations(account).map { |l| @client_api_integration.active_locations_reviews.dig(account)&.include?(l[1]) ? [@client_api_integration.active_locations_names&.dig(l[1]).presence || l[0], l[1]] : nil }.compact_blank
      end

      def review_campaign_ids_excluded
        self.client_api_integration.review_campaign_ids_excluded
      end

      def stages_allowed?
        self.client.stages_count.positive?
      end

      def time_zone
        self.client.time_zone
      end

      def total_reviews
        return 'Account not selected.' if @account.blank?
        return 'Location not selected.' if @location.blank?

        # self.ggl_client.total_reviews(@account, @location)
        Review.where(client_id: @client.id, account: @account, location: @location).count
      end

      def user_api_integration=(user_api_integration)
        @user_api_integration = case user_api_integration
                                when UserApiIntegration
                                  user_api_integration
                                when Integer
                                  UserApiIntegration.find_by(id: user_api_integration)
                                else
                                  UserApiIntegration.new
                                end

        @account                   = nil
        @client                    = @user_api_integration.user.client
        @client_api_integration    = nil
        @google_calendar_list      = []
        @google_messages_locations = nil
        @google_reviews_locations  = nil
        @ggl_client                = nil
        @location                  = nil
        @google_accounts           = nil
        @google_reviews            = nil
        @options_for_accounts      = nil
        @options_for_locations     = nil
        @page                      = 1
        @per_page                  = 20

        self.connection_valid?
      end
    end
  end
end
