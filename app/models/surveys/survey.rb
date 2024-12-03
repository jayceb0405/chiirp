# frozen_string_literal: true

# app/models/surveys/survey.rb
module Surveys
  class Survey < ApplicationRecord
    has_one_attached :background_image
    has_one_attached :logo_image

    belongs_to :client

    has_many :screens, dependent: :destroy, class_name: '::Surveys::Screen'
    has_many :results, dependent: :destroy, class_name: '::Surveys::Result'

    store_accessor :data, :background_color, :facebook_pixel_base_code, :first_screen_id, :footer_links, :header_color, :page_domain, :page_name

    validates :name, presence: true, length: { minimum: 2 }
    validates :share_code, uniqueness: true
    validates :survey_key, uniqueness: true

    after_initialize :apply_defaults, if: :new_record?

    scope :all_page_names, ->(page_domain) {
      where('data @> ?', { page_domain: }.to_json)
        .filter_map(&:page_name)
    }

    # copy a Survey
    # survey.copy(new_client_id)
    # new_client_id: (Integer)
    def copy(new_client_id)
      new_survey = nil

      return new_survey unless new_client_id.to_i.positive? && (new_client = Client.find_by(id: new_client_id))

      begin
        ActiveRecord::Base.transaction do
          new_survey = self.dup
          new_survey.client_id                = new_client.id
          new_survey.name                     = "Copy of #{new_survey.name}" if new_client.surveys.find_by(name: new_survey.name)
          new_survey.facebook_pixel_base_code = '' unless new_client.id == self.client_id
          new_survey.first_screen_id          = 0
          new_survey.hits                     = 0
          new_survey.background_image.attach(self.background_image.blob) if self.background_image.attached?
          new_survey.logo_image.attach(self.logo_image.blob) if self.logo_image.attached?
          new_survey.share_code               = self.new_share_code
          new_survey.survey_key               = self.new_survey_key

          raise ActiveRecord::Rollback, "ActiveRecord::Rollback: Survey #{self.name} (#{self.id})" unless new_survey.save

          copied_campaigns = {}
          copied_screens   = {}

          self.screens.each do |screen|
            raise ActiveRecord::Rollback, "ActiveRecord::Rollback: Screen #{screen.name} (#{screen.id})" unless (new_screen = screen.copy(new_survey.id, copied_campaigns))

            copied_campaigns[screen.actions['campaign_id']] = new_screen.actions['campaign_id'] if self.client_id != new_survey.client_id && screen.screen_type == 'data'
            copied_screens[screen.id] = new_screen.id
            new_survey.first_screen_id = new_screen.id if self.first_screen_id == screen.id
          end

          new_survey.screens.each do |screen|
            case screen.screen_type
            when 'data', 'info'
              screen.actions['redirect_screen_id'] = copied_screens[screen.actions.dig('redirect_screen_id')].to_i
            when 'question'
              screen.responses.each { |k, v| screen.responses[k]['screen'] = copied_screens[v.dig('screen')].to_i }
            end

            screen.save
          end
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Surveys::Survey.copy')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params({ new_client_id: })

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            file: __FILE__,
            line: __LINE__
          )
        end

        new_survey = nil
      end

      new_survey
    end

    def landing_page_url
      # generate a url to this Survey as a landing page
      tenant_app_protocol = I18n.with_locale(self.client.tenant) { I18n.t('tenant.app_protocol') }
      tenant_domain       = I18n.with_locale(self.client.tenant) { I18n.t('tenant.domain') }
      tenant_app_host     = I18n.with_locale(self.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

      if self.page_domain.present? && self.page_name.present?
        "#{tenant_app_protocol}://#{if Rails.env.production?
                                      self.page_domain == tenant_domain ? 'app' : 'www'
                                    else
                                      'dev'
                                    end}.#{self.page_domain}/surveys/#{self.page_name}"
      else
        Rails.application.routes.url_helpers.survey_url(self.survey_key, 0, host: tenant_app_host, protocol: tenant_app_protocol)
      end
    end

    def new_share_code
      share_code = RandomCode.new.create(20)
      share_code = RandomCode.new.create(20) while ::Surveys::Survey.find_by(share_code:)

      share_code
    end

    def new_survey_key
      survey_key   = RandomCode.new.create(20)
      survey_key   = RandomCode.new.create(20) while ::Surveys::Survey.find_by(survey_key:)

      survey_key
    end

    def self.title
      I18n.t('activerecord.models.survey.title')
    end

    private

    def apply_defaults
      self.background_color         ||= ''
      self.facebook_pixel_base_code ||= ''
      self.first_screen_id          ||= 0
      self.footer_links             ||= { label_01: '', link_01: '', label_02: '', link_02: '', label_03: '', link_03: '' }
      self.header_color             ||= ''
      self.page_domain              ||= ''
      self.page_name                ||= ''
      self.share_code                 = self.new_share_code if self.share_code.blank?
      self.survey_key                 = self.new_survey_key if self.survey_key.blank?
    end
  end
end
