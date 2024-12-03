# frozen_string_literal: true

# app/lib/constraints/surveys.rb
module Constraints
  # route constraints specific to Surveys
  class Surveys
    def matches?(request)
      matching_domain_path?(request)
    end

    def matching_domain_path?(request)
      JsonLog.info 'Constraints::Surveys.matching_domain_path', { path: request.path, domain: request.domain }
      request.path.present? && ::Surveys::Survey.all_page_names(request.domain).include?(request.path.gsub('/surveys/', ''))
    end
  end
end
