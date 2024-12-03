# frozen_string_literal: true

# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :user_settings_buttons, only: %i[destroy edit index_tasks show update update_buttons update_period]
  before_action :user_setting_cal_tasks, only: %i[show update_cal_tasks]

  # (GET) reply with json calendar events (scheduled group actions)
  # user_cal_actions_path(id)
  # /dashboard/cal_actions
  # cal_actions_dashboard_path
  # cal_actions_dashboard_url
  def cal_actions
    # rubocop:disable Rails/OutputSafety
    render json: DelayedJob.scheduled_actions(current_user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).map { |x| { id: x[:id], user_id: x[:user_id], title: x[:title], start: Time.strptime(x[:min_run_at].strftime('%Y-%m-%dT%H:%M:%S%z'), '%Y-%m-%dT%H:%M:%S%z').in_time_zone(current_user.client.time_zone).strftime('%FT%T%:z') } }.to_json.html_safe, status: :ok
    # rubocop:enable Rails/OutputSafety
  end

  # (GET) reply with json calendar events (scheduled messages)
  # /dashboard/cal_msgs
  # cal_msgs_dashboard_path
  # cal_msgs_dashboard_url
  def cal_msgs
    # rubocop:disable Rails/OutputSafety
    render json: DelayedJob.scheduled_messages(current_user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).map { |x| { id: x[:id], contact_id: x[:contact_id], title: x[:title], start: Time.strptime(x[:start].strftime('%Y-%m-%dT%H:%M:%S%z'), '%Y-%m-%dT%H:%M:%S%z').in_time_zone(current_user.client.time_zone).strftime('%FT%T%:z') } }.to_json.html_safe, status: :ok
    # rubocop:enable Rails/OutputSafety
  end

  # (GET) reply with json calendar events (tasks)
  # /dashboard/cal_tasks
  # cal_tasks_dashboard_path
  # cal_tasks_dashboard_url
  def cal_tasks
    # rubocop:disable Rails/OutputSafety
    render json: Task.scheduled(current_user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).map { |t| { 'id' => t.id, 'contact_id' => t.contact_id, 'title' => t.name.to_s, 'start' => Time.strptime(t.due_at.strftime('%Y-%m-%dT%H:%M:%S%z'), '%Y-%m-%dT%H:%M:%S%z').in_time_zone(current_user.client.time_zone).strftime('%FT%T%:z') } }.to_json.html_safe, status: :ok
    # rubocop:enable Rails/OutputSafety
  end

  # (POST) save a new dashboard config
  # /dashboards
  # dashboards_path
  # dashboards_url
  def create
    new_user_settings.update(params_dashboard_buttons)

    respond_to do |format|
      format.js { render partial: 'dashboards/js/show', locals: { cards: %w[header buttons hide_config] } }
      format.html { redirect_to root_path }
    end
  end

  # (DELETE) destroy a dashboard config
  # /dashboards/:id
  # dashboard_path(:id)
  # dashboard_url(:id)
  def destroy
    @user_settings_buttons.destroy
    @user_settings_buttons = current_user.user_settings.find_by(controller_action: 'dashboard_buttons', current: 1) || current_user.user_settings.find_or_initialize_by(controller_action: 'dashboard_buttons')
    @user_settings_buttons.current = 1
    @user_settings_buttons.name    = 'My Dashboard' if @user_settings_buttons.name.blank?
    @user_settings_buttons.save

    respond_to do |format|
      format.js { render partial: 'dashboards/js/show', locals: { cards: %w[header buttons] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) show dashboard config
  # /dashboards/:id/edit
  # edit_dashboard_path(:id)
  # edit_dashboard_url(:id)
  def edit
    respond_to do |format|
      format.js { render partial: 'dashboards/js/show', locals: { cards: %w[config show_config] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET)
  # /dashboards/tasks
  # index_tasks_dashboard_path
  # index_tasks_dashboard_url
  def index_tasks
    @user_settings_buttons.data[:user_for_tasks] = params.dig(:user_for_tasks).to_i
    @user_settings_buttons.save

    render partial: 'dashboards/js/show', locals: { cards: %w[show_tasks] }
  end

  # (GET) show a new dashboard config
  # /dashboards/new
  # new_dashboard_path
  # new_dashboard_url
  def new
    respond_to do |format|
      format.js { render partial: 'dashboards/js/show', locals: { cards: %w[config show_config], new_dashboard: true } }
      format.html { redirect_to root_path }
    end
  end

  # (GET) show dashboard
  # /users/:user_id/dashboard
  # user_dashboard_path(:user_id)
  # user_dashboard_url(:user_id)
  # /dashboards/:id
  # dashboard_path(:id)
  # dashboard_url(:id)
  def show
    @user_settings_buttons.current = 1
    @user_settings_buttons.name    = 'My Dashboard' if @user_settings_buttons.name.blank?
    @user_settings_buttons.save

    unless @phone_number_assigned && @contact_created && @user_phone_defined
      @client    = current_user.client
      @twnumber  = @client.twnumbers.new
      @twnumbers = @client.twnumbers.order(:name, :phonenumber)
    end

    respond_to do |format|
      format.html { render "dashboards/dashboard/#{@phone_number_assigned && @contact_created && @user_phone_defined ? 'full' : 'onboard'}" }
      format.js   { render partial: 'dashboards/js/show', locals: { cards: %w[header buttons] } }
    end
  end

  # (GET) renders a button in the Dashboard
  # /dashboards/buttons/:type
  # button_show_dashboard_path(:user_id)
  # button_show_dashboard_url(:user_id)
  def show_button
    @dashboard_button_type = params[:type]
    @dashboard_button_id = params[:id]
  end

  # (PUT/PATCH) update dashboard config
  # /dashboards/:id
  # dashboard_path(:id)
  # dashboard_url(:id)
  def update
    @user_settings_buttons.update(params_dashboard_buttons)

    render partial: 'dashboards/js/show', locals: { cards: %w[header buttons hide_config] }
  end

  # (PUT/PATCH) save new order for dashboard buttons
  # /dashboards/buttons/:id
  # buttons_dashboard_path(:id)
  # buttons_dashboard_url(:id)
  def update_buttons
    @user_settings_buttons.data[:dashboard_buttons] = params.permit(dashboard_buttons: []).dig(:dashboard_buttons) || []
    @user_settings_buttons.save

    head :accepted
  end

  # (PATCH) save Users::Setting "dashboard_cal_tasks"
  # /dashboard/cal_tasks
  # cal_tasks_dashboard_path
  # cal_tasks_dashboard_url
  def update_cal_tasks
    @user_setting_cal_tasks.update(params_dashboard_cal_tasks)

    respond_to do |format|
      format.js { render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok }
      format.html { redirect_to root_path }
    end
  end

  # Example:
  # /dashboard/period/:id
  # period_dashboard_path(:id)
  # period_dashboard_url(:id)
  def update_period
    @user_settings_buttons.update(params_dynamic_period)

    render partial: 'dashboards/js/show', locals: { cards: %w[header buttons] }
  end

  # (PATCH) set 1 or many Tasks as complete
  # /dashboards/task_complete
  # task_complete_path
  # task_complete_url
  def update_task_complete
    task_id        = params.dig(:task_id).to_i
    task_filter    = params.dig(:task_filter).to_s
    user_for_tasks = params.dig(:user_for_tasks).to_i

    if task_id.positive? && user_for_tasks.positive? && (task = current_user.client.tasks.find_by(id: task_id, user_id: user_for_tasks))
      task.update(completed_at: Time.current)
    elsif %w[past current future].include?(task_filter)
      case task_filter
      when 'past'
        tasks = current_user.client.tasks.past_due.where(user_for_tasks.zero? ? '1=1' : "user_id=#{user_for_tasks}")
      when 'current'
        tasks = current_user.client.tasks.current.where(user_for_tasks.zero? ? '1=1' : "user_id=#{user_for_tasks}")
      when 'future'
        tasks = current_user.client.tasks.future.where(user_for_tasks.zero? ? '1=1' : "user_id=#{user_for_tasks}")
      end

      # rubocop:disable Rails/SkipsModelValidations
      tasks.update_all(completed_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end

    render partial: 'dashboards/js/show', locals: { cards: %w[show_tasks] }
  end

  private

  def authorize_user!
    super
    return if current_user&.access_controller?('dashboard', 'allowed', session)

    if current_user&.access_controller?('my_contacts', 'allowed', session)
      redirect_path = my_contacts_path
    elsif current_user&.access_controller?('central', 'allowed', session)
      redirect_path = central_path
    elsif current_user&.access_controller?('user', 'allowed', session)
      redirect_path = edit_users_overview_path(current_user.id)
    elsif current_user.nil?
      redirect_path = new_user_session_path
    else
      sign_out_and_redirect(current_user) and return false
    end

    raise ExceptionHandlers::UserNotAuthorized.new('Dashboard', redirect_path)
  end

  def new_user_settings
    response = current_user.user_settings.new(
      controller_action: 'dashboard_buttons',
      name:              '',
      current:           1,
      data:              {
        dynamic: 'l30',
        from:    '',
        to:      ''
      }
    )
    response.data[:dashboard_buttons] = response.dashboard_buttons_default

    response
  end

  def params_dashboard_buttons
    response = if defined?(@user_settings_buttons)
                 @user_settings_buttons.attributes.symbolize_keys
               else
                 new_user_settings.attributes.symbolize_keys
               end

    # split custom dates only if received
    sanitized_params = params.require(:user_setting).permit(:dynamic_period, :custom_period, :name, :buttons_user_id, dashboard_buttons: [])

    response[:data][:buttons_user_id]   = (sanitized_params.dig(:buttons_user_id) || current_user.id).to_i
    response[:name]                     = (sanitized_params.dig(:name) || response[:name]).to_s

    dashboard_buttons                   = sanitized_params.dig(:dashboard_buttons) || []
    dashboard_buttons.delete('')
    response[:data][:dashboard_buttons] = dashboard_buttons if dashboard_buttons.sort != response.dig(:data, :dashboard_buttons).sort

    response[:data][:dynamic]           = 'l30' if response[:data][:dynamic].empty? && response[:data][:from].empty? && response[:data][:to].empty?

    response
  end

  def params_dashboard_cal_tasks
    response = @user_setting_cal_tasks.attributes.symbolize_keys

    # set default calendar view only if received
    response[:data][:cal_default_view] = params.permit(:cal_default_view).to_h[:cal_default_view] if params.include?(:cal_default_view)

    response
  end

  def params_dynamic_period
    response = @user_settings_buttons.attributes.symbolize_keys

    sanitized_params = params.require(:user_setting).permit(:dynamic_period, :custom_period)

    if sanitized_params.dig(:dynamic_period).to_s.present?
      response[:data][:dynamic] = sanitized_params.dig(:dynamic_period).to_s
      response[:data][:from]    = ''
      response[:data][:to]      = ''
    elsif sanitized_params.dig(:custom_period).to_s.present?
      custom_dates = sanitized_params.dig(:custom_period).to_s.split(' to ')

      response[:data][:dynamic] = ''
      response[:data][:from]    = custom_dates[0].to_s
      response[:data][:to]      = custom_dates[1].present? ? custom_dates[1].to_s : Chronic.parse(response[:data][:from]).end_of_day.strftime('%m/%d/%Y %I:%M %p')
    else
      response[:data][:dynamic] = 'td'
      response[:data][:from]    = ''
      response[:data][:to]      = ''
    end

    response
  end

  def user_settings_buttons
    @user_settings_buttons = current_user.user_settings.find_or_initialize_by(controller_action: 'dashboard_buttons', current: 1) unless params.dig(:id).to_i.positive? && (@user_settings_buttons = current_user.user_settings.find_by(id: params[:id]))
  end

  def user_setting_cal_tasks
    @user_setting_cal_tasks = current_user.user_settings.find_or_initialize_by(controller_action: 'dashboard_cal_tasks')
  end
end
