# frozen_string_literal: true

# app/helpers/users/user_helper.rb
module Users
  # helpers specific to Users
  module UserHelper
    # Create User options for a select form element
    # options_for_users(user: User, client: Client, controller: String, selected: String/Integer)
    # (req) user:       User
    # (opt) client:     Client
    # (opt) controller: String
    # (opt) selected:   String ("all_*") / Integer (User id)
    def options_for_users(**args)
      user       = args.dig(:user)
      client     = args.dig(:client)
      controller = args.dig(:controller).to_s
      selected   = args.dig(:selected) || ''

      return [] unless user.is_a?(User)

      client = user.client unless client.is_a?(Client)

      if user.access_controller?(controller, 'all_contacts')

        if client.agency_access && user.agent?
          grouped_options_for_select(user.users_for_active_contacts(all_users: true, agent: true), selected:)
        else
          options_for_select(user.users_for_active_contacts(all_users: true), selected:)
        end
      else
        options_for_select(user.users_for_active_contacts, selected:)
      end
    end
  end
end
