# frozen_string_literal: true

# app/controllers/api/v3/user_contact_forms_controller.rb
module Api
  module V3
    class UserContactFormsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[save_contact show_frame show_frame_init show_modal_init show_page]
      before_action :authenticate_user!, only: %i[background_image create edit new update]
      before_action :set_user_contact_form_by_page_key, only: %i[save_contact show_frame show_frame_init show_modal show_modal_init show_page]
      before_action :set_user_contact_form_by_id, only: %i[background_image edit edit_template update]
      before_action :user_api_integration_for_activeprospect, only: %i[show_frame show_frame_init show_modal_init show_page]
      after_action  :allow_iframe, only: %i[show_frame show_modal]

      # (PATCH) save/delete background image for a UserContactForm
      # /api/v3/users/contact_form/:id/background_image
      # api_v3_background_image_user_contact_form_path(:id)
      # api_v3_background_image_user_contact_form_url(:id)
      def background_image
        image_delete = params.dig(:image_delete).to_bool

        if image_delete
          @user_contact_form.background_image.purge
        else
          background_image = params.require(:user_contact_form).permit(:background_image).dig(:background_image)
          @user_contact_form.update(background_image:)
        end

        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/js/show', locals: { cards: %w[show_form_formatting] } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      # (POST) create a new UserContactForm
      # /api/v3/user_contact_forms
      # api_v3_user_contact_forms_path
      # api_v3_user_contact_forms_url
      def create
        @user_contact_form  = current_user.user_contact_forms.create(params_user_contact_form)
        @user_contact_forms = current_user.user_contact_forms.order(:form_name)

        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/js/show', locals: { cards: %w[edit_form user_contact_forms_dropdown] } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      # (GET) edit an existing UserContactForm
      # /api/v3/user_contact_forms/:id/edit
      # edit_api_v3_user_contact_form_path(:id)
      # edit_api_v3_user_contact_form_url(:id)
      def edit
        @user_contact_forms = current_user.user_contact_forms.order(:form_name)

        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/js/show', locals: { cards: %w[edit_form] } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      # (GET) display UserContactForm template
      # /api/v3/users/contact_form/:id/edit_template
      # api_v3_edit_template_user_contact_form_path(:id)
      # api_v3_edit_template_user_contact_form_url(:id)
      def edit_template
        render partial: 'user_contact_forms/v3/js/show', locals: { cards: %w[edit_template] }
      end

      # (GET) set up for a new UserContactForm
      # /api/v3/user_contact_forms/new
      # new_api_v3_user_contact_form_path
      # new_api_v3_user_contact_form_url
      def new
        @user_contact_form = current_user.user_contact_forms.new(form_name: 'New QuickPage')

        respond_to do |format|
          format.js   { render partial: 'user_contact_forms/v3/js/show', locals: { cards: %w[edit_form] } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      # (POST) save a Contact Form
      # /api/v3/quicklead/:page_key
      # api_v3_user_contact_form_save_contact_path(:page_key)
      # api_v3_user_contact_form_save_contact_url(:page_key)
      # validate rendered_by
      def save_contact
        rendered_by = %w[page frame modal].include?(params.dig(:rendered_by).to_s) ? params[:rendered_by].to_s : 'page'

        # convert American date to DateTime
        contact_data = contact_params
        contact_data[:birthdate] = Chronic.parse(contact_data[:birthdate]) if contact_data.include?(:birthdate)
        contact_data[:email]     = contact_data.dig(:email).to_s

        # submitting form for an existing Contact?
        contact_id = params.dig(:contact_id).to_s

        if contact_id.present?
          @contact = Contact.find_by(id: Base64.decode64(CGI.unescape(contact_id)))
          primary_found = false

          contact_phone_params.each do |phone, label|
            contact_phone = @contact.contact_phones.find_or_initialize_by(phone: phone.clean_phone(@user_contact_form.user.client.primary_area_code))
            contact_phone.label = label
            contact_phone.primary = true unless primary_found
            primary_found = true
          end
        end

        @contact ||= Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @user_contact_form.user.client_id, phones: contact_phone_params, emails: [contact_data[:email]])
        @contact.update(
          lastname:     (contact_data.dig(:lastname) || @contact.lastname).to_s,
          firstname:    (contact_data.dig(:firstname) || @contact.firstname).to_s,
          email:        (contact_data.dig(:email) || @contact.email).to_s,
          address1:     (contact_data.dig(:address1) || @contact.address1).to_s,
          address2:     (contact_data.dig(:address2) || @contact.address2).to_s,
          city:         contact_data.dig(:city) || @contact.city.to_s,
          state:        contact_data.dig(:state) || @contact.state.to_s,
          zipcode:      contact_data.dig(:zipcode) || @contact.zipcode.to_s,
          birthdate:    contact_data.dig(:birthdate) || @contact.birthdate,
          ok2text:      (contact_data.dig(:ok2text) || 1).to_i,
          ok2email:     (contact_data.dig(:ok2email) || @contact.ok2email).to_s,
          trusted_form: {
            token:    params.dig(:xxTrustedFormToken).to_s,
            cert_url: params.dig(:xxTrustedFormCertUrl).to_s,
            ping_url: params.dig(:xxTrustedFormPingUrl).to_s
          }
        )

        if @contact.errors.any?
          path_params = {}
          sweetalert_error('Sorry!', "#{@contact.errors.full_messages.join(' & ')}.", '', { persistent: 'OK' })
        else
          # save ContactCustomFields
          @contact.update_custom_fields(custom_fields: client_custom_fields_params.to_h)

          Integrations::Searchlight::V1::PostUserContactFormJob.perform_later(
            action_at:            Time.current,
            client_id:            @contact.client_id,
            contact_id:           @contact.id,
            user_contact_form_id: @user_contact_form.id,
            user_id:              @contact.user_id
          )

          if params.dig(:campaign_id).to_i.positive?
            # Campaign was selected in form to apply to new Contact
            Contacts::Campaigns::StartJob.perform_later(
              campaign_id: params.dig(:campaign_id),
              client_id:   @contact.client_id,
              contact_id:  @contact.id,
              user_id:     @contact.user_id
            )
          end

          @contact.process_actions(
            campaign_id:       @user_contact_form.campaign_id,
            group_id:          @user_contact_form.group_id,
            stage_id:          @user_contact_form.stage_id,
            tag_id:            @user_contact_form.tag_id,
            stop_campaign_ids: @user_contact_form.stop_campaign_ids
          )

          path_params = { contact_id: CGI.escape(Base64.encode64(@contact.id.to_s).strip) }
          sweetalert_success("Thank You#{@contact.firstname.present? ? " #{@contact.firstname}" : ''}!", 'Your information was saved.', '', {}) if @user_contact_form.redirect_url.blank?
        end

        respond_to do |format|
          if @user_contact_form.redirect_url.present?

            case rendered_by
            when 'page'
              format.html { redirect_to @user_contact_form.redirect_url + (path_params.present? ? "?#{path_params.map { |key, value| "#{key}=#{value}" }.join('&')}" : ''), allow_other_host: true }
              format.js { render js: "window.location = '#{@user_contact_form.redirect_url + (path_params.present? ? "?#{path_params.map { |key, value| "#{key}=#{value}" }.join('&')}" : '')}'" }
            when 'frame'
              path_params[:redirect] = 'true'
              format.html { redirect_to api_v3_user_contact_form_frame_path(@user_contact_form.page_key, path_params) }
              format.js { render js: "window.parent.postMessage('{'action':'redirect_frame'}', '*'');" }
            when 'modal'
              path_params[:redirect] = 'true'
              format.html { redirect_to api_v3_user_contact_form_modal_path(@user_contact_form.page_key, path_params) }
              format.js { render js: "window.parent.postMessage('{'action':'redirect_frame'}', '*'');" }
            end
          else

            case rendered_by
            when 'page'
              format.html { redirect_to api_v3_user_contact_form_page_path(@user_contact_form.page_key) }
              format.js { render js: "window.location = '#{api_v3_user_contact_form_page_path(@user_contact_form.page_key)}'" }
            when 'frame'
              format.html { redirect_to api_v3_user_contact_form_frame_path(@user_contact_form.page_key) }
              format.js { render js: "window.location = '#{api_v3_user_contact_form_frame_path(@user_contact_form.page_key)}'" }
            when 'modal'
              format.html { redirect_to api_v3_user_contact_form_modal_path(@user_contact_form.page_key) }
              format.js { render js: "window.location = '#{api_v3_user_contact_form_modal_path(@user_contact_form.page_key)}'" }
            end
          end
        end
      end

      # (GET) show iFrame code
      # /api/v3/quicklead/frame/:page_key
      # api_v3_user_contact_form_frame_path(:page_key)
      # api_v3_user_contact_form_frame_url(:page_key)
      def show_frame
        respond_to do |format|
          format.js { render js: "window.location = '#{api_v3_user_contact_form_frame_path(@user_contact_form.page_key)}'" }
          format.html { render 'user_contact_forms/v3/frame/show', layout: false, status: :ok, locals: { rendered_by: 'frame' } }
        end
      end

      # (GET) javascript to display fixed iframe
      # /api/v3/quicklead/frameinit/:page_key
      # api_v3_user_contact_form_frame_init_path(:page_key)
      # api_v3_user_contact_form_frame_init_url(:page_key)
      def show_frame_init
        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/frame/init' }
          format.html { redirect_to root_path }
        end
      end

      # (GET) show modal code
      # /api/v3/quicklead/modal/:page_key
      # api_v3_user_contact_form_modal_path(:page_key)
      # api_v3_user_contact_form_modal_url(:page_key)
      def show_modal
        respond_to do |format|
          format.js { render js: "window.location = '#{api_v3_user_contact_form_modal_path(@user_contact_form.page_key)}'" }
          format.html { render 'user_contact_forms/v3/modal/show', layout: false, status: :ok, locals: { rendered_by: 'modal' } }
        end
      end

      # (GET) javascript to display modal iframe
      # /api/v3/quicklead/modalinit/:page_key
      # api_v3_user_contact_form_modal_init_path(:page_key)
      # api_v3_user_contact_form_modal_init_url(:page_key)
      def show_modal_init
        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/modal/init' }
          format.html { redirect_to root_path }
        end
      end

      # (GET) show a UserContactForm
      # /api/v3/quicklead/:page_key
      # api_v3_user_contact_form_page_path(:page_key)
      # api_v3_user_contact_form_page_url(:page_key)
      def show_page
        respond_to do |format|
          format.html { render 'user_contact_forms/v3/show', layout: false, status: :ok }
          format.js { render js: "window.location = '#{api_v3_user_contact_form_page_path(@user_contact_form.page_key)}'" }
        end
      end

      # (PATCH/PUT) update an existing UserCustomForm
      # /api/v3/user_contact_forms/:id
      # api_v3_user_contact_form_path(:id)
      # api_v3_user_contact_form_url(:id)
      def update
        commit = params.dig(:commit).to_s.downcase
        cards  = %w[user_contact_forms_dropdown edit_form]

        case commit
        when 'update_page_domain'
          # save domain
          @user_contact_form.update(params_page_domain)

          cards = %w[show_links update_button_view_in_new_tab]
        when 'update_page_name'
          # save domain
          @user_contact_form.update(params_page_name)

          cards = %w[show_links update_button_view_in_new_tab]
        when 'create_trackable_link'
          # create a TrackableLink
          trackable_link = current_user.client.trackable_links.new
          trackable_link.name = "Link To #{@user_contact_form.form_name}"
          trackable_link.original_url = @user_contact_form.landing_page_url

          if trackable_link.save
            sweetalert_success('QuickPage Trackable Link Success!', "Hurray! Trackable Link: #{trackable_link.name} was created successfully.", '', { persistent: 'OK' })
          else
            sweetalert_error('QuickPage Trackable Link Failed!', 'We were not able to create the Trackable Link you requested.', '', { persistent: 'OK' })
          end

          cards = %w[edit_form]
        else
          @user_contact_form.update(params_user_contact_form)

          default_for_domain = params.dig(:default_for_domain).to_s

          if default_for_domain.present? && (client = @user_contact_form.user.client) && client.domains.key?(default_for_domain)
            client.domains[default_for_domain] = @user_contact_form.id
            client.save
          end

          cards = [] if commit == 'save template'
        end

        @user_contact_forms = current_user.user_contact_forms.order(:form_name)

        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v3/js/show', locals: { cards: } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      private

      def client_custom_fields_params
        params.include?(:client_custom_fields) ? params.require(:client_custom_fields).permit(params[:client_custom_fields].keys.map(&:to_sym) - general_form_fields - ::Webhook.internal_key_hash(@user_contact_form.user.client, 'contact', %w[phones]).keys.map(&:to_sym)) : {}
      end

      def contact_params
        if params.include?(:client_custom_fields)
          response = params.require(:client_custom_fields).permit(general_form_fields)

          if response.dig(:fullname).to_s.present?
            fullname = response[:fullname].to_s.parse_name
            response[:firstname] = fullname[:firstname] if response.dig(:firstname).to_s.blank?
            response[:lastname]  = fullname[:lastname] if response.dig(:lastname).to_s.blank?
          end

          response.delete(:fullname)
        else
          response = {}
        end

        response
      end

      def contact_phone_params
        if params.include?(:client_custom_fields)
          params.require(:client_custom_fields).permit(::Webhook.internal_key_hash(@user_contact_form.user.client, 'contact', %w[phones]).symbolize_keys.keys).to_h.to_h { |k, v| [v.clean_phone(@user_contact_form.user.client.primary_area_code), k.gsub('phone_', '')] }
        else
          {}
        end
      end

      def general_form_fields
        ::Webhook.internal_key_hash(@user_contact_form.user.client, 'contact', %w[personal ext_references]).keys.map(&:to_sym) + %i[notes user_id sleep block ok2text ok2email]
      end

      def params_page_domain
        params.require(:user_contact_form).permit(:page_domain)
      end

      def params_page_name
        params.require(:user_contact_form).permit(:page_name)
      end

      def params_user_contact_form
        if @user_contact_form&.marketplace
          response = params.require(:user_contact_form).permit(
            :redirect_url, :campaign_id, :tag_id, :group_id, :stage_id, :page_domain, :page_name, stop_campaign_ids: []
          )
        else
          form_fields = []

          ::Webhook.internal_key_hash(current_user.client, 'contact', %w[personal phones custom_fields]).each_key do |key|
            form_fields << "'#{key}' => [\"order\", \"show\", \"required\"]"
          end

          form_fields = [JSON.parse("{#{form_fields.join(',')}}".gsub(' =>', ':').tr("'", '"'))]

          response = params.require(:user_contact_form).permit(
            :title, :header_notes, :footer_notes, :redirect_url, :campaign_id, :tag_id, :group_id, :stage_id, :form_name,
            :ok2text, :ok2text_text, :ok2email, :ok2email_text,
            :submit_button_text, :tag_line, :youtube_video, :head_string, :script_string,
            :submit_button_color, :header_bg_color, :body_bg_color, :form_bg_color, :template,
            :selectable_campaign_label, selectable_campaign_ids: [], form_fields:, stop_campaign_ids: []
          )
        end

        response[:campaign_id]       = response[:campaign_id].to_i if response.include?(:campaign_id)
        response[:stop_campaign_ids] = response[:stop_campaign_ids]&.compact_blank
        response[:stop_campaign_ids] = [0] if response[:stop_campaign_ids]&.include?('0')
        response[:tag_id]            = response[:tag_id].to_i if response.include?(:tag_id)
        response[:group_id]          = response[:group_id].to_i if response.include?(:group_id)
        response[:stage_id]          = response[:stage_id].to_i if response.include?(:stage_id)
        response[:redirect_url]      = if response.include?(:redirect_url) && response[:redirect_url].present?
                                         response[:redirect_url][0, 7].casecmp?('http://') || response[:redirect_url][0, 8].casecmp?('https://') ? response[:redirect_url] : "https://#{response[:redirect_url]}"
                                       else
                                         ''
                                       end
        response[:head_string]       = response[:head_string].gsub('{script', '<script').gsub('{/script}', '</script>') if response.include?(:head_string)
        response[:script_string]     = response[:script_string].gsub('{script', '<script').gsub('{/script}', '</script>') if response.include?(:script_string)

        response[:selectable_campaign_ids].delete('') if response.include?(:selectable_campaign_ids)

        response
      end

      def set_user_contact_form_by_id
        user_contact_form_id = params.dig(:id).to_i

        @user_contact_form = if user_contact_form_id.zero?
                               current_user.user_contact_forms.new
                             else
                               current_user.user_contact_forms.find_by(id: user_contact_form_id)
                             end

        return if @user_contact_form

        sweetalert_error('QuickPage NOT found!', 'We were not able to access the QuickPage you requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{user_contact_forms_path}'" and return false }
          format.html { redirect_to user_contact_forms_path and return false }
        end
      end

      def set_user_contact_form_by_page_key
        page_key = params.dig(:page_key).to_s

        if page_key.present?

          if !(@user_contact_form = UserContactForm.find_by(page_key:)) && %w[save_contact show_page].include?(action_name)
            # find UserContactForm by page_domain/page_name
            @user_contact_form = UserContactForm.find_by(page_domain: request.domain, page_name: page_key)
          end
        else
          @user_contact_form = nil
        end

        return if @user_contact_form

        sweetalert_error('QuickPage NOT found!', 'We were not able to access the QuickPage form requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def user_api_integration_for_activeprospect
        @user_api_integration = UserApiIntegration.find_by(user_id: @user_contact_form.user_id, target: 'activeprospect')
      end
    end
  end
end
