# frozen_string_literal: true

# app/models/campaign.rb
class Campaign < ApplicationRecord
  has_one_attached :marketplace_image

  belongs_to :client
  belongs_to :campaign_group,          optional: true
  belongs_to :client_attachment,       optional: true

  has_many   :aiagents,                dependent: :nullify
  has_one    :campaign_share_code,     dependent: :destroy
  has_many   :contact_campaigns,       dependent: nil, class_name: '::Contacts::Campaign'
  has_many   :package_campaigns,       dependent: :delete_all
  has_many   :stages,                  dependent: nil
  has_many   :tags,                    dependent: nil
  has_many   :tasks,                   dependent: nil
  has_many   :trackable_links,         dependent: nil
  has_many   :triggers,                dependent: :destroy

  has_many   :triggeractions, through: :triggers

  store_accessor :data, :allow_repeat_interval, :allow_repeat_period, :description

  validates :name, presence: true, length: { minimum: 1 }
  validate  :count_is_approved, on: [:create]

  after_initialize     :apply_defaults, if: :new_record?
  before_save          :before_save_actions

  scope :by_tenant, ->(tenant = 'chiirp') {
    joins(:client)
      .where(clients: { tenant: })
  }
  scope :keywords, ->(client_id) {
    joins(:triggers)
      .where(campaigns: { client_id: })
      .where(triggers: { trigger_type: 110 })
  }
  scope :with_trigger_type, -> {
    select('campaigns.*, triggers.trigger_type AS trigger_type')
      .left_outer_joins(:triggers)
      .where(triggers: { step_numb: [1, nil] })
      .includes(:campaign_share_code)
      .order(:trigger_type, :name)
  }
  scope :for_select, ->(client_id, sort_order = 'name', excluded_campaign_ids = [], first_trigger_types = [115, 120, 125, 130, 133, 134, 135, 137, 140, 145]) {
    where(client_id:)
      .where.not(id: excluded_campaign_ids)
      .joins(:triggers)
      .where(triggers: { trigger_type: first_trigger_types })
      .order(sort_order.to_sym)
      .distinct
  }
  scope :active_only, -> {
    where(active: true)
  }

  # analyze a Campaign for errors
  # returns a hash of errors
  #   [
  #     {trigger_id: Integer, triggeraction_id: Integer},
  #     {trigger_id: Integer, triggeraction_id: Integer}
  #   ]
  # result = campaign.analyze!
  def analyze!
    response = []

    response << { trigger_id: 0, triggeraction_id: 0, description: 'Triggers have NOT been created.' } if triggers.empty?

    triggers.each do |trigger|
      response += trigger.analyze!
    end

    response
  end

  # copy a Campaign
  # campaign.copy(new_client_id: Integer)
  def copy(args = {})
    new_client_id         = args.dig(:new_client_id).to_i
    new_campaign_group_id = args.dig(:new_campaign_group_id).to_i
    campaign_id_prefix    = args.dig(:campaign_id_prefix).to_s
    new_campaign          = nil

    if new_client_id.positive? && (new_client = Client.find_by(id: new_client_id))
      # create new Campaign
      new_campaign = self.dup
      new_campaign.name              = "Copy of #{new_campaign.name}" if new_client.campaigns.find_by(name: new_campaign.name)
      new_campaign.client_id         = new_client.id
      new_campaign.default_phone     = '' unless new_campaign.default_phone == 'user_number'
      new_campaign.marketplace       = false
      new_campaign.marketplace_ok    = false
      new_campaign.price             = 0
      new_campaign.marketplace_image.attach(self.marketplace_image.blob) if self.marketplace_image.attached?

      if new_campaign_group_id.positive?
        new_campaign.campaign_group_id = new_campaign_group_id
      elsif self.campaign_group_id.positive? && self.client_id != new_client_id
        # copy to new Client / create a new CampaignGroup if necessary
        new_campaign.campaign_group_id = (new_campaign_group = new_client.campaign_groups.find_by('name ILIKE ?', "%#{self.campaign_group.name}%")) ? new_campaign_group.id : 0
      end

      if new_campaign.save
        # create new Triggers
        self.triggers.order(:step_numb).each do |trigger|
          unless trigger.copy(new_campaign_id: new_campaign.id, campaign_id_prefix:)
            # new Trigger was NOT created
            new_campaign.destroy
            new_campaign = nil
            break
          end
        end

        new_campaign.update(analyzed: new_campaign.analyze!.empty?)
      else
        new_campaign = nil
      end
    end

    new_campaign
  end

  # return a locked phone number or empty string if not locked
  # campaign.get_lock_phone( contact: Contact )
  def get_lock_phone(args = {})
    contact  = args.dig(:contact)
    response = ''

    if contact.is_a?(Contact) && self.lock_phone

      response = case self.default_phone.to_s
                 when ''
                   # last number used
                   contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
                 when 'user_number'
                   # User's default number
                   contact.user.default_from_twnumber&.phonenumber.to_s
                 else
                   # specific phone number
                   self.default_phone.to_s
                 end
    end

    response
  end

  def marketplace?
    self.marketplace
  end

  def repeatable?(contact)
    (self.allow_repeat && (self.allow_repeat_period == 'immediately' || contact.contact_campaigns.where(campaign_id: self.id).where('created_at > ?', self.allow_repeat_interval.to_i.send(self.allow_repeat_period || 'days').ago).blank?)) || contact.contact_campaigns.find_by(campaign_id: self.id).nil?
  end

  def triggeraction_array
    Triggeraction.where(trigger_id: self.triggers.pluck(:id)).pluck(:id)
  end

  # validate that a campaign has locked the phone number and that a phone number matches the locked number
  # campaign.validate_lock_phone( contact: Contact, phone_number: String )
  def validate_lock_phone(args = {})
    !self.lock_phone || self.get_lock_phone(contact: args.dig(:contact)) == args.dig(:phone_number).to_s
  end

  private

  def after_create_commit_actions
    super

    self.create_campaign_share_code.save
  end

  def apply_defaults
    self.allow_repeat_interval ||= 0
    self.allow_repeat_period   ||= 'immediately'
    self.description           ||= ''
  end

  def before_save_actions
    self.analyzed = self.analyze!.empty?
  end

  # confirm that count is less than Client.campaigns_count setting
  # validate :count_is_approved
  def count_is_approved
    errors.add(:base, "Maximum Campaigns for #{self.client.name} has been met.") unless self.client.campaigns.count < self.client.campaigns_count
  end
end
