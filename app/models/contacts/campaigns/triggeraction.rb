# frozen_string_literal: true

# app/models/contacts/campaigns/triggeraction.rb
module Contacts
  module Campaigns
    class Triggeraction < ApplicationRecord
      self.table_name = 'contact_campaign_triggeractions'

      belongs_to :contact_campaign, class_name: '::Contacts::Campaign'
      belongs_to :triggeraction,    class_name: '::Triggeraction'

      has_many :delayed_jobs, through: :contact_campaign
      has_one  :trigger,      through: :triggeraction
      has_one  :campaign,     through: :contact_campaign

      # outcome may be filled with scheduled, completed, cancelled

      # Contacts::Campaigns::Triggeraction.cancelled()
      #   (req) contact_campaign_id: (Integer)
      #   (req) triggeraction_id:    (Integer)
      def self.cancelled(contact_campaign_id, triggeraction_id)
        return unless contact_campaign_id.to_i.positive? && triggeraction_id.to_i.positive? && (contact_campaign_triggeraction = Contacts::Campaigns::Triggeraction.find_by(contact_campaign_id:, triggeraction_id:))

        contact_campaign_triggeraction.update(outcome: 'cancelled')
      end

      # Contacts::Campaigns::Triggeraction.completed()
      #   (req) contact_campaign_id: (Integer)
      #   (req) triggeraction_id:    (Integer)
      def self.completed(contact_campaign_id, triggeraction_id)
        return unless contact_campaign_id.to_i.positive? && triggeraction_id.to_i.positive? && (contact_campaign_triggeraction = Contacts::Campaigns::Triggeraction.find_by(contact_campaign_id:, triggeraction_id:))

        contact_campaign_triggeraction.update(outcome: 'completed')
      end

      private

      def after_create_commit_actions
        super

        update_contact_campaign_completed
      end

      def after_destroy_commit_actions
        super

        update_contact_campaign_completed
      end

      def after_update_commit_actions
        super

        update_contact_campaign_completed
      end

      def update_contact_campaign_completed
        self.contact_campaign.update(completed: true) if (self.campaign.triggeraction_array - self.contact_campaign.contact_campaign_triggeractions.pluck(:triggeraction_id)).empty? && self.contact_campaign.contact_campaign_triggeractions.find_by(outcome: 'scheduled').nil?
      end
    end
  end
end
