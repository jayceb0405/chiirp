# frozen_string_literal: true

# app/models/org_user.rb
class OrgUser < ApplicationRecord
  belongs_to       :client
  belongs_to       :user,              optional: true
  belongs_to       :org_position,      optional: true

  # create Hash of all available OrgUsers
  # @org_users = OrgUser.available_org_users( Client )
  def self.available_org_users(client)
    org_users = client.users.left_outer_joins(:org_users).where(org_users: { user_id: nil }).pluck(:id, :lastname, :firstname, :phone, :email).map { |user| { table: 'user', id: user[0], lastname: user[1], firstname: user[2], phone: user[3], email: user[4] } }
    org_users += client.org_users.where(org_group: 0).pluck(:id, :lastname, :firstname, :phone, :email).map { |user| { table: 'orguser', id: user[0], lastname: user[1], firstname: user[2], phone: user[3], email: user[4] } }

    org_users
  end
end
