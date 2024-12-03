# frozen_string_literal: true

# app/controllers/clients/dlc10/brands_controller.rb
module Clients
  module Dlc10
    class IntrosController < Clients::Dlc10::BaseController
      # (GET) show 10DLC introduction
      # /clients/dlc10/intro
      # clients_dlc10_intro_path(:client_id)
      # clients_dlc10_intro_url(:client_id)
      def show
        @dlc10_tab = 'intro'

        respond_to do |format|
          format.js { render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[intro] } }
          format.html { render 'clients/show', locals: { client_page_section: 'dlc10' } }
        end
      end
    end
  end
end
