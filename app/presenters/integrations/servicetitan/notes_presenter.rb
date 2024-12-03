# frozen_string_literal: true

# app/presenters/integrations/servicetitan/custom_fields_presenter.rb
module Integrations
  module Servicetitan
    class NotesPresenter < BasePresenter
      attr_reader :notes

      def initialize(client_api_integration)
        super

        @notes = (@client_api_integration.notes || {}).symbolize_keys
      end

      def push_notes
        @notes.dig(:push_notes).to_bool
      end

      def push_textin
        @notes.dig(:textin).to_bool
      end

      def push_textout_aiagent
        @notes.dig(:textout_aiagent)
      end

      def push_textout_auto
        @notes.dig(:textout_auto)
      end

      def push_textout_manual
        @notes.dig(:textout_manual)
      end
    end
  end
end
