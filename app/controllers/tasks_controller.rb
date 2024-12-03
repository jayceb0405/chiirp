# frozen_string_literal: true

# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!, except: %i[contact]
  before_action :set_task, only: %i[complete edit update]

  # (POST)
  # /tasks/:id/complete
  # complete_task_path(:id)
  # complete_task_url(:id)
  def complete
    @task.update(completed_at: (@task.completed_at.present? ? nil : Time.current))

    respond_to do |format|
      format.js { render partial: 'tasks/js/show', locals: { cards: %w[index] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) create a list of Contacts based on search criteria
  # /tasks/contact
  # contact_task_path
  # contact_task_url
  def contact
    client_id   = params.dig(:client_id).to_i
    searchchars = params.dig(:searchchars).to_s
    response    = []

    response = Contact.where(client_id:).where('lastname ILIKE ? OR firstname ILIKE ?', "%#{searchchars}%", "%#{searchchars}%").map { |c| [['value', c.id.to_s], ['text', c.fullname]].to_h } if client_id.positive? && searchchars.length > 2

    respond_to do |format|
      format.json { render json: response }
    end
  end

  # (POST) create/save a new Task
  # /tasks
  # tasks_path
  # tasks_url
  def create
    @task = current_user.client.tasks.create(task_params)

    set_tasks

    respond_to do |format|
      format.js { render partial: 'tasks/js/show', locals: { cards: %w[index], tasks_index_collapsed: false } }
      format.html { redirect_to root_path }
    end
  end

  # (DELETE) destroy a Task
  # /tasks/:id
  # task_path(:id)
  # task_url(:id)
  def destroy
    if params.dig(:id).to_i.positive?
      set_task

      return unless @task

      @task.destroy

    elsif params.dig(:tasks_checked).present?
      task_params = params.permit(tasks_checked: [])
      current_user.client.tasks.where(id: task_params.dig(:tasks_checked)).destroy_all
    end

    if params.dig(:contact_id).to_i.positive?
      # working with a specific Contact
      @contact = current_user.client.contacts.find_by(id: params[:contact_id].to_i)
    end

    set_tasks

    respond_to do |format|
      format.js { render partial: 'tasks/js/show', locals: { cards: %w[index], tasks_index_collapsed: false } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) edit a Task
  # /tasks/:id/edit
  # edit_task_path(:id)
  # edit_task_url(:id)
  def edit
    contact = if params.dig(:contact_id).to_i.positive?
                # working with a specific Contact
                current_user.client.contacts.find_by(id: params[:contact_id].to_i)
              end

    respond_to do |format|
      format.js { render partial: 'tasks/js/show', locals: { cards: %w[edit task_edit_show], task: @task, contact: } }
      format.html { redirect_to root_path }
    end
  end

  # (GET)
  # /tasks
  # tasks_path
  # tasks_url
  def index
    tasks_filter_selected = params.dig(:tasks_filter_selected).to_s
    tasks_filter_user     = params.dig(:tasks_filter_user).to_s

    if %w[all today up_coming past_due someday incomplete].include?(tasks_filter_selected)
      user_settings = current_user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)
      user_settings.data[:tasks_filter] ||= {}
      user_settings.data[:tasks_filter][:selected] = tasks_filter_selected
      user_settings.save
    end

    if (current_user.client.users.pluck(:id).map(&:to_s) << 'all').include?(tasks_filter_user)
      user_settings = current_user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)
      user_settings.data[:tasks_filter] ||= {}
      user_settings.data[:tasks_filter][:user] = tasks_filter_user
      user_settings.save
    end

    if params.dig(:tasks_sort)
      user_settings = current_user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)
      user_settings.data[:tasks_sort] ||= {}
      user_settings.data[:tasks_sort][:col] = (params.dig(:tasks_sort, :col) || 'name').to_s
      user_settings.data[:tasks_sort][:dir] = (params.dig(:tasks_sort, :dir) || 'asc').to_s
      user_settings.save
    end

    respond_to do |format|
      format.js   { render partial: 'tasks/js/show', locals: { cards: %w[index], task: params.dig(:task_id).to_i, contact: params.dig(:contact_id).to_i } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) show Task edit with a new Task
  # /tasks/new
  # new_task_path
  # new_task_url
  def new
    task = current_user.client.tasks.new

    if params.dig(:contact_id).to_i.positive? && (contact = current_user.client.contacts.find_by(id: params[:contact_id].to_i))
      task.contact_id = contact.id
      task.user_id    = contact.user_id
    else
      task.user_id = current_user.id
      contact      = nil
    end

    respond_to do |format|
      format.js { render partial: 'tasks/js/show', locals: { cards: %w[edit task_edit_show], task:, contact: } }
      format.html { redirect_to root_path }
    end
  end

  # (PUT/PATCH) save edited Task
  # /tasks/:id
  # task_path(:id)
  # task_url(:id)
  def update
    @task.update(task_params)

    render partial: 'tasks/js/show', locals: { cards: %w[index task_edit_hide], task: params.dig(:task_id).to_i, contact: params.dig(:contact_id).to_i }
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('users', 'tasks', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Tasks', root_path)
  end

  def set_task
    return if (@task = current_user.client.tasks.find_by(id: params[:id]))

    sweetalert_error('Task not found!', 'We were not able to access the Task you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_tasks
    @contact  = current_user.client.contacts.find_by(id: params.dig(:contact_id).to_i)
    @user     = current_user.client.users.find_by(id: params.dig(:user_id).to_i)

    # save Users::Setting
    @user_setting = current_user.user_settings.find_or_initialize_by(controller_action: 'dashboard_cal_tasks')
    @user_setting.data[:all_tasks]            = (params.dig(:all_tasks) || @user_setting.data.dig(:all_tasks)).to_i
    @user_setting.data[:my_tasks]             = ((current_user.admin? ? params.dig(:my_tasks) : nil) || @user_setting.data.dig(:my_tasks)).to_i
    @user_setting.data[:cal_default_view]     = (@user_setting.data.dig(:cal_default_view) || 'timeGridDay').to_s
    @user_setting.data[:task_list][:page]     = (params.dig(:page) || @user_setting.data[:task_list][:page]).to_i
    @user_setting.data[:task_list][:per_page] = (params.dig(:per_page) || @user_setting.data[:task_list][:per_page]).to_i

    if params.dig(:sort)
      sort_order = params.require(:sort).permit(:col, :dir)
      @user_setting.data[:task_list][:sort] = { col: sort_order.dig(:col).to_s, dir: sort_order.dig(:dir).to_s }
    end

    @user_setting.save

    @tasks = if @contact
               # list for a specific Contact
               @contact.tasks
             elsif @user && @user_setting.data[:my_tasks] == 1
               # list Tasks for a specific User
               @user.tasks
             else
               # list Tasks for the current User
               current_user.client.tasks
             end

    case @user_setting.data[:task_list][:sort][:col]
    when 'assign_to'
      @tasks = @tasks.select('tasks.*', 'users.lastname AS lastname', 'users.firstname AS firstname').left_outer_joins(:user)
    when 'contact'
      @tasks = @tasks.select('tasks.*', 'contacts.lastname AS lastname', 'contacts.firstname AS firstname').left_outer_joins(:contact)
    end

    if @user_setting.data[:my_tasks] == 1

      @tasks = if @user
                 @tasks.where(user_id: @user.id)
               else
                 @tasks.where(user_id: current_user.id)
               end
    end

    @tasks = @tasks.includes(:contact, :client, :user)
    @tasks = @tasks.where(completed_at: nil) if @user_setting.data[:all_tasks].to_i.zero?

    if @user_setting.data.dig(:task_list, :sort, :col).to_s.present? && @user_setting.data.dig(:task_list, :sort, :dir).to_s.present?

      case @user_setting.data[:task_list][:sort][:col]
      when 'name'
        @tasks = @tasks.order(name: @user_setting.data[:task_list][:sort][:dir].to_sym, due_at: @user_setting.data[:task_list][:sort][:dir].to_sym, completed_at: @user_setting.data[:task_list][:sort][:dir].to_sym)
      when 'assign_to', 'contact'
        @tasks = @tasks.order(lastname: @user_setting.data[:task_list][:sort][:dir].to_sym, firstname: @user_setting.data[:task_list][:sort][:dir].to_sym, due_at: :asc, completed_at: :asc)
      when 'due_date'
        @tasks = @tasks.order(due_at: @user_setting.data[:task_list][:sort][:dir].to_sym, name: @user_setting.data[:task_list][:sort][:dir].to_sym)
      when 'completed'
        @tasks = @tasks.order(completed_at: @user_setting.data[:task_list][:sort][:dir].to_sym, due_at: @user_setting.data[:task_list][:sort][:dir].to_sym, name: @user_setting.data[:task_list][:sort][:dir].to_sym)
      end
    end

    @tasks = @tasks.page(@user_setting.data[:task_list][:page]).per(@user_setting.data[:task_list][:per_page])
  end

  def task_params
    sanitized_params = params.require(:task).permit(:name, :from_phone, :description, :user_id, :contact_id, :campaign_id, :due_at, :completed_at, :deadline_at, :cancel_after)

    sanitized_params[:due_at]       = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:due_at]) } if sanitized_params[:due_at] && sanitized_params[:due_at].to_s.present?
    sanitized_params[:completed_at] = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:completed_at]) } if sanitized_params[:completed_at] && sanitized_params[:completed_at].to_s.present?
    sanitized_params[:deadline_at]  = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:deadline_at]) } if sanitized_params[:deadline_at] && sanitized_params[:deadline_at].to_s.present?
    sanitized_params[:cancel_after] = sanitized_params[:cancel_after].to_i if sanitized_params.include?(:cancel_after)
    sanitized_params[:campaign_id]  = sanitized_params[:campaign_id].to_i if sanitized_params.include?(:campaign_id)

    sanitized_params
  end
end
