# frozen_string_literal: true

# app/controllers/users/omniauth_callbacks_controller.rb
module Users
  # OmniAuth callbacks supporting Facebook & Slack
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def all
      provider = Tenant.omniauth_provider(request)

      if current_user.present?

        case provider
        when 'facebook'

          if (user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'facebook', name: ''))
            fb_user_token = request.env['omniauth.auth']&.credentials&.token.to_s
            fb_user_id    = request.env['omniauth.auth']&.uid.to_s
            fb_user       = Integrations::FaceBook::Base.new(fb_user_id:, token: fb_user_token).user

            if (user = user_api_integration.users.find { |u| u['id'] == fb_user[:id] })
              user[:name]  = fb_user[:name]
              user[:token] = fb_user_token
            else
              user_api_integration.users << {
                id:    fb_user[:id],
                name:  fb_user[:name],
                token: fb_user_token
              }
            end

            user_api_integration.save

            redirect_to integrations_facebook_integration_path and return
          else
            sweetalert_error('Something Went Wrong!', "Please log in using a Facebook account matching your #{I18n.t('tenant.name')} email.", '', { persistent: 'OK' })
            redirect_to edit_integrations_google_connections_path and return
          end
        when 'google_oauth2'

          if (user_api_integration = current_user.user_api_integrations.find_by(target: 'google', name: ''))
            user_token = request.env['omniauth.auth']&.credentials&.token.to_s
            user_refresh_token = request.env['omniauth.auth']&.credentials&.refresh_token.to_s

            user_api_integration.update(
              token:         user_token,
              refresh_token: user_refresh_token.presence || user_api_integration.refresh_token
            )
          else
            sweetalert_error('Something Went Wrong!', "Please log in using a Google account matching your #{I18n.t('tenant.name')} email.", '', { persistent: 'OK' })
          end

          redirect_to edit_integrations_google_connections_path and return
        when 'outreach'

          if request.env['omniauth.auth']&.credentials&.token.to_s.present? && request.env['omniauth.auth']&.credentials&.refresh_token.to_s.present? && (client_api_integration = current_user.client.client_api_integrations.find_by(target: 'outreach'))
            client_api_integration.update(
              token:         request.env['omniauth.auth']&.credentials&.token.to_s,
              refresh_token: request.env['omniauth.auth']&.credentials&.refresh_token.to_s,
              expires_at:    request.env['omniauth.auth']&.credentials&.expires_at
            )
            sweetalert_info('Yea!!', 'Your Outreach credentials were saved.', '', { persistent: 'OK' })
          else
            sweetalert_error('Oops!!', 'Your Outreach credentials were NOT received.', '', { persistent: 'OK' })
          end

          redirect_to edit_integrations_outreach_connections_path and return
        when 'slack'

          if request.env['omniauth.auth']&.credentials&.token.to_s.present? && (user_api_integration = current_user.user_api_integrations.find_by(target: 'slack', name: ''))
            user_api_integration.update(token: request.env['omniauth.auth']&.credentials&.token.to_s)
            sweetalert_info('Yea!!', 'Your Slack credentials were saved.', '', { persistent: 'OK' })
          else
            sweetalert_error('Oops!!', 'Your Slack credentials were NOT received.', '', { persistent: 'OK' })
          end

          redirect_to edit_integrations_slack_connections_path and return
        else
          current_user.apply_omniauth(request.env['omniauth.auth'])
          sweetalert_info('Yea!!', "Your #{provider.camelcase} login was received.", '', { persistent: 'OK' })
        end

        redirect_to root_path
      else
        @user = User.from_omniauth(request.env['omniauth.auth'])

        if @user.nil? || @user.new_record?
          sweetalert_error("Unable to locate #{provider.camelcase} login!", "Please log in using a previously used method then add your #{provider.camelcase} login using 'Edit Password'.", '', { persistent: 'OK' })
          redirect_to after_omniauth_failure_path_for(resource_name)
        else
          sign_in_and_redirect @user
        end
      end
    end

    alias facebook all
    alias google_oauth2_chiirp all
    alias outreach_chiirp all
    alias slack_chiirp all

    #####################################
    # OmniAuth (request.env['omniauth.auth']) after Facebook
    # request.env['omniauth.auth'].credentials {
    #   expires=false
    #   token="EAAaZCSOaNbRQBAMQ2GZBTJjAvGfXQezRKrmVzIN1f7LA4qLSVgGS3qZAqBwgaH6qLDxYZCyo41C5nfM"
    # }
    # request.env['omniauth.auth'].extra {
    #   raw_info {
    #     email="kevin@kevinneubert.com"
    #     first_name="Kevin"
    #     id="2263573190337140"
    #     last_name="Neubert"
    #     name="Kevin Neubert"
    #     name_format="{first} {last}"
    #     picture {
    #       data {
    #         height=50
    #         is_silhouette=false
    #         url="https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=2263573190337140&height=50&width=50&ext=1595454066&hash=AeTWF78odAi0X0_e"
    #         width=50
    #       }
    #     }
    #     short_name="Kevin"
    #   }
    # }
    # request.env['omniauth.auth'].info {
    #   email="kevin@kevinneubert.com"
    #   first_name="Kevin"
    #   image="http://graph.facebook.com/v3.1/2263573190337140/picture"
    #   last_name="Neubert"
    #   name="Kevin Neubert"
    # }
    # request.env['omniauth.auth'].provider="facebook"
    # request.env['omniauth.auth'].uid="2263573190337140"

    #####################################
    # Slack response
    # request.env['omniauth.auth'].credentials:
    #   .expires=false
    #   .scope="channels:read,users:read,users:read.email,users.profile:read,channels:write,chat:write"
    #   .scopes=#<OmniAuth::Slack::AuthHash classic=#<Hashie::Array ["channels:read", "users:read", "users:read.email", "users.profile:read", "channels:write", "chat:write"]>>
    #   .token="xoxp-383831588325-384716488390-6701303603621-23b158d11e7d5f987e84b2be56fcd3d9"
    #   .token_type="user"
    #
    # {
    #   provider: "slack",
    #   uid: "-",
    #   credentials {
    #     expires: false,
    #     token: "xoxp-596521025075-596910184546-1002272351142-352e0f4967eeec8eafd6c38140aaacbd"
    #   }
    #   extra: {
    #     raw_info: {
    #       bot_info= {},
    #       team_identity: {},
    #       team_info: {
    #         ok: true,
    #         team: {
    #           domain: "neuberts",
    #           email_domain: "",
    #           icon: [
    #             image_102="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_102.png",
    #             image_132="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_132.png",
    #             image_230="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_230.png",
    #             image_34="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_34.png",
    #             image_44="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_44.png",
    #             image_68="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_68.png",
    #             image_88="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_88.png",
    #             image_original="https://avatars.slack-edge.com/2019-05-06/626776913748_d17ef10ef301e3528ae8_original.png"
    #           ],
    #           id: "THJFB0R27",
    #           name: "neuberts"
    #         }
    #       },
    #       user_identity: {},
    #       user_info: {
    #         error: "user_not_found",
    #         ok: false
    #       },
    #       web_hook_info: {}
    #     }
    #   }
    #   info: {
    #     email: nil,
    #     first_name: nil,
    #     image: nil,
    #     last_name: nil,
    #     name: nil,
    #     phone: nil,
    #     team_name: nil
    #   }
    # }

    #####################################
    # Google response
    # request.env['omniauth.auth']: #<OmniAuth::AuthHash
    #   credentials=#<OmniAuth::AuthHash
    #     expires=true
    #     expires_at=1633643171
    #     refresh_token="1//0d97GEoBVlXxtCgYIARAAGA0SNwF-L9IrmMFP2tXpwpesX2MZR9T4wvnyfPuKHilt0J3e6cSIql0cO10SvJ6WUD3IqgZ2xM03rwc"
    #     token="ya29.a0ARrdaM_f5ezrQ0JABQrYmTvvTgb0hRhjL0hb2oEPSvup_x36sOrVw4LdERy44LdFpd5RVOrsvk1sQWjAE9c5PgFZKRtaGLcj9MVr57E-GQFc_ycMcZQM1NFiPoRk4DDYQE__zKsZ0gQQra5ckahMypl0d5Bg"
    #   >
    #   extra=#<OmniAuth::AuthHash id_info=#<OmniAuth::AuthHash
    #     at_hash="lip1k5DNbP_1svvRtfNRBg"
    #     aud="734887748645-p9qoecm9oigiknfsbqf35m2jqo1o4h7q.apps.googleusercontent.com"
    #     azp="734887748645-p9qoecm9oigiknfsbqf35m2jqo1o4h7q.apps.googleusercontent.com"
    #     email="kevin@chiirp.com"
    #     email_verified=true
    #     exp=1633643172
    #     family_name="Neubert"
    #     given_name="Kevin"
    #     hd="chiirp.com"
    #     iat=1633639572
    #     iss="https://accounts.google.com"
    #     locale="en"
    #     name="Kevin Neubert"
    #     sub="106702836638822736000">
    #     id_token="eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0MTk2YWVlMTE5ZmUyMTU5M2Q0OGJmY2ZiNWJmMDAxNzdkZDRhNGQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI3MzQ4ODc3NDg2NDUtcDlxb2VjbTlvaWdpa25mc2JxZjM1bTJqcW8xbzRoN3EuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI3MzQ4ODc3NDg2NDUtcDlxb2VjbTlvaWdpa25mc2JxZjM1bTJqcW8xbzRoN3EuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDY3MDI4MzY2Mzg4MjI3MzYwMDAiLCJoZCI6ImNoaWlycC5jb20iLCJlbWFpbCI6ImtldmluQGNoaWlycC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6ImxpcDFrNUROYlBfMXN2dlJ0Zk5SQmciLCJuYW1lIjoiS2V2aW4gTmV1YmVydCIsImdpdmVuX25hbWUiOiJLZXZpbiIsImZhbWlseV9uYW1lIjoiTmV1YmVydCIsImxvY2FsZSI6ImVuIiwiaWF0IjoxNjMzNjM5NTcyLCJleHAiOjE2MzM2NDMxNzJ9.hvGhFHCb11jdtiLL-G3wPdRGb9vuhmR2eLEkUO9LMAbtHqNqRMNsOqoWh6j3P4MYD693_cDFY35JCcqIdjVwCUA9DtXxqcDhNwRCPO4qV0s1w_HfcrBCOw_QnELSKq9kfMYIzu3eexc66xs8Z6QbtVGi3fOR5yQfNZCebv58cWJ0O7BWFhSd9wpWYWbky9rDjWrXgKcSXZvAXknXFIccQ-81nllZW6eqqSXZCoRaMAd1bphYTuFnCNTdMU7zv8AxGujcmb_gEoJj_zbgwv7nfwHPz6mPb9bLyDt_aw8wsG4DDIOXoBNuqGM5W_GjfQ9bCbp9H7PIiMJS966B5b2JsQ"
    #     raw_info=#<OmniAuth::AuthHash
    #       email="kevin@chiirp.com"
    #       email_verified=true
    #       family_name="Neubert"
    #       given_name="Kevin"
    #       hd="chiirp.com"
    #       locale="en"
    #       name="Kevin Neubert"
    #       picture="https://lh3.googleusercontent.com/a-/AOh14GguItW51Qi9muFVax5tjEJZPahtlVFA_v0RUcNdooCTauWCWNqBKwYNbozF3FnTNmxNPTzl7jMZUmhXfgLPPcNaZwgWWWntLSTevu8Ken87Kg6PnIGHh23qkVH4r1Zcb1ajGbAPKC8UVnxE_0FafKF1tvO4QsYtefxxEf6KHC6YCyzBtmGS6lufBhsPQTHbWJkFHUnbpCO4paw_Z_hi4-GH723dPmY0tILnb6rJZ7stl2d_Nd-vd9mueA3q2lY6jX0lnEMtgtfISzYjnfqcU99Q_4w4_zAum-0hG6sEv_hq2w-lUPUcKlJcrt2x6fwb1z5ou-mvxLZ79mjNZ-yrNP4_Zcr1Z2_j8DbD1RpfN3BVTwSLgnlosE0rdRm8qPYG0KUjfrc1fXk_ANe6KgEGScGJZsjdSIAjihxY-oflMPqFm3SLxYPEBtTaJpPwGw5vt4k_fROjDEKA3kXutV0jvSnorTRpy6cXUNAmjQKKpYxSXJdmg1KK7wLB8Mmm0GJid29U-7sggi4rrosrzV6N-lhDDRXWD44Lrcvb9na3BCpfl0TF1DnIaSdU0MSpPCpmJOxNm5P950os9ybf_e3J6HMIZlDkSqJh8GNba3NR8mweVq32Yav2bvZfd64UmT5W1_R5b-D5_4skXupbp-dRWTG7evmKAr1tc-172GiagqXAlWB8mwrp5kkx5UgdPkKNqshmeJIVUwRSsvsqW5OOMWTkfPPFHNDjFvjCp3xSh1xkS9LZkSM0NfSD5DUpxK4JTY4Teg=s96-c"
    #       sub="106702836638822736000"
    #     >
    #   >
    #   info=#<OmniAuth::AuthHash::InfoHash
    #     email="kevin@chiirp.com"
    #     email_verified=true
    #     first_name="Kevin"
    #     image="https://lh3.googleusercontent.com/a-/AOh14GguItW51Qi9muFVax5tjEJZPahtlVFA_v0RUcNdooCTauWCWNqBKwYNbozF3FnTNmxNPTzl7jMZUmhXfgLPPcNaZwgWWWntLSTevu8Ken87Kg6PnIGHh23qkVH4r1Zcb1ajGbAPKC8UVnxE_0FafKF1tvO4QsYtefxxEf6KHC6YCyzBtmGS6lufBhsPQTHbWJkFHUnbpCO4paw_Z_hi4-GH723dPmY0tILnb6rJZ7stl2d_Nd-vd9mueA3q2lY6jX0lnEMtgtfISzYjnfqcU99Q_4w4_zAum-0hG6sEv_hq2w-lUPUcKlJcrt2x6fwb1z5ou-mvxLZ79mjNZ-yrNP4_Zcr1Z2_j8DbD1RpfN3BVTwSLgnlosE0rdRm8qPYG0KUjfrc1fXk_ANe6KgEGScGJZsjdSIAjihxY-oflMPqFm3SLxYPEBtTaJpPwGw5vt4k_fROjDEKA3kXutV0jvSnorTRpy6cXUNAmjQKKpYxSXJdmg1KK7wLB8Mmm0GJid29U-7sggi4rrosrzV6N-lhDDRXWD44Lrcvb9na3BCpfl0TF1DnIaSdU0MSpPCpmJOxNm5P950os9ybf_e3J6HMIZlDkSqJh8GNba3NR8mweVq32Yav2bvZfd64UmT5W1_R5b-D5_4skXupbp-dRWTG7evmKAr1tc-172GiagqXAlWB8mwrp5kkx5UgdPkKNqshmeJIVUwRSsvsqW5OOMWTkfPPFHNDjFvjCp3xSh1xkS9LZkSM0NfSD5DUpxK4JTY4Teg=s96-c"
    #     last_name="Neubert"
    #     name="Kevin Neubert"
    #     unverified_email="kevin@chiirp.com"
    #   >
    #   provider="google_oauth2"
    #   uid="106702836638822736000"
    # >
    def failure
      redirect_to root_path
    end
  end
end
