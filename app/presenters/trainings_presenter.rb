# frozen_string_literal: true

# app/presenters/trainings_presenter.rb
class TrainingsPresenter
  attr_reader :training, :training_page

  def initialize(args = {})
    self.training      = args.dig(:training)
    self.training_page = args.dig(:training_page)

    @training_pages = nil
    @trainings      = nil
  end

  def trainings
    @trainings || Training.all
  end

  def training=(training)
    @training = if training.is_a?(Training)
                  training
                elsif training.is_a?(Integer)
                  Training.find_by(id: training)
                else
                  Training.new
                end
  end

  def training_page=(training_page)
    @training_page = if training_page.is_a?(TrainingPage)
                       training_page
                     elsif training_page.is_a?(Integer)
                       TrainingPage.find_by(id: training_page)
                     elsif self.training
                       self.training.training_pages.order(:position).first || self.training.training_pages.new
                     else
                       TrainingPage.new
                     end

    return if @training_page.training_id == self.training.id

    self.training = @training_page.training
  end

  def training_pages
    @training_pages || self.training.training_pages.order(:position)
  end

  def training_pages_edit_buttons
    response = self.training_page.new_record? ? [] : [{ title: 'Edit Header', id: 'training_page_header_button' }, { title: 'Edit Footer', id: 'training_page_footer_button' }]
    response + [{ title: 'Save Course Page', id: 'save_training_page_submit', disable_with: 'Saving Course Page' }]
  end
end
