# frozen_string_literal: true

# app/controllers/integrations/google/reviews/reviews_controller.rb
module Integrations
  module Google
    module Reviews
      class ReviewsController < Google::IntegrationsController
        before_action :primary_user_api_integration, only: %i[destroy update]
        before_action :review, only: %i[destroy edit update]

        # (POST) update all nil Reviews read_at with current time
        # /integrations/google/reviews/clear
        # integrations_google_reviews_clear_path
        # integrations_google_reviews_clear_url
        def clear
          if defined?(current_user)
            contact_id = params.dig(:contact_id).to_i
            review_id  = params.dig(:review_id).to_i

            if contact_id.positive? && (contact = Contact.find_by(id: contact_id, user_id: current_user.id))
              # rubocop:disable Rails/SkipsModelValidations
              Review.unread_reviews_by_contact(contact.id).update_all(read_at: Time.current)
              # rubocop:enable Rails/SkipsModelValidations
            elsif review_id.positive? && (review = Review.where(id: review_id))
              review.update(read_at: DateTime.current)
            else
              # rubocop:disable Rails/SkipsModelValidations
              Review.unread_reviews_by_client(current_user.client_id).update_all(read_at: Time.current)
              # rubocop:enable Rails/SkipsModelValidations
            end
          end

          render partial: 'layouts/looper/common/header/js/show', locals: { cards: %w[header_unread_reviews_list header_unread_reviews_clear] }
        end

        # (DELETE) delete a Google review reply
        # /integrations/google/reviews/reviews/:id
        # integrations_google_reviews_review_path(:id)
        # integrations_google_reviews_review_url(:id)
        def destroy
          if @primary_user_api_integration
            Integration::Google.valid_token?(@primary_user_api_integration)

            if (ggl_client = Integrations::Ggl::Base.new(@primary_user_api_integration.token, I18n.t('tenant.id')))
              ggl_client.review_delete_reply(@review.account, @review.location, @review.review_id)

              if ggl_client.success?
                @review.update(
                  reply:      '',
                  replied_at: nil
                )
              end
            end
          end

          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[review_edit] }
        end

        # (GET) edit/create a Google review reply
        # /integrations/google/reviews/reviews/:id/edit
        # edit_integrations_google_reviews_review_path(:id)
        # edit_integrations_google_reviews_review_url(:id)
        def edit
          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[review_edit] }
        end

        # (GET) display unread Reviews
        # /integrations/google/reviews/unread_reviews
        # integrations_google_reviews_unread_reviews_path
        # integrations_google_reviews_unread_reviews_url
        def header_unread_reviews
          render partial: 'layouts/looper/common/header/js/show', locals: { cards: %w[header_unread_reviews_list] }
        end

        # (GET) list Google reviews
        # /integrations/google/reviews/reviews
        # integrations_google_reviews_reviews_path
        # integrations_google_reviews_reviews_url
        def index
          sanitized_params = params.permit(:account, :location, :page, :per_page)

          cards = if sanitized_params.dig(:page) || sanitized_params.dig(:per_page)
                    %w[reviews_list_only]
                  else
                    %w[reviews_index]
                  end

          render partial: 'integrations/google/reviews/js/show', locals: {
            cards:,
            account:  sanitized_params.dig(:account),
            location: sanitized_params.dig(:location),
            page:     sanitized_params.dig(:page),
            per_page: sanitized_params.dig(:per_page)
          }
        end

        # (PUT/PATCH) save & post Google review reply
        # /integrations/google/reviews/reviews/:id
        # integrations_google_reviews_review_path(:id)
        # integrations_google_reviews_review_url(:id)
        def update
          if @primary_user_api_integration
            new_contact_id = params.permit(:new_contact_id).dig(:new_contact_id)

            if new_contact_id.nil?
              reply = params.include?(:review) ? params.require(:review).permit(:reply).dig(:reply).to_s : ''

              Integration::Google.valid_token?(@primary_user_api_integration)

              if reply.present? && (ggl_client = Integrations::Ggl::Base.new(@primary_user_api_integration.token, I18n.t('tenant.id')))
                ggl_client.review_update_reply(@review.account, @review.location, @review.review_id, reply)

                if ggl_client.success?
                  @review.update(
                    reply:,
                    replied_at: Time.current
                  )
                end
              end
            elsif (contact = Contact.find_by(client_id: @client_api_integration.client_id, id: new_contact_id))
              new_match = @review.contact_id != contact.id
              @review.update(contact_id: contact.id)
              Integration::Google.process_actions_for_review(@client_api_integration, contact, @review) if new_match
            else
              @review.update(contact_id: nil)
            end
          end

          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[review_edit] }
        end

        private

        def review
          @review = ::Review.find_by(id: params.dig(:id).to_i)
        end
      end
    end
  end
end
