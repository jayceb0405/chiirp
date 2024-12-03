# frozen_string_literal: true

# app/controllers/clients/widgets_controller.rb
module Clients
  class WidgetsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :client
    before_action :client_widget, only: %i[destroy]

    # (DELETE) destroy a Clients::Widget
    # /clients/widgets/:id
    # clients_widget_path(:id)
    # clients_widget_url(:id)
    def destroy
      @client_widget.destroy

      render partial: 'clients/widgets/js/show', locals: { cards: %w[index dropdown] }
    end

    # (POST) import a shared Clients::Widget
    # /clients/widget/import
    # clients_import_widget_path
    # clients_import_widget_url
    def import
      share_code = params.permit(:share_code).dig(:share_code).to_s

      if share_code.present?

        if (client_widget = Clients::Widget.find_by(share_code:))
          client = current_user.client

          @client_widget                  = client_widget.dup
          @client_widget.client_id        = client.id
          @client_widget.widget_name      = "Copy of #{client_widget.widget_name}"
          @client_widget.campaign_id      = 0
          @client_widget.group_id         = 0
          @client_widget.stage_id         = 0
          @client_widget.tag_id           = 0
          @client_widget.button_image.attach(client_widget.button_image.blob) if client_widget.button_image.attached?
          @client_widget.new_widget_key
          @client_widget.new_share_code

          if @client_widget.version == 'v3'
            new_user_client_field_list = ::Webhook.internal_key_hash(client, 'contact', %w[personal phones custom_fields])

            @client_widget.form_fields.each do |key, value|
              unless new_user_client_field_list.key?(key)

                if value['show'].to_i == 1 && (client_custom_field = client.client_custom_fields.find_by(var_var: key))
                  new_client_custom_field = client_custom_field.dup
                  new_client_custom_field.client_id     = client.id
                  new_client_custom_field.var_important = false

                  @client_widget.form_fields.delete(key) unless new_client_custom_field.save
                else
                  @client_widget.form_fields.delete(key)
                end
              end
            end
          end

          if @client_widget.save
            sweetalert_success('Widget Import Success!', "Hurray! #{@client_widget.widget_name} was imported successfully.", '', { persistent: 'OK' })
          else
            sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't import that Widget. <ul>#{@client_widget.errors.full_messages.collect { |m| "#{m} & " }}.", { persistent: 'OK' })
          end
        else
          sweetalert_warning('Widget Not Found!', "Sorry, we couldn't find that share code. Please verify the code and try again.", '', { persistent: 'OK' })
        end

        render partial: 'clients/widgets/js/show', locals: { cards: %w[index dropdown import_close] }
      else
        render js: "window.location = '#{clients_widgets_path}'"
      end
    end

    # (GET) show Clients::Widget import modal
    # /clients/widget/import/show
    # clients_import_widget_show_path
    # clients_import_widget_show_url
    def import_show
      render partial: 'clients/widgets/js/show', locals: { cards: %w[import] }
    end

    # (GET) list all Clients::Widgets
    # /clients/widgets
    # clients_widgets_path
    # clients_widgets_url
    def index
      render 'clients/widgets/index'
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('widgets', 'users', session)

      raise ExceptionHandlers::UserNotAuthorized.new('SiteChat', root_path)
    end

    def client
      @client = current_user.client
    end

    def client_widget
      return if (@client_widget = @client.client_widgets.find_by(id: params.permit(:id).dig(:id).to_i))

      sweetalert_error('SiteChat NOT found!', 'We were not able to access the SiteChat you requested.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{clients_widgets_path}'" and return false }
        format.html { redirect_to clients_widgets_path and return false }
      end
    end
  end
end
