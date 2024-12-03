# frozen_string_literal: true

# app/lib/integrations/fred.rb
module Integrations
  # access economic data from Federal Reserve of St. Louis
  class Fred
    attr_reader :error, :message, :result

    # initialize Integrations::Fred object
    # fred_client = Integrations::Fred.new
    def initialize
      reset_attributes
      @result = nil
    end

    # get current interest rate
    # Integrations::Fred.new.current_mortgage_rate
    # fred_client.current_mortgage_rate
    def current_mortgage_rate(args = { type: 'MORTGAGE30US' })
      reset_attributes
      @result = []

      success, error, message = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend: 'Integrations::Fred::CurrentMortgageRate',
        current_variables:     {
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.get("#{base_api_url}/series/observations") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.params['api_key']        = Rails.application.credentials[:fred][:api_key]
          req.params['series_id']      = args.dig(:type).to_s
          req.params['realtime_start'] = 10.days.ago.strftime('%Y-%m-%d')
          req.params['realtime_end']   = '9999-12-31'
          req.params['file_type']      = 'json'
          req.params['sort_order']     = 'desc'
        end

        result_body = JSON.parse(result.body).deep_symbolize_keys

        if result.status == 200
          @success  = true
          @result   = result_body.dig(:observations).first
        else
          @error   = result.status
          @message = result_body.dig(:error).to_s.titleize.capitalize

          ProcessError::Report.send(
            error_code:    @error,
            error_message: "Integrations::Fred::CurrentMortgageRate: #{@message}",
            variables:     {
              args:            args.inspect,
              error:           @error.inspect,
              message:         @message.inspect,
              response_result: @result.inspect,
              result:          result.inspect,
              result_body:     result_body.inspect,
              result_methods:  result.public_methods.inspect,
              result_status:   result.status.inspect,
              success:         @success.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      @success = false unless success
      @error   = error
      @message = message if message.present?

      @result
    end

    # get mortgage rate types
    # Integrations::Fred.new.mortgage_rate_types
    # fred_client.mortgage_rate_types
    def mortgage_rate_types
      reset_attributes
      @result = []

      success, error, message = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend: 'Integrations::Fred::MortgageRateTypes',
        current_variables:     {
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.get("#{base_api_url}/category/series") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.params['api_key']        = Rails.application.credentials[:fred][:api_key]
          req.params['category_id']    = 114
          req.params['file_type']      = 'json'
        end

        result_body = JSON.parse(result.body).deep_symbolize_keys

        if result.status == 200
          @success  = true
          @result   = result_body.dig(:seriess).filter_map { |type| Chronic.parse(type.dig(:observation_end).to_s) < (1.month.ago) ? nil : type }
        else
          @error   = result.status
          @message = result_body.dig(:error).to_s.titleize.capitalize

          ProcessError::Report.send(
            error_code:    @error,
            error_message: "Integrations::Fred::CurrentMortgageRate: #{@message}",
            variables:     {
              error:           @error.inspect,
              message:         @message.inspect,
              response_result: @result.inspect,
              result:          result.inspect,
              result_body:     result_body.inspect,
              result_methods:  result.public_methods.inspect,
              result_status:   result.status.inspect,
              success:         @success.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      @success = false unless success
      @error   = error
      @message = message if message.present?

      @result
    end
    # {
    #   "realtime_start": "2020-05-16",
    #   "realtime_end": "2020-05-16",
    #   "order_by": "series_id",
    #   "sort_order": "asc",
    #   "count": 14,
    #   "offset": 0,
    #   "limit": 1000,
    #   "seriess": [
    #     {
    #       "id": "FHA30",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "30-Year FHA Mortgage Rate: Secondary Market (DISCONTINUED)",
    #       "observation_start": "1964-01-01",
    #       "observation_end": "2000-06-01",
    #       "frequency": "Monthly",
    #       "frequency_short": "M",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2006-06-07 15:42:36-05",
    #       "popularity": 14,
    #       "group_popularity": 14
    #     },
    #     {
    #       "id": "MORTG",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "30-Year Conventional Mortgage Rate (DISCONTINUED)",
    #       "observation_start": "1971-04-01",
    #       "observation_end": "2016-09-01",
    #       "frequency": "Monthly",
    #       "frequency_short": "M",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2016-10-03 15:47:08-05",
    #       "popularity": 50,
    #       "group_popularity": 54,
    #       "notes": "The Federal Reserve Board has discontinued this series as of October 11, 2016. More information, including possible alternative series, can be found at http://www.federalreserve.gov/feeds/h15.html.\n\nContract interest rates on commitments for fixed-rate first mortgages. Source: Primary Mortgage Market Survey data provided by Freddie Mac.\n\nCopyright, 2016, Freddie Mac. Reprinted with permission."
    #     },
    #     {
    #       "id": "MORTGAGE15US",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "15-Year Fixed Rate Mortgage Average in the United States",
    #       "observation_start": "1991-08-30",
    #       "observation_end": "2020-05-14",
    #       "frequency": "Weekly, Ending Thursday",
    #       "frequency_short": "W",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2020-05-14 11:31:26-05",
    #       "popularity": 83,
    #       "group_popularity": 83,
    #       "notes": "Data is provided \"as is,\" with no warranties of any kind, express or implied, including, but not limited to, warranties of accuracy or implied warranties of merchantability or fitness for a particular purpose. Use of the data is at the user's sole risk. In no event will Freddie Mac be liable for any damages arising out of or related to the data, including, but not limited to direct, indirect, incidental, special, consequential, or punitive damages, whether under a contract, tort, or any other theory of liability, even if Freddie Mac is aware of the possibility of such damages.\n\nCopyright, 2016, Freddie Mac. Reprinted with permission."
    #     },
    #     {
    #       "id": "MORTGAGE1US",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "1-Year Adjustable Rate Mortgage Average in the United States (DISCONTINUED)",
    #       "observation_start": "1984-01-06",
    #       "observation_end": "2015-12-31",
    #       "frequency": "Weekly, Ending Thursday",
    #       "frequency_short": "W",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2015-12-31 10:16:04-06",
    #       "popularity": 9,
    #       "group_popularity": 9,
    #       "notes": "Data is provided \"as is,\" by Freddie Mac® with no warranties of any kind, express or implied, including, but not limited to, warranties of accuracy or implied warranties of merchantability or fitness for a particular purpose. Use of the data is at the user's sole risk. In no event will Freddie Mac be liable for any damages arising out of or related to the data, including, but not limited to direct, indirect, incidental, special, consequential, or punitive damages, whether under a contract, tort, or any other theory of liability, even if Freddie Mac is aware of the possibility of such damages.\n\nCopyright, 2016, Freddie Mac. Reprinted with permission."
    #     },
    #     {
    #       "id": "MORTGAGE30US",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "30-Year Fixed Rate Mortgage Average in the United States",
    #       "observation_start": "1971-04-02",
    #       "observation_end": "2020-05-14",
    #       "frequency": "Weekly, Ending Thursday",
    #       "frequency_short": "W",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2020-05-14 11:31:01-05",
    #       "popularity": 92,
    #       "group_popularity": 92,
    #       "notes": "Data is provided \"as is,\" by Freddie Mac® with no warranties of any kind, express or implied, including, but not limited to, warranties of accuracy or implied warranties of merchantability or fitness for a particular purpose. Use of the data is at the user's sole risk. In no event will Freddie Mac be liable for any damages arising out of or related to the data, including, but not limited to direct, indirect, incidental, special, consequential, or punitive damages, whether under a contract, tort, or any other theory of liability, even if Freddie Mac is aware of the possibility of such damages.\n\nCopyright, 2016, Freddie Mac. Reprinted with permission."
    #     },
    #     {
    #       "id": "MORTGAGE5US",
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "title": "5/1-Year Adjustable Rate Mortgage Average in the United States",
    #       "observation_start": "2005-01-06",
    #       "observation_end": "2020-05-14",
    #       "frequency": "Weekly, Ending Thursday",
    #       "frequency_short": "W",
    #       "units": "Percent",
    #       "units_short": "%",
    #       "seasonal_adjustment": "Not Seasonally Adjusted",
    #       "seasonal_adjustment_short": "NSA",
    #       "last_updated": "2020-05-14 11:31:29-05",
    #       "popularity": 56,
    #       "group_popularity": 56,
    #       "notes": "Data is provided \"as is,\" by Freddie Mac® with no warranties of any kind, express or implied, including, but not limited to, warranties of accuracy or implied warranties of merchantability or fitness for a particular purpose. Use of the data is at the user's sole risk. In no event will Freddie Mac be liable for any damages arising out of or related to the data, including, but not limited to direct, indirect, incidental, special, consequential, or punitive damages, whether under a contract, tort, or any other theory of liability, even if Freddie Mac is aware of the possibility of such damages.\n\nCopyright, 2016, Freddie Mac. Reprinted with permission."
    #     }
    #   }
    # }

    # get interest rate history
    # Integrations::Fred.new.mortgage_rates
    # fred_client.mortgage_rates
    def mortgage_rates
      reset_attributes
      @result = []

      success, error, message = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend: 'Integrations::Fred::MortgageRates',
        current_variables:     {
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.get("#{base_api_url}/series/observations") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.params['api_key']        = Rails.application.credentials[:fred][:api_key]
          req.params['series_id']      = 'MORTGAGE30US'
          req.params['file_type']      = 'json'
          req.params['sort_order']     = 'desc'
        end

        result_body = JSON.parse(result.body).deep_symbolize_keys

        if result.status == 200
          @success  = true
          @result   = result_body.dig(:observations) || []
        else
          @error   = result.status
          @message = result_body.dig(:error).to_s.titleize.capitalize

          ProcessError::Report.send(
            error_code:    @error,
            error_message: "Integrations::Fred::CurrentMortgageRate: #{@message}",
            variables:     {
              error:           @error.inspect,
              message:         @message.inspect,
              response_result: @result.inspect,
              result:          result.inspect,
              result_body:     result_body.inspect,
              result_methods:  result.public_methods.inspect,
              result_status:   result.status.inspect,
              success:         @success.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      @success = false unless success
      @error   = error
      @message = message if message.present?

      @result
    end
    # {
    #   "realtime_start": "2020-05-16",
    #   "realtime_end": "2020-05-16",
    #   "observation_start": "1600-01-01",
    #   "observation_end": "9999-12-31",
    #   "units": "lin",
    #   "output_type": 1,
    #   "file_type": "json",
    #   "order_by": "observation_date",
    #   "sort_order": "desc",
    #   "count": 2564,
    #   "offset": 0,
    #   "limit": 100000,
    #   "observations": [
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-05-14",
    #       "value": "3.28"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-05-07",
    #       "value": "3.26"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-04-30",
    #       "value": "3.23"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-04-23",
    #       "value": "3.33"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-04-16",
    #       "value": "3.31"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-04-09",
    #       "value": "3.33"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-04-02",
    #       "value": "3.33"
    #     },
    #     {
    #       "realtime_start": "2020-05-16",
    #       "realtime_end": "2020-05-16",
    #       "date": "2020-03-26",
    #       "value": "3.5"
    #     }
    #   }
    # }

    def success?
      @success
    end

    private

    def base_api_url
      'https://api.stlouisfed.org/fred'
    end

    def reset_attributes
      @error       = 0
      @message     = ''
      @success     = false
    end
  end
end
