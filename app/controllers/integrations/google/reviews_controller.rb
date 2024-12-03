# frozen_string_literal: true

# app/controllers/integrations/google/reviews_controller.rb
module Integrations
  module Google
    class ReviewsController < Google::IntegrationsController
      # (GET) Google Reviews integration main screen
      # /integrations/google/reviews
      # integrations_google_reviews_path
      # integrations_google_reviews_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[reviews_show reviews_index] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end
    end
  end
end
