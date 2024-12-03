# frozen_string_literal: true

# app/models/surveys/screen.rb
module Surveys
  class Screen < ApplicationRecord
    self.table_name = 'survey_screens'

    has_one_attached :question_0_image
    has_one_attached :question_1_image
    has_one_attached :question_2_image
    has_one_attached :question_3_image
    has_one_attached :question_4_image

    belongs_to :survey

    store_accessor :data, :header, :sub_header, :question, :custom_field_id, :responses, :info, :facebook_event_code, :form_data, :form_fields, :actions

    validates :name, presence: true, length: { minimum: 2 }
    # rubocop:disable Rails/UniqueValidationWithoutIndex
    validates :screen_key, uniqueness: true
    # rubocop:enable Rails/UniqueValidationWithoutIndex

    after_initialize :apply_defaults, if: :new_record?

    # copy a Sueveys::Screen
    # screen.copy(new_survey_id, copied_campaigns)
    # (req) new_survey_id:    (Integer)
    # (req) copied_campaigns: (Hash) ex: { old_campaign_id => new_campaign_id, ... }
    def copy(new_survey_id, copied_campaigns)
      new_screen = nil

      return new_screen unless new_survey_id.to_i.positive? && (new_survey = Surveys::Survey.find_by(id: new_survey_id))

      new_screen = self.dup
      new_screen.survey_id  = new_survey.id
      new_screen.name       = "Copy of #{new_screen.name}" if new_survey.screens.find_by(name: new_screen.name)
      new_screen.screen_key = self.new_screen_key
      new_screen.hits       = 0

      if new_screen.save

        if self.survey.client_id != new_screen.survey.client_id && new_screen.screen_type == 'data'

          if new_screen.actions.dig('campaign_id').to_i.positive?

            new_screen.actions['campaign_id'] = if copied_campaigns.key?(new_screen.actions['campaign_id'])
                                                  copied_campaigns[new_screen.actions['campaign_id']]
                                                else
                                                  Campaign.find_by(id: new_screen.actions['campaign_id'])&.copy(new_client_id: self.survey.client_id)&.id.to_i
                                                end
          end

          new_screen.actions['group_id'] = Group.find_by(id: new_screen.actions['group_id'])&.copy(new_client_id: self.survey.client_id)&.id.to_i if new_screen.actions.dig('group_id').to_i.positive?
          new_screen.actions['stage_id'] = Stage.find_by(id: new_screen.actions['stage_id'])&.copy(new_client_id: self.survey.client_id)&.id.to_i if new_screen.actions.dig('stage_id').to_i.positive?
          new_screen.actions['tag_id'] = Tag.find_by(id: new_screen.actions['tag_id'])&.copy(new_client_id: self.survey.client_id)&.id.to_i if new_screen.actions.dig('tag_id').to_i.positive?
          new_screen.save
        end
      else
        new_screen = nil
      end

      new_screen
    end

    def new_screen_key
      screen_key   = RandomCode.new.create(20)
      screen_key   = RandomCode.new.create(20) while ::Surveys::Screen.find_by(screen_key:)

      screen_key
    end

    def self.title
      I18n.t('activerecord.models.survey_screen.title')
    end

    private

    def apply_defaults
      self.screen_key                         = self.new_screen_key if self.screen_key.blank?
      self.header                           ||= ''
      self.sub_header                       ||= ''
      self.question                         ||= ''
      self.custom_field_id                  ||= 0
      self.responses                        ||= {}
      self.info                             ||= ''
      self.facebook_event_code              ||= ''
      self.form_data                        ||= {}
      self.form_data['submit_button_text']  ||= 'Submit'
      self.form_data['ok2text_text']        ||= 'May We Send Text Messages?'
      self.form_data['ok2email_text']       ||= 'May We Send Email Messages?'
      self.form_data['disclaimer_text']     ||= ''
      self.form_fields                      ||= {}
      self.actions                          ||= {}
      self.actions['campaign_id']           ||= 0
      self.actions['group_id']              ||= 0
      self.actions['tag_id']                ||= 0
      self.actions['stage_id']              ||= 0
      self.actions['redirect_url']          ||= ''
      self.actions['redirect_screen_id']    ||= 0
    end
  end
end
