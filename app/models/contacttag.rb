# frozen_string_literal: true

# app/models/contacttag.rb
class Contacttag < ApplicationRecord
  belongs_to :contact
  belongs_to :tag

  # rubocop:disable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  validates :tag, uniqueness: { scope: :contact, message: 'may only be applied once per Contact' }
  # rubocop:enable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts

  before_destroy :destroy_data

  scope :by_client_and_period, ->(client_id, from_date, to_date) {
    joins(:tag)
      .where(tags: { client_id: })
      .where(created_at: from_date..to_date)
  }
  scope :by_tag_and_period, ->(tag_id, from_date, to_date) {
    joins(:tag)
      .where(tags: { id: tag_id })
      .where(created_at: from_date..to_date)
  }
  scope :by_tag_and_user_and_period, ->(tag_id, user_id, from_date, to_date) {
    joins(:tag)
      .joins(:contact)
      .where(contacts: { user_id: })
      .where(tags: { id: tag_id })
      .where(created_at: from_date..to_date)
  }
  scope :by_user_and_period, ->(user_id, from_date, to_date) {
    joins(:tag)
      .joins(:contact)
      .where(contacts: { user_id: })
      .where(created_at: from_date..to_date)
  }

  private

  def after_create_commit_actions
    super

    self.contact.send_to_zapier(action: 'receive_new_tag', tag_data: { tag_id: self.tag.id, tag: self.tag.name })
    self.contact.send_to_xencall(tag_id: self.tag_id)
    process_tag_actions
  end

  def after_destroy_commit_actions
    super

    return unless @destroyed_tag_id_was.to_i.positive? && @destroyed_tag_id_contact_id_was.to_i.positive?

    contact = Contact.find_by(id: @destroyed_tag_id_contact_id_was.to_i)
    tag     = Tag.find_by(id: @destroyed_tag_id_was.to_i)

    return unless contact && tag

    contact.send_to_zapier(action: 'receive_remove_tag', tag_data: { tag_id: tag.id, tag: tag.name })
  end

  def after_update_commit_actions
    super

    return if self.previous_changes.blank?

    process_tag_actions
  end

  def process_tag_actions
    # process actions on Contact defined by Tag
    self.contact.process_actions(
      campaign_id:       self.tag.campaign_id,
      group_id:          self.tag.group_id,
      stage_id:          self.tag.stage_id,
      tag_id:            self.tag.tag_id,
      stop_campaign_ids: self.tag.stop_campaign_ids
    )

    # Dope Marketing
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'dope_marketing', name: '')) &&
       client_api_integration.automations.map(&:symbolize_keys).map { |automation| automation.dig(:tag_id) }&.include?(self.tag_id)

      Integration::Dope::V1::Dope.delay(
        priority:   DelayedJob.job_priority('dope_tag_applied'),
        queue:      DelayedJob.job_queue('dope_tag_applied'),
        contact_id: self.contact_id,
        process:    'dope_tag_applied',
        data:       { contact_id: self.contact_id, tag_id: self.tag_id }
      ).start_automation(contact_id: self.contact_id, tag_id: self.tag_id)
    end

    # Five9
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'five9', name: '')) &&
       client_api_integration.lists.deep_symbolize_keys.find { |_key, value| value[:tag_id] == self.tag_id }

      Integration::Five9::Base.new(client_api_integration).delay(
        priority:   DelayedJob.job_priority('five9_tag_applied'),
        queue:      DelayedJob.job_queue('five9_tag_applied'),
        contact_id: self.contact_id,
        process:    'five9_tag_applied',
        data:       { contacttag_id: self.id }
      ).call(:tag_applied, { contacttag: self })
    end

    # Housecall Pro
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'housecall', name: '')) &&
       client_api_integration.push_leads_tag_id == self.tag_id

      Integration::Housecallpro::V1::Base.new(client_api_integration).delay(
        priority:   DelayedJob.job_priority('housecallpro_tag_applied'),
        queue:      DelayedJob.job_queue('housecallpro_tag_applied'),
        contact_id: self.contact_id,
        process:    'housecallpro_tag_applied',
        data:       { contacttag_id: self.id }
      ).tag_applied(self)
    end

    # Jobber
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'jobber', name: '')) &&
       client_api_integration.data.dig('credentials', 'version').present? && client_api_integration.push_contacts_tag_id == self.tag_id

      "Integration::Jobber::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration).delay(
        priority:   DelayedJob.job_priority('jobber_tag_applied'),
        queue:      DelayedJob.job_queue('jobber_tag_applied'),
        contact_id: self.contact_id,
        process:    'jobber_tag_applied',
        data:       { contacttag_id: self.id }
      ).tag_applied(contacttag: self)
    end

    # JobNimbus
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'jobnimbus', name: '')) &&
       client_api_integration.push_contacts_tag_id == self.tag_id

      Integrations::Jobnimbus::V1::Tags::AppliedJob.set(wait_until: 1.day.from_now).perform_later(
        client_id:     client_api_integration.client_id,
        contact_id:    self.contact_id,
        contacttag_id: self.id
      )
    end

    # SendJim
    if ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'sendjim', name: '')
      Integration::Sendjim::V3::Sendjim.delay(
        priority:   DelayedJob.job_priority('sendjim_tag_applied'),
        queue:      DelayedJob.job_queue('sendjim_tag_applied'),
        contact_id: self.contact_id,
        process:    'sendjim_tag_applied',
        data:       { contacttag_id: self.id }
      ).push_tag_applied(contacttag: self)
      # Integration::Sendjim::V3::Sendjim.push_tag_applied(contacttag: self)
    end

    # ServiceMonster
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'servicemonster', name: '')) &&
       client_api_integration.push_leads_tag_id == self.tag_id

      Integration::Servicemonster.delay(
        priority:   DelayedJob.job_priority('servicemonster_tag_applied'),
        queue:      DelayedJob.job_queue('servicemonster_tag_applied'),
        contact_id: self.contact_id,
        process:    'servicemonster_tag_applied',
        data:       { contacttag_id: self.id }
      ).tag_applied(contacttag: self)
    end

    # ServiceTitan
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'servicetitan', name: '')) &&
       client_api_integration.push_contacts.present?
      Integration::Servicetitan::V2::Base.new(client_api_integration).delay(
        priority:   DelayedJob.job_priority('servicetitan_tag_applied'),
        queue:      DelayedJob.job_queue('servicetitan_tag_applied'),
        contact_id: self.contact_id,
        process:    'servicetitan_tag_applied',
        data:       { contacttag_id: self.id }
      ).push_tag_applied(self)
    end

    # Successware
    if (client_api_integration = ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'successware', name: '')) &&
       client_api_integration.data.dig('credentials', 'version').present? && client_api_integration.push_contact_tags.find { |pct| pct.dig('tag_id') == self.tag_id }

      "Integration::Successware::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration).delay(
        priority:   DelayedJob.job_priority('integration_successware_tag_applied'),
        queue:      DelayedJob.job_queue('integration_successware_tag_applied'),
        contact_id: self.contact_id,
        process:    'integration_successware_tag_applied',
        data:       { contacttag_id: self.id }
      ).tag_applied(contacttag: self)
    end
  end

  def destroy_data
    @destroyed_tag_id_was            = self.tag_id
    @destroyed_tag_id_contact_id_was = self.contact_id
  end
end
