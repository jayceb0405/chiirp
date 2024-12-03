# frozen_string_literal: true

# app/controllers/integrations/google/reviews/reviews_links_controller.rb
module Integrations
  module Google
    module Reviews
      class ReviewsLinksController < Google::IntegrationsController
        before_action :authorize_user_for_accounts_locations_config!
        # (GET) show Google review link form
        # /integrations/google/reviews/reviews_links
        # integrations_google_reviews_reviews_links_path
        # integrations_google_reviews_reviews_links_url
        def show
          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[reviews_links_show] }
        end

        # (PUT/PATCH) save Google review link
        # /integrations/google/reviews/reviews_links
        # integrations_google_reviews_reviews_links_path
        # integrations_google_reviews_reviews_links_url
        def update
          @client_api_integration.update(reviews_links: params_reviews_links)

          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[reviews_links_show] }
        end

        private

        def params_reviews_links
          params.require(:reviews).permit(reviews_links: {}).dig(:reviews_links)
        end
      end
    end
  end
end
