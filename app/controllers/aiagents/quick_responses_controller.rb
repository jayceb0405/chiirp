# frozen_string_literal: true

# app/controllers/aiagents/quick_responses_controller.rb
module Aiagents
  class QuickResponsesController < ApplicationController
    # (POST)
    # /aiagents/:aiagent_id/respond_to/:contact_id
    # aiagent_quick_response_path(:aiagent_id, :contact_id)
    # aiagent_quick_response_url(:aiagent_id, :contact_id)
    def respond
      aiagent = current_user.client.aiagents.find_by(id: params[:aiagent_id])
      contact = current_user.client.contacts.find_by(id: params[:contact_id])

      return unless aiagent && contact

      days = aiagent.lookback_days&.to_i

      context = {
        role:    :system,
        content: "You are talking to #{contact.firstname}.\n"
      }
      context[:content] << "#{contact.firstname} works for #{contact.companyname}.\n" if contact.companyname.present?
      context[:content] << "#{contact.firstname}'s birthday is on #{contact.birthdate.to_date}." if contact.birthdate.present?
      context[:content] << "#{contact.firstname}'s address is #{contact.address1}, #{contact.city}, #{contact.state} #{contact.zipcode}." if contact.address1.present?

      history = contact.messages
      history = history.where(created_at: days.days.ago..) unless days.zero?
      history = history.where(from_phone: params[:phone_number]).or(history.where(to_phone: params[:phone_number]))
      history = history.limit(100)

      res = aiagent.respond([aiagent.to_openai] + [context] + history.map(&:to_openai))

      render json: res.dig(:choices, 0, :message)
    end
  end
end
