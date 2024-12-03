# frozen_string_literal: true

# app/presenters/clients/holidays/presenter.rb
module Clients
  module Holidays
    class Presenter
      attr_accessor :holiday
      attr_reader :client

      # presenter = local_assigns.dig(:presenter) || Clients::Holidays::Presenter.new(client: @client)
      def initialize(args = {})
        self.client = args.dig(:client)
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

      def holidays
        Clients::Holiday::HOLIDAYS.invert.to_a
      end

      def occurs_at_value
        @holiday&.occurs_at.respond_to?(:strftime) ? @holiday.occurs_at.strftime('%m/%d/%Y') : ''
      end

      def actions
        Clients::Holiday::ACTIONS.invert.to_a
      end
    end
  end
end
