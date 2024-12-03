# frozen_string_literal: true

# app/models/contacts/campaign.rb
module Contacts
  class Campaign < ApplicationRecord
    self.table_name = 'contact_campaigns'

    belongs_to :contact
    belongs_to :campaign, class_name: '::Campaign', optional: true

    has_many   :contact_campaign_triggeractions, dependent: :delete_all, foreign_key: :contact_campaign_id, inverse_of: :contact_campaign, class_name: '::Contacts::Campaigns::Triggeraction'
    has_many   :delayed_jobs,                    dependent: :delete_all, foreign_key: :contact_campaign_id, inverse_of: :contact_campaign

    serialize  :data, coder: YAML, type: Hash

    after_create :trigger_contact

    scope :campaign, ->(campaign_id, from_date = 50.years.ago, to_date = Time.current) {
      where(campaign_id:)
        .where(created_at: from_date..to_date)
    }
    scope :campaign_by_user, ->(campaign_id, user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(campaign_id:)
        .where(created_at: from_date..to_date)
        .where(contacts: { user_id: })
    }
    scope :campaign_completed, ->(campaign_id, from_date = 50.years.ago, to_date = Time.current) {
      where(campaign_id:)
        .where(completed: true)
        .where(created_at: from_date..to_date)
    }
    scope :campaign_completed_by_user, ->(campaign_id, user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(campaign_id:)
        .where(completed: true)
        .where(created_at: from_date..to_date)
        .where(contacts: { user_id: })
    }
    scope :campaigns, ->(client_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(created_at: from_date..to_date)
        .where(contacts: { client_id: })
    }
    scope :campaigns_by_user, ->(user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(created_at: from_date..to_date)
        .where(contacts: { user_id: })
    }
    scope :campaigns_completed, ->(client_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(completed: true)
        .where(created_at: from_date..to_date)
        .where(contacts: { client_id: })
    }
    scope :campaigns_completed_by_user, ->(user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(completed: true)
        .where(created_at: from_date..to_date)
        .where(contacts: { user_id: })
    }

    def stop(keep_triggeraction_ids: [])
      JsonLog.info 'Contacts::Campaign.stop', { id: self.id, keep_triggeraction_ids: }
      return unless keep_triggeraction_ids.is_a?(Array)

      dj_triggeraction_ids = Delayed::Job.where(contact_campaign_id: self.id).where.not(triggeraction_id: keep_triggeraction_ids).pluck(:triggeraction_id)
      DelayedJob.where(contact_campaign_id: self.id, triggeraction_id: dj_triggeraction_ids).destroy_all
      self.contact_campaign_triggeractions.where(contact_campaign_id: self.id, triggeraction_id: dj_triggeraction_ids).update_all(outcome: 'cancelled')
      self.update(completed: true)
    end

    private

    def after_create_commit_actions
      super

      self.campaign.update(last_started_at: self.created_at)
    end

    def trigger_contact
      self.contact.campaign_started(self.campaign) if self.campaign.present?
    end
  end
end
