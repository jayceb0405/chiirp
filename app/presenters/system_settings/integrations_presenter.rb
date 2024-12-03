# frozen_string_literal: true

# app/presenters/system_settings/integrations_presenter.rb
module SystemSettings
  class IntegrationsPresenter < BasePresenter
    attr_accessor :integration
    attr_reader :user

    def initialize(_args = {})
      super

      @integration            = nil
      @integrations           = nil
      @integrations_for_index = nil
      @configured_for_client_and_user = {}
    end

    def configured_for_client_and_user?
      @configured_for_client_and_user[@integration.integration] ||= @integration.configured_for_client_and_user?(self.user.client, self.user)
    end

    def integration_logo(width: 150, height: 60)
      if @integration.logo_image.present?
        ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(@integration.logo_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }), class: 'img-fluid', style: "max-height:#{height}px;max-width:#{width}px;")
      else
        ActionController::Base.helpers.image_tag("tenant/#{I18n.t('tenant.id')}/logo-600.png", class: 'img-fluid', style: "max-height:#{height}px;max-width:#{width}px;")
      end
    end

    def integration_name
      if @integration.show_company_name
        @integration.company_name
      else
        ''
      end
    end

    def integrations
      @integrations ||= SystemSettings::Integration.order(company_name: :asc)
    end

    def integrations_for_index
      @integrations_for_index_db ||= SystemSettings::Integration.order(sort_order: :asc, company_name: :asc)
      @integrations_for_index    ||= if self.user.integrations_order
                                       @integrations_for_index_db.sort_by do |integration|
                                         self.user.integrations_order.index(integration.id) || -1
                                       end
                                     else
                                       @integrations_for_index_db
                                     end
    end

    def onclick_function
      @integration&.accessible_to_user?(self.user) ? "window.location.href='#{@integration.link_url}';" : ''
    end

    def cursor_style
      @integration&.accessible_to_user?(self.user) ? 'cursor:pointer;' : ''
    end
  end
end
