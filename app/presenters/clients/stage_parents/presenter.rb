# frozen_string_literal: true

# app/presenters/clients/stage_parents/presenter.rb
module Clients
  module StageParents
    # variables required by Clients::StageParents views
    class Presenter
      attr_reader :client, :stage_parent

      def initialize(args = {})
        if args.dig(:stage_parent)
          self.stage_parent = args.dig(:stage_parent)
          self.client       = args.dig(:client)
        else
          self.client       = args.dig(:client)
          self.stage_parent = args.dig(:stage_parent)
        end

        @stages_count        = nil
        @stage_parents_count = nil
      end

      def client=(client)
        @client = if client.is_a?(Client)
                    client
                  elsif client.is_a?(Integer)
                    Client.find_by(id: client)
                  elsif self.stage_parent.is_a?(StageParent)
                    self.stage_parent.client
                  else
                    Client.new
                  end
      end

      def stage_parent=(stage_parent)
        @stage_parent = if stage_parent.is_a?(StageParent)
                          stage_parent
                        elsif stage_parent.is_a?(Integer)
                          StageParent.find_by(id: stage_parent)
                        elsif self.client.is_a?(Client)
                          self.client.stage_parents.new
                        else
                          StageParent.new
                        end
      end

      def stage_parents
        self.client.stage_parents.order(:name)
      end

      def stage_parents_count
        @stage_parents_count ||= self.stage_parents.count
      end

      def stages_count
        @stages_count ||= @stage_parent.stages.count
      end

      def users_array
        [['All Users', 0]] + User.where(client_id: self.client.id).order(lastname: :asc, firstname: :asc).map { |user| [user.fullname, user.id] }
      end

      def users_for_select
        ActionController::Base.helpers.options_from_collection_for_select(User.where(client_id: self.client.id).order(lastname: :asc, firstname: :asc), :id, :fullname, self.stage_parent.users_permitted)
      end
    end
  end
end
