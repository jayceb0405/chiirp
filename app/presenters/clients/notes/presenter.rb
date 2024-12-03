# frozen_string_literal: true

# app/presenters/clients/notes/presenter.rb
module Clients
  module Notes
    class Presenter
      attr_reader :client, :note

      # presenter = local_assigns.dig(:presenter) || Clients::Holidays::Presenter.new(client: @client)
      def initialize(args = {})
        self.client = args.dig(:client)
        @note = @client.notes.new
      end

      def client=(client)
        @client = case client
                  when Client
                    client
                  when Integer
                    Client.find_by(id: client)
                  else
                    Client.new
                  end
      end

      def form_url
        if @note.new_record?
          Rails.application.routes.url_helpers.client_notes_path(@client)
        else
          Rails.application.routes.url_helpers.client_note_path(@client, @note)
        end
      end

      def note=(note)
        @note = case note
                when Note
                  note
                when Integer
                  @client.notes.find_by(id: note)
                else
                  @client.notes.new
                end
      end

      def notes
        @client.notes.order(created_at: :desc)
      end
    end
  end
end
