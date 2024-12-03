# frozen_string_literal: true

# app/controllers/integrations/facebook/messenger/pages_controller.rb
module Integrations
  module Facebook
    module Messenger
      class PagesController < Facebook::IntegrationsController
        # (GET) list all Facebook Pages for Messenger
        # /integrations/facebook/messenger/pages
        # integrations_facebook_messenger_pages_path
        # integrations_facebook_messenger_pages_url
        def index
          locals = if params.include?(:user_id)
                     { cards: %w[index_messenger_user], user_id: params.permit(:user_id).dig(:user_id).to_s }
                   elsif params.include?(:page_id)
                     { cards: %w[index_messenger_page], page_id: params.permit(:page_id).dig(:page_id).to_s }
                   else
                     { cards: %w[index_messenger] }
                   end

          respond_to do |format|
            format.js { render partial: 'integrations/facebook/js/show', locals: }
            format.html { redirect_to integrations_facebook_integration_path }
          end
        end
      end
    end
  end
end
