# frozen_string_literal: true

# app/presenters/quick_responses_presenter.rb
class QuickResponsesPresenter
  attr_accessor :message_id, :quick_response

  def initialize(quick_response = nil)
    self.quick_response = quick_response
  end

  def form_url
    self.quick_response.new_record? ? Rails.application.routes.url_helpers.quick_responses_path(message_id: @message_id) : Rails.application.routes.url_helpers.quick_response_path(self.quick_response, message_id: @message_id)
  end

  def form_method
    self.quick_response.new_record? ? :post : :patch
  end
end
