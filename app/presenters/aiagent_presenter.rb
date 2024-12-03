# frozen_string_literal: true

# AiagentPresenter.new(client_api_integration:)
# app/presenters/aiagent_presenter.rb
class AiagentPresenter
  attr_accessor :agent, :client

  # Integrations::Aiagent::V1::Presenter::INITIAL_PROMPT
  # DEFAULT_SYSTEM_PROMPT = <<~PROMPT
  #   You are a customer service representative that wants to get a client's contact information and help them schedule an appointment.
  #   Your name is "AI Agent".
  #   You need to get their first and last name, phone number, street address, city, state, and zip code.
  #   Additionally you need to schedule a mutually agreeable appointment time. You can use the available_appointments function to see what times are available.
  #   After you have collected the information, tell the client that it will take a moment to process their request.
  #   You can complete the request and save the appointment by calling the set_appointment function.
  # PROMPT

  def initialize(agent)
    self.agent = agent
    self.client = agent&.client
  end

  def action_friendly_name
    self.agent.action_types[self.agent.action.to_sym]
  end

  def action_type_options_for_select
    self.agent.action_types.map { |type, desc| [desc, type] }
  end

  def action_type_keys
    self.agent.action_types.keys
  end

  def custom_form_fields
    @custom_form_fields ||= ::Webhook.internal_key_hash(self.client, 'contact', %w[personal phones custom_fields])
  end

  def custom_form_fields_for_edit
    custom_form_fields.each do |key, value|
      custom_form_fields[key] = { 'name' => value }

      if (ff = agent.custom_fields&.dig(key))
        ff.each do |k, v|
          custom_form_fields[key][k] = v
        end
      else
        custom_form_fields[key]['order']    = custom_form_fields.length.to_s
        custom_form_fields[key]['show']     = '0'
        custom_form_fields[key]['required'] = '0'
      end
    end

    if custom_form_fields.reject { |_key, value| value['order'] == custom_form_fields.length.to_s }.any?
      custom_form_fields.sort_by { |_key, value| value['order'].to_i }
    else
      custom_form_fields.sort_by { |_key, value| value['name'] }
    end
  end

  def default_prompt_pre(action)
    Aiagent::PRE_PROMPTS[action]
  end

  def default_prompt_post(action)
    Aiagent::POST_PROMPTS[action]
  end

  def form_method
    self.agent.new_record? ? :post : :patch
  end

  def form_url
    self.agent.new_record? ? Rails.application.routes.url_helpers.aiagents_path : Rails.application.routes.url_helpers.aiagent_path(@agent.id)
  end

  def service_titan?
    action_type_keys.include?('booking_st')
  end

  def valid_credentials?
    true
  end
end
