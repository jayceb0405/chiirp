# frozen_string_literal: true

# app/controllers/clients/holidays_controller.rb
module Clients
  class HolidaysController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :holiday, only: %i[edit destroy update]

    # (POST) save a newly created holiday
    # /clients/holidays
    # clients_holidays_path
    # clients_holidays_url
    def create
      @client.holidays.create(params_holiday)

      render partial: 'clients/js/show', locals: { cards: %w[holidays_index] }
    end

    # (GET) display a holiday to edit
    # /clients/holidays/:id/edit
    # edit_clients_holiday_path(:id)
    # edit_clients_holiday_url(:id)
    def edit
      render partial: 'clients/js/show', locals: { cards: %w[holidays_edit] }
    end

    # (DELETE) destroy a holiday
    # /clients/holidays/:id
    # clients_holiday_path(:id)
    # clients_holiday_url(:id)
    def destroy
      @holiday.destroy

      render partial: 'clients/js/show', locals: { cards: %w[holidays_index] }
    end

    # (GET) list all holidays
    # /clients/holidays
    # clients_holidays_path
    # clients_holidays_url
    def index
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[holidays_index] } }
        format.html { render 'clients/show', locals: { client_page_section: 'holidays' } }
      end
    end

    # (GET) start a new holiday
    # /clients/holidays/new
    # new_clients_holiday_path
    # new_clients_holiday_url
    def new
      @holiday = @client.holidays.create

      render partial: 'clients/js/show', locals: { cards: %w[holidays_new] }
    end

    # (PATCH/PUT) save updated holiday
    # /clients/holidays/:id
    # clients_holiday_path(:id)
    # clients_holiday_url(:id)
    def update
      @holiday.update(params_holiday)

      if params.dig(:adjust_existing_actions).present? && params[:adjust_existing_actions].to_bool
        @holiday.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('holiday_adjust_delayed_jobs'),
          queue:               DelayedJob.job_queue('holiday_adjust_delayed_jobs'),
          user_id:             current_user.id,
          contact_id:          0,
          triggeraction_id:    0,
          contact_campaign_id: 0,
          group_process:       0,
          process:             'holiday_adjust_delayed_jobs',
          data:                {}
        ).adjust_delayed_jobs
      end

      render partial: 'clients/js/show', locals: { cards: %w[holidays_index] }
    end

    private

    def client
      return if (@client = current_user.client)

      sweetalert_error('Client NOT found!', 'We were not able to access the client you requested.', '', { persistent: 'OK' }) if current_user.team_member?

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def holiday
      return if (@holiday = @client.holidays.find_by(id: params.dig(:id)))

      sweetalert_error('Holiday NOT found!', 'We were not able to access the holiday you requested.', '', { persistent: 'OK' })

      render js: "window.location = '#{clients_holidays_path}'" and return false
    end

    def params_holiday
      sanitized_params = params.require(:clients_holiday).permit(:name, :occurs_at, :action)

      sanitized_params[:occurs_at] = Chronic.parse(sanitized_params.dig(:occurs_at).to_s).to_date

      sanitized_params
    end
  end
end
