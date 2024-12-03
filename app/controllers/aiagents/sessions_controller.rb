# frozen_string_literal: true

# app/controllers/aiagents/sessions_controller.rb
module Aiagents
  class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :find_aiagent_by_aiagent_id
    before_action :setup_aiagent_session

    # (GET) AI Agent agent test screen
    # /aiagents/:id/test
    # test_aiagent_path
    # test_aiagent_url
    def test
      render partial: 'aiagents/js/show', locals: { cards: %w[test] }
    end

    # (POST) AI Agent agent clear messages
    # /aiagents/:id/test/reset
    # aiagent_test_reset_path
    # aiagent_test_reset_url
    def test_reset
      @session.stop!
      setup_aiagent_session

      render partial: 'aiagents/js/show', locals: { cards: %w[test] }
    end

    # (POST) AI Agent agent test send message
    # /aiagents/:id/test
    # test_aiagent_path
    # test_aiagent_url
    def test_send
      @session.aiagent_messages.create role: :user, content: aiagent_test_params[:message]
      @session.respond!

      render partial: 'aiagents/js/show', locals: { cards: %w[test] }
    end

    # (PUT) AI Agent update agent test session
    # /aiagents/:id/test
    # aiagent_test_path
    # aiagent_test_url
    def update
      @session.contact_id = params[:contact_id]
      @session.save

      render partial: 'aiagents/js/show', locals: { cards: %w[test] }
    end

    private

    def aiagent_test_params
      params.require(:aiagent_test).permit(:message)
    end

    def authorize_user!
      super

      return if current_user&.access_controller?('aiagents', 'allowed', session)

      raise ExceptionHandlers::UserNotAuthorized.new('AI Agents', root_path)
    end

    def find_aiagent_by_aiagent_id
      @aiagent = current_user.client.aiagents.find(params[:aiagent_id])
    end

    def setup_aiagent_session
      @session = @aiagent.aiagent_test_sessions.active.first || new_aiagent_test_session
    end

    def new_aiagent_test_session
      contact_id = params[:contact_id] || @aiagent.aiagent_test_sessions.last&.contact_id
      session = @aiagent.aiagent_test_sessions.new(aiagent_type: @aiagent.aiagent_type, contact_id:)
      session.save

      content = session.contact ? session.contact.message_tag_replace(session.initial_prompt_for_contact) : session.initial_prompt_for_contact
      session.aiagent_messages.create(role: :assistant, content:)
      session
    end
  end
end
