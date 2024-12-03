# frozen_string_literal: true

# app/models/user_contact_form.rb
class UserContactForm < ApplicationRecord
  has_one_attached :logo_image
  has_one_attached :background_image
  has_one_attached :marketplace_image

  belongs_to :campaign, optional: true
  belongs_to :group,    optional: true
  belongs_to :stage,    optional: true
  belongs_to :tag,      optional: true
  belongs_to :user

  store_accessor :formatting, :ok2text, :ok2text_text, :ok2email, :ok2email_text,
                 :submit_button_text, :header_text, :tag_line, :youtube_video,
                 :submit_button_color, :header_bg_color, :body_bg_color, :form_bg_color,
                 :template, :version, :description, :head_string, :script_string, :selectable_campaign_ids, :selectable_campaign_label

  serialize :form_fields, coder: YAML, type: Hash

  validates :form_name, presence: true, length: { minimum: 5 }
  validate  :count_is_approved, on: [:create]
  # rubocop:disable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  validates :page_name, uniqueness: { scope: :page_domain, allow_blank: true, message: 'already exists for that domain' }
  validates :page_name, exclusion: { in: %w[central client client_statistics clients dashboard mycontacts my_contacts mywebhooks packagemanager packagepages quickleads sitechat tasks tl trackablelinks messages user vid voicerecordings], message: '%{value} is reserved.' }
  # rubocop:enable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts

  after_initialize     :apply_defaults
  after_initialize     :apply_new_record_data, if: :new_record?

  scope :all_page_names, ->(page_domain) {
    where(page_domain:)
      .pluck(:page_name).compact
  }
  scope :by_tenant, ->(tenant = 'chiirp') {
    joins({ user: :client })
      .where(clients: { tenant: })
  }

  # return array of available domains for QuickPages
  # UserContactForm.available_domains(client: Client)
  def self.available_domains(args = {})
    client   = args.dig(:client)
    response = []

    if client.is_a?(Client)
      response  = ENV.fetch('user_contact_form_domains', nil)
      response  = response.split(',').map { |domain| domain.include?('.') ? domain : "#{domain}.com" } + client.domains.keys
    end

    response
  end

  # copy a UserContactForm
  # user_contact_form.copy(new_user_id: Integer)
  def copy(args = {})
    new_user_id           = args.dig(:new_user_id).to_i
    new_user_contact_form = nil

    if new_user_id.positive? && (new_user = User.find_by(id: new_user_id))
      # create new UserContactForm
      new_user_contact_form = self.dup
      new_user_contact_form.form_name        = "Copy of #{new_user_contact_form.form_name}" while new_user.user_contact_forms.find_by(form_name: new_user_contact_form.form_name)
      new_user_contact_form.user_id          = new_user.id
      new_user_contact_form.campaign_id      = 0
      new_user_contact_form.tag_id           = 0
      new_user_contact_form.marketplace      = false
      new_user_contact_form.marketplace_ok   = false
      new_user_contact_form.price            = 0
      new_user_contact_form.page_domain      = ''
      new_user_contact_form.page_name        = ''
      new_user_contact_form.background_image.attach(self.background_image.blob) if self.background_image.attached?
      new_user_contact_form.marketplace_image.attach(self.marketplace_image.blob) if self.marketplace_image.attached?
      new_user_contact_form.logo_image.attach(self.logo_image.blob) if self.logo_image.attached?
      new_user_contact_form.new_page_key
      new_user_contact_form.new_share_code

      new_user_client_field_list = ::Webhook.internal_key_hash(new_user_contact_form.user.client, 'contact', %w[personal phones custom_fields])

      self.form_fields.each do |key, value|
        unless new_user_client_field_list.key?(key)
          # copied field is not in new User's Client's fields

          if value['show'].to_i == 1 && (client_custom_field = self.user.client.client_custom_fields.find_by(var_var: key))
            # this UserContactForm uses the field / add the field
            # original ClientCustomField was found / add the keys
            new_client_custom_field = client_custom_field.dup
            new_client_custom_field.client_id     = self.user.client_id
            new_client_custom_field.var_important = false

            unless new_client_custom_field.save
              # new ClientCustomField.was NOT saved
              new_user_contact_form.form_fields.delete(key)
            end
          else
            # this UserContactForm does not use the field / delete it
            new_user_contact_form.form_fields.delete(key)
          end
        end
      end

      new_user_contact_form.save
    end

    new_user_contact_form
  end

  # generate a url to this UserContactForm as a landing page
  # user_contact_form.landing_page_url
  def landing_page_url
    tenant_app_protocol = I18n.with_locale(self.user.client.tenant) { I18n.t('tenant.app_protocol') }
    tenant_domain       = I18n.with_locale(self.user.client.tenant) { I18n.t('tenant.domain') }
    tenant_app_host     = I18n.with_locale(self.user.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

    if self.page_domain.present? && self.page_name.present?
      "#{tenant_app_protocol}://#{if Rails.env.production?
                                    self.page_domain == tenant_domain ? 'app' : 'www'
                                  else
                                    'dev'
                                  end}.#{self.page_domain}/#{self.page_name}"
    else
      Rails.application.routes.url_helpers.api_v3_user_contact_form_page_url(self.page_key, host: tenant_app_host, protocol: tenant_app_protocol)
    end
  end

  # change the page_key
  # user_contact_form.new_page_key
  def new_page_key
    self.page_key   = RandomCode.new.create(20)
    self.page_key   = RandomCode.new.create(20) while UserContactForm.find_by_page_key(self.page_key)
  end

  # change the share_code
  # user_contact_form.new_share_code
  def new_share_code
    self.share_code = RandomCode.new.create(20)
    self.share_code = RandomCode.new.create(20) while UserContactForm.find_by_share_code(self.share_code)
  end

  private

  def apply_defaults
    self.submit_button_text        ||= 'Submit'
    self.submit_button_color       ||= '#007bff'
    self.ok2text                   ||= '1'
    self.ok2text_text              ||= 'May We Send Text Messages?'
    self.ok2email                  ||= '1'
    self.ok2email_text             ||= 'May We Send Email Messages?'
    self.header_bg_color           ||= '#ffffff'
    self.body_bg_color             ||= '#ffffff'
    self.form_bg_color             ||= '#f8f9fa'
    self.tag_line                  ||= ''
    self.youtube_video             ||= ''
    self.template                  ||= ''
    self.version                   ||= 3
    self.description               ||= ''
    self.head_string               ||= ''
    self.script_string             ||= ''
    self.selectable_campaign_ids   ||= []
    self.selectable_campaign_label ||= ''
  end

  def apply_new_record_data
    self.form_fields = {}
    self.new_page_key
    self.new_share_code
  end

  def count_is_approved
    errors.add(:base, "Maximum QuickPages for #{self.user.client.name} has been met.") unless self.user.user_contact_forms.count < self.user.client.quick_leads_count.to_i
  end
end
