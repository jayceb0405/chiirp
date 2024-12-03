# frozen_string_literal: true

# app/controllers/api/v3/clients/widgets_controller.rb
module Api
  module V3
    module Clients
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
        # /api/v3/clients/widgets/:id/button_image
        # api_v3_clients_edit_widget_button_image_path(:id)
        # api_v3_clients_edit_widget_button_image_url(:id)
        def button_image
          image_delete = params.permit(:image_delete).dig(:image_delete).to_bool

          if image_delete
            # deleting an image
            @client_widget.button_image.purge
          else
            button_image = params.require(:clients_widget).permit(:button_image).dig(:button_image)
            @client_widget.update(button_image:)
          end

          @client_widgets = current_user.client.client_widgets.order(:widget_name)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v3' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (POST) create a new Clients::Widget
        # /api/v3/clients/widgets
        # api_v3_clients_widgets_path
        # api_v3_clients_widgets_url
        def create
          @client_widget = @client.client_widgets.create(params_client_widget)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v3' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (GET) show an existing Clients::Widget to edit
        # /api/v3/clients/widgets/:id/edit
        # edit_api_v3_clients_widget_path(:id)
        # edit_api_v3_clients_widget_url(:id)
        def edit
          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit], version: 'v3' } }
            format.html { render 'clients/widgets/index' }
          end
        end

        # (GET) show a new Clients::Widget to edit
        # /api/v3/clients/widgets/new
        # new_api_v3_clients_widget_path
        # new_api_v3_clients_widget_url
        def new
          @client_widget = current_user.client.client_widgets.new(widget_name: 'New SiteChat Button', version: 'v3')

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit], version: 'v3' } }
            format.html { redirect_to clients_widgets_path }
          end
        end

        # (GET) javascript to display SiteChat button
        # /api/v3/clients/sitechat/:widget_key
        # api_v3_clients_clients_widgets_path(:widget_key)
        # api_v3_clients_sitechat_url(:widget_key)
        def sitechat
          JsonLog.info 'Api::V3::Clients::WidgetsController.sitechat', { referer: request.referer }
          if @client_widget.bb_show

            if cookies[:bbs].to_i == 1
              @client_widget.bb_show = false
            else
              cookies[:bbs] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js   { render 'clients/widgets/v3/sitechat' }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
          end
        end

        # (POST) save Contact Message
        # /api/v3/clients/:client_id/widget/:widget_key
        # api_v3_clients_save_widget_contact_path(:client_id, :widget_key)
        # api_v3_clients_save_widget_contact_url(:client_id, :widget_key)
        def save_contact
          contact_data   = params_contact
          contact_phones = params_contact_phone

          # convert American date to DateTime
          contact_data[:birthdate] = Chronic.parse(contact_data[:birthdate]) if contact_data.include?(:birthdate)
          contact_data[:email]     = contact_data.dig(:email).to_s

          @contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_widget.client_id, phones: contact_phones, emails: [contact_data[:email]])
          @contact.update(
            lastname:  (contact_data.dig(:lastname) || @contact.lastname).to_s,
            firstname: (contact_data.dig(:firstname) || @contact.firstname).to_s,
            email:     (contact_data.dig(:email) || @contact.email).to_s,
            address1:  (contact_data.dig(:address1) || @contact.address1).to_s,
            address2:  (contact_data.dig(:address2) || @contact.address2).to_s,
            city:      contact_data.dig(:city) || @contact.city.to_s,
            state:     contact_data.dig(:state) || @contact.state.to_s,
            zipcode:   contact_data.dig(:zipcode) || @contact.zipcode.to_s,
            birthdate: contact_data.dig(:birthdate) || @contact.birthdate,
            ok2text:   1,
            ok2email:  1,
            sleep:     false
          )

          unless @contact.errors.any?
            @contact.update_custom_fields(custom_fields: params_client_custom_fields.to_h)

            Integrations::Searchlight::V1::PostWidgetJob.perform_later(
              action_at:        Time.current,
              client_id:        @client_widget.client_id,
              client_widget_id: @client_widget.id,
              contact_id:       @contact.id,
              user_id:          @contact.user_id
            )

            from_phone = contact_phones.find { |k, v| v == 'mobile' }&.first.to_s.clean_phone
            from_phone = contact_phones.keys.map { |p| p.clean_phone if p.clean_phone.length == 10 }.compact_blank.first || 'widget' if from_phone.length != 10
            from_phone = @contact.primary_phone&.phone.to_s.strip.presence || 'widget' if from_phone.length != 10

            message = @contact.messages.create({
                                                 automated:  false,
                                                 from_phone:,
                                                 message:    params.dig(:question).to_s.strip.presence || 'SiteChat - no message',
                                                 msg_type:   'widgetin',
                                                 status:     'received',
                                                 to_phone:   @contact.latest_client_phonenumber(current_session: session, default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
                                               })

            ['All Contacts', params.permit(:dropdown_option).dig(:dropdown_option).to_s].compact_blank.each do |dropdown_option|
              user_id           = @client_widget.w_dd_actions.dig(dropdown_option, 'user_id').to_i
              campaign_id       = @client_widget.w_dd_actions.dig(dropdown_option, 'campaign_id').to_i
              group_id          = @client_widget.w_dd_actions.dig(dropdown_option, 'group_id').to_i
              stage_id          = @client_widget.w_dd_actions.dig(dropdown_option, 'stage_id').to_i
              tag_id            = @client_widget.w_dd_actions.dig(dropdown_option, 'tag_id').to_i
              stop_campaign_ids = @client_widget.w_dd_actions.dig(dropdown_option, 'stop_campaign_ids')&.compact_blank

              @contact.update(user_id:) if user_id.positive?

              @contact.process_actions(
                campaign_id:,
                group_id:,
                stage_id:,
                tag_id:,
                stop_campaign_ids:
              )
            end

            Users::SendPushJob.perform_later(
              contact_id: @contact.id,
              content:    "#{@contact.fullname}: #{message.message}",
              title:      'SiteChat Message Received',
              type:       'sitechat',
              url:        central_url(contact_id: @contact.id),
              user_id:    @contact.user_id
            )

            show_live_messenger = ShowLiveMessenger.new(message:)
            show_live_messenger.queue_broadcast_active_contacts
            show_live_messenger.queue_broadcast_message_thread_message

            flash.notice = "Thank You#{@contact.firstname.present? ? " #{@contact.firstname}" : ''}!<br />Your question was submitted."
          end

          if @client_widget.w_auto_popup

            if cookies[:wap].to_i == 1
              @client_widget.w_auto_popup = false
            else
              cookies[:wap] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v3/show_widget', layout: false, status: :ok }
          end
        end

        # (GET) show widget button
        # /api/v3/clients/widget/:widget_key
        # api_v3_clients_show_widget_path(:widget_key)
        # api_v3_clients_show_widget_url(:widget_key)
        def show_widget
          JsonLog.info 'Api::V3::Clients::WidgetsController.show_widget', { referer: request.referer }
          if @client_widget.w_auto_popup

            if cookies[:wap].to_i == 1
              @client_widget.w_auto_popup = false
            else
              cookies[:wap] = {
                value:   '1',
                expires: 12.hours.from_now
              }
            end
          end

          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v3/show_widget', layout: false, status: :ok }
          end
        end

        # (GET) show widget bubble
        # /api/v3/clients/widget_bubble/:widget_key
        # api_v3_clients_show_widget_bubble_path(:widget_key)
        # api_v3_clients_show_widget_bubble_url(:widget_key)
        def show_widget_bubble
          JsonLog.info 'Api::V3::Clients::WidgetsController.show_widget_bubble', { referer: request.referer }
          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { render 'clients/widgets/v3/show_bubble', layout: false, status: :ok }
          end
        end

        # (PUT/PATCH) update an existing Clients::Widget
        # /api/v3/clients/widgets/:id
        # api_v3_clients_widget_path(:id)
        # api_v3_clients_widget_url(:id)
        def update
          @client_widget.update(params_client_widget)

          respond_to do |format|
            format.js { render partial: 'clients/widgets/js/show', locals: { cards: %w[edit dropdown], version: 'v3' } }
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

        def general_form_fields
          ::Webhook.internal_key_hash((@client_widget&.client || @client), 'contact', %w[personal ext_references]).keys.map(&:to_sym) + %i[notes user_id sleep block ok2text ok2email]
        end

        def params_client_custom_fields
          params.include?(:client_custom_fields) ? params.require(:client_custom_fields).permit(params[:client_custom_fields].keys.map(&:to_sym) - general_form_fields - ::Webhook.internal_key_hash(@client_widget.client, 'contact', %w[phones]).keys.map(&:to_sym)) : {}
        end

        def params_client_widget
          form_fields = {}

          ::Webhook.internal_key_hash(current_user.client, 'contact', %w[personal phones custom_fields]).each_key do |key|
            form_fields[key.to_sym] = %i[order show required]
          end

          response = params.require(:clients_widget).permit(
            :widget_name, :campaign_id, :group_id, :tag_id, :stage_id,
            :bb_bg_color, :bb_font, :bb_show, :bb_text, :bb_text_color, :bb_timeout, :bb_user_avatar, :bb_user_id,
            :b_bg_color, :b_icon, :b_icon_color,
            :w_auto_popup, :w_auto_popup_timeout, :w_bg_color, :w_def_question, :w_dd_comment, :w_font, :w_footer_color, :w_header_color, :w_show_question,
            :w_submit_button_color, :w_submit_button_text, :w_tag_line, :w_text_message, :w_title, :w_user_avatar, :w_user_id,
            w_dd_options: [], w_dd_actions: {}, form_fields:
          )

          response[:version]                 = 'v3'
          response[:bb_show]                 = response[:bb_show].to_bool if response.include?(:bb_show)
          response[:bb_timeout]              = response[:bb_timeout].to_i if response.include?(:bb_timeout)
          response[:bb_user_avatar]          = response[:bb_user_avatar].to_bool if response.include?(:bb_user_avatar)
          response[:bb_user_id]              = response[:bb_user_id].to_i if response.include?(:bb_user_id)
          response[:w_show_question]         = response[:w_show_question].to_bool if response.include?(:w_show_question)
          response[:w_auto_popup]            = response[:w_auto_popup].to_bool if response.include?(:w_auto_popup)
          response[:w_auto_popup_timeout]    = response[:w_auto_popup_timeout].to_i if response.include?(:w_auto_popup_timeout)
          response[:w_dd_options]            = response[:w_dd_options].compact_blank if response.include?(:w_dd_options)
          response[:w_user_avatar]           = response[:w_user_avatar].to_bool if response.include?(:w_user_avatar)
          response[:w_user_id]               = response[:w_user_id].to_i if response.include?(:w_user_id)
          response[:campaign_id]             = response[:campaign_id].to_i if response.include?(:campaign_id)
          response[:group_id]                = response[:group_id].to_i if response.include?(:group_id)
          response[:stage_id]                = response[:stage_id].to_i if response.include?(:stage_id)
          response[:tag_id]                  = response[:tag_id].to_i if response.include?(:tag_id)

          if response.include?(:w_dd_actions)
            response[:w_dd_actions].each do |option_key, option_values|
              option_values.each do |key, value|
                response[:w_dd_actions][option_key][key] = if key == 'stop_campaign_ids'
                                                             value.include?('0') ? [0] : value.compact_blank
                                                           else
                                                             value.to_i
                                                           end
              end
            end
          end

          response
        end

        def params_contact
          if params.include?(:client_custom_fields)
            sanitized_params = params.require(:client_custom_fields).permit(general_form_fields)

            if sanitized_params.dig(:fullname).to_s.present?
              fullname = sanitized_params[:fullname].to_s.parse_name
              sanitized_params[:firstname] = fullname[:firstname] if sanitized_params.dig(:firstname).to_s.blank?
              sanitized_params[:lastname]  = fullname[:lastname] if sanitized_params.dig(:lastname).to_s.blank?
            end
          else
            sanitized_params = {}
          end

          sanitized_params.except(:fullname)
        end

        def params_contact_phone
          if params.include?(:client_custom_fields)
            params.require(:client_custom_fields).permit(::Webhook.internal_key_hash(@client_widget.client, 'contact', %w[phones]).symbolize_keys.keys).to_h.to_h { |k, v| [v.clean_phone(@client_widget.client.primary_area_code), k.gsub('phone_', '')] }
          else
            {}
          end
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
