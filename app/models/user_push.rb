# frozen_string_literal: true

# app/models/user_push.rb
class UserPush < ApplicationRecord
  belongs_to :user

  # mobile push notifications
  store_accessor :data, :mobile_key

  after_initialize :apply_defaults, if: :new_record?

  def self.all_mobile_keys
    self.where(target: 'mobile').pluck(Arel.sql("data -> 'mobile_key'"))
  end

  private

  def apply_defaults
    return unless self.target.casecmp?('mobile')

    self.mobile_key ||= ''
  end
end
