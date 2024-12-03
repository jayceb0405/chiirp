# frozen_string_literal: true

# app/presenters/affiliates/presenter.rb
module Affiliates
  class Presenter
    attr_reader :affiliate

    def initialize(args = {})
      self.affiliate = args[:affiliate] if args.key?(:affiliate)
    end

    def affiliate_array(include_extras)
      (affiliates.pluck(:company_name, :id) + (include_extras ? [['SearchLight', -1], ['CardX', -2]] : [])).sort_by { |p| p[0] }
    end

    def affiliates
      Affiliates::Affiliate.all
    end

    def report_submit_buttons
      ([] << (@affiliate.present? && @affiliate.id.present? ? { title: 'Print', id: 'affiliates_reports_print', disable_with: 'Creating Printable Report' } : nil) << { title: 'Create Report', disable_with: 'Creating Report' }).compact_blank
    end

    private

    def affiliate=(affiliate)
      @affiliate = case affiliate
                   when Affiliates::Affiliate
                     affiliate
                   when Integer
                     Affiliates::Affiliate.find_by(id: affiliate)
                   else
                     Affiliates::Affiliate.new
                   end
    end
  end
end
