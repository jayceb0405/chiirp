# frozen_string_literal: true

# app/lib/constraints/quick_page.rb
module Constraints
  class QuickPage
    def matches?(request)
      matching_domain_path?(request)
    end

    private

    def matching_domain_path?(request)
      request.path.present? && UserContactForm.all_page_names(request.domain).include?(request.path.delete('/'))
    end
  end
end
