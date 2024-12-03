# frozen_string_literal: true

# app/presenters/surveys/presenter.rb
module Surveys
  class Presenter
    attr_reader :client, :client_custom_field, :survey_screen, :survey

    def initialize(args = {})
      self.client        = args.dig(:client)
      self.survey        = args[:survey] if args.dig(:survey)
      self.survey_screen = args[:survey_screen] if args.dig(:survey_screen)

      @surveys             = nil
      @survey_screens      = nil
      @client_custom_field = nil
    end

    def client=(client)
      @client = case client
                when Client
                  client
                when Integer
                  Client.find_by(id: client)
                end
    end

    def client_custom_field=(id)
      @client_custom_field = id.present? ? self.client.client_custom_fields.find_by(id:) : self.client.client_custom_fields.new

      return unless @client_custom_field.new_record?

      @client_custom_field.id          = id
      @client_custom_field.var_type    = 'string'
      @client_custom_field.var_options = {}
    end

    def field_selection
      ::Webhook.internal_key_hash(self.client, 'contact', %w[personal ext_references]).invert.to_a + [['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(self.client, 'contact', %w[phones]).merge(self.client.client_custom_fields.pluck(:id, :var_name).to_h).invert.to_a
    end

    def form_fields
      form_fields = ::Webhook.internal_key_hash(self.client, 'contact', %w[personal phones custom_fields])

      form_fields.each do |key, value|
        form_fields[key] = { 'name' => value }

        if (ff = self.survey_screen.form_fields&.dig(key))

          ff.each do |k, v|
            form_fields[key][k] = v
          end
        else
          form_fields[key]['order']    = form_fields.length.to_s
          form_fields[key]['show']     = '0'
          form_fields[key]['required'] = '0'
        end
      end

      form_fields = form_fields.sort_by { |_key, value| value['order'].to_i }.to_h
    end

    def options_for_first_screen_id
      @survey.screens.order(:name).pluck(:name, :id)
    end

    def screen_types_for_select
      [['Question Screen', 'question'], ['Info Screen', 'info'], ['Data Collection Screen', 'data']]
    end

    def survey_screen=(survey_screen)
      @survey_screen = case survey_screen
                       when ::Surveys::Screen
                         survey_screen
                       when Integer
                         ::Surveys::Screen.find_by(id: survey_screen)
                       end

      @survey = @survey_screen.survey if @survey_screen&.survey_id
    end

    def survey_screen_option_screens_for_select
      [['Another Web Page', 0]] + self.survey.screens.where.not(id: self.survey_screen.id).pluck(:name, :id)
    end

    def screens
      @survey_screens || (@survey_screens = self.survey.screens)
    end

    def survey=(survey)
      @survey = case survey
                when ::Surveys::Survey
                  survey
                when Integer
                  ::Surveys::Survey.find_by(id: survey)
                end
    end

    def surveys
      @surveys || (@surveys = self.client.surveys)
    end
  end
end
