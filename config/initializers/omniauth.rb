# initializers/omniauth.rb
module OmniAuth
  OmniAuth.config.allowed_request_methods = %i[get post]
  OmniAuth.config.silence_get_warning = true

  module Strategies
    class GoogleOauth2Chiirp < GoogleOauth2
      def name
        :google_oauth2_chiirp
      end
    end

    class OutreachChiirp < Outreach
      def name
        :outreach_chiirp
      end
    end

    class SlackChiirp < Slack
      def name
        :slack_chiirp
      end
    end
  end
end
