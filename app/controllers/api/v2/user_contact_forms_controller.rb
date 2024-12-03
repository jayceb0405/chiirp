# frozen_string_literal: true

# app/controllers/api/v2/user_contact_forms_controller.rb
module Api
  module V2
    class UserContactFormsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[show_frame_init show_modal_init show_page]
      before_action :authenticate_user!, only: %i[edit update]
      before_action :set_user_contact_form_by_page_key, only: %i[save_contact show_frame show_frame_init show_modal show_modal_init show_page]
      before_action :set_user_contact_form_by_id, only: %i[edit update]
      after_action  :allow_iframe, only: %i[show_frame show_modal]

      def edit
        # (GET) show an existing UserCustomForm to edit
        # /api/v2/user_contact_forms/:id/edit
        # edit_api_v2_user_contact_form_path(:id)
        # edit_api_v2_user_contact_form_url(:id)
        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v2/js/show', locals: { cards: %w[edit_form] } }
          format.html { redirect_to quickleads_path }
        end
      end

      def save_contact
        # (POST) save a Contact Form
        # /api/v2/quicklead/:page_key
        # api_v2_user_contact_form_save_contact_path(:page_key)
        # api_v2_user_contact_form_save_contact_url(:page_key)
        rendered_by  = params.include?(:rendered_by) && %w[page frame modal].include?(params[:rendered_by].to_s) ? params[:rendered_by].to_s : 'page'

        phone_params = params.require(:client_custom_fields).permit(:phone, :alt_phone, :email)
        phones       = {}
        phones[phone_params[:phone].to_s.clean_phone(@user_contact_form.user.client.primary_area_code)]     = 'mobile' if phone_params.include?(:phone) && !phone_params[:phone].to_s.empty?
        phones[phone_params[:alt_phone].to_s.clean_phone(@user_contact_form.user.client.primary_area_code)] = 'other' if phone_params.include?(:alt_phone) && !phone_params[:alt_phone].to_s.empty?
        emails = []
        emails << phone_params[:email].to_s if phone_params.include?(:email) && !phone_params[:email].to_s.empty?

        # find or create new Contact
        @contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @user_contact_form.user.client_id, phones:, emails:, update_primary_phone: true)
        @contact.update(contact_params)

        if @contact.errors.any?
          sweetalert_error('Sorry!', "#{@contact.errors.full_messages.join(' & ')}.", '', { persistent: 'OK' })
        else
          # Contact was saved successfully

          # save ContactCustomFields
          @contact.update_custom_fields(custom_fields: client_custom_fields_params.to_h)

          Integrations::Searchlight::V1::PostUserContactFormJob.perform_later(
            action_at:            Time.current,
            client_id:            @contact.client_id,
            contact_id:           @contact.id,
            user_contact_form_id: @user_contact_form.id,
            user_id:              @contact.user_id
          )

          @contact.process_actions(
            campaign_id: @user_contact_form.campaign_id,
            group_id:    @user_contact_form.group_id,
            stage_id:    @user_contact_form.stage_id,
            tag_id:      @user_contact_form.tag_id
          )

          sweetalert_success("Thank You#{@contact.firstname.present? ? " #{@contact.firstname}" : ''}!", 'Your information was saved.', '', {})
        end

        respond_to do |format|
          if @user_contact_form.redirect_url.present?
            format.js { render js: "window.location = '#{@user_contact_form.redirect_url}'" }
            format.html { redirect_to @user_contact_form.redirect_url }
          else

            case rendered_by
            when 'page'
              format.js { render js: "window.location = '#{api_v2_user_contact_form_page_path(@user_contact_form.page_key)}'" }
              format.html { redirect_to api_v2_user_contact_form_page_path(@user_contact_form.page_key) }
            when 'frame'
              format.js { render js: "window.location = '#{api_v2_user_contact_form_frame_path(@user_contact_form.page_key)}'" }
              format.html { redirect_to api_v2_user_contact_form_frame_path(@user_contact_form.page_key) }
            when 'modal'
              format.js { render js: "window.location = '#{api_v2_user_contact_form_modal_path(@user_contact_form.page_key)}'" }
              format.html { redirect_to api_v2_user_contact_form_modal_path(@user_contact_form.page_key) }
            end
          end
        end
      end

      def show_frame
        # (GET) show iFrame code
        # /api/v2/quicklead/frame/:page_key
        # api_v2_user_contact_form_frame_path(:page_key)
        # api_v2_user_contact_form_frame_url(:page_key)
        respond_to do |format|
          format.html { render 'user_contact_forms/v2/frame/show', layout: false, status: :ok }
          format.js { render js: "window.location = '#{users_contact_form_v2_show_frame_path(@user_contact_form.page_key)}'" }
        end
      end

      def show_frame_init
        # (GET) javascript to display fixed iframe
        # /api/v2/quicklead/frameinit/:page_key
        # api_v2_user_contact_form_frame_init_path(:page_key)
        # api_v2_user_contact_form_frame_init_url(:page_key)
        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v2/frame/init' }
          format.html { redirect_to root_path }
        end
      end

      def show_modal
        # (GET) show modal code
        # /api/v2/quicklead/modal/:page_key
        # api_v2_user_contact_form_modal_path(:page_key)
        # api_v2_user_contact_form_modal_url(:page_key)
        respond_to do |format|
          format.js { render js: "window.location = '#{api_v2_user_contact_form_modal_path(@user_contact_form.page_key)}'" }
          format.html { render 'user_contact_forms/v2/modal/show', layout: false, status: :ok }
        end
      end

      def show_modal_init
        # (GET) javascript to display modal iframe
        # /api/v2/quicklead/modalinit/:page_key
        # api_v2_user_contact_form_modal_init_path(:page_key)
        # api_v2_user_contact_form_modal_init_url(:page_key)
        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v2/modal/init' }
          format.html { redirect_to root_path }
        end
      end

      def show_page
        # (GET) show a Contact Form page
        # /api/v2/quicklead/:page_key
        # api_v2_user_contact_form_page_path(:page_key)
        # api_v2_user_contact_form_page_url(:page_key)
        respond_to do |format|
          format.html { render 'user_contact_forms/v2/show', layout: false, status: :ok }
          format.js { render js: "window.location = '#{api_v2_user_contact_form_page_path(@user_contact_form.page_key)}'" }
        end
      end

      def update
        # (PATCH/PUT) update an existing UserCustomForm
        # /api/v3/user_contact_forms/:id
        # api_v3_user_contact_form_path(:id)
        # api_v3_user_contact_form_url(:id)
        if params.include?(:logo_image_delete) || params.include?(:background_image_delete)
          # deleting an image

          if params.dig(:logo_image_delete).to_s == 'true'
            @user_contact_form.logo_image.purge
          elsif params.dig(:background_image_delete).to_s == 'true'
            @user_contact_form.background_image.purge
          end
        else
          @user_contact_form.update(user_contact_form_params)
        end

        respond_to do |format|
          format.js { render partial: 'user_contact_forms/v2/js/show', locals: { cards: %w[edit_form] } }
          format.html { redirect_to user_contact_forms_path }
        end
      end

      private

      def client_custom_fields_params
        response = {}

        if params.include?(:client_custom_fields)
          response = params.require(:client_custom_fields).permit(params[:client_custom_fields].keys)
          response.delete(:fullname) if response.include?(:fullname)
          response.delete(:firstname) if response.include?(:firstname)
          response.delete(:lastname) if response.include?(:lastname)
          response.delete(:phone) if response.include?(:phone)
          response.delete(:email) if response.include?(:email)
          response.delete(:address1) if response.include?(:address1)
          response.delete(:address2) if response.include?(:address2)
          response.delete(:city) if response.include?(:city)
          response.delete(:state) if response.include?(:state)
          response.delete(:zipcode) if response.include?(:zipcode)
          response.delete(:alt_phone) if response.include?(:alt_phone)
          response.delete(:birthdate) if response.include?(:birthdate)
          response.delete(:notes) if response.include?(:notes)
          response.delete(:user_id) if response.include?(:user_id)
          response.delete(:sleep) if response.include?(:sleep)
          response.delete(:block) if response.include?(:block)
          response.delete(:ok2text) if response.include?(:ok2text)
          response.delete(:ok2email) if response.include?(:ok2email)
        end

        response
      end

      def contact_params
        sanitized_params = params.require(:client_custom_fields).permit(:fullname, :firstname, :lastname, :email, :address1, :address2, :city, :state, :zipcode, :birthdate, :notes, :user_id, :block, :sleep, :ok2text, :ok2email)

        if sanitized_params.dig(:fullname).to_s.present?
          fullname = sanitized_params[:fullname].to_s.parse_name
          sanitized_params[:firstname] = fullname[:firstname] if sanitized_params.dig(:firstname).to_s.blank?
          sanitized_params[:lastname]  = fullname[:lastname] if sanitized_params.dig(:lastname).to_s.blank?
        else
          sanitized_params[:firstname] = sanitized_params.dig(:firstname).to_s
          sanitized_params[:lastname]  = sanitized_params.dig(:lastname).to_s
        end

        sanitized_params[:birthdate] = Chronic.parse(sanitized_params[:birthdate]) if sanitized_params.include?(:birthdate)
        sanitized_params[:sleep]     = sanitized_params[:sleep].to_bool if sanitized_params.include?(:sleep)
        sanitized_params[:block]     = sanitized_params[:block].to_bool if sanitized_params.include?(:block)
        sanitized_params.delete(:fullname)

        sanitized_params
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
        # set up UserContactForm object
        return if params.dig(:page_key).to_s.blank?

        @user_contact_form = UserContactForm.find_by_page_key(params[:page_key])

        return if @user_contact_form

        sweetalert_error('Contact form NOT found!', 'We were not able to access the QuickPage form requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.html { redirect_to root_path and return false }
          format.js   { render js: "window.location = '#{root_path}'" and return false }
          format.any  { redirect_to root_path and return false }
        end
      end

      def user_contact_form_params
        response = params.require(:user_contact_form).permit(
          :title, :header_notes, :footer_notes, :logo_image, :background_image, :redirect_url, :campaign_id, :tag_id, :group_id, :stage_id, :form_name,
          :ok2text, :ok2text_text, :ok2email, :ok2email_text,
          :submit_button_text, :tag_line, :youtube_video,
          :submit_button_color, :header_bg_color, :body_bg_color, :form_bg_color, :template,
          form_fields: ::Webhook.internal_key_hash(client, 'contact', %w[personal phones custom_fields]).keys.map { |k| [k.to_sym, :"#{k}_required"] }.flatten
        )

        response[:campaign_id]  = response[:campaign_id].to_i if response.include?(:campaign_id)
        response[:tag_id]       = response[:tag_id].to_i if response.include?(:tag_id)
        response[:group_id]     = response[:group_id].to_i if response.include?(:group_id)
        response[:stage_id]     = response[:stage_id].to_i if response.include?(:stage_id)
        response[:redirect_url] = if response.include?(:redirect_url) && response[:redirect_url].present?
                                    response[:redirect_url][0, 7].casecmp?('http://') || response[:redirect_url][0, 8].casecmp?('https://') ? response[:redirect_url] : "https://#{response[:redirect_url]}"
                                  else
                                    ''
                                  end

        response
      end
    end
  end
end
