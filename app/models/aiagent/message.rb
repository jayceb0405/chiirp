# frozen_string_literal: true

# app/models/aiagent/message.rb
class Aiagent
  class Message < ApplicationRecord
    belongs_to :aiagent_session, class_name: 'Aiagent::Session'
    belongs_to :message, optional: true

    has_one    :contact, through: :session

    scope :system, -> { where(role: :system) }
    scope :from_assistant, -> { where(role: :assistant) }

    validates :role, presence: true

    def to_openai
      out = {
        role:,
        content:
      }

      out[:name] = self.function_name if self.role == 'function'
      if self.role == 'assistant' && self.function_name.present?
        out[:function_call] = {
          name:      self.function_name,
          arguments: self.function_params
        }
      end

      out
    end
  end
end
