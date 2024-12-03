# frozen_string_literal: true

# app/controllers/trainings_controller.rb
class TrainingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_training, only: %i[destroy edit show update]
  before_action :authorize_user!

  # (POST) create a new Training
  # /trainings
  # trainings_path
  # trainings_url
  def create
    @training  = Training.create(new_training_params)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_edit training_index] } }
      format.html { redirect_to root_path }
    end
  end

  # (DELETE) Destroy a Training
  # /trainings/:id
  # training_path(:id)
  # training_url(:id)
  def destroy
    @training.destroy
    remove_instance_variable(:@training)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_show training_pages_index training_index] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) edit a Training
  # /trainings/:id/edit
  # edit_training_path(:id)
  # edit_training_url(:id)
  def edit
    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_edit] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) list Trainings
  # /trainings
  # trainings_path
  # trainings_url
  def index
    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_index] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) create a new Training
  # /trainings/new
  # new_training_path
  # new_training_url
  def new
    @training = Training.create(menu_label: 'New Course', title: 'New Course')
    current_user.client.update(training: current_user.client.training << @training.id.to_s)

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_edit training_index] } }
      format.html { render 'trainings/show', locals: { training_edit: true } }
    end
  end

  # (GET) show Training selected from left side menu
  # /trainings/:id
  # training_path(:id)
  # training_url(:id)
  def show
    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: %w[training_page_show training_pages_index] } }
      format.html { render 'trainings/show', locals: { training_edit: false } }
    end
  end

  # (PATCH/PUT) update a Training
  # /trainings/:id
  # training_path(:id)
  # training_url(:id)
  def update
    sort = params.dig(:sort).to_i
    training_pages_order = [params.dig(:training_pages_order) || []].flatten

    if sort.zero?
      @training.update(update_training_params)
    else

      training_pages_order.each_with_index do |id, counter|
        if (training_page = @training.training_pages.find_by(id:))
          training_page.update(position: (counter + 1))
        end
      end
    end

    respond_to do |format|
      format.js   { render partial: 'trainings/js/show', locals: { cards: (sort.zero? ? %w[training_page_show training_pages_index training_index] : [22]) } }
      format.html { render 'trainings/show' }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.client.training.present? && TrainingPage.user_authorized?(current_user, @training, action_name)

    raise ExceptionHandlers::UserNotAuthorized.new('Training', root_path)
  end

  def new_training_params
    params.require(:training).permit(:title)
  end

  def set_training
    return if (@training = Training.find_by(id: params[:id]))

    sweetalert_error('Training NOT found!', 'Unable to access the requested Training.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js   { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def update_training_params
    params.require(:training).permit(:title, :menu_label, :description)
  end
end
