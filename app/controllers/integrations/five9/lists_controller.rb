# frozen_string_literal: true

# app/controllers/integrations/five9/lists_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 lists configuration
    class ListsController < Five9::IntegrationsController
      before_action :client_api_integration

      # (POST) save a new List for Five9 integration
      # /integrations/five9/lists
      # integrations_five9_lists_path
      # integrations_five9_lists_url
      def create
        list    = params.require(:list).permit(:name, :action, :tag_id)
        list_id = list[:name].strip.gsub(%r{\W}, '_').downcase
        list_id = "#{list_id}_01" while @client_api_integration.lists.key?(list_id)

        if list_id.present?
          @client_api_integration.lists[list_id] = { name: list[:name], action: list[:action], tag_id: list[:tag_id].to_i }
          @client_api_integration.save
        end

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index], list: [] } }
          format.html { redirect_to central_path }
        end
      end

      # (POST) create a new Five9 List
      # /integrations/five9/lists/create_list/:id
      # integrations_five9_create_list_path(:id)
      # integrations_five9_create_list_url(:id)
      def create_list
        list = if @client_api_integration.lists.key?(params[:id])
                 @client_api_integration.lists.dig(params[:id])
               else
                 { name: 'New List', action: 'add', tag_id: 0 }
               end

        if params.dig(:list_name).to_s.present?
          list[:name] = params.permit(:list_name).dig(:list_name).to_s
          Integrations::FiveNine::Base.new(@client_api_integration.credentials).call(:create_list, { list_name: list[:name] })
        end

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index list_edit], list: [params[:id], list] } }
          format.html { redirect_to central_path }
        end
      end

      # (DELETE) delete a List for Five9 integration
      # /integrations/five9/lists/:id
      # integrations_five9_list_path(:id)
      # integrations_five9_list_url(:id)
      def destroy
        @client_api_integration.lists.delete(params[:id])
        @client_api_integration.save

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index], list: [] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) edit a List for Five9 integration
      # /integrations/five9/lists/:id/edit
      # edit_integrations_five9_list_path(:id)
      # edit_integrations_five9_list_url(:id)
      def edit
        list = @client_api_integration.lists.dig(params[:id])

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_edit], list: [params[:id], list] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) list Lists for Five9 integration
      # /integrations/five9/lists
      # integrations_five9_lists_path
      # integrations_five9_lists_url
      def index
        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index], list: [] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) show as new List for Five9 integration
      # /integrations/five9/lists/new
      # new_integrations_five9_list_path
      # new_integrations_five9_list_url
      def new
        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index], list: ['new_list', { name: 'New List', action: 'add', tag_id: 0 }] } }
          format.html { redirect_to central_path }
        end
      end

      # (PUT/PATCH) save List for Five9 integration
      # /integrations/five9/lists/:id
      # integrations_five9_list_path(:id)
      # integrations_five9_list_url(:id)
      def update
        list = params.require(:list).permit(:name, :action, :tag_id)
        id   = params.permit(:id).dig(:id).to_s

        if list[:name].to_s.present?
          @client_api_integration.lists[id][:name]   = list[:name].to_s
          @client_api_integration.lists[id][:action] = list[:action].to_s
          @client_api_integration.lists[id][:tag_id] = list[:tag_id].to_i
        else
          @client_api_integration.lists.delete(id)
        end

        @client_api_integration.save

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[list_index], list: } }
          format.html { redirect_to central_path }
        end
      end
    end
  end
end
