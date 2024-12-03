# frozen_string_literal: true

module Users
  # Users::SignInDebug.all.map {|s| JSON.parse(s.ciphertext_for(:password))}
  # Users::SignInDebug.failed.map {|s| JSON.parse(s.ciphertext_for(:password))}
  # Users::SignInDebug.failed.map(&:attributes)
  # Users::SignInDebug.failed.group(:remote_ip).select('remote_ip, count(remote_ip)').order('count(remote_ip) desc').map(&:attributes)
  # Users::SignInDebug.failed.group(:email, :remote_ip).select('email, remote_ip, count(remote_ip)').order('count(remote_ip)').map(&:attributes)
  # Users::SignInDebug.failed.group(:user_id, :remote_ip).select('user_id, remote_ip, count(remote_ip)').order('count(remote_ip)').map(&:attributes)
  # Users::SignInDebug.where(remote_ip: '2.59.157.242').map(&:attributes)
  class SignInDebug < ApplicationRecord
    store_accessor :data, :headers

    belongs_to :user, optional: true

    scope :by_email, ->(email) { where(email:) }
    scope :by_remote_ip, ->(remote_ip) { where(remote_ip:) }
    scope :successful, -> { where(user_signed_in?: true) }
    scope :failed, -> { where(user_signed_in?: false) }
    scope :old, -> { where(created_at: ..30.days.ago.beginning_of_day) }
  end
end
