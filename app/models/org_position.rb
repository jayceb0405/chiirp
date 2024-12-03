# frozen_string_literal: true

# app/models/org_position.rb
class OrgPosition < ApplicationRecord
  belongs_to :client
  belongs_to :client_custom_field, optional: true

  has_many   :org_users, dependent: nil

  before_create        :before_create_actions
  before_destroy       :before_destroy_actions

  private

  def after_destroy_commit_actions
    super

    next_level = 0

    self.client.org_positions.order(:level).each do |org_position|
      org_position.update(level: next_level)
      next_level += 1
    end
  end

  def before_create_actions
    last_org_position = self.client.org_positions.order(:level).last
    self.level = last_org_position.level + 1 if last_org_position
  end

  def before_destroy_actions
    self.client.org_users.where(org_position_id: self.id).find_each do |org_user|
      if org_user.user_id.positive?
        org_user.destroy
      else
        org_user.update(org_group: 0, org_position_id: 0)
      end
    end
  end
end
