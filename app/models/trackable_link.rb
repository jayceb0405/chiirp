# frozen_string_literal: true

# app/models/trackable_link.rb
class TrackableLink < ApplicationRecord
  belongs_to :client
  belongs_to :campaign, optional: true
  belongs_to :group,    optional: true
  belongs_to :stage,    optional: true
  belongs_to :tag,      optional: true

  has_many :trackable_short_links, dependent: :destroy
  has_many :trackable_links_hits,  through: :trackable_short_links

  validate :count_is_approved, on: [:create]

  # create a relation of Contacts who received the TrackableLink
  # TrackableLink.contacts_delivered(trackable_link_id, from_time, to_time)
  scope :contacts_delivered, ->(trackable_link_id, from_date, to_date) {
    Contact.joins(:trackable_short_links)
           .where(trackable_short_links: { trackable_link_id: })
           .where(trackable_short_links: { created_at: [from_date..to_date] })
           .group(:id)
  }
  scope :contacts_delivered_by_user, ->(trackable_link_id, user_id, from_date, to_date) {
    Contact.joins(:trackable_short_links)
           .where(contacts: { user_id: })
           .where(trackable_short_links: { trackable_link_id: })
           .where(trackable_short_links: { created_at: [from_date..to_date] })
           .group(:id)
  }
  # create a relation of Contacts who clicked the TrackableLink
  # TrackableLink.contacts_clicked(trackable_link_id, from_time, to_time)
  scope :contacts_clicked, ->(trackable_link_id, from_date, to_date) {
    Contact.joins(:trackable_short_links)
           .joins(trackable_short_links: :trackable_links_hits)
           .where(trackable_links_hits: { created_at: [from_date..to_date] })
           .where(trackable_short_links: { trackable_link_id: })
           .group(:id)
  }
  scope :contacts_clicked_by_user, ->(trackable_link_id, user_id, from_date, to_date) {
    Contact.joins(:trackable_short_links)
           .joins(trackable_short_links: :trackable_links_hits)
           .where(contacts: { user_id: })
           .where(trackable_links_hits: { created_at: [from_date..to_date] })
           .where(trackable_short_links: { trackable_link_id: })
           .group(:id)
  }
  scope :by_tenant, ->(tenant = 'chiirp') {
    joins(:client)
      .where(clients: { tenant: })
  }
  scope :delivered_to_contact, ->(contact_id) {
    Contact.joins(:trackable_short_links)
           .where(contacts: { id: contact_id })
  }
  scope :clicked_by_contact, ->(contact_id) {
    Contact.joins(:trackable_short_links)
           .joins(trackable_short_links: :trackable_links_hits)
           .where(contacts: { id: contact_id })
  }

  def copy(args = {})
    # copy TrackableLink
    new_client         = args.dig(:new_client)
    campaign_id_prefix = args.dig(:campaign_id_prefix).to_s
    new_trackable_link = nil

    if (new_client.is_a?(Client) && !new_client.new_record?) || (new_client.to_i.positive? && (new_client = Client.find_by(id: new_client.to_i)))

      if self.client_id != new_client.id

        unless (new_trackable_link = new_client.trackable_links.find_by(original_url: self.original_url))
          new_trackable_link = self.dup
          new_trackable_link.client_id = new_client.id
        end

        # update the Tag
        new_trackable_link.tag_id = if self.tag_id.positive? && (tag = Tag.find_by(id: self.tag_id)) && (new_tag = tag.copy(new_client_id: new_client.id))
                                      new_tag.id
                                    else
                                      0
                                    end

        # update the Group
        new_trackable_link.group_id = if self.group_id.positive? && (group = Group.find_by(id: self.group_id)) && (new_group = group.copy(new_client_id: new_client.id))
                                        new_group.id
                                      else
                                        0
                                      end

        # update the Stage
        new_trackable_link.stage_id = if self.stage_id.positive? && (stage = Stage.find_by(id: self.stage_id)) && (new_stage = stage.copy(new_client:))
                                        new_stage.id
                                      else
                                        0
                                      end

        # update the Campaign
        if self.campaign_id.positive?
          # Campaign can NOT be copied to a new Client
          # rubocop:disable Style/StringConcatenation
          new_trackable_link.original_url += '#{' + campaign_id_prefix + new_trackable_link.campaign_id.to_s.strip + '}' if campaign_id_prefix.present?
          # rubocop:enable Style/StringConcatenation
          new_trackable_link.campaign_id   = 0
        end
      end

      new_trackable_link = nil unless new_trackable_link.save
    end

    new_trackable_link
  end

  def create_short_url(contact)
    tsl = self.trackable_short_links.create(contact_id: contact.id)

    tenant_mini_domain  = JSON.parse(ENV.fetch('mini_domain', nil)).symbolize_keys[self.client.tenant.to_sym]
    # tenant_mini_domain  = I18n.with_locale(self.client.tenant) do I18n.t("tenant.#{Rails.env}.mini_domain") end
    tenant_app_protocol = I18n.with_locale(self.client.tenant) { I18n.t('tenant.app_protocol') }

    "#{tenant_app_protocol}://#{tenant_mini_domain}/#{tsl.short_code}"
  end

  private

  def count_is_approved
    # confirm that count is less than Client.trackable_links_count setting
    #
    # Example:
    # 	validate :count_is_approved
    #
    # Required Parameters:
    # 	none
    #
    # Optional Parameters:
    #   none
    #
    errors.add(:base, "Maximum Trackable Links for #{self.client.name} has been met.") unless self.client.trackable_links.count < self.client.trackable_links_count.to_i
  end
end
