# frozen_string_literal: true

# app/controllers/affiliates/affiliates_controller.rb
module Affiliates
  class AffiliatesController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :affiliate, only: %i[destroy edit show update]

    # (POST) create an Affiliate
    # /affiliates/affiliates
    # affiliates_affiliates_path
    # affiliates_affiliates_url
    def create
      @affiliate = Affiliates::Affiliate.create(params_affiliate)

      render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_index] }
    end

    # (DELETE) delete an Affiliate
    # /affiliates/affiliates/:id
    # affiliates_affiliate_path(:id)
    # affiliates_affiliate_url(:id)
    def destroy
      @affiliate.destroy

      render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_index] }
    end

    # (GET) edit an Affiliate
    # /affiliates/affiliates/:id/edit
    # edit_affiliates_affiliate_path(:id)
    # edit_affiliates_affiliate_url(:id)
    def edit
      render partial: 'affiliates/js/show', locals: { cards: %w[affiliate_edit] }
    end

    # (GET) list Affiliates
    # /affiliates/affiliates
    # affiliates_affiliates_path
    # affiliates_affiliates_url
    def index
      respond_to do |format|
        format.js   { render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_index] } }
        format.html { render 'affiliates/index' }
      end
    end

    # (GET) initialize a new Affiliate
    # /affiliates/affiliates/new
    # new_affiliates_affiliate_path
    # new_affiliates_affiliate_url
    def new
      @affiliate = Affiliates::Affiliate.new

      render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_index affiliate_open_new] }
    end

    # (GET) show an Affiliate in a modal
    # /affiliates/affiliates/:id
    # affiliates_affiliate_path(:id)
    # affiliates_affiliate_url(:id)
    def show
      render partial: 'affiliates/js/show', locals: { cards: %w[affiliate_show] }
    end

    # (PATCH/PUT) upsate an existing Affiliate
    # /affiliates/affiliates/:id
    # affiliates_affiliate_path(:id)
    # affiliates_affiliate_url(:id)
    def update
      @affiliate.update(params_affiliate)

      render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_index] }
    end

    private

    def authorize_user!
      super

      return if current_user.super_admin?

      raise ExceptionHandlers::UserNotAuthorized.new('Affiliates', root_path)
    end

    def params_affiliate
      sanitized_params = params.require(:affiliates_affiliate).permit(:company_name, :contact_name, :contact_phone, :contact_email, :commission, :notes)

      sanitized_params[:commission] = sanitized_params.dig(:commission).to_d

      sanitized_params
    end

    def affiliate
      @affiliate = Affiliates::Affiliate.find_by(id: params.permit(:id).dig(:id).to_i)
    end
  end
end
