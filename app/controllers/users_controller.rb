# frozen_string_literal: true

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[rcvpushtoken validate]
  before_action :authenticate_user!, except: %i[rcvpushtoken validate]
  before_action :set_user, only: %i[edit_mobile destroy_mobile_push file_upload logout send_test_push show update]
  before_action :client, only: %i[create show]

  # (GET) log in as a different User
  # /users/:user_id/become
  # user_become_path(User)
  # user_become_url(User)
  def become
    redirect_path = root_path

    if current_user.agent?

      if (new_user = User.find_by(id: params.permit(:user_id).dig(:user_id))) && [42, 129, 1019, 4348].exclude?(new_user.id)
        if current_user.my_agent_token.present?

          User.where("data->'agency_user_tokens' ?| array[:options]", options: current_user.my_agent_token).find_each do |user|
            user.agency_user_tokens.delete(current_user.my_agent_token)
            user.save
          end
        else
          user_token = RandomCode.new.create(20)
          user_token = RandomCode.new.create(20) while User.where('data @> ?', { my_agent_token: user_token }.to_json).any?

          current_user.update(my_agent_token: user_token)
        end

        new_user.agency_user_tokens << current_user.my_agent_token
        new_user.save
        session[:agency_user_token] = current_user.my_agent_token

        bypass_sign_in new_user

        Rails.logger.info "UsersController#become: #{{ status: :success, user_id: current_user.id, become_user_id: new_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      else
        redirect_path = clients_companies_path
        sweetalert_error('Unable to Log In!', 'User selected was NOT found.', '', { persistent: 'OK', ajax: true })
        Rails.logger.info "UsersController#become: #{{ status: :not_found, user_id: current_user.id, become_user_id: params.dig(:user_id).to_i }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      end
    else
      current_user.update(my_agent_token: '')
      session.delete(:agency_user_token)

      sweetalert_error('Unable to Log In!', 'You are not an Agent or your company does not have Agency access!', '', { persistent: 'OK', ajax: true })
      Rails.logger.info "UsersController#become: #{{ status: :not_agent, user_id: current_user.id, become_user_id: params.dig(:user_id).to_i }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    respond_to do |format|
      format.js { render js: "window.location = '#{redirect_path}'" }
      format.html { redirect_to redirect_path }
    end
  end

  # (DELETE) delete the saved mobile push tokens
  # /users/:user_id/destroy_mobile_push
  # user_push_destroy_mobile_path(:user_id)
  # user_push_destroy_mobile_url(:user_id)
  def destroy_mobile_push
    @user.user_pushes.where(target: 'mobile').destroy_all

    respond_to do |format|
      format.js { render partial: 'users/js/show', locals: { cards: %w[notifications] } }
      format.html { redirect_to client_users_path(@client) }
    end
  end

  # (GET) edit User "phone" in a modal
  # /users/:user_id/editmobile
  # user_edit_mobile_path(:user_id)
  # user_edit_mobile_url(:user_id)
  def edit_mobile
    respond_to do |format|
      format.js { render partial: 'users/js/show', locals: { cards: %w[edit_user_mobile edit_user_mobile_show] } }
      format.html { redirect_to root_path }
    end
  end

  # (POST) upload a file to Cloudinary for a User
  # /users/:user_id/file_upload
  # user_file_upload_path(:user_id)
  # user_file_upload_url(:user_id)
  def file_upload
    file_id       = 0
    file_url      = ''
    error_message = ''

    if params.include?(:file)
      begin
        # upload into User images folder
        user_attachment = @user.user_attachments.create!(image: params[:file])

        file_url = user_attachment.image.thumb.url(resource_type: user_attachment.image.resource_type, secure: true)
        retries  = 0

        while file_url.nil? && retries < 10
          retries += 1
          sleep ProcessError::Backoff.full_jitter(retries:)
          user_attachment.reload
          file_url = user_attachment.image.thumb.url(resource_type: user_attachment.image.resource_type, secure: true)
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('UsersController#file_upload')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            file_url:,
            retries:,
            user_attachment:,
            file:            __FILE__,
            line:            __LINE__
          )
        end

        error_message = 'We encountered an error while attempting to upload your file. Please try again.'
      end
    else
      user_attachment = nil
      error_message   = 'File was NOT received.'
    end

    file_id = user_attachment.id if user_attachment

    respond_to do |format|
      format.json { render json: { fileId: file_id, fileUrl: file_url, errorMessage: error_message, status: 200 } }
      format.html { render plain: 'Invalid format.', content_type: 'text/plain', layout: false, status: :not_acceptable }
    end
  end

  # (GET) log out current_user
  # /users/:user_id/logout
  # user_logout_path(:user_id)
  # user_logout_url(:user_id)
  def logout
    if current_user.my_agent_token.present?

      User.where("data->'agency_user_tokens' ?| array[:options]", options: current_user.my_agent_token).find_each do |user|
        user.agency_user_tokens.delete(current_user.my_agent_token)
        user.save
      end
    end

    sign_out_and_redirect(current_user)
  end

  # (POST) receive a push token for User
  # /users/:user_id/rcvpushtoken
  # user_rcvpushtoken_path(:user_id)
  # user_rcvpushtoken_url(:user_id)
  def rcvpushtoken
    response_status = 200
    response_text   = ''

    unless session.include?(:agency_user_token)
      # logged in as some other User / don't process token

      if params.dig(:user_id).to_i.positive? && params.dig(:token).to_s.present?
        # mobile push token

        if (user = User.find_by(id: params[:user_id].to_i))

          if user.user_pushes.where(target: 'mobile').where('data @> ?', { mobile_key: params[:token].to_s }.to_json).empty?
            # existing User push token was not found / add this token
            user.user_pushes.create(target: 'mobile', mobile_key: params.require(:token).to_s)
          end
        else
          response_status = 404
          response_text   = 'User was NOT found.'
        end
      else
        response_status = 400
        response_text   = 'Invalid parameters. Required parameters: user_id, token.'
      end
    end

    render plain: response_text, content_type: 'text/plain', layout: false, status: response_status
  end

  # (GET) return to self after logging in as different User
  # /users/:user_id/return
  # user_return_to_self_path(:user_id)
  # user_return_to_self_url(:user_id)
  def return_to_self
    session_agency_user_token = session[:agency_user_token].to_s

    return unless session_agency_user_token.present? && (new_user = params.include?(:user_id) ? User.find_by(id: params[:user_id].to_i) : nil) && session_agency_user_token == new_user.my_agent_token

    current_user.agency_user_tokens.delete(new_user.my_agent_token)
    current_user.save
    session.delete(:agency_user_token)

    bypass_sign_in new_user

    Rails.logger.info "UsersController#return_to_self: #{{ logout_user_id: current_user.id, user_id: new_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

    respond_to do |format|
      format.js { render js: "window.location = '#{clients_companies_path}'" }
      format.html { redirect_to clients_companies_path }
    end
  end

  # (POST) send test push notifications
  # /users/:user_id/send_test_push
  # user_push_test_path(:user_id)
  # user_push_test_url(:user_id)
  def send_test_push
    Users::SendPushJob.perform_now(
      content: 'Test Notification',
      target:  %w[desktop mobile],
      title:   'Test',
      user_id: @user.id
    )

    respond_to do |format|
      format.js { render partial: 'users/js/show', locals: { cards: %w[notifications] } }
      format.html { redirect_to client_users_path(@client) }
    end
  end

  # (GET) show My Configuration page
  # /clients/:client_id/users/:id
  # client_user_path(:client_id, :id)
  # client_user_url(:client_id, :id)
  def show
    @contact = @user.contacts.new
    @tag     = @client.tags.new

    # change the default User to the screen User
    @contact.user_id = @user.id

    render 'users/user/show'
  end

  # (PUT/PATCH) update a User
  # /users/:id
  # user_path(:id)
  # user_url(:id)
  def update
    @user.update(phone: params.require(:user).permit(:phone).dig(:phone).to_s)

    if params.dig(:redirect_to).to_s.present?
      respond_to do |format|
        format.js   { render js: "window.location = '#{params[:redirect_to]}'" }
        format.html { redirect_to params[:redirect_to].to_s }
      end
    else
      @client  = @user.client
      @contact = @user.contacts.new

      respond_to do |format|
        format.js   { render partial: 'users/js/show', locals: { cards: [2, 3] } }
        format.html { redirect_to client_users_path(@client) }
      end
    end
  end

  # (POST) receive email & password / validate / return 200/401/404
  # /users/validate
  # user_validate_path
  # user_validate_url
  def validate
    email    = params.dig(:email).to_s
    password = params.dig(:password).to_s
    response = { message: 'Unable to validate password', status: 401, user_id: 0, user_token: '' }

    if email.present? && password.present?
      response = if (user = User.find_for_authentication(email:)) && user.valid_password?(password)
                   { message: 'Password validated.', status: 200, user_id: user.id, user_token: Base64.urlsafe_encode64("#{email}#{password}").strip }
                 else
                   { message: 'Email/Password not found.', status: 404, user_id: 0, user_token: '' }
                 end
    end

    Rails.logger.info "UsersController#{}validate: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

    respond_to do |format|
      format.json { render json: response }
      format.js   { render js: response[:message], layout: false, message: response[:message], status: response[:status], user_id: response[:user_id], user_token: response[:token] }
      format.html { render plain: response[:message], content_type: 'text/plain', layout: false, status: response[:status], user_id: response[:user_id], user_token: response[:token] }
    end
  end

  private

  def client
    return true if params.dig(:client_id).to_i.positive? && (@client = Client.find_by(id: params[:client_id])) && (current_user.team_member? || (current_user.admin? && @client.users.find_by(id: current_user.id)) || (current_user.agent? && @client.my_agencies.include?(current_user.client_id)))
    return true if action_name == 'show' && (@client = @user ? @user.client : current_user.client)

    sweetalert_error('Client NOT found!', 'We were not able to access the Client you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_user
    @user = if %w[central central_call_contact central_sleep destroy_mobile_push file_upload logout send_test_push show_active_contacts show_live_messages].include?(action_name)
              User.find_by(id: params.dig(:user_id).to_i) || current_user
            elsif %w[show edit_mobile].include?(action_name)
              User.find_by(id: params.dig(:id).to_i) || current_user
            else
              User.find_by(id: params.dig(:id).to_i)
            end

    return true if @user && (@user.id == current_user.id || current_user.team_member?)

    sweetalert_error('User NOT found!', 'We were not able to access the person you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
