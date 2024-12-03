# frozen_string_literal: true

# app/controllers/integrations/stripo/integrations_controller.rb
module Integrations
  module Stripo
    class TestController < Stripo::IntegrationsController
      before_action :email_template, only: %i[show update]

      # (POST) create a new EmailTemplate
      # /integrations/stripo/test
      # integrations_stripo_test_path
      # integrations_stripo_test_url
      def create
        @email_template = current_user.client.email_templates.create(name: 'Test', subject: 'Test', html: params.dig(:html_data), css: params.dig(:css_data), content: Integrations::StripO::Base.new.compiled_html(html: params.dig(:html_data), css: params.dig(:css_data)))
        JsonLog.info 'Integrations::Stripo::TestController.create', { email_template_errors: @email_template.errors }
        render 'integrations/stripo/show'
      end

      # (GET) start a new EmailTemplate
      # /integrations/stripo/test/new
      # new_integrations_stripo_test_path
      # new_integrations_stripo_test_url
      def new
        @email_template = current_user.client.email_templates.new(name: 'Test', subject: 'Test', html: '', css: '', share_code: '', content: '')

        render 'integrations/stripo/show'
      end

      # (GET) Stripo integration sample
      # /integrations/stripo/test/:id
      # integrations_stripo_test_path(:id)
      # integrations_stripo_test_url(:id)
      def show
        render 'integrations/stripo/show'
      end

      # (PUT/PATCH) update EmailTemplate
      # /integrations/stripo/test/:id
      # integrations_stripo_test_path(:id)
      # integrations_stripo_test_url(:id)
      def update
        @email_template.update(html: params.dig(:html_data), css: params.dig(:css_data), content: 'Up next!')

        render 'integrations/stripo/show'
      end
    end
  end
end
