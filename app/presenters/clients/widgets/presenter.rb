# frozen_string_literal: true

# app/presenters/clients/widgets/presenter.rb
module Clients
  module Widgets
    class Presenter
      attr_reader :client, :widget

      def initialize(args = {})
        self.client = args.dig(:client)
      end

      def button_icons_options(selected)
        ActionController::Base.helpers.options_for_select [
          ["Default #{I18n.t('tenant.name')} Logo", 'default'],
          ['Uploaded Button Image', 'image'],
          ['My Company Profile Avatar', 'avatar'],
          ['SMS Bubble', 'fas fa-sms', { data: { icon: 'fas fa-sms' } }],
          ['Comment Bubble (solid)', 'fas fa-comment', { data: { icon: 'fas fa-comment' } }],
          ['Comment Bubble', 'far fa-comment', { data: { icon: 'far fa-comment' } }],
          ['Comment Bubbles (solid)', 'fas fa-comments', { data: { icon: 'fas fa-comments' } }],
          ['Comment Bubbles', 'far fa-comments', { data: { icon: 'far fa-comments' } }],
          ['Comment Bubble w/Dots (solid)', 'fas fa-comment-dots', { data: { icon: 'fas fa-comment-dots' } }],
          ['Comment Bubble w/Dots', 'far fa-comment-dots', { data: { icon: 'far fa-comment-dots' } }],
          ['Square Comment Bubble (solid)', 'fas fa-comment-alt', { data: { icon: 'fas fa-comment-alt' } }],
          ['Square Comment Bubble', 'far fa-comment-alt', { data: { icon: 'far fa-comment-alt' } }]
        ], selected
      end

      def button_image
        if @widget.b_icon == 'image' && @widget.button_image.attached?
          ActionController::Base.helpers.cl_image_tag @widget.button_image.key, { class: 'launch-button-image', secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [width: 50, height: 50, crop: 'fit'], format: 'png' }
        elsif @widget.b_icon == 'avatar' && @widget.client.logo_image&.attached?
          ActionController::Base.helpers.cl_image_tag @widget.client.logo_image.key, { class: 'launch-button-image', secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [width: 50, height: 50, crop: 'fit'], format: 'png' }
        elsif @widget.b_icon[0, 2] == 'fa'
          "<i class=\"#{@widget.b_icon}\" style=\"font-size:1.75em;\"></i>"
        else
          ActionController::Base.helpers.image_tag "tenant/#{I18n.t('tenant.id')}/logo-600.png", { class: 'launch-button-image' }
        end
      end

      def button_image_path
        Rails.application.routes.url_helpers.send("api_#{@widget.version}_clients_edit_widget_button_image_path", @widget.id)
      end

      def bubble_text_width
        show_bubble_user_avatar? ? 205 : 255
      end

      def bubble_user
        @bubble_user ||= @client.users.find_by(id: @widget.bb_user_id)
      end

      def bubble_user_avatar
        show_bubble_user_avatar? ? "<div class=\"avatar\">#{ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(self.bubble_user.avatar.key, { class: 'img-responsive', secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ gravity: 'face', radius: 'max', crop: 'crop' }, { width: 50, height: 50, crop: 'scale' }], format: 'png' }))}</div>" : ''
      end

      def client=(client)
        @client = case client
                  when Client
                    client
                  when Integer
                    Client.find_by(id: client)
                  else
                    Client.new
                  end

        @button_user          = nil
        @widgets              = nil
        @widget               = nil
        @window_user          = nil
      end

      def form_fields_for_edit
        form_fields = ::Webhook.internal_key_hash(@widget.client, 'contact', %w[personal phones custom_fields])

        form_fields.each do |key, value|
          form_fields[key] = { 'name' => value }

          if (ff = @widget.form_fields&.dig(key))

            ff.each do |k, v|
              form_fields[key][k] = v
            end
          else
            form_fields[key]['order']    = form_fields.length.to_s
            form_fields[key]['show']     = '0'
            form_fields[key]['required'] = '0'
          end
        end

        form_fields.sort_by { |_key, value| value['order'].to_i }.to_h
      end

      def form_fields_for_widget
        all_fields  = ::Webhook.internal_key_hash(@widget.client, 'contact', %w[personal phones custom_fields])

        form_fields = {}

        @widget.form_fields.each do |key, value|
          if value&.dig('show').to_i == 1
            form_fields[key] = { 'name' => all_fields.dig(key).to_s }

            value.each do |k, v|
              form_fields[key][k] = v
            end
          end
        end

        form_fields.sort_by { |_key, value| value['order'].to_i }.to_h
      end

      def widget_delete_path
        Rails.application.routes.url_helpers.send(:clients_widget_path, @widget.id)
      end

      def form_method
        @widget.new_record? ? 'post' : 'patch'
      end

      def form_path
        @widget.new_record? ? Rails.application.routes.url_helpers.send("api_#{@widget.version}_clients_widgets_path") : Rails.application.routes.url_helpers.send("api_#{@widget.version}_clients_widget_path", @widget.id)
      end

      def show_bubble_user_avatar?
        @widget.bb_user_avatar && self.bubble_user&.avatar&.attached?
      end

      def show_window_user_avatar?
        @widget.w_user_avatar && self.window_user&.avatar&.attached?
      end

      def sitechat_url
        app_host = I18n.with_locale(@client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
        Rails.application.routes.url_helpers.send("api_#{@widget.version}_clients_sitechat_url", @widget.widget_key.to_s, host: app_host)
      end

      def users_with_avatar
        @client.users.where.not(id: nil).order(:lastname, :firstname).map { |user| [user.fullname, user.id] if user.avatar.attached? }.compact_blank
      end

      def widget=(widget)
        @widget = case widget
                  when Clients::Widget
                    widget
                  when Integer
                    Clients::Widget.find_by(id: widget)
                  else
                    Clients::Widget.new
                  end

        @button_user = nil
        @window_user = nil
      end

      def widgets
        @widgets ||= @client.client_widgets.order(:widget_name)
      end

      def window_dropdown_comment
        @widget.w_dd_comment.present? ? "<p class=\"small text-muted\" style=\"text-align:left;\">#{@widget.w_dd_comment}</p>" : ''
      end

      def window_dropdown_options
        @widget.w_dd_options.present? ? "<div class=\"form-group\">#{ActionController::Base.helpers.select_tag 'dropdown_option', ActionController::Base.helpers.options_for_select(@widget.w_dd_options), class: 'form-select'}</div>" : ''
      end

      def window_question
        @widget.w_show_question ? "<div class=\"form-group\">#{ActionController::Base.helpers.text_area_tag 'question', @widget.w_def_question, { class: 'form-control', placeholder: 'Your Question?', required: true }}</div>" : ''
      end

      def window_user
        @window_user ||= @client.users.find_by(id: @widget.w_user_id)
      end

      def window_user_avatar
        show_window_user_avatar? ? "<div class=\"user-avatar\">#{ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(self.window_user.avatar.key, { class: 'img-responsive', secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }))}</div>" : ''
      end
    end
  end
end
