# frozen_string_literal: true

# app/presenters/email_templates_presenter.rb
class EmailTemplatesPresenter < BasePresenter
  def initialize
    super
    @categories = nil
  end

  def category_options_for_select
    self.categories.map { |category| [category.titleize, category] }
  end

  def categories
    @categories ||= EmailTemplate.categories.order(:category).map(&:category)
  end
end
