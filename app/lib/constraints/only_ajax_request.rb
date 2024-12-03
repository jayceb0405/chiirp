# frozen_string_literal: true

# app/lib/constraints/only_ajax_request.rb
module Constraints
  class OnlyAjaxRequest
    def matches?(request)
      request.xhr?
    end
  end
end
