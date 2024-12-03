# frozen_string_literal: true

# app/lib/integrations/ggl/my_business/reviews.rb
module Integrations
  module Ggl
    module MyBusiness
      # Google API calls to support Business Profile Reviews
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Reviews
        def average_reviews_rating(account_id, location_id)
          reset_attributes
          @result = 0

          if @average_rating.dig(account_id, location_id)
            @success = true
            @result = @average_rating[account_id][location_id]
          else
            self.reviews(account_id, location_id)
            @success = self.success?
            @result = @average_rating.dig(account_id, location_id)
          end

          @result
        end

        # get a specific Google Review for an Account/Location
        # ggl_client.review
        # (req) account_id:  (String / ex: 'accounts/106702836638822736000')
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        # (req) review_id:   (String / ex: )
        def review(account_id, location_id, review_id)
          reset_attributes
          @result = []

          if account_id.blank?
            @message = 'Account ID is required.'
            return @result
          elsif location_id.blank?
            @message = 'Location ID is required.'
            return @result
          elsif review_id.blank?
            @message = 'Review ID is required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::MyBusiness::Reviews.review',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{my_business_base_url}/#{my_business_base_version}/#{account_id}/#{location_id}/#{api_method_reviews}/#{review_id}"
          )

          @result
        end

        # delete a specific Google Review Reply for an Account/Location
        # ggl_client.review_delete_reply
        # (req) account_id:  (String / ex: 'accounts/106702836638822736000')
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        # (req) review_id:   (String / ex: )
        def review_delete_reply(account_id, location_id, review_id)
          reset_attributes
          @result = []

          if account_id.blank?
            @message = 'Account ID is required.'
            return @result
          elsif location_id.blank?
            @message = 'Location ID is required.'
            return @result
          elsif review_id.blank?
            @message = 'Review ID is required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::MyBusiness::Reviews.review_delete_reply',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{my_business_base_url}/#{my_business_base_version}/#{account_id}/#{location_id}/#{api_method_reviews}/#{review_id}/reply"
          )

          @result
        end

        # update/add a specific Google Review Reply for an Account/Location
        # ggl_client.review_update_reply
        # (req) account_id:  (String / ex: 'accounts/106702836638822736000')
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        # (req) review_id:   (String / ex: )
        # (req) reply:       (String)
        def review_update_reply(account_id, location_id, review_id, reply)
          reset_attributes
          @result = []

          if account_id.blank?
            @message = 'Account ID is required.'
            return @result
          elsif location_id.blank?
            @message = 'Location ID is required.'
            return @result
          elsif review_id.blank?
            @message = 'Review ID is required.'
            return @result
          elsif reply.blank?
            @message = 'Reply is required.'
            return @result
          end

          body = {
            comment:    reply,
            updateTime: Time.current.rfc3339
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::MyBusiness::Reviews.review_update_reply',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "#{my_business_base_url}/#{my_business_base_version}/#{account_id}/#{location_id}/#{api_method_reviews}/#{review_id}/reply"
          )

          @result
        end

        # get a list of Google Reviews for an Account/Location
        # ggl_client.reviews
        # (req) account_id:  (String / ex: 'accounts/106702836638822736000')
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        # docs: https://developers.google.com/my-business/reference/rest/v4/accounts.locations.reviews/list
        def reviews(account_id, location_id, start_date = nil)
          reset_attributes
          response = []

          if account_id.blank?
            @message = 'Account ID is required.'
            return response
          elsif location_id.blank?
            @message = 'Location ID is required.'
            return response
          end

          # pageSize: How many reviews to fetch per page. The maximum pageSize is 50.
          # orderBy:  Specifies the field to sort reviews by. If unspecified, the order of reviews returned will default to updateTime desc. Valid orders to sort by are rating, rating desc and updateTime desc.

          params = {
            pageSize: 50
          }

          loop do
            self.google_request(
              body:                  nil,
              error_message_prepend: 'Integrations::Ggl::MyBusiness::Reviews.reviews',
              method:                'get',
              params:,
              default_result:        [],
              url:                   "#{my_business_base_url}/#{my_business_base_version}/#{account_id}/#{location_id}/#{api_method_reviews}"
            )

            if @success && @result.is_a?(Hash)
              response += @result.dig(:reviews) || []
              @average_rating[account_id] = (@average_rating.dig(account_id) || {}).merge({ location_id => @result.dig(:averageRating).to_d })
              @total_reviews[account_id]  = (@total_reviews.dig(account_id) || {}).merge({ location_id => @result.dig(:totalReviewCount).to_i })
              break if (params[:pageToken] = @result.dig(:nextPageToken)).blank? || (start_date.respond_to?(:strftime) && response.last.dig(:updateTime).to_datetime < start_date)
            else
              response = []
              break
            end
          end

          @result = if start_date.respond_to?(:strftime)
                      response.map { |r| r[:updateTime] >= start_date ? r : nil }.compact_blank
                    else
                      response
                    end
        end
        # example response:
        # {
        #   "reviews":[
        #     {
        #       "reviewId":"AbFvOqllIQFfqZq0t4PFJFt54VjdpzwbjBlRFO13IyKgYwN4ZNgZLsl5lXd0ySxvJ4zLyALVTCI1Tw",
        #       "reviewer":{
        #         "profilePhotoUrl":"https://lh3.googleusercontent.com/a-/ALV-UjXPd_uUE6n658Gppj8lctgr9bE4XMcgtCkMh6h-_QYEgwpd=s120-c-rp-mo-br100",
        #         "displayName":"Bryan Mosier"
        #       },
        #       "starRating":"FIVE",
        #       "createTime":"2022-05-16T11:27:14.829390Z",
        #       "updateTime":"2022-05-16T11:27:14.829390Z",
        #       "reviewReply":{
        #         "comment":"Thanks for letting us take care of your homes heat and air conditioning needs.",
        #         "updateTime":"2022-05-17T15:18:52.509033Z"
        #       },
        #       "name":"accounts/106509872556840346245/locations/18310729826786066313/reviews/AbFvOqllIQFfqZq0t4PFJFt54VjdpzwbjBlRFO13IyKgYwN4ZNgZLsl5lXd0ySxvJ4zLyALVTCI1Tw"
        #     }, ...
        #   ]
        # }

        # get a total number of Google Reviews for an Account/Location
        # ggl_client.total_reviews(account_id, location_id)
        # (req) account_id:  (String / ex: 'accounts/106702836638822736000')
        # (req) location_id: (String / ex: 'locations/12247487312543151044')
        def total_reviews(account_id, location_id)
          reset_attributes
          @result = 0

          if @total_reviews.dig(account_id, location_id)
            @success = true
            @result  = @total_reviews[account_id][location_id]
          else
            self.reviews(account_id, location_id)
            @success = self.success?
            @result  = @total_reviews.dig(account_id, location_id)
          end

          @result
        end

        private

        def api_method_reviews
          'reviews'
        end
      end
    end
  end
end
