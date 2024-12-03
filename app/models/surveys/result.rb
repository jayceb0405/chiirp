# frozen_string_literal: true

# app/models/surveys/result.rb
module Surveys
  class Result < ApplicationRecord
    self.table_name = 'survey_results'

    belongs_to :survey
    belongs_to :contact, optional: true

    store_accessor :data, :screen_results

    after_initialize :apply_defaults, if: :new_record?

    def self.title
      I18n.t('activerecord.models.survey_result.title')
    end

    private

    def apply_defaults
      self.screen_results ||= {}
    end
  end
end
