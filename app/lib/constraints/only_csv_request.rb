# frozen_string_literal: true

# app/lib/constraints/only_csv_request.rb
module Constraints
  class OnlyCsvRequest
    def matches?(request)
      request.format.csv?
    end
  end
end
