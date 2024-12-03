# frozen_string_literal: true

# app/controllers/clients/stage_parents_controller.rb
module Clients
  # support for editing StageParents
  class StageParentsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :stage_parent, only: %i[destroy edit import_copy update]

    # (DELETE)
    # /client/:client_id/stage_parents/:id
    # client_stage_parent_path(:client_id, :id)
    # client_stage_parent_url(:client_id, :id)
    def destroy
      @stage_parent.destroy
      remove_instance_variable(:@stage_parent)

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_index] } }
        format.html { redirect_to client_stage_parents_path(@client.id) }
      end
    end

    # (GET)
    # /client/:client_id/stage_parents/:id/edit
    # edit_client_stage_parent_path(:client_id, :id)
    # edit_client_stage_parent_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_edit] } }
        format.html { render 'clients/show', locals: { client_page_section: 'stage_parents' } }
      end
    end

    # (POST) receive a StageParent share code to copy a Pipeline
    # /client/:client_id/stage_parents/import
    # client_import_stage_parent_path(:client_id)
    # client_import_stage_parent_url(:client_id)
    def import
      share_code = params.permit(:share_code).dig(:share_code).to_s

      if share_code.present?

        if (stage_parent = StageParent.find_by(share_code:))
          copy_stage_parent(stage_parent, 'import', 'imported')
        else
          sweetalert_warning("#{StageParent.title} Not Found!", "Sorry, we couldn't find that share code. Please verify the code and try again.", '', { persistent: 'OK' })
        end

        render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_index import_close] }
      else
        render js: "window.location = '#{clients_widgets_path}'"
      end
    end

    # (GET) copy a StageParent
    # /client/:client_id/stage_parents/import/copy
    # client_import_stage_parent_copy_path
    # client_import_stage_parent_copy_url
    def import_copy
      copy_stage_parent(@stage_parent, 'copy', 'copied')

      render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_index] }
    end

    # (GET) show StageParent share code modal
    # /client/:client_id/stage_parents/import/show
    # client_import_stage_parent_show_path(:client_id)
    # client_import_stage_parent_show_url(:client_id)
    def import_show
      render partial: 'clients/stage_parents/js/show', locals: { cards: %w[import] }
    end

    # (GET)
    # /client/:client_id/stage_parents
    # client_stage_parents_path(:client_id)
    # client_stage_parents_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_index] } }
        format.html { render 'clients/show', locals: { client_page_section: 'stage_parents' } }
      end
    end

    # (GET)
    # /client/:client_id/stage_parents/new
    # new_client_stage_parent_path(:client_id)
    # new_client_stage_parent_url(:client_id)
    def new
      new_stage_parent_name = "New #{StageParent.title}"
      new_stage_parent_name = "New #{new_stage_parent_name}" while @client.stage_parents.find_by(name: new_stage_parent_name)
      @stage_parent         = @client.stage_parents.create(name: new_stage_parent_name)

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_index stage_parent_edit_show] } }
        format.html { redirect_to client_stage_parents_path(@client.id) }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/stage_parents/:id
    # client_stage_parent_path(:client_id, :id)
    # client_stage_parent_url(:client_id, :id)
    def update
      if params.dig(:sort_order)
        sort_order = 0

        # rubocop:disable Rails/SkipsModelValidations
        params[:sort_order].each do |stage|
          if stage[stage.length - 3, 3] == '_tr'
            @stage_parent.stages.where(id: stage.split('_')[2]).update_all(sort_order:)
            sort_order += 1
          end
        end
        # rubocop:enable Rails/SkipsModelValidations

        respond_to do |format|
          format.js   { render js: '', layout: false, status: :ok }
          format.html { redirect_to client_stage_parents_path(@client.id) }
        end
      else
        @stage_parent.update(params_stage_parent)

        respond_to do |format|
          format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_parent_edit stage_parent_name] } }
          format.html { redirect_to client_stage_parents_path(@client.id) }
        end
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'pipelines', session)

      raise ExceptionHandlers::UserNotAuthorized.new("My Company Profile > #{StageParent.title.pluralize}", root_path)
    end

    def copy_stage_parent(stage_parent, process, process_past)
      new_stage_parent = stage_parent.copy(new_client: @client)

      if new_stage_parent.present?
        sweetalert_success("#{StageParent.title} #{process.titleize} Success!", "Hurray! #{new_stage_parent.name} was #{process_past.downcase} successfully.", '', { persistent: 'OK' })
      else
        sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't #{process.downcase} that #{StageParent.title}.", { persistent: 'OK' })
      end

      new_stage_parent
    end

    def params_stage_parent
      response = params.require(:stage_parent).permit(:name, users_permitted: [])
      response[:users_permitted] = response[:users_permitted].filter_map { |x| x.empty? ? nil : x }.map(&:to_i)

      response
    end

    def stage_parent
      stage_parent_id = params.dig(:id).to_i

      if stage_parent_id.positive? && (@stage_parent = @client.stage_parents.find_by(id: stage_parent_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js   { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
