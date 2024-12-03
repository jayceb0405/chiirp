# frozen_string_literal: true

# app/controllers/api/v2/clients/widgets_controller.rb
module Api
  module V2
    module Clients
      # endpoints supporting SiteChat V2
      class WidgetsController < ApplicationController
        skip_before_action :verify_authenticity_token, only: %i[save_contact show_widget show_widget_bubble sitechat]
        before_action :authenticate_user!, only: %i[button_image create edit new update]
        before_action :authorize_user!, only: %i[button_image create edit new update]
        before_action :client, only: %i[button_image create edit new update]
        before_action :client_widget_by_key, only: %i[save_contact show_widget show_widget_bubble sitechat]
        before_action :client_widget_by_id, only: %i[button_image edit update]
        before_action :authorize_client!
        after_action :allow_iframe, only: %i[save_contact show_widget show_widget_bubble sitechat]

        # (PATCH)
        # /api/v2/clients/widgets/:id/button_image
        # api_v2_clients_edit_widget_button_image_path(:id)
        # api_v2_clients_edit_widget_button_image_url(:id)
        def button_image
          image_delete = params.dig(:image_delete).to_bool

          if image_delete
            # deleting an image
            @client_widget.button_image.purge
          else
            button_image = params.require(:clients_widget).permit(:button_image).dig(:button_image)
            @client_widget.update(button_image:)
          end

          @client_widgets = current_user.client.client_widgets.order(:widget_name)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v2' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (POST) create a new Clients::Widget
        # /api/v2/clients/widgets
        # api_v2_clients_widgets_path
        # api_v2_clients_widgets_url
        def create
          @client_widget = @client.client_widgets.create(params_client_widget)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v2' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (GET) show an existing Clients::Widget to edit
        # /api/v2/clients/widgets/:id/edit
        # edit_api_v2_clients_widget_path(:id)
        # edit_api_v2_clients_widget_url(:id)
        def edit
          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit], version: 'v2' } }
            format.html { render 'clients/widgets/index' }
          end
        end

        # (GET) show a new Clients::Widget to edit
        # /api/v2/clients/widgets/new
        # new_api_v2_clients_widget_path
        # new_api_v2_clients_widget_url
        def new
          @client_widget = current_user.client.client_widgets.new(widget_name: 'New SiteChat Button', version: 'v2')

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit], version: 'v2' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (GET) javascript to display SiteChat button
        # /api/v2/clients/sitechat/:widget_key
        # api_v2_clients_clients_widgets_path(:widget_key)
        # api_v2_clients_sitechat_url(:widget_key)
        def sitechat
          # TODO: Remove this JsonLog
          # Probably don't need this anymore, this data should be in the Lograge controller log
          JsonLog.info 'Api::V2::Clients::WidgetsController.sitechat', { referer: request.referer }
          @client_widget_user = @client_widget.client.users.find_by(id: @client_widget.image_user_id.to_i)

          respond_to do |format|
            format.js   { render 'clients/widgets/v2/sitechat' }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
          end
        end

        # (POST) save Contact Message
        # /api/v2/clients/:client_id/widget/:widget_key
        # api_v2_clients_save_widget_contact_path(:client_id, :widget_key)
        # api_v2_clients_save_widget_contact_url(:client_id, :widget_key)
        def save_contact
          contact_data = params_contact

          @contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_widget.client_id, phones: { contact_data[:phone] => 'mobile' })
          @contact.update(
            lastname:  contact_data[:lastname],
            firstname: contact_data[:firstname],
            ok2text:   1,
            sleep:     false
          )

          unless @contact.errors.any?
            Integrations::Searchlight::V1::PostWidgetJob.perform_later(
              action_at:        Time.current,
              client_id:        @client_widget.client_id,
              client_widget_id: @client_widget.id,
              contact_id:       @contact.id,
              user_id:          @contact.user_id
            )

            message = @contact.messages.create({
                                                 automated:  false,
                                                 from_phone: @contact.primary_phone&.phone.to_s.strip.presence || 'widget',
                                                 message:    params.dig(:question).to_s.strip.presence || 'SiteChat - no message',
                                                 msg_type:   'widgetin',
                                                 status:     'received',
                                                 to_phone:   @contact.latest_client_phonenumber(current_session: session, default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
                                               })

            @contact.process_actions(
              campaign_id: @client_widget.campaign_id,
              group_id:    @client_widget.group_id,
              stage_id:    @client_widget.stage_id,
              tag_id:      @client_widget.tag_id
            )

            Users::SendPushJob.perform_later(
              contact_id: message.contact_id,
              content:    "#{message.contact.fullname}: #{message.message}",
              title:      'SiteChat Message Received',
              type:       'sitechat',
              url:        central_url(contact_id: message.contact_id),
              user_id:    message.contact.user_id
            )

            show_live_messenger = ShowLiveMessenger.new(message:)
            show_live_messenger.queue_broadcast_active_contacts
            show_live_messenger.queue_broadcast_message_thread_message

            flash.notice = "Thank You#{@contact.firstname.present? ? " #{@contact.firstname}" : ''}!<br />Your question was submitted."
          end

          if @client_widget.auto_popup.to_i == 1

            if cookies[:sitechat].to_i == 1
              @client_widget.auto_popup = 0
            else
              cookies[:sitechat] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v2/show_widget', layout: false, status: :ok }
          end
        end

        # (GET) show widget button
        # /api/v2/clients/widget/:widget_key
        # api_v2_clients_show_widget_path(:widget_key)
        # api_v2_clients_show_widget_url(:widget_key)
        def show_widget
          # TODO: Remove this JsonLog
          # Probably don't need this anymore, this data should be in the Lograge controller log
          JsonLog.info 'Api::V2::Clients::WidgetsController.show_widget', { referer: request.referer }
          @client_widget_user = @client_widget.client.users.find_by(id: @client_widget.image_user_id.to_i)

          if @client_widget.auto_popup.to_i == 1

            if cookies[:sitechat].to_i == 1
              @client_widget.auto_popup = 0
            else
              cookies[:sitechat] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v2/show_widget', layout: false, status: :ok }
          end
        end

        # (GET) show widget bubble
        # /api/v2/clients/widget_bubble/:widget_key
        # api_v2_clients_show_widget_bubble_path(:widget_key)
        # api_v2_clients_show_widget_bubble_url(:widget_key)
        def show_widget_bubble
          # TODO: Remove this JsonLog
          # Probably don't need this anymore, this data should be in the Lograge controller log
          JsonLog.info 'Api::V2::Clients::WidgetsController.show_widget_bubble', { referer: request.referer }
          @client_widget_user = @client_widget.client.users.find_by(id: @client_widget.image_user_id.to_i)

          if @client_widget.auto_popup.to_i == 1

            if cookies[:sitechat].to_i == 1
              @client_widget.auto_popup = 0
            else
              cookies[:sitechat] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v2/show_widget_bubble', layout: false, status: :ok }
          end
        end

        # (PUT/PATCH) update an existing Clients::Widget
        # /api/v2/clients/widgets/:id
        # api_v2_clients_widget_path(:id)
        # api_v2_clients_widget_url(:id)
        def update
          @client_widget.update(params_client_widget)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v2' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        private

        def authorize_client!
          return if super(@client_widget&.client || @client)

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok and return false }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok and return false }
          end
        end

        def authorize_user!
          super

          return if current_user.access_controller?('widgets', 'allowed', session)

          raise ExceptionHandlers::UserNotAuthorized.new('SiteChat', root_path)
        end

        def params_client_widget
          response = params.require(:clients_widget).permit(
            :widget_name, :campaign_id, :tag_id, :group_id, :stage_id,
            :title, :tag_line, :submit_button_text, :text_message, :auto_popup,
            :submit_button_color, :background_color, :image_user_id, :show_user_avatar, :button_image,
            :show_bubble, :bubble_text, :bubble_color, :show_question, :default_question
          )

          response[:campaign_id]      = response[:campaign_id].to_i if response.include?(:campaign_id)
          response[:tag_id]           = response[:tag_id].to_i if response.include?(:tag_id)
          response[:stage_id]         = response[:stage_id].to_i if response.include?(:stage_id)
          response[:group_id]         = response[:group_id].to_i if response.include?(:group_id)
          response[:image_user_id]    = response[:image_user_id].to_i if response.include?(:image_user_id)
          response[:show_user_avatar] = response[:show_user_avatar].to_i if response.include?(:show_user_avatar)
          response[:show_bubble]      = response[:show_bubble].to_i == 1 if response.include?(:show_bubble)
          response[:show_question]    = response[:show_question].to_bool if response.include?(:show_question)
          response[:version]          = 'v2'

          response
        end

        def params_contact
          sanitized_params = params.require(:client_widget).permit(:fullname, :phone)

          if sanitized_params.dig(:fullname).to_s.present?
            fullname = sanitized_params[:fullname].to_s.parse_name
            sanitized_params[:firstname] = fullname[:firstname] if sanitized_params[:firstname].to_s.blank?
            sanitized_params[:lastname]  = fullname[:lastname] if sanitized_params[:lastname].to_s.blank?
          else
            sanitized_params[:firstname] = sanitized_params.dig(:firstname).to_s
            sanitized_params[:lastname]  = sanitized_params.dig(:lastname).to_s
          end

          sanitized_params.except(:fullname)
        end

        def client
          @client = current_user.client
        end

        def client_widget_by_id
          return if (@client_widget = @client.client_widgets.find_by(id: params.permit(:id).dig(:id).to_i))

          sweetalert_error('SiteChat NOT found!', 'We were not able to access the SiteChat you requested.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{clients_widgets_path}'" and return false }
            format.html { redirect_to clients_widgets_path and return false }
          end
        end

        def client_widget_by_key
          return if (@client_widget = ::Clients::Widget.find_by(widget_key: params.permit(:widget_key).dig(:widget_key).to_s))

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok and return false }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok and return false }
          end
        end
      end
    end
  end
end
