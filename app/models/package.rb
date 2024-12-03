# frozen_string_literal: true

# app/models/package.rb
class Package < ApplicationRecord
  has_one_attached :join_form_image

  belongs_to :affiliate, class_name: 'Affiliates::Affiliate', optional: true

  has_many :package_pages_01, dependent: nil, class_name: 'PackagePage', foreign_key: :package_01_id, inverse_of: :package_01
  has_many :package_pages_02, dependent: nil, class_name: 'PackagePage', foreign_key: :package_02_id, inverse_of: :package_02
  has_many :package_pages_03, dependent: nil, class_name: 'PackagePage', foreign_key: :package_03_id, inverse_of: :package_03
  has_many :package_pages_04, dependent: nil, class_name: 'PackagePage', foreign_key: :package_04_id, inverse_of: :package_04

  has_many :clients, dependent: :nullify

  has_many :package_campaigns, dependent: :delete_all
  has_many :campaigns,         through: :package_campaigns

  # Package Settings
  store_accessor :package_data, :credit_charge, :dlc10_required, :dlc10_charged,
                 :first_payment_delay_days, :first_payment_delay_months,
                 :max_phone_numbers, :mo_charge, :mo_credits,
                 :promo_credit_charge, :promo_max_phone_numbers, :promo_mo_charge, :promo_mo_credits, :promo_months, :searchlight_fee, :setup_fee,
                 :trial_credits, :campaign_id, :group_id, :tag_id, :stage_id, :stop_campaign_ids

  # Package Features
  store_accessor :package_data, :campaigns_count, :custom_fields_count, :folders_count, :groups_count, :import_contacts_count, :integrations_allowed,
                 :max_contacts_count, :max_email_templates, :max_kpis_count, :max_users_count, :max_voice_recordings, :message_central_allowed, :my_contacts_allowed, :my_contacts_group_actions_all_allowed,
                 :phone_call_credits, :phone_calls_allowed, :quick_leads_count, :rvm_allowed, :rvm_credits,
                 :share_email_templates_allowed, :share_funnels_allowed, :share_quick_leads_allowed, :share_surveys_allowed, :share_widgets_allowed, :share_stages_allowed, :stages_count, :surveys_count,
                 :tasks_allowed, :text_image_credits, :text_message_credits, :text_message_images_allowed, :text_segment_charge_type, :trackable_links_count, :training,
                 :user_chat_allowed, :video_call_credits, :video_calls_allowed, :widgets_count

  # AI Agent features
  store_accessor :package_data, :aiagent_base_charge, :aiagent_included_count, :aiagent_overage_charge, :aiagent_message_credits, :aiagent_trial_period_days, :aiagent_trial_period_months, :share_aiagents_allowed

  # Task Actions
  store_accessor :package_data, :task_actions

  # Agencies
  store_accessor :package_data, :agency_ids

  validates :name, presence: true, length: { minimum: 3 }
  validates :tenant, presence: true

  after_initialize :apply_defaults, if: :new_record?

  scope :persistent, -> { where(onetime: false) }
  scope :onetime, -> { where(onetime: true) }
  scope :expired, -> { where(expired_on: ...Date.current) }

  def belongs_to_package_page?
    PackagePage.where(package_01_id: self.id).or(PackagePage.where(package_02_id: self.id)).or(PackagePage.where(package_03_id: self.id)).or(PackagePage.where(package_04_id: self.id)).present?
  end

  def copy
    response = nil

    # create new Package
    new_package = self.dup
    new_package.name              = "Copy of #{new_package.name}" if Package.find_by(name: new_package.name)
    new_package.package_key       = ''
    new_package.set_package_key

    response = new_package if new_package.save

    response
  end

  def last_promo_payment_date(effective_date = Time.current)
    effective_date + (self.promo_months - 1).months
  end

  # determines if Package requires a credit card
  # @package.requires_credit_card?
  def requires_credit_card?
    (self.promo_mo_charge.to_d + self.mo_charge.to_d + self.setup_fee.to_d).positive?
  end

  def set_package_key
    self.package_key = RandomCode.new.create(20) unless self.package_key.to_s.length == 20
    self.package_key = RandomCode.new.create(20) while Package.find_by(package_key: self.package_key)
  end

  def within_promo_period?(effective_date = Time.current)
    Time.current < self.last_promo_payment_date(effective_date) + 1.month
  end

  private

  def after_destroy_commit_actions
    super

    # rubocop:disable Rails/SkipsModelValidations
    PackagePage.where(package_01_id: self.id).update_all(package_01_id: 0)
    PackagePage.where(package_02_id: self.id).update_all(package_02_id: 0)
    PackagePage.where(package_03_id: self.id).update_all(package_03_id: 0)
    PackagePage.where(package_04_id: self.id).update_all(package_04_id: 0)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def apply_defaults
    self.text_message_credits                           ||= BigDecimal(2)
    self.text_image_credits                             ||= BigDecimal(2)
    self.phone_call_credits                             ||= BigDecimal(2)
    self.video_call_credits                             ||= BigDecimal(3)
    self.rvm_credits                                    ||= BigDecimal(4)

    # settings
    self.campaign_id                                    ||= 0
    self.credit_charge                                  ||= BigDecimal('0.04')
    self.dlc10_charged                                  ||= self.dlc10_charged.nil? ? true : self.dlc10_charged
    self.first_payment_delay_days                       ||= 0
    self.first_payment_delay_months                     ||= 0
    self.group_id                                       ||= 0
    self.max_phone_numbers                              ||= 1 # existing
    self.mo_charge                                      ||= BigDecimal(0)
    self.mo_credits                                     ||= BigDecimal(0)
    self.promo_credit_charge                            ||= BigDecimal('0.04')
    self.promo_max_phone_numbers                        ||= 0
    self.promo_mo_charge                                ||= BigDecimal(0)
    self.promo_mo_credits                               ||= BigDecimal(0)
    self.promo_months                                   ||= 0
    self.searchlight_fee                                ||= BigDecimal(0)
    self.setup_fee                                      ||= BigDecimal(0)
    self.stage_id                                       ||= 0
    self.stop_campaign_ids                              ||= []
    self.tag_id                                         ||= 0
    self.trial_credits                                  ||= BigDecimal(0)

    # features
    self.aiagent_base_charge                            ||= 200.0
    self.aiagent_included_count                         ||= 4
    self.aiagent_overage_charge                         ||= 25.0
    self.aiagent_message_credits                        ||= 1.0
    self.aiagent_trial_period_days                      ||= 0
    self.aiagent_trial_period_months                    ||= 3
    self.dlc10_required                                 ||= self.dlc10_required.nil? ? true : self.dlc10_required
    self.share_aiagents_allowed                         ||= self.share_aiagents_allowed.nil? ? true : self.share_aiagents_allowed
    self.campaigns_count                                ||= 0
    self.quick_leads_count                              ||= 0
    self.widgets_count                                  ||= 0
    self.trackable_links_count                          ||= 0
    self.custom_fields_count                            ||= 0
    self.folders_count                                  ||= 0
    self.groups_count                                   ||= 0
    self.stages_count                                   ||= 0
    self.surveys_count                                  ||= 0
    self.share_surveys_allowed                            = self.share_surveys_allowed.nil? ? false : self.share_surveys_allowed
    self.import_contacts_count                          ||= 0
    self.max_voice_recordings                           ||= 0 # existing
    self.message_central_allowed                          = self.message_central_allowed.nil? ? false : self.message_central_allowed
    self.my_contacts_allowed                              = self.my_contacts_allowed.nil? ? false : self.my_contacts_allowed
    self.text_message_images_allowed                      = self.text_message_images_allowed.nil? ? false : self.text_message_images_allowed
    self.phone_calls_allowed                              = self.phone_calls_allowed.nil? ? false : self.phone_calls_allowed
    self.rvm_allowed                                      = self.rvm_allowed.nil? ? false : self.rvm_allowed
    self.video_calls_allowed                              = self.video_calls_allowed.nil? ? false : self.video_calls_allowed
    self.share_aiagents_allowed                           = self.share_aiagents_allowed.nil? ? false : self.share_aiagents_allowed
    self.share_email_templates_allowed                    = self.share_email_templates_allowed.nil? ? false : self.share_email_templates_allowed
    self.share_funnels_allowed                            = self.share_funnels_allowed.nil? ? false : self.share_funnels_allowed
    self.share_quick_leads_allowed                        = self.share_quick_leads_allowed.nil? ? false : self.share_quick_leads_allowed
    self.share_widgets_allowed                            = self.share_widgets_allowed.nil? ? false : self.share_widgets_allowed
    self.share_stages_allowed                             = self.share_stages_allowed.nil? ? false : self.share_stages_allowed
    self.my_contacts_group_actions_all_allowed            = self.my_contacts_group_actions_all_allowed.nil? ? false : self.my_contacts_group_actions_all_allowed
    self.max_email_templates                            ||= 0
    self.max_contacts_count                             ||= 100
    self.max_kpis_count                                 ||= 0
    self.max_users_count                                ||= 1
    self.text_segment_charge_type                       ||= 0
    self.user_chat_allowed                                = self.user_chat_allowed.nil? ? false : self.user_chat_allowed
    self.tasks_allowed                                    = self.tasks_allowed.nil? ? false : self.tasks_allowed
    self.task_actions                                   ||= {}
    self.task_actions['assigned']                       ||= {}
    self.task_actions['assigned']['campaign_id']        ||= 0
    self.task_actions['assigned']['group_id']           ||= 0
    self.task_actions['assigned']['tag_id']             ||= 0
    self.task_actions['assigned']['stage_id']           ||= 0
    self.task_actions['assigned']['stop_campaign_ids']  ||= []
    self.task_actions['due']                            ||= {}
    self.task_actions['due']['campaign_id']             ||= 0
    self.task_actions['due']['group_id']                ||= 0
    self.task_actions['due']['tag_id']                  ||= 0
    self.task_actions['due']['stage_id'] ||= 0
    self.task_actions['due']['stop_campaign_ids']       ||= []
    self.task_actions['deadline']                       ||= {}
    self.task_actions['deadline']['campaign_id']        ||= 0
    self.task_actions['deadline']['group_id']           ||= 0
    self.task_actions['deadline']['tag_id']             ||= 0
    self.task_actions['deadline']['stage_id']           ||= 0
    self.task_actions['deadline']['stop_campaign_ids']  ||= []
    self.task_actions['completed']                      ||= {}
    self.task_actions['completed']['campaign_id']       ||= 0
    self.task_actions['completed']['group_id']          ||= 0
    self.task_actions['completed']['tag_id']            ||= 0
    self.task_actions['completed']['stage_id']          ||= 0
    self.task_actions['completed']['stop_campaign_ids'] ||= []

    self.integrations_allowed                           ||= []
    self.training                                       ||= []

    self.agency_ids                                     ||= []

    self.tenant                                         ||= I18n.locale.to_s

    self.set_package_key if self.package_key.blank?
  end
end
