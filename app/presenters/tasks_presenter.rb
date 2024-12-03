# frozen_string_literal: true

# app/presenters/tasks_presenter.rb
class TasksPresenter
  attr_reader :client, :contact, :task, :user

  def initialize(args = {})
    self.user     = args.dig(:user)
    self.client   = args.dig(:client)
    self.task     = args.dig(:task)
    self.contact  = args.dig(:contact)

    @user_settings         = nil
    @user_tasks            = nil
  end

  def client=(client)
    @client = if client.is_a?(Client)
                client
              elsif client.is_a?(Integer)
                Client.find_by(id: client)
              elsif self.task&.client
                self.task.client
              elsif self.user.is_a?(User)
                self.user.client
              elsif self.contact.is_a?(Contact)
                self.contact.client
              else
                Client.new
              end
  end

  def contact=(contact)
    @contact = if contact.is_a?(Contact)
                 contact
               elsif contact.is_a?(Integer) && contact.positive?
                 Contact.find_by(id: contact)
               elsif self.task&.contact
                 self.task.contact
               elsif self.user.is_a?(User)
                 self.user.contacts.new
               elsif self.client.is_a?(Client)
                 self.client.contacts.new
               else
                 Contact.new
               end
  end

  def contact_name
    self.contact.fullname_or_phone
  end

  def deadline_at_string
    self.task.deadline_at ? self.task.deadline_at.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y %H:%M %p') : ''
  end

  def due_at_string
    self.task.due_at ? self.task.due_at.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y %H:%M %p') : ''
  end

  def new_sort_dir
    if self.user_settings.data.dig(:task_list, :sort, :dir).to_s.present?
      if self.user_settings.data.dig(:task_list, :sort, :dir).to_s == 'asc'
        'desc'
      else
        self.user_settings.data.dig(:task_list, :sort, :dir).to_s == 'desc' ? '' : 'asc'
      end
    else
      'asc'
    end
  end

  def page
    (self.user_settings.data.dig(:pagination, :page) || 1).to_i
  end

  def per_page
    (self.user_settings.data.dig(:pagination, :per_page) || 10).to_i
  end

  def task=(task)
    @task = if task.is_a?(Task)
              task
            elsif task.is_a?(Integer)
              Task.find_by(id: task)
            elsif self.client.is_a?(Client)
              Task.new(user_id: self.user&.id, client_id: self.client&.id, contact_id: self.contact&.id)
            else
              Task.new
            end
  end

  def task_contact_string
    self.contact.is_a?(Contact) && !self.contact.new_record? ? self.contact.fullname_or_phone : 'Unassigned'
  end

  def task_days(created_at, due_at, completed_at)
    if due_at.present?
      ((due_at - created_at) / (60 * 60 * 24)).to_i
    else
      (completed_at.present? ? ((completed_at - created_at) / (60 * 60 * 24)).to_i : 0)
    end
  end

  def task_ontime?(created_at, due_at, completed_at)
    self.task_days(created_at, due_at, completed_at).zero? ? true : self.task_days(created_at, due_at, completed_at) >= self.task_progress_elapsed_days(created_at, completed_at)
    # (completed_at.present? && due_at.present? && completed_at <= due_at) || (due_at.present? && due_at >= Time.current) || (due_at.nil? && completed_at.nil?)
  end

  def task_progress(created_at, due_at, completed_at)
    if self.task_ontime?(created_at, due_at, completed_at)
      due_at.nil? && completed_at.nil? ? 100 : (self.task_progress_elapsed_days(created_at, completed_at) / self.task_days(created_at, due_at, completed_at).to_f) * 100
    else
      100
    end
  end

  def task_progress_elapsed_days(created_at, completed_at)
    (((completed_at.presence || Time.current) - created_at) / (60 * 60 * 24)).to_i
  end

  def task_progress_label(created_at, due_at, completed_at)
    if completed_at.nil?
      self.task_ontime?(created_at, due_at, completed_at) ? 'On Time' : 'Past Due'
    else
      'Completed'
    end
  end

  def task_user_assigned_string
    if !self.user.is_a?(User) || self.user.new_record?
      'Unassigned'
    elsif self.user.id == self.task.user_id
      self.user.fullname
    else
      self.task.user.fullname
    end
  end

  def tasks_filter_selected
    (self.user_settings.data.dig(:tasks_filter, :selected) || 'all').to_s
  end

  def tasks_filter_selected_options
    [
      ['All Tasks', 'all'],
      ['Today\'s Tasks', 'today'],
      ['Up Coming Tasks', 'up_coming'],
      ['Past Due Tasks', 'past_due'],
      %w[Someday someday],
      %w[Incomplete incomplete]
    ]
  end

  def tasks_filter_user
    if self.user.admin?
      (self.user_settings.data.dig(:tasks_filter, :user) || self.user.id).to_s
    else
      self.user.id.to_s
    end
  end

  def tasks_filter_user_options
    if self.user.admin?
      [
        ['All Users', 'all']
      ] + self.client.users.order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), user[0].to_s] }
    else
      [[self.user.fullname, self.user.id]]
    end
  end

  def tasks_sort_col
    (self.user_settings.data.dig(:tasks_sort, :col) || 'name').to_s
  end

  def tasks_sort_dir
    (self.user_settings.data.dig(:tasks_sort, :dir) || 'asc').to_s
  end

  def tasks_sort_order_selected(col, dir)
    self.tasks_sort_col == col && self.tasks_sort_dir == dir ? 'unread' : ''
  end

  def text_color_for_date(created_at, due_at, completed_at)
    self.task_ontime?(created_at, due_at, completed_at) ? 'text-muted' : 'text-danger'
  end

  def text_color_for_progress_bar(created_at, due_at, completed_at)
    self.task_ontime?(created_at, due_at, completed_at) ? 'success' : 'danger'
  end

  def text_days_remaining(created_at, due_at, completed_at)
    if completed_at.present?
      "Completed in #{ActionController::Base.helpers.pluralize(self.task_progress_elapsed_days(created_at, completed_at), 'day', 'days')}"
    elsif due_at.present?
      if self.task_ontime?(created_at, due_at, completed_at)
        "#{ActionController::Base.helpers.pluralize(task_days(created_at, due_at, completed_at) - task_progress_elapsed_days(created_at, completed_at), 'Day', 'Days')} Remaining"
      else
        "#{ActionController::Base.helpers.pluralize(task_progress_elapsed_days(created_at, completed_at) - task_days(created_at, due_at, completed_at), 'Day', 'Days')} Past Due"
      end
    else
      "#{ActionController::Base.helpers.pluralize(task_progress_elapsed_days(created_at, completed_at), 'day', 'days')} Elapsed"
    end
  end

  def user=(user)
    @user = if user.is_a?(User)
              user
            elsif user.is_a?(Integer) && user.positive?
              User.find_by(id: user)
            elsif self.task&.user
              self.task.user
            elsif self.contact.is_a?(Contact)
              self.contact.user
            elsif self.client.is_a?(Client)
              self.client.users.new
            else
              User.new
            end
  end

  def user_settings
    @user_settings ||= self.user.user_settings.find_or_create_by(controller_action: 'tasks_index', current: 1)
    self.user_settings_initialize if @user_settings.new_record?

    @user_settings
  end

  # rubocop:disable Style/OptionalBooleanParameter
  def user_tasks(paginate = true)
    # rubocop:enable Style/OptionalBooleanParameter
    if @user_tasks.nil?
      @user_tasks = case self.tasks_filter_selected
                    when 'today'
                      Task.current
                    when 'up_coming'
                      Task.future
                    when 'past_due'
                      Task.past_due
                    when 'someday'
                      Task.someday
                    when 'incomplete'
                      Task.incomplete
                    else
                      Task.all
                    end

      @user_tasks = @user_tasks.where(client_id: self.user.client_id)

      @user_tasks = @user_tasks.where(user_id: self.tasks_filter_user) unless self.tasks_filter_user == 'all'

      @user_tasks = @user_tasks.where(contact_id: self.contact.id) unless self.contact.new_record?

      @user_tasks = case self.tasks_sort_col
                    when 'contact'
                      @user_tasks.joins(:contact).select('tasks.*, contacts.lastname, contacts.firstname').order(lastname: self.tasks_sort_dir.to_sym, firstname: self.tasks_sort_dir.to_sym, name: self.tasks_sort_dir.to_sym)
                    when 'user'
                      @user_tasks.joins(:user).select('tasks.*, users.lastname, users.firstname').order(lastname: self.tasks_sort_dir.to_sym, firstname: self.tasks_sort_dir.to_sym, name: self.tasks_sort_dir.to_sym)
                    when 'name'
                      @user_tasks.order("#{self.tasks_sort_col} #{self.tasks_sort_dir.upcase}")
                    else
                      @user_tasks.order("#{self.tasks_sort_col} #{self.tasks_sort_dir.upcase}, name #{self.tasks_sort_dir.upcase}")
                    end
    end

    if paginate
      self.user_settings.data[:pagination][:page] = 1 if self.page > 1 && self.user_tasks_count <= ((self.page - 1) * self.per_page)

      @user_tasks.page(self.page).per(self.per_page)
    else
      @user_tasks
    end
  end

  def user_tasks_count
    self.user_tasks(false).pluck(:id).count
  end

  def view_all_tasks
    self.user_settings.data.dig(:all_tasks).to_i
  end

  def view_my_tasks
    self.user_settings.data.dig(:my_tasks).to_i
  end

  private

  def user_settings_initialize
    @user_settings.update(data: {
                            tasks_filter: { selected: 'today', user: 'all' },
                            tasks_sort:   { col: 'name', dir: 'desc' },
                            pagination:   { per_page: 10, page: 1 }
                          })
  end
end
