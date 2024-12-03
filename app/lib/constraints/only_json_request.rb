# frozen_string_literal: true

# app/lib/constraints/only_json_request.rb
module Constraints
  class OnlyJsonRequest
    def matches?(request)
      request.format.json?
    end
  end
end
