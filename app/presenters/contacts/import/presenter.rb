# frozen_string_literal: true

# app/presenters/contacts/import/presenter.rb
module Contacts
  module Import
    class Presenter
      attr_reader :client, :user

      def initialize(user)
        self.user = user
      end

      def contacts_waiting
        @contacts_waiting ||= [DelayedJob.scheduled_imports(@user.id).count - 1, 0].max * 50
      end

      def import_fields
        @import_fields ||= ::Webhook.internal_key_hash(@client, 'contact', %w[personal ext_references]).invert.to_a + [['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(@client, 'contact', %w[phones]).invert.to_a +
                           @client.client_custom_fields.map { |ccv| [ccv.var_name, ccv.var_var] } + [%w[Tag tag]]
      end

      def options_for_users
        @options_for_users ||= @client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), user[0]] }
      end

      def spreadsheet_data_example
        user.user_settings.find_by(controller_action: 'contacts_import', name: '')&.data&.dig(:spreadsheet)&.first(6)
      end

      def user=(user)
        @user = case user
                when User
                  user
                when Integer
                  User.find_by(id: user)
                else
                  User.new
                end

        @client            = @user.client
        @contacts_waiting  = nil
        @import_fields     = nil
        @options_for_users = nil
      end
    end
  end
end
