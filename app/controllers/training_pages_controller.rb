# frozen_string_literal: true

# app/controllers/training_pages_controller.rb
class TrainingPagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_training
  before_action :authorize_user!
  before_action :set_training_page, only: %i[destroy edit show update]

  # (POST) create a new TrainingPage
  # /trainings/:training_id/training_pages
  # training_training_pages_path(:training_id)
  # training_training_pages_url(:training_id)
  def create
    @training_page  = @training.training_pages.create(params_training_page)
    @training_pages = @training.training_pages.order(:position)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_edit training_pages_index] } }
      format.html { redirect_to root_path }
    end
  end

  # (DELETE) Destroy a TrainingPage
  # /trainings/:training_id/training_pages/:id
  # training_training_page_path(:training_id, :id)
  # training_training_page_url(:training_id, :id)
  def destroy
    @training_page.destroy
    remove_instance_variable(:@training_page)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_show training_pages_index] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) edit a TrainingPage
  # /trainings/:training_id/training_pages/:id/edit
  # edit_training_training_page_path(:training_id, :id)
  # edit_training_training_page_url(:training_id, :id)
  def edit
    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_pages_edit] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) list TrainingPages
  # /trainings/:training_id/training_pages
  # training_training_pages_path(:training_id)
  # training_training_pages_url(:training_id)
  def index
    sort = params.dig(:sort).to_i

    @training_pages = @training.training_pages.order(:position)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: (sort.zero? ? %(training_pages_index) : %(training_pages_sort)) } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) create a new TrainingPage
  # /trainings/:training_id/training_pages/new
  # new_training_training_page_path(:training_id)
  # new_training_training_page_url(:training_id)
  def new
    @training_page = @training.training_pages.new(title: 'New Course Page', menu_label: 'New Course Page', parent: true)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %(training_pages_edit) } }
      format.html { render 'trainings/show' }
    end
  end

  # (GET) show TrainingPage
  # /trainings/:training_id/training_pages/:id
  # training_training_page_path(:training_id, :id)
  # training_training_page_url(:training_id, :id)
  def show
    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_show] } }
      format.html { render 'trainings/show' }
    end
  end

  # (PATCH/PUT) update a TrainingPage
  # /trainings/:training_id/training_pages/:id
  # training_training_page_patth(:training_id, :id)
  # training_training_page_url(:training_id, :id)
  def update
    @training_page.update(params_training_page)
    @training_pages = @training.training_pages.order(:position)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_show training_pages_index] } }
      format.html { render 'trainings/show' }
    end
  end

  private

  def authorize_user!
    return if current_user.user?
    return if TrainingPage.user_authorized?(current_user, @training, action_name)

    raise ExceptionHandlers::UserNotAuthorized.new('Training', root_path)
  end

  def set_training
    return if (@training = Training.find_by(id: params[:training_id]))

    sweetalert_error('Training NOT found!', 'Unable to access the requested Training.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js   { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_training_page
    return if (@training_page = @training.training_pages.find_by(id: params[:id]))

    sweetalert_error('Training Page NOT found!', 'Unable to access the requested Training Page.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js   { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def params_training_page
    response = params.require(:training_page).permit(:title, :menu_label, :parent, :type, :position, :header, :footer, :video_link)

    response[:video_link] = response[:video_link].gsub('{script', '<script').gsub('{/script}', '</script>').gsub('{onload}', 'onload') if response.include?(:video_link)

    response
  end
end
