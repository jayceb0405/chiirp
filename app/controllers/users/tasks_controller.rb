# frozen_string_literal: true

# app/controllers/users/tasks_controller.rb
module Users
  class TasksController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!

    # (GET)
    # /users/tasks
    # users_tasks_path
    # users_tasks_url
    def index
      @user = current_user

      if params.dig(:tasks_filter_selected) || params.dig(:per_page) || params.dig(:page)
        user_settings = @user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)

        if params.dig(:tasks_filter_selected).to_s.present?
          user_settings.data[:tasks_filter] ||= {}
          user_settings.data[:tasks_filter][:selected] = params.permit(:tasks_filter_selected)[:tasks_filter_selected]
        end

        if params.dig(:per_page).to_i.positive?
          user_settings.data[:pagination] ||= {}
          user_settings.data[:pagination][:page] = 1 if user_settings.data[:pagination].dig(:per_page).to_i != params.permit(:per_page)[:per_page]
          user_settings.data[:pagination][:per_page] = params.permit(:per_page)[:per_page].to_i
        end

        if params.dig(:page).to_i.positive?
          user_settings.data[:pagination] ||= {}
          user_settings.data[:pagination][:page] = params.permit(:page)[:page].to_i
        end

        user_settings.save
      end

      respond_to do |format|
        format.js   { render partial: 'users/js/show', locals: { cards: %w[index_tasks] } }
        format.html { render 'users/show', locals: { user_page_section: 'tasks' } }
      end
    end

    # (PUT/PATCH)
    # /users/tasks/:id
    # users_task_path(:id)
    # users_task_url(:id)
    def update
      task_id = params.dig(:task_id).to_i

      if params.dig(:task_complete).to_bool && task_id.positive? && (task = @user.tasks.find_by(id: task_id))
        task.update(completed_at: task.completed_at.nil? ? Time.current : nil)
        cards = %w[tasks]
      elsif params.dig(:task_edit).to_bool && task_id.positive? && @user.tasks.find_by(id: task_id)
        cards = %w[edit_tasks show_tasks]
      elsif params.dig(:tasks_filter_selected).to_s.present?
        user_settings = @user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)
        user_settings.data[:tasks_filter] ||= {}
        user_settings.data[:tasks_filter][:selected] = params.permit(:tasks_filter_selected)[:tasks_filter_selected]
        user_settings.save
        cards = %w[tasks]
      end

      render partial: 'users/js/show', locals: { cards:, task_id: }
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('users', 'tasks', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Profile > Tasks', root_path)
    end
  end
end
