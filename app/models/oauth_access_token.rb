# frozen_string_literal: true

# app/models/oauth_access_token.rb
class OauthAccessToken < ApplicationRecord
  # rubocop:disable Rails/InverseOf
  belongs_to :user, class_name: :User, foreign_key: :resource_owner_id
  # rubocop:enable Rails/InverseOf
end
