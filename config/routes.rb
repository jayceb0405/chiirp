# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  # constraints are processed before Tenant is processed in ApplicationController

  use_doorkeeper

  # health check
  get '/up', to: 'health_check#up'

  # QuickPage forms
  get    '/:page_key',                                     to: 'api/v3/user_contact_forms#show_page',                                      constraints: Constraints::QuickPage.new
  post   '/:page_key',                                     to: 'api/v3/user_contact_forms#save_contact',                                   constraints: Constraints::QuickPage.new

  # ShortCodes
  get 'sc/:code',                                          to: 'short_codes#show', as: :short_code

  namespace :api do
    namespace :v1 do
      resources :profiles
      resources :users

      # Zapier integration
      get  '/zapier/campaigns/:token',                     to: 'zapiers#campaigns',                          as: :zapier_campaigns
      get  '/zapier/contacts/:token',                      to: 'zapiers#contacts',                           as: :zapier_contacts
      post '/zapier/contacts/:token',                      to: 'zapiers#register_subscription'
      post '/zapier/subscribe/:token',                     to: 'zapiers#register_subscription',              as: :zapier_register_subscription
      post '/zapier/unsubscribe/:token',                   to: 'zapiers#register_unsubscription',            as: :zapier_register_unsubscription
      post '/zapier/contact_rcv/:token',                   to: 'zapiers#contact_rcv',                        as: :zapier_contact_rcv
      get  '/zapier/fields/:token',                        to: 'zapiers#fields',                             as: :zapier_fields
      get  '/zapier/tags/:token',                          to: 'zapiers#tags',                               as: :zapier_tags
      get  '/zapier/groups/:token',                        to: 'zapiers#groups',                             as: :zapier_groups

      get  '/me',                                          to: 'credentials#me'
      get  '/fast',                                        to: 'fast#index'

      get  '/central',                                     to: 'central#central'
      get  '/central/show',                                to: 'central#show'
      get  '/central/init',                                to: 'central#init'
    end

    namespace :chiirpapp do
      namespace :v1 do
        resources :user, only: %i[] do
          resources :active_contacts, only: %i[index], constraints: Constraints::OnlyJsonRequest.new
          resources :contact, only: %i[] do
            scope module: 'contacts' do
              resources :notes, only: %i[create destroy index show update],                                                                constraints: Constraints::OnlyJsonRequest.new
              resources :tags, only: %i[create destroy index show],                                                                        constraints: Constraints::OnlyJsonRequest.new
            end
          end
          resources :contacts, only: %i[create destroy index show update],                                                                 constraints: Constraints::OnlyJsonRequest.new
          resources :conversations, only: %i[index],                                                                                       constraints: Constraints::OnlyJsonRequest.new
          get  'conversations/call_history/:phone_number', to: 'conversations#call_history',                 as: :call_history,            constraints: Constraints::OnlyJsonRequest.new
          get  'conversations/:contact_id',                to: 'conversations#contact_phone_numbers',        as: :conversation_contact,    constraints: Constraints::OnlyJsonRequest.new
          post 'conversations/:contact_id/call',           to: 'conversations#call_contact',                 as: :call_contact,            constraints: Constraints::OnlyJsonRequest.new
          post 'conversations/:contact_id/send',           to: 'conversations#send_message',                 as: :conversation_send,       constraints: Constraints::OnlyJsonRequest.new
          post 'conversations/file_upload',                to: 'conversations#file_upload',                  as: :file_upload,             constraints: Constraints::OnlyJsonRequest.new
          put  'conversations/:contact_id/message/:message_id', to: 'conversations#update_message',          as: :update_message,          constraints: Constraints::OnlyJsonRequest.new
          resource  :settings, only: %i[show update],                                                                                      constraints: Constraints::OnlyJsonRequest.new
          resources :tags, only: %i[create destroy index show],                                                                            constraints: Constraints::OnlyJsonRequest.new
        end
        resources :users, only: %i[show update], param: :user_id, constraints: Constraints::OnlyJsonRequest.new
        post 'users/:user_id', to: 'users#password_reset', constraints: Constraints::OnlyJsonRequest.new
      end
    end

    namespace :ui do
      namespace :v1 do
        resources :contacts, only: %i[index] do
        end
        resources :dashboard, only: %i[] do
          collection do
            get :automations
            get :metrics
            get :attributes
            put :attributes
          end
          member do
            get :metric
          end
        end
        resources :misc, only: %i[] do
          collection do
            get :timeframes
          end
        end
        resources :users, only: %i[index] do
          collection do
            get :me
            post :legacy
          end
        end
      end
    end
  end

  devise_scope :user do
    get  'login',                                          to: 'devise/sessions#new'
    post 'users',                                          to: 'users#create'
  end

  get   '/users/2fa/method', to: 'users/two_factor#new', as: 'method_user_two_factor'
  patch '/users/2fa/method', to: 'users/two_factor#method'
  get   '/users/2fa', to: 'users/two_factor#attempt', as: 'attempt_user_two_factor'
  patch '/users/2fa', to: 'users/two_factor#create'

  devise_for :users, controllers: {
    registrations:      'registrations',
    invitations:        'invitations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions:           'users/sessions'
  }

  # server WebSocket Cable requests in progress
  mount ActionCable.server, at: '/cable'

  post   'cloudinary/callback',                            to: 'cloudinary#callback'

  get    'facebook/endpoint',                              to: 'integrations/facebook/integrations#endpoint'
  post   'facebook/endpoint',                              to: 'integrations/facebook/integrations#endpoint'
  get    'facebook/webhooks',                              to: 'integrations/facebook/integrations#endpoint'
  post   'facebook/webhooks',                              to: 'integrations/facebook/integrations#endpoint'
  get    'facebook/platform',                              to: 'integrations/facebook/integrations#platform'
  get    'facebook/logintest',                             to: 'integrations/facebook/integrations#logintest'
  get    'facebook/longlivetoken',                         to: 'integrations/facebook/integrations#longlivetoken'

  post   '/funnel_webhooks/test',                          action: 'test', controller: 'integrations/clickfunnels/integrations'

  get    'welcome/about',                                  to: redirect('https://www.chiirp.com', status: 301)
  get    'welcome/contact',                                to: redirect('https://www.chiirp.com/demo/')
  post   'welcome/contact',                                to: redirect('https://www.chiirp.com/demo/')
  get    'welcome/courses',                                to: redirect('https://www.chiirp.com/watch-demo/')
  get    'welcome/demo',                                   to: redirect('https://www.chiirp.com/demo/')
  get    'welcome/experience',                             to: redirect('https://www.chiirp.com/watch-demo/')
  get    'welcome/failed_link',                            to: 'welcome#failed_link', as: :welcome_failed_link
  get    'welcome/features',                               to: redirect('https://www.chiirp.com/features/')
  get    'welcome/index',                                  to: redirect('https://www.chiirp.com')
  get    'welcome/join/:package_key',                      to: 'welcome#join',                               as: :welcome_join
  get    'welcome/join/min/:package_key',                  to: 'welcome#join_min',                           as: :welcome_join_min
  get    'welcome/pricing/:package_page_key',              to: 'welcome#pricing',                            as: :welcome_pricing
  get    'welcome/pricing/init/:package_page_key',         to: 'welcome#pricing_init',                       as: :welcome_pricing_init
  get    'welcome/pricing',                                to: 'welcome#pricing',                            as: :welcome_pricing_default
  get    'welcome/privacy',                                to: redirect('https://www.chiirp.com/privacy-policy/')
  get    'welcome/scheduler',                              to: redirect('https://www.chiirp.com/demo/')
  get    'welcome/serviceterms',                           to: redirect('https://www.chiirp.com/terms-of-service/')
  get    'welcome/success/:id',                            to: 'welcome#success',                            as: :welcome_success
  get    'welcome/training',                               to: 'welcome#training',                           as: :welcome_training
  get    'welcome/why',                                    to: redirect('https://chiirp.com')
  get    'welcome/unsubscribe/:client_id/:contact_id',     to: 'welcome#unsubscribe', as: :welcome_unsubscribe

  scope module: 'users' do
    resources :authentications, only: %i[destroy]
  end

  #################
  # Affiliates
  #################
  namespace :affiliates do
    resources :affiliates
    resources :reports, only: %i[index]
  end

  #################
  # Campaigns
  #################
  post   'campaigns/import',                               to: 'campaigns#import',                           as: :import_campaign,         constraints: Constraints::OnlyAjaxRequest.new
  get    'campaigns/import/index',                         to: 'campaigns#index_import',                     as: :index_import_campaign,   constraints: Constraints::OnlyAjaxRequest.new
  get    'campaigns/contact/:contact_campaign_id',         to: 'campaigns#index_contact_campaign_actions',   as: :index_contact_campaign_actions, constraints: Constraints::OnlyAjaxRequest.new
  post   'campaigns/apply/:contact_id',                    to: 'campaigns#apply_campaign',                   as: :apply_campaign,          constraints: Constraints::OnlyAjaxRequest.new
  delete 'campaigns/stop/:contact_campaign_id',            to: 'campaigns#stop_campaign',                    as: :stop_campaign,           constraints: Constraints::OnlyAjaxRequest.new

  resources :campaigns, only: %i[index] do
    resources :triggers, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
  end

  resources :campaigns, only: %i[create destroy edit new show update], constraints: Constraints::OnlyAjaxRequest.new

  #################
  # CampaignGroups
  #################
  resources :campaign_groups, only: %i[create destroy edit index new update]

  #################
  # CampaignMarketplaces
  #################
  post   'campaign_marketplaces/:id/approve',              to: 'campaign_marketplaces#approve',              as: :approve_campaign
  post   'campaign_marketplaces/:id/buy',                  to: 'campaign_marketplaces#buy',                  as: :buy_campaign
  patch  'campaign_marketplaces/:id/image',                to: 'campaign_marketplaces#image',                as: :image_campaign

  resources :campaign_marketplaces, only: %i[edit index show update]

  #################
  # AI agents
  #################
  get    'aiagents',                                       to: 'aiagents#show'
  post   'aiagents/apply/:contact_id',                     to: 'aiagents#apply_contact',                    as: :aiagents_apply,             constraints: Constraints::OnlyAjaxRequest.new
  post   'aiagents/import',                                to: 'aiagents#import',                           as: :aiagents_import,            constraints: Constraints::OnlyAjaxRequest.new
  put    'aiagents/terms',                                 to: 'aiagents#terms',                            as: :aiagents_terms,             constraints: Constraints::OnlyAjaxRequest.new
  post   'aiagents/new/purchase',                          to: 'aiagents#purchase',                         as: :aiagents_purchase,          constraints: Constraints::OnlyAjaxRequest.new

  resources :aiagents, only: %i[create destroy edit new update] do
    get  '/test',                                          to: 'aiagents/sessions#test'
    put  '/test',                                          to: 'aiagents/sessions#update'
    post '/test',                                          to: 'aiagents/sessions#test_send'
    post '/test/reset',                                    to: 'aiagents/sessions#test_reset'
    post '/respond_to/:contact_id',                        to: 'aiagents/quick_responses#respond', as: :quick_response, constraints: Constraints::OnlyJsonRequest.new
  end

  #################
  # Central
  #################
  get    'central',                                        to: 'central#index',                             as: :central
  get    'central/active_contacts',                        to: 'central#index_active_contacts',             as: :central_active_contacts, constraints: Constraints::OnlyAjaxRequest.new
  get    'central/:push_token',                            to: 'central#index',                             as: :central_login_mobile
  post   'central/call_contact/:contact_id',               to: 'central#call_contact',                      as: :central_call_contact,       constraints: Constraints::OnlyAjaxRequest.new
  get    'central/contact_options/:contact_id',            to: 'central#contact_options',                   as: :central_contact_options,    constraints: Constraints::OnlyAjaxRequest.new
  get    'central/contact_profile/:contact_id',            to: 'central#contact_profile',                   as: :central_contact_profile,    constraints: Constraints::OnlyAjaxRequest.new
  get    'central/conversation/:contact_id',               to: 'central#conversation',                      as: :central_conversation,       constraints: Constraints::OnlyAjaxRequest.new
  get    'central/fsimage/:contact_attachment_id',         to: 'central#full_size_image',                   as: :central_full_size_image
  get    'central/:contact_id/aiagent_sessions',           to: 'central#index_aiagent_sessions',            as: :central_aiagent_sessions,   constraints: Constraints::OnlyAjaxRequest.new
  get    'central/:contact_id/campaigns',                  to: 'central#index_campaigns',                   as: :central_campaigns,          constraints: Constraints::OnlyAjaxRequest.new
  delete 'central/:contact_id/stop_aiagent',               to: 'central#stop_aiagent',                      as: :central_stop_aiagent,       constraints: Constraints::OnlyAjaxRequest.new
  get    'central/:contact_id/tags',                       to: 'central#index_tags',                        as: :central_tags,               constraints: Constraints::OnlyAjaxRequest.new
  get    'central/:contact_id/tasks',                      to: 'central#index_tasks',                       as: :central_tasks,              constraints: Constraints::OnlyAjaxRequest.new
  post   'central/:contact_id/toggleok2email',             to: 'central#toggle_ok_2_email',                 as: :central_toggle_ok_2_email,  constraints: Constraints::OnlyAjaxRequest.new
  post   'central/:contact_id/toggleok2text',              to: 'central#toggle_ok_2_text',                  as: :central_toggle_ok_2_text,   constraints: Constraints::OnlyAjaxRequest.new
  post   'central/markasunread/:message_id',               to: 'central#mark_as_unread',                    as: :central_mark_as_unread,     constraints: Constraints::OnlyAjaxRequest.new
  get    'central/messagedropdown/:message_id',            to: 'central#message_dropdown',                  as: :central_dropdown,           constraints: Constraints::OnlyAjaxRequest.new
  patch  'central/update_message_meta',                    to: 'central#update_message_meta',               as: :central_update_message_meta, constraints: Constraints::OnlyAjaxRequest.new

  #################
  # Clients
  #################
  namespace :clients do
    resources :admin, only: %i[edit update], param: :client_id
    resource  :analytics, only: %i[edit show update], param: :client_id
    resources :avatar, only: %i[update], param: :client_id
    resources :billing, only: %i[edit update], param: :client_id
    resources :companies, only: %i[index show], param: :client_id
    resources :features, only: %i[edit update], param: :client_id
    resources :holidays, only: %i[index]
    resources :holidays, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
    resources :kpis, only: %i[create destroy index edit new update]
    resources :overview, only: %i[edit], param: :client_id
    resources :profile, only: %i[edit update], param: :client_id
    patch 'profile/update_vitally/:client_id', to: 'profile#update_vitally', as: :profile_update_vitally
    resources :settings, only: %i[edit update], param: :client_id
    resources :statements, only: %i[show], param: :client_id
    get '/statements/:client_id/print', controller: 'statements', action: :print, as: :statements_print
    resources :task_actions, only: %i[edit update], param: :client_id
    resources :terms, only: %i[edit update], param: :client_id
    resources :widgets, only: %i[index destroy]

    namespace :dlc10 do
      resources :brands, only: %i[edit], param: :client_id
      resources :brands, only: %i[show update], param: :client_id,                                                                         constraints: Constraints::OnlyAjaxRequest.new
      resources :campaign_types, only: %i[show], param: :client_id,                                                                        constraints: Constraints::OnlyAjaxRequest.new
      resources :campaigns, only: %i[create destroy index edit new update], param: :client_id,                                             constraints: Constraints::OnlyAjaxRequest.new
      resources :intros, only: %i[show], param: :client_id
      resources :phone_numbers, only: %i[index update], param: :client_id,                                                                 constraints: Constraints::OnlyAjaxRequest.new
      get  'campaign/:client_id/sub_use_cases',            to: 'campaigns#sub_use_cases',                    as: :campaign_sub_use_cases,  constraints: Constraints::OnlyJsonRequest.new
      post 'webhooks/endpoint',                            to: 'webhooks#endpoint',                          as: :webhook_endpoint
    end

    get     'widget/import/show',                          to: 'widgets#import_show',                        as: :import_widget_show,      constraints: Constraints::OnlyAjaxRequest.new
    post    'widget/import',                               to: 'widgets#import',                             as: :import_widget,           constraints: Constraints::OnlyAjaxRequest.new
  end

  post 'twvoice/rvm_callback', to: 'clients/voice_recordings#rvm_callback', as: :rvm_callback_voice_recording

  scope module: 'clients' do
    resources :client, only: %i[] do
      resources :custom_fields, only: %i[create destroy edit index new update]
      resources :folders, only: %i[create destroy edit index new update]
      resources :groups, only: %i[create destroy edit index new update]
      resources :lead_sources, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
      resources :lead_sources, only: %i[index]
      resources :phone_numbers, only: %i[destroy edit index update]
      resources :org_positions
      resources :org_users, only: %i[create destroy edit index new update]

      resources :stage_parents, only: %i[destroy edit index new update] do
        resources :stages, only: %i[create destroy edit index new update]
      end

      get  'stage_parents/import/copy/:id',                to: 'stage_parents#import_copy',                  as: :import_stage_parent_copy, constraints: Constraints::OnlyAjaxRequest.new
      get  'stage_parents/import/show',                    to: 'stage_parents#import_show',                  as: :import_stage_parent_show, constraints: Constraints::OnlyAjaxRequest.new
      post 'stage_parents/import',                         to: 'stage_parents#import',                       as: :import_stage_parent,      constraints: Constraints::OnlyAjaxRequest.new

      resources :tags, only: %i[create destroy edit index new update]
      resources :users, only: %i[create destroy edit index new update]
      patch 'users/:id/update_vitally', to: 'users#update_vitally', as: :users_update_vitally
      resources :voice_recordings, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
      resources :voice_recordings, only: %i[index]
    end

    patch 'client/:client_id/voice_recordings/:id/save_audio_file', to: 'voice_recordings#save_audio_file', as: :save_audio_file_voice_recording, constraints: Constraints::OnlyAjaxRequest.new
    patch 'client/:client_id/voice_recordings/:id/new_voice_recording', to: 'voice_recordings#new_voice_recording', as: :new_voice_recording, constraints: Constraints::OnlyAjaxRequest.new
    post  'client/:client_id/voice_recordings/:id/record_voice_recording', to: 'voice_recordings#record_voice_recording', as: :record_voice_recording
    post  'client/:client_id/voice_recordings/:id/save_voice_recording', to: 'voice_recordings#save_voice_recording', as: :save_voice_recording
  end

  get    'client/:client_id/org_chart',                    to: 'clients/org_positions#org_chart',            as: :client_org_chart
  # get    'clients/onboard_confirm',                        to: 'clients#update_onboard',                     as: :update_client_onboard
  patch  'client/:client_id/custom_fields/:id/important',  to: 'clients/custom_fields#important',            as: :important_client_custom_field
  # get    'clients/:client_id/onboard',                     to: 'clients#edit_onboard',                       as: :edit_client_onboard
  get    'clients/:client_id/upgrade',                     to: 'clients#upgrade',                            as: :client_upgrade
  post   'clients/:client_id/upgrade',                     to: 'clients#upgrade_account',                    as: :client_upgrade_account

  resources :clients, only: %i[create destroy edit new update], param: :client_id

  resources :clients, only: %i[] do
    resources :twnumbers, only: %i[create]
    resources :notes, controller: 'clients/notes', constraints: Constraints::OnlyAjaxRequest.new

    post 'file_upload',                                    to: 'clients#file_upload', as: :file_upload
    patch 'update_agency',                                 to: 'clients#update_agency'
    get 'user_list', to: 'clients#user_list', as: :users_list, defaults: { format: :json }, constraints: Constraints::OnlyAjaxRequest.new
  end

  get    'validate_unique_email',                          to: 'clients#validate_unique_email',              as: :validate_unique_email, defaults: { format: :json }
  post   'twnumbers/subscription_callback',                to: 'twnumbers#subscription_callback',            as: :subscription_callback_twnumber

  namespace :api do
    namespace :v2 do
      get     'sitechat/:widget_key', to: 'clients/widgets#sitechat', as: :sitechat

      namespace :clients do
        resources :widgets, only: %i[create edit new update]

        get   'sitechat/:widget_key',                      to: 'widgets#sitechat',                           as: :sitechat
        get   'widget/:widget_key',                        to: 'widgets#show_widget',                        as: :show_widget
        get   'widget_bubble/:widget_key',                 to: 'widgets#show_widget_bubble',                 as: :show_widget_bubble
        post  ':client_id/widget/:widget_key',             to: 'widgets#save_contact',                       as: :save_widget_contact
        patch 'widgets/:id/button_image',                  to: 'widgets#button_image',                       as: :edit_widget_button_image
      end
    end

    namespace :v3 do
      namespace :clients do
        resources :widgets, only: %i[create edit new update]

        get   'sitechat/:widget_key',                      to: 'widgets#sitechat',                           as: :sitechat
        get   'widget/:widget_key',                        to: 'widgets#show_widget',                        as: :show_widget
        get   'widget_bubble/:widget_key',                 to: 'widgets#show_widget_bubble',                 as: :show_widget_bubble
        post  ':client_id/widget/:widget_key',             to: 'widgets#save_contact',                       as: :save_widget_contact
        patch 'widgets/:id/button_image',                  to: 'widgets#button_image',                       as: :edit_widget_button_image
      end
    end
  end

  #################
  # Contacts
  #################
  resources :contacts, only: %i[create destroy edit new update], param: :contact_id

  resources :contacts, only: %i[] do
    post   'block', to: 'contacts#block', as: :block, constraints: Constraints::OnlyAjaxRequest.new
    post   'file_upload', to: 'contacts#file_upload', as: :file_upload
    post   'groupadd'
    delete 'groupremove'
    post   'sleep',                                        to: 'contacts#sleep',                             as: :sleep, constraints: Constraints::OnlyAjaxRequest.new
    post   'tagapply',                                     to: 'contacts#tag_apply',                         as: :tag_apply
    delete 'tagremove/:contacttag_id',                     to: 'contacts#tag_remove',                        as: :tag_remove
  end

  namespace :contacts do
    resources :fb_pages, only: %i[create destroy edit index new show update]
    resource  :import, only: %i[show update], constraints: Constraints::OnlyAjaxRequest.new
  end

  get    '/contacts/import',                               to: 'contacts/imports#show',                      as: :import_contacts
  post   '/contacts/import',                               to: 'contacts/imports#update',                    as: :import_rcv_contacts
  get    '/contacts/:contact_id/scheduled_action/:id/edit', to: 'contacts#edit_scheduled_action',            as: :edit_contact_scheduled_action, constraints: Constraints::OnlyAjaxRequest.new
  get    '/contacts/:contact_id/scheduled_actions',        to: 'contacts#index_scheduled_actions',           as: :contact_scheduled_actions, constraints: Constraints::OnlyAjaxRequest.new
  delete '/contacts/:contact_id/scheduled_action/:id',     to: 'contacts#destroy_scheduled_action',          as: :contact_scheduled_action, constraints: Constraints::OnlyAjaxRequest.new
  patch  '/contacts/:contact_id/scheduled_action/:id',     to: 'contacts#update_scheduled_action',           as: :update_contact_scheduled_action, constraints: Constraints::OnlyAjaxRequest.new
  get    '/contacts/raw_posts/:id',                        to: 'contacts/raw_posts#show',                    as: :raw_post
  get    '/contacts/:contact_id/raw_posts',                to: 'contacts/raw_posts#index',                   as: :raw_posts

  #################
  # Dashboards
  #################
  get    'dashboards',                                     to: 'dashboards#show'
  get    'dashboards/button/:type',                        to: 'dashboards#show_button',                     as: :button_show_dashboard
  patch  'dashboards/buttons/:id',                         to: 'dashboards#update_buttons',                  as: :buttons_dashboard,       constraints: Constraints::OnlyAjaxRequest.new
  patch  'dashboards/period/:id',                          to: 'dashboards#update_period',                   as: :period_dashboard,        constraints: Constraints::OnlyAjaxRequest.new
  get    'dashboards/cal_actions',                         to: 'dashboards#cal_actions',                     as: :cal_actions_dashboard
  get    'dashboards/cal_msgs',                            to: 'dashboards#cal_msgs',                        as: :cal_msgs_dashboard
  patch  'dashboards/cal_tasks',                           to: 'dashboards#update_cal_tasks',                as: :cal_tasks_dashboard
  get    'dashboards/cal_tasks',                           to: 'dashboards#cal_tasks',                       as: nil
  get    'dashboards/tasks',                               to: 'dashboards#index_tasks',                     as: :index_tasks_dashboard,   constraints: Constraints::OnlyAjaxRequest.new
  patch  'dashboards/task_complete',                       to: 'dashboards#update_task_complete',            as: :task_complete,           constraints: Constraints::OnlyAjaxRequest.new
  root                                                     to: 'dashboards#show'

  resources :dashboards, only: %i[create destroy edit new show update]

  #################
  # EmailTemplates
  #################
  get    'email_templates',                                 to: 'email_templates#show'
  post   'email_templates/import',                          to: 'email_templates#import', as: :email_templates_import, constraints: Constraints::OnlyAjaxRequest.new

  resources :email_templates, only: %i[create destroy edit new update] do
    patch '/image',                                         to: 'email_templates#image',                     as: :image
  end

  #################
  # Folders
  #################
  resources :folders, only: %i[] do
    post 'message_apply',                                   to: 'folders#message_apply',                     as: :message_apply,           constraints: Constraints::OnlyAjaxRequest.new
    post 'message_remove',                                  to: 'folders#message_remove',                    as: :message_remove,          constraints: Constraints::OnlyAjaxRequest.new
    post 'message_toggle',                                  to: 'folders#message_toggle',                    as: :message_toggle,          constraints: Constraints::OnlyAjaxRequest.new
  end

  #################
  # Groups
  #################
  resources :groups, only: %i[create new]

  #################
  # Integrations
  #################
  resources :integrations, only: %i[index] do
    patch 'user_settings', to: 'integrations#update_user_settings', as: :update_user_settings, on: :collection
  end

  get    'integrations/maestro',                           to: 'integrations#maestro_edit',                  as: :integrations_maestro_edit
  get    'integrations/maestro/test',                      to: 'integrations#maestro_test',                  as: :integrations_maestro_test
  get    'integrations/maestro/contact/:contact_id',       to: 'integrations#maestro_contact_edit',          as: :integrations_maestro_contact_edit
  patch  'integrations/maestro/contact/:contact_id',       to: 'integrations#maestro_contact_update',        as: :integrations_maestro_contact
  post   'integrations/maestro/endpoint',                  to: 'integrations#maestro_endpoint',              as: :integrations_maestro_endpoint
  put    'integrations/maestro/hotelid',                   to: 'integrations#maestro_hotelid_update',        as: :integrations_maestro_hotelid_update
  put    'integrations/maestro/new_contact',               to: 'integrations#maestro_new_contact_update',    as: :integrations_maestro_new_contact_update
  put    'integrations/maestro/checkin_contact',           to: 'integrations#maestro_checkin_contact_update', as: :integrations_maestro_checkin_contact_update
  put    'integrations/maestro/checkout_contact',          to: 'integrations#maestro_checkout_contact_update', as: :integrations_maestro_checkout_contact_update
  put    'integrations/maestro/roommove_contact',          to: 'integrations#maestro_roommove_contact_update', as: :integrations_maestro_roommove_contact_update
  put    'integrations/maestro/custom_field_assignments',  to: 'integrations#maestro_custom_field_assignments_update', as: :integrations_maestro_custom_field_assignments_update

  namespace :integrations do
    # ActiveProspect
    namespace :activeprospect do
      resource :integration, only: %i[edit show update]
      get 'integration/instructions', to: 'integrations#instructions', as: :integration_instructions
    end

    # Angi
    resource :angi, only: %i[show], controller: 'angi/integrations'
    resources :angi, only: %i[], controller: 'angi/integrations' do
      member do
        post :endpoint
        get  :endpoint
      end
    end

    namespace :angi do
      resource :v1, only: %i[show], controller: 'v1/integrations'
      namespace :v1 do
        resources :events, only: %i[destroy edit index new show update]
        resource :instructions, only: %i[show]
      end
    end

    # Calendly
    namespace :calendly do
      resource :integration, only: %i[edit show update]
      get  'integration/instructions',                     to: 'integrations#instructions',                  as: :integration_instructions
      get  'integration/appointment/:contact_id',          to: 'integrations#appointment',                   as: :integration_appointment
    end

    # CallRail
    namespace :callrail do
      namespace :v3 do
        get  '',                                           to: 'integrations#show'
        post ':webhook_api_key/endpoint(/:type)',          to: 'integrations#endpoint', as: :endpoint

        resource  :connections, only: %i[destroy edit update],                                                                             constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resources :events, except: %i[create],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # CardX
    namespace :cardx do
      get  '',                                           to: 'integrations#show'
      post ':webhook_api_key/endpoint',                  to: 'integrations#endpoint', as: :endpoint

      resource  :connections, only: %i[destroy edit update],                                                                             constraints: Constraints::OnlyAjaxRequest.new
      resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
      resource  :service_titan, only: %i[edit update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
      resources :events, except: %i[create],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
    end

    # ClickFunnels
    namespace :clickfunnels do
      post 'test',                                         to: 'integrations#test',                          as: :test
      post 'purchase_created',                             to: 'integrations#endpoint_purchase_created',     as: :endpoint_purchase_created
      post 'stripe_customer_created',                      to: 'integrations#endpoint_stripe_customer_created', as: :endpoint_stripe_customer_created
    end

    # Contractor Commerce
    namespace :contractorcommerce do
      resource :integration, only: %i[show]

      namespace :v1 do
        post 'webhook/:uuid', to: 'integrations#webhook', as: :webhook
        get  '', to: 'integrations#show'

        resource  :connections, only: %i[destroy edit]
        resources :events, only: %i[create destroy edit index new update]
      end
    end

    # Dope Marketing
    namespace :dope do
      namespace :v1 do
        post 'endpoint', to: 'integrations#endpoint', as: :endpoint

        resource  :connection, only: %i[show update], constraints: Constraints::OnlyAjaxRequest.new
        resource  :integration, only: %i[show]
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resources :automations, only: %i[index update],                                                                                    constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # Dropfunnels
    namespace :dropfunnels do
      resource :integration, only: %i[show]
      get  'integration/instructions',                     to: 'integrations#instructions',                  as: :integration_instructions
      post 'endpoint/:api_key',                            to: 'integrations#endpoint',                      as: :integration_endpoint

      resource  :api_key, only: %i[show]
      resource  :lead_create, only: %i[show update]
      resource  :two_step_lead_create, only: %i[show update]
      resource  :member_create, only: %i[show update]
      resource  :product_purchased_main, only: %i[show update]
      resource  :product_purchased_order_bump, only: %i[show update]
      resource  :product_purchased_order_upsell, only: %i[show update]
      resource  :submit_quiz, only: %i[show update]
    end

    # Email
    namespace :email do
      namespace :v1 do
        get '', to: 'integrations#show'

        resource  :connections, only: %i[destroy edit update],  constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                constraints: Constraints::OnlyAjaxRequest.new
        resource  :domain_verifications, only: %i[show create], constraints: Constraints::OnlyAjaxRequest.new
        resource  :stats, only: %i[show],                       constraints: Constraints::OnlyAjaxRequest.new
        post '/inbound', to: 'integrations#inbound', as: :inbound
      end
    end

    # Facebook
    namespace :facebook do
      resource  :connections, only: %i[destroy edit update]
      resource  :instructions, only: %i[show]
      resource  :integration, only: %i[show]
      resources :pages, only: %i[index update] do
        member do
          get :page
          get :user
        end
      end

      namespace :leads do
        resources :forms, only: %i[edit index update]
      end

      namespace :messenger do
        resources :pages, only: %i[index]
      end
    end

    # FieldPulse
    resource :fieldpulse, only: %i[show], controller: 'fieldpulse/integrations'

    namespace :fieldpulse do
      get  'endpoint', controller: 'integrations', to: 'integrations#endpoint'
      post 'endpoint', controller: 'integrations', to: 'integrations#endpoint'

      namespace :v1 do
        resource :connections, only: %i[edit update]
        resources :events, only: %i[destroy edit index new show update]
        resource  :import_contacts, only: %i[show update]
        resource :instructions, only: %i[show]
        get '', to: 'integrations#show'
        get 'events/refresh_workflows/:id', to: 'events#refresh_workflows', as: :event_refresh_workflows
      end
    end

    # FieldRoutes
    resource :fieldroutes, only: %i[show], controller: 'fieldroutes/integrations'

    namespace :fieldroutes do
      get  'endpoint', controller: 'integrations', to: 'integrations#endpoint'
      post 'endpoint', controller: 'integrations', to: 'integrations#endpoint'

      namespace :v1 do
        resource :connections, only: %i[edit update]
        resources :events, only: %i[destroy edit index new show update]
        resource  :import_contacts, only: %i[show update]
        resource :instructions, only: %i[show]
        get '', to: 'integrations#show'
        get 'events/refresh_employees/:id', to: 'events#refresh_employees', as: :event_refresh_employees
      end
    end

    # Five9
    namespace :five9 do
      resource  :campaigns, only: %i[edit update]
      resource  :contact_lists, only: %i[edit update]
      resources :dispositions, only: %i[edit index update]
      resource  :instructions, only: %i[show]
      resource  :integration, only: %i[show]
      resource  :lead_source, only: %i[edit update]
      resources :lists, only: %i[create destroy edit index new update]
      post 'lists/create_list/:id',                        to: 'lists#create_list', as: :create_list

      namespace :api do
        namespace :v1 do
          post 'endpoints/central',                        to: 'integrations#mcendpoint',                    as: :mcendpoint
          post 'endpoints/disposition',                    to: 'integrations#dispendpoint',                  as: :dispendpoint
          post 'endpoints/msg',                            to: 'integrations#msendpoint',                    as: :msendpoint
        end
      end

      namespace :v12 do
        resource :connections, only: %i[edit update]
      end
    end

    post 'callcenter/api/v1/endpoints/central',            to: 'five9/api/v1/integrations#mcendpoint'
    post 'callcenter/api/v1/endpoints/disposition',        to: 'five9/api/v1/integrations#dispendpoint'
    post 'callcenter/api/v1/endpoints/msg',                to: 'five9/api/v1/integrations#msendpoint'

    # Google
    namespace :google do
      resource  :accounts, only: %i[show update], constraints: Constraints::OnlyAjaxRequest.new
      resource  :connections, only: %i[destroy edit update]
      resource  :calendars, only: %i[edit update],                                                                                         constraints: Constraints::OnlyAjaxRequest.new
      resource  :instructions, only: %i[show],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
      resource  :integrations, only: %i[create],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
      resource  :integrations, only: %i[show]
      resource  :locations, only: %i[show update],                                                                                         constraints: Constraints::OnlyAjaxRequest.new
      resource  :messages, only: %i[show],                                                                                                 constraints: Constraints::OnlyAjaxRequest.new

      namespace :messages do
        post 'endpoint'
      end

      resource  :reviews, only: %i[show], constraints: Constraints::OnlyAjaxRequest.new

      namespace :reviews do
        resource  :actions, only: %i[edit update], constraints: Constraints::OnlyAjaxRequest.new
        post      'actions/review_campaigns', to: 'actions#review_campaigns', as: :actions_review_campaigns, constraints: Constraints::OnlyAjaxRequest.new
        resource  :reviews_links, only: %i[show update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
        resources :reviews, only: %i[destroy edit index update],                                                                           constraints: Constraints::OnlyAjaxRequest.new
        get       'unread_reviews',                        to: 'reviews#header_unread_reviews',              as: :unread_reviews,          constraints: Constraints::OnlyAjaxRequest.new
        post      'clear',                                 to: 'reviews#clear',                              as: :clear,                   constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # Housecall Pro
    namespace :housecall do
      get  '',                                             to: 'integrations#show'
      post 'endpoint/webhook',                             to: 'integrations#endpoint',                      as: :endpoint
      get  'endpoint/authcode',                            to: 'integrations#auth_code',                     as: :auth_code

      resource  :api_key, only: %i[update]
      resource  :api_key, only: %i[destroy edit],                                                                                          constraints: Constraints::OnlyAjaxRequest.new
      resources :contacts, only: %i[edit],                                                                                                 constraints: Constraints::OnlyAjaxRequest.new
      resource  :employees, only: %i[show update],                                                                                         constraints: Constraints::OnlyAjaxRequest.new
      resource  :import_estimates, only: %i[show update],                                                                                  constraints: Constraints::OnlyAjaxRequest.new
      get 'import_estimates/refresh_technicians', to: 'import_estimates#refresh_technicians', as: :import_estimates_refresh_technicians
      resource  :import_jobs, only: %i[show update],                                                                                       constraints: Constraints::OnlyAjaxRequest.new
      resource  :instructions, only: %i[show],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
      resource  :price_book, only: %i[show update],                                                                                        constraints: Constraints::OnlyAjaxRequest.new
      resource  :push_leads, only: %i[edit update],                                                                                        constraints: Constraints::OnlyAjaxRequest.new
      resource  :update_contacts, only: %i[show update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
      resources :webhooks, only: %i[create destroy edit index new update],                                                                 constraints: Constraints::OnlyAjaxRequest.new
      get 'webhooks/refresh_technicians', to: 'webhooks#refresh_technicians', as: :webhooks_refresh_technicians
      patch 'webhooks/:id/activate/:event', to: 'webhooks#activate', as: :webhook_activate, constraints: Constraints::OnlyAjaxRequest.new
    end

    # Interest Rates
    namespace :interest_rates do
      resource :integration, only: %i[edit update]
      get 'integration/instructions', to: 'integrations#instructions', as: :integration_instructions
    end

    # Jobber
    resource :jobber, only: %i[show], controller: 'jobber/integrations'
    post 'jobber/endpoint', controller: 'jobber/integrations', to: 'jobber/integrations#endpoint', as: :jobber_endpoint
    get  'jobber/authcode', controller: 'jobber/integrations', to: 'jobber/integrations#auth_code', as: :jobber_auth_code

    namespace :jobber do
      namespace :v20220915 do
        get  '',                                           to: 'integrations#show'
        post 'endpoint',                                   to: 'integrations#endpoint',                      as: :endpoint
        get  'endpoint/authcode',                          to: 'connections#auth_code',                      as: :auth_code

        resource  :connections, only: %i[destroy edit],                                                                                    constraints: Constraints::OnlyAjaxRequest.new
        resource  :employees, only: %i[show update],                                                                                       constraints: Constraints::OnlyAjaxRequest.new
        resource  :import_contacts, only: %i[show update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resource  :push_contacts, only: %i[edit update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
        resources :webhooks, only: %i[create destroy edit index new update],                                                               constraints: Constraints::OnlyAjaxRequest.new
      end

      namespace :v20231115 do
        get '', to: 'integrations#show'

        resource  :connections, only: %i[destroy edit],                                                                                    constraints: Constraints::OnlyAjaxRequest.new
        resource  :employees, only: %i[show update],                                                                                       constraints: Constraints::OnlyAjaxRequest.new
        resource  :import_contacts, only: %i[show update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resource  :push_contacts, only: %i[edit update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
        resources :webhooks, only: %i[create destroy edit index new update],                                                               constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # JobNimbus
    namespace :jobnimbus do
      get  '',                                             to: 'integrations#show'
      post 'endpoint/:webhook_api_key',                    to: 'integrations#webhook', as: :endpoint

      resource  :connections, only: %i[show update]
      resource  :instructions, only: %i[show]
      resource  :push_contacts, only: %i[edit update]
      resource  :update_contacts, only: %i[show update]
      resources :webhooks, only: %i[create destroy edit index new update]
    end

    # Jotform
    resource :jotform, only: %i[show], controller: 'jotform/integrations'
    get  'jotform/integration/endpoint', controller: 'jotform/integrations', to: 'jotform/integrations#endpoint'
    post 'jotform/integration/endpoint', controller: 'jotform/integrations', to: 'jotform/integrations#endpoint'

    namespace :jotform do
      namespace :v1 do
        resource :connections, only: %i[create show]
        resource :forms, only: %i[show update]
        resource :instructions, only: %i[show]
        get '', to: 'integrations#show'
        resource :subscriptions, only: %i[update]
      end
    end

    # Outreach
    namespace :outreach do
      resource  :connections, only: %i[edit destroy]
      resource  :instructions, only: %i[show]
      resource  :integration, only: %i[show]
      resource  :users, only: %i[show update]
      resources :webhooks, only: %i[create destroy edit index new update]
      post 'integration/endpoint',                         to: 'integrations#endpoint'
      post 'integration/endpoint/:client_id',              to: 'integrations#endpoint'
    end

    # PC Richard
    namespace :pcrichard do
      namespace :v1 do
        get  '',                                           to: 'integrations#show'
        post 'orders/new/:api_key',                        to: 'orders#new',                                 as: :new_orders
        post 'leads/new/:api_key',                         to: 'leads#new',                                  as: :new_leads

        resource  :connections, only: %i[edit update],                                                                                     constraints: Constraints::OnlyAjaxRequest.new
        resource  :custom_fields, only: %i[edit update],                                                                                   constraints: Constraints::OnlyAjaxRequest.new
        resource  :models, only: %i[show update],                                                                                          constraints: Constraints::OnlyAjaxRequest.new
        resource  :model_submissions, only: %i[edit update], path: 'models/:contact_id',                                                   constraints: Constraints::OnlyAjaxRequest.new
        resource  :orders, only: %i[edit update],                                                                                          constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resource  :leads, only: %i[edit update],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # PhoneSites
    namespace :phone_sites do
      resource :integration, only: %i[create destroy edit show]
      get  'integration/endpoint',                         to: 'integrations#endpoint'
      post 'integration/endpoint',                         to: 'integrations#endpoint'
      get  'integration/forms',                            to: 'integrations#edit_forms',                    as: :integration_forms_edit
      post 'integration/forms',                            to: 'integrations#update_forms',                  as: :integration_forms_update
      get  'integration/instructions',                     to: 'integrations#instructions',                  as: :integration_instructions
    end

    # ResponsiBid
    namespace :responsibid do
      get  '',                                             to: 'integrations#show'
      post 'endpoint/:api_key',                            to: 'integrations#webhook', as: :endpoint

      resource  :connections, only: %i[show]
      resource  :instructions, only: %i[show]
      resources :webhooks, only: %i[create destroy edit index new update]
    end

    # SalesRabbit
    namespace :salesrabbit do
      resource :integration, only: %i[edit]
      resource :api_key, only: %i[show update]
      resource :contact, only: %i[show update]
      resource :status, only: %i[show update]
      resource :user, only: %i[show update]
      resource :leads, only: %i[show update]
      get 'integration/instructions', to: 'integrations#instructions', as: :integration_instructions
    end

    namespace :searchlight do
      namespace :v1 do
        get '', to: 'integrations#show'

        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resource  :connection, only: %i[edit update],                                                                                      constraints: Constraints::OnlyAjaxRequest.new
        resource  :dashboard, only: %i[show]
        resource  :revenue_gen, only: %i[edit update], constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # Sendgrid
    namespace :sendgrid do
      post 'endpoint',                                     to: 'v1/integrations#endpoint'
      post 'bounced',                                      to: 'v1/integrations#bounced'

      namespace :v1 do
        get '', to: 'integrations#show'

        resource  :api_key, only: %i[destroy edit update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :email_addresses, only: %i[edit update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # SendJim
    namespace :sendjim do
      namespace :v3 do
        post 'auth',                                         to: 'connections#authorize'
        get  'callback',                                     to: 'connections#callback'
        post 'endpoint',                                     to: 'integrations#endpoint'

        resource  :connection, only: %i[edit destroy],                                                                                     constraints: Constraints::OnlyAjaxRequest.new
        resource  :import_contacts, only: %i[show update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :instruction, only: %i[show],                                                                                            constraints: Constraints::OnlyAjaxRequest.new
        resource  :integration, only: %i[show]
        resources :push_contacts, only: %i[destroy edit new index update], constraints: Constraints::OnlyAjaxRequest.new
      end
    end

    # ServiceMonster
    namespace :servicemonster do
      get  '',                                             to: 'integrations#show'
      get  'endpoint/authcode',                            to: 'integrations#auth_code'
      get  'endpoint/authcode/:sub_integration',           to: 'integrations#auth_code'
      post 'endpoint/webhook/:webhook_id',                 to: 'integrations#webhook', as: :endpoint

      resource  :employees, only: %i[show update]
      resource  :import_jobs, only: %i[show update]
      resource  :instructions, only: %i[show]
      resource  :push_leads, only: %i[edit update]
      resource  :update_contacts, only: %i[show update]
      resources :webhooks, only: %i[create destroy edit index new update]
    end

    get 'service_monster/endpoint/authcode', to: 'servicemonster/integrations#auth_code'

    # ServiceTitan
    namespace :servicetitan do
      get  '',                                             to: 'integrations#show'
      get  'contacts/balances',                            to: 'contacts#index_balances',                    as: :contacts_balances
      post 'contacts/import_jobs/:contact_id',             to: 'contacts#import_jobs',                       as: :contacts_import_jobs
      get  'contacts/search',                              to: 'contacts#search',                            as: :contacts_search, constraints: Constraints::OnlyAjaxRequest.new
      post 'endpoint/:webhook/:api_key',                   to: 'integrations#endpoint' # legacy endpoint (do not delete)
      post 'endpoint',                                     to: 'integrations#endpoint',                      as: :endpoint

      resource  :balance_update, only: %i[show update]
      resource  :connection, only: %i[show update],                                                                                        constraints: Constraints::OnlyAjaxRequest.new
      resources :contact_bookings, only: %i[edit update], param: :contact_id,                                                              constraints: Constraints::OnlyAjaxRequest.new
      resource  :custom_fields, only: %i[edit update],                                                                                     constraints: Constraints::OnlyAjaxRequest.new
      get 'custom_fields', to: 'custom_fields#index',                                                                                      constraints: Constraints::OnlyAjaxRequest.new
      resource :employees, only: %i[show update], constraints: Constraints::OnlyAjaxRequest.new
      get 'employees/refresh', to: 'employees#refresh', as: :employees_refresh
      resource :events, only: %i[show]
      get 'events/refresh_business_units', to: 'events#refresh_business_units', as: :events_refresh_business_units
      get 'events/refresh_call_reasons', to: 'events#refresh_call_reasons', as: :events_refresh_call_reasons
      get 'events/refresh_campaigns', to: 'events#refresh_campaigns', as: :events_refresh_campaigns
      get 'events/refresh_job_cancel_reasons', to: 'events#refresh_job_cancel_reasons', as: :events_refresh_job_cancel_reasons
      get 'events/refresh_job_types', to: 'events#refresh_job_types', as: :events_refresh_job_types
      get 'events/refresh_membership_types', to: 'events#refresh_membership_types', as: :events_refresh_membership_types
      get 'events/refresh_tag_ids', to: 'events#refresh_tag_ids', as: :events_refresh_tag_ids
      get 'events/refresh_technicians', to: 'events#refresh_technicians', as: :events_refresh_technicians

      namespace :events do
        resources :events, only: %i[destroy edit index new update]
        resource :settings, only: %i[edit update]
        get 'settings/line_items', to: 'settings#line_items', as: :settings_line_items
      end

      resource  :import, only: %i[show update]
      resource  :import_estimates, only: %i[show update],                                                                                  constraints: Constraints::OnlyAjaxRequest.new
      resource  :import_jobs, only: %i[show update],                                                                                       constraints: Constraints::OnlyAjaxRequest.new
      resource  :instructions, only: %i[show],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
      resource  :notes, only: %i[show update],                                                                                             constraints: Constraints::OnlyAjaxRequest.new
      resources :push_contacts, only: %i[destroy edit new index update],                                                                   constraints: Constraints::OnlyAjaxRequest.new
      resources :reports, only: %i[destroy edit new index update]
      get  'reports/refresh_report_categories',            to: 'reports#refresh_report_categories',          as: :reports_refresh_report_categories
      get  'reports/refresh_reports',                      to: 'reports#refresh_reports',                    as: :reports_refresh_reports
      get  'reports/update_report_reports/:id',            to: 'reports#update_report_reports',              as: :update_report_reports
      get  'reports/update_report_criteria/:id',           to: 'reports#update_report_criteria',             as: :update_report_criteria
    end

    # Slack
    namespace :slack do
      resource  :connections, only: %i[destroy edit]
      resource  :instructions, only: %i[show]
      resource  :integration, only: %i[show]
      resource  :notifications, only: %i[edit update]
    end

    # Stripo
    namespace :stripo do
      get 'html_css/:id', to: 'integrations#html_css', as: :html_css, constraints: Constraints::OnlyAjaxRequest.new

      resources :test, only: %i[create new show update]
    end

    # Successware
    resource :successware, only: %i[show], controller: 'successware/integrations'
    post 'successware/confirm', controller: 'successware/integrations', to: 'successware/integrations#confirm', as: :successware_confirmation
    post 'successware/endpoint', controller: 'successware/integrations', to: 'successware/integrations#endpoint', as: :successware_endpoint
    post 'successware/register', controller: 'successware/integrations', to: 'successware/integrations#register', as: :successware_register

    namespace :successware do
      namespace :v202311 do
        get '', to: 'integrations#show'

        resource  :connections, only: %i[destroy edit],                                                                                    constraints: Constraints::OnlyAjaxRequest.new
        resource  :employees, only: %i[show update],                                                                                       constraints: Constraints::OnlyAjaxRequest.new
        resource  :import_contacts, only: %i[show update],                                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resource  :instructions, only: %i[show],                                                                                           constraints: Constraints::OnlyAjaxRequest.new
        resources :push_contacts, only: %i[destroy edit index new update],                                                                 constraints: Constraints::OnlyAjaxRequest.new
        resources :webhooks, only: %i[create destroy edit index new update],                                                               constraints: Constraints::OnlyAjaxRequest.new
        get  'webhooks/refresh_job_types/:id', to: 'webhooks#refresh_job_types', as: :webhooks_refresh_job_types
      end
    end

    # SunbaseData
    namespace :sunbasedata do
      put 'integration/sendappt/:contact_id', to: 'integrations#send_appt', as: :integration_send_appt

      resource :integration, only: %i[create edit show update]
    end

    # Thumbtack
    namespace :thumbtack do
      resource :integration, only: %i[show]
      get 'authcode', to: 'integrations#auth_code', as: :auth_code

      namespace :v2 do
        post 'endpoint/lead',        to: 'integrations#endpoint_lead',        as: :endpoint_lead
        put  'endpoint/lead',        to: 'integrations#endpoint_lead_update', as: :endpoint_lead_update
        post 'endpoint/message',     to: 'integrations#endpoint_message',     as: :endpoint_message
        post 'endpoint/review',      to: 'integrations#endpoint_review',      as: :endpoint_review
        get  '',                     to: 'integrations#show'

        resource  :connections, only: %i[destroy edit]
        resources :events, only: %i[create destroy edit index new update]
      end
    end

    # TikTok
    namespace :tik_tok do
      resource :integrations, only: %i[create show]
      get '/endpoint', to: 'integrations#endpoint', as: :endpoint
    end

    # Webhooks
    namespace :webhook do
      resource  :instructions, only: %i[show], constraints: Constraints::OnlyAjaxRequest.new
      resource  :integration, only: %i[show]
      resources :webhooks, only: %i[create destroy edit index new update],                                                                 constraints: Constraints::OnlyAjaxRequest.new
      resources :apis, only: %i[create destroy edit index new update],                                                                     constraints: Constraints::OnlyAjaxRequest.new
      get    'apis/option/:id/:parent_key/:key/:internal_key', to: 'apis#edit_option',                       as: :edit_option,             constraints: Constraints::OnlyAjaxRequest.new
      get    'apis/test/:id',                              to: 'apis#testpost',                              as: :test_webhook
      post   'appsignal',                                  to: 'integrations#appsignal'
      post   'clients/:client_id/:token',                  to: 'integrations#api',                           as: :client_api
      post   'users/:client_id/:token',                    to: 'integrations#api',                           as: :user_api

      namespace :v1 do
        # General API requests
        get  ':token/campaigns',                           to: 'apis#campaigns',                             as: :api_campaigns
        get  ':token/custom_fields',                       to: 'apis#custom_fields',                         as: :api_custom_fields
        get  ':token/groups',                              to: 'apis#groups',                                as: :api_groups
        get  ':token/stages',                              to: 'apis#stages',                                as: :api_stages
        get  ':token/tags',                                to: 'apis#tags',                                  as: :api_tags
      end
    end

    # Xencall
    namespace :xencall do
      get    '',                                           to: 'integrations#edit',                          as: :edit
      put    '/api_key',                                   to: 'integrations#update_api_key',                as: :api_key_update
      get    '/custom_field',                              to: 'integrations#edit_custom_field',             as: :custom_field_edit
      put    '/custom_field',                              to: 'integrations#update_custom_field',           as: :custom_field_update
      put    '/channel_assign',                            to: 'integrations#update_channel_assign',         as: :channel_assign_update
      get    '/contact/:contact_id',                       to: 'integrations#edit_contact',                  as: :contact_edit
      patch  '/contact/:contact_id',                       to: 'integrations#update_contact',                as: :contact_update
      post   '/endpoint',                                  to: 'integrations#endpoint',                      as: :endpoint
    end

    # Zapier
    namespace :zapier do
      resource :integrations, only: %i[show]
    end
  end

  #################
  # Messages
  #################
  namespace :messages do
    resources :messages, only: %i[] do
      resource :email, only: %i[show], constraints: Constraints::OnlyAjaxRequest.new
      get '/html_body', to: 'emails#html_body', as: 'email_html_body'
    end

    resources :contacts, only: %i[] do
      resources :messages, only: %i[create]
    end

    post   '',                                                to: 'messages#create',                                                       constraints: Constraints::OnlyAjaxRequest.new
    post   'messages/msg_clear',                              to: 'messages#clear_messages',                 as: :messages_clear,          constraints: Constraints::OnlyAjaxRequest.new
    get    'messages/unread_messages_list',                   to: 'messages#header_unread_messages_list',    as: :header_unread_messages_list, constraints: Constraints::OnlyAjaxRequest.new
  end

  post   'message/msgin',                                     to: 'messages/messages#msgin'
  post   'message/msg_callback',                              to: 'messages/messages#msg_callback'
  post   'twmessage/msgin',                                   to: 'messages/messages#msgin'
  post   'twmessage/msg_callback',                            to: 'messages/messages#msg_callback'

  #################
  # My Contacts
  #################
  resource  :my_contacts, only: %i[create], constraints: Constraints::OnlyAjaxRequest.new
  resources :my_contacts, only: %i[index]
  get    'mycontacts',                                     to: redirect('/my_contacts')
  get    'my_contacts/broadcast_action',                   to: 'my_contacts#broadcast_action',               as: :my_contacts_broadcast_action, constraints: Constraints::OnlyAjaxRequest.new
  get    'my_contacts/contacts',                           to: 'my_contacts#contacts',                       as: :my_contacts_contacts
  post   'my_contacts/search',                             to: 'my_contacts#search',                         as: :my_contacts_search, constraints: Constraints::OnlyAjaxRequest.new
  get    'my_contacts/groupactions',                       to: 'my_contacts#index_group_actions'
  get    'my_contacts/groupactions/:action_id',            to: 'my_contacts#index_group_actions_detail', as: :my_contacts_groupactions_detail
  post   'my_contacts/groupactions',                       to: 'my_contacts#index_group_actions'
  put    'my_contacts/groupactions',                       to: 'my_contacts#index_group_actions'
  delete 'my_contacts/groupactions',                       to: 'my_contacts#index_group_actions'

  #################
  # Notes
  #################
  resources :contacts, only: %i[] do
    resources :notes, only: %i[create destroy edit index update], constraints: Constraints::OnlyAjaxRequest.new
  end

  #################
  # Pages & Packages
  #################
  resources :packages, only: %i[create destroy edit index new update] do
    resources :campaigns, only: %i[create destroy index new], controller: 'package_campaigns'
  end

  get    'packagemanager',                                 to: 'packages#show',                              as: :packagemanager
  patch  'packages/:id/image',                             to: 'packages#image',                             as: :image_package

  resources :package_pages, only: %i[create destroy edit index new update]

  get    'packagepages',                                   to: 'package_pages#show',                         as: :packagepages
  get    'package_pages/select',                           to: 'package_pages#select',                       as: :package_pages_select
  get    '/packages/onetime/(:package_id)',                to: 'packages#onetime',                           as: :package_onetime

  #################
  # Quick Responses
  #################
  resources :quick_responses, only: %i[create destroy edit index new update], constraints: Constraints::OnlyAjaxRequest.new

  #################
  # Stages
  #################
  resources :stages, only: %i[index show update]
  resources :stage_parents, only: %i[] do
    patch 'search',                                        to: 'stages#search',                              as: :search
    patch 'user/:user_id',                                 to: 'stages#user',                                as: :user
  end

  #################
  # Surveys
  #################
  namespace :surveys do
    resources :surveys, only: %i[index]
    resources :surveys, only: %i[destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
    resources :surveys, only: %i[] do
      resources :surveys_screens, only: %i[destroy edit index new update], controller: :screens, constraints: Constraints::OnlyAjaxRequest.new
    end

    post  'import',                                          to: 'surveys#import',                           as: :import,                  constraints: Constraints::OnlyAjaxRequest.new
    patch 'copy/:id',                                        to: 'surveys#copy',                             as: :copy,                    constraints: Constraints::OnlyAjaxRequest.new
    patch ':id/update_background_image',                     to: 'surveys#update_background_image',          as: :background_image,        constraints: Constraints::OnlyAjaxRequest.new
    patch ':id/update_logo_image',                           to: 'surveys#update_logo_image',                as: :logo_image,              constraints: Constraints::OnlyAjaxRequest.new
    patch ':survey_id/screens/:id/update_image/:question_id', to: 'screens#update_image',                    as: :screen_image,            constraints: Constraints::OnlyAjaxRequest.new
    get   ':page_name',                                      to: 'surveys#show',                                                           constraints: Constraints::Surveys.new
    post  ':page_name',                                      to: 'surveys#update_contact',                                                 constraints: Constraints::Surveys.new
  end

  get     'surveys/:survey_key/:screen_key',                 to: 'surveys/surveys#show',                     as: :survey
  post    'surveys/:survey_key/:screen_key',                 to: 'surveys/surveys#update_contact',           as: :survey_contact

  #################
  # System Settings
  #################
  get    'system_settings',                                to: 'system_settings/system_settings#index',      as: :system_settings
  get    'versionhistory',                                 to: 'system_settings/versions#history',           as: :system_settings_version_history

  namespace :system_settings do
    resources :phone_numbers, only: %i[create new], constraints: Constraints::OnlyAjaxRequest.new
    resource  :toast, only: %i[create edit]
    resources :versions, only: %i[create edit index new update]

    patch 'integrations/arrangement', to: 'integrations#arrangement', as: :integration_arrangement, constraints: Constraints::OnlyAjaxRequest.new
    resources :integrations, only: %i[create destroy index new update], constraints: Constraints::OnlyAjaxRequest.new
    resources :integrations, only: %i[edit]
    patch 'integrations/:id/logo_upload', to: 'integrations#logo_upload', as: :integration_logo_upload, constraints: Constraints::OnlyAjaxRequest.new
  end

  #################
  # Tags
  #################
  resources :tags, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new

  #################
  # Tasks
  #################
  resources :tasks, only: %i[create destroy edit index new update]
  get    'tasks/contact',                                  to: 'tasks#contact',                              as: :contact_task,            defaults: { format: 'json' }
  post   'tasks/:id/complete',                             to: 'tasks#complete',                             as: :complete_task,           constraints: Constraints::OnlyAjaxRequest.new

  #################
  # TrackableLinks
  #################
  get    'trackablelinks',                                 to: 'trackable_links#show'
  get    'tl/:short_code',                                 to: 'trackable_links#redirect', as: :trackable_links_redirect

  resources :trackable_links, only: %i[create destroy edit new update]

  #################
  # Trainings
  #################
  resources :trainings, only: %i[create destroy edit index new show update] do
    resources :training_pages, only: %i[create destroy edit index new show update]
  end

  #################
  # Triggeractions
  #################
  resources :triggers, only: %i[] do
    resources :triggeractions, only: %i[create destroy edit new update], constraints: Constraints::OnlyAjaxRequest.new
  end

  get '/triggers/:trigger_id/triggeractions/:id/client_custom_fields', to: 'triggeractions#edit_client_custom_fields', as: :edit_client_custom_fields_trigger_triggeraction, constraints: Constraints::OnlyAjaxRequest.new
  get '/triggers/:trigger_id/triggeractions/:id/801index', to: 'triggeractions#index_801', as: :index_801_trigger_triggeraction, constraints: Constraints::OnlyAjaxRequest.new

  #################
  # Users
  #################
  post 'users/validate', to: 'users#validate', as: :user_validate

  namespace :users do
    resources :admin, only: %i[edit update]
    resources :avatar, only: %i[update]
    resources :notifications, only: %i[edit update]
    resources :overview, only: %i[edit]
    resources :permissions, only: %i[edit update]
    resources :phone, only: %i[edit update]
    resources :tasks, only: %i[index]
  end

  resources :users, only: %i[update] do
    get  'become',                                         to: 'users#become',                               as: :become
    get  'return',                                         to: 'users#return_to_self',                       as: :return_to_self
    get  'editmobile',                                     to: 'users#edit_mobile',                          as: :edit_mobile
    get  'show_active_contacts',                           to: 'users#show_active_contacts'
    get  'show_active_contacts/:page',                     to: 'users#show_active_contacts'
    post 'file_upload',                                    to: 'users#file_upload', as: :file_upload
    get  'logout',                                         to: 'users#logout'
    post 'rcvpushtoken',                                   to: 'users#rcvpushtoken',                         as: :rcvpushtoken
    delete 'destroy_desktop_push',                         to: 'users#destroy_desktop_push',                 as: :push_destroy_desktop
    delete 'destroy_mobile_push',                          to: 'users#destroy_mobile_push',                  as: :push_destroy_mobile
    post 'send_test_push',                                 to: 'users#send_test_push',                       as: :push_test
  end

  #################
  # UserChats
  #################
  get  'user_chats/user_index',                            to: 'user_chats#index_users',                     as: :index_user_chats_users
  get  'user_chats/chat_index/:id',                        to: 'user_chats#index_chats',                     as: :index_user_chats_chats

  resources :user_chats, only: %i[create index show]

  #################
  # UserContactForms
  #################
  resources :user_contact_forms, only: %i[destroy index]
  get    'user_contact_form/import/index',                 to: 'user_contact_forms#index_import',            as: :index_import_user_contact_form, constraints: Constraints::OnlyAjaxRequest.new
  post   'user_contact_form/import',                       to: 'user_contact_forms#import',                  as: :import_user_contact_form

  # get  'quickleads',                                       to: 'user_contact_forms#show'
  # post 'users/contact_form/import',                        to: 'user_contact_forms#import',                  as: :import_user_contact_form
  # get  'users/contact_form/cms_config',                    to: 'user_contact_forms#cms_config',              as: :cms_config_user_contact_form
  # get  'users/contact_form/:page_key',                     to: 'user_contact_forms#show_contact_form',       as: :show_user_contact_form
  # post 'users/contact_form/:page_key',                     to: 'user_contact_forms#save_contact',            as: :save_contact

  namespace :api do
    namespace :v2 do
      resources :user_contact_forms, only: %i[edit update]

      get  'quicklead/link/:page_key',                     to: 'user_contact_forms#show_link',               as: :user_contact_form_link
      get  'quicklead/modalinit/:page_key',                to: 'user_contact_forms#show_modal_init',         as: :user_contact_form_modal_init
      get  'quicklead/modal/:page_key',                    to: 'user_contact_forms#show_modal',              as: :user_contact_form_modal
      get  'quicklead/frameinit/:page_key',                to: 'user_contact_forms#show_frame_init',         as: :user_contact_form_frame_init
      get  'quicklead/frame/:page_key',                    to: 'user_contact_forms#show_frame',              as: :user_contact_form_frame
      get  'quicklead/form/:page_key',                     to: 'user_contact_forms#show_form',               as: :user_contact_form_form
      get  'quicklead/:page_key',                          to: 'user_contact_forms#show_page',               as: :user_contact_form_page
      post 'quicklead/:page_key',                          to: 'user_contact_forms#save_contact',            as: :user_contact_form_save_contact
    end

    namespace :v3 do
      resources :user_contact_forms, only: %i[create edit new update]

      get 'quickleads',                                   to: 'user_contact_forms#show'
      patch 'users/contact_form/:id/background_image',     to: 'user_contact_forms#background_image',        as: :background_image_user_contact_form
      get  'users/contact_form/:id/edit_template',         to: 'user_contact_forms#edit_template',           as: :edit_template_user_contact_form, constraints: Constraints::OnlyAjaxRequest.new
      get  'users/contact_form/:page_key',                 to: 'user_contact_forms#show_contact_form',       as: :show_user_contact_form
      post 'users/contact_form/:page_key',                 to: 'user_contact_forms#save_contact',            as: :save_contact

      get  'quicklead/modalinit/:page_key',                to: 'user_contact_forms#show_modal_init',         as: :user_contact_form_modal_init
      get  'quicklead/modal/:page_key',                    to: 'user_contact_forms#show_modal',              as: :user_contact_form_modal
      get  'quicklead/frameinit/:page_key',                to: 'user_contact_forms#show_frame_init',         as: :user_contact_form_frame_init
      get  'quicklead/frame/:page_key',                    to: 'user_contact_forms#show_frame',              as: :user_contact_form_frame
      get  'quicklead/:page_key',                          to: 'user_contact_forms#show_page',               as: :user_contact_form_page
      post 'quicklead/:page_key',                          to: 'user_contact_forms#save_contact',            as: :user_contact_form_save_contact
    end
  end

  #################
  # UserContactFormMarketplaces
  #################
  post   'user_contact_form_marketplaces/:id/approve',     to: 'user_contact_form_marketplaces#approve',     as: :approve_user_contact_form
  post   'user_contact_form_marketplaces/:id/buy',         to: 'user_contact_form_marketplaces#buy',         as: :buy_user_contact_form
  patch  'user_contact_form_marketplaces/:id/image',       to: 'user_contact_form_marketplaces#image',       as: :image_user_contact_form_marketplaces

  resources :user_contact_form_marketplaces, only: %i[edit index show update]

  #################
  # Video
  #################
  post   'video/callback',                                 to: 'video#callback',                             as: :video_callback
  post   'video/send_invite',                              to: 'video#send_invite',                          as: :video_send_invite
  get    'video/join_video/:contact_id/:user_id',          to: 'video#join_video',                           as: :video_join_video
  get    'video/start_user/:contact_id/:user_id',          to: 'video#start_user',                           as: :video_start_user

  #################
  # VoiceIn
  #################
  post   'twvoice/voicein',                                to: 'voice_in#voice_in',                          as: :twvoice_voicein

  namespace :voices do
    # Bandwidth
    namespace :bandwidth do
      # general
      post 'voicecomplete',                                to: 'voice#voice_complete',                       as: :voice_complete

      # outbound calls
      post 'out/user_answered',                            to: 'outbound#user_answered',                     as: :out_user_answered
      post 'out/bridge_complete/:parent_call_id',          to: 'outbound#bridge_complete',                   as: :out_bridge_complete
      post 'out/bridge_target_complete',                   to: 'outbound#bridge_target_complete',            as: :out_bridge_target_complete
      post 'out/contact_answered/:parent_call_id',         to: 'outbound#contact_answered',                  as: :out_contact_answered
      post 'out/disconnected_call/:parent_call_id',        to: 'outbound#disconnected_call',                 as: :out_disconnected_call

      # inbound calls
      post 'in/bridge_call/:parent_call_id',               to: 'inbound#bridge_call',                        as: :in_bridge_call
      post 'in/bridge_complete/:parent_call_id',           to: 'inbound#bridge_complete',                    as: :in_bridge_complete
      post 'in/bridge_target_complete',                    to: 'inbound#bridge_target_complete',             as: :in_bridge_target_complete
      post 'in/disconnectedcalls/:parent_call_id',         to: 'inbound#disconnected_contact_call',          as: :in_disconnected_contact_call
      post 'in/disconnectedcallu/:parent_call_id',         to: 'inbound#disconnected_user_call',             as: :in_disconnected_user_call
      post 'in/offer_voicemail/:parent_call_id',           to: 'inbound#offer_voicemail',                    as: :in_offer_voicemail
      post 'in/receive_voicemail',                         to: 'inbound#receive_voicemail',                  as: :in_receive_voicemail
      post 'in/user_answered/:parent_call_id',             to: 'inbound#user_answered',                      as: :in_user_answered
      post 'in/user_responded/:parent_call_id/:client_phone', to: 'inbound#user_responded',                  as: :in_user_responded
      post 'in/voicemail_answered/:parent_call_id',        to: 'inbound#voicemail_answered',                 as: :in_voicemail_answered
    end

    # Twilio
    namespace :twiliovoice do
      # outbound calls
      post 'out/user_answered',                            to: 'outbound#user_answered',                     as: :out_user_answered

      # inbound calls
      post 'in/bridge_complete/:parent_call_id',           to: 'inbound#bridge_complete',                    as: :in_bridge_complete
      post 'in/bridge_target_complete',                    to: 'inbound#bridge_target_complete',             as: :in_bridge_target_complete
      post 'in/call_complete',                             to: 'inbound#call_complete',                      as: :in_call_complete
      post 'in/offer_voicemail/:parent_call_id',           to: 'inbound#offer_voicemail',                    as: :in_offer_voicemail
      post 'in/receive_voicemail',                         to: 'inbound#receive_voicemail',                  as: :in_receive_voicemail
      post 'in/user_answered/:parent_call_id',             to: 'inbound#user_answered',                      as: :in_user_answered
      post 'in/user_responded/:parent_call_id/:parent_from_phone', to: 'inbound#user_responded',             as: :in_user_responded
    end
  end

  #################
  # Webhooks (legacy)
  #################
  post   'clients/:client_id/:token',                      to: 'integrations/webhook/integrations#api',      as: :client_subscription_webhook
  post   'users/:client_id/:token',                        to: 'integrations/webhook/integrations#api',      as: :user_subscription_webhook

  get    'vid/:short_code',                                to: 'messages/messages#show_video',               as: :messages_show_video

  get    'layout_design',                                  to: 'application#layout_design'

  get    'humans.txt',                                     to: 'exceptions#humans', defaults: { format: 'html' }

  get '/LjR8XqKTIec4M1Bw/Q6gF8HkrlDYvDp5p', to: 'testing/formats#show', as: :testing_format unless Rails.env.production?
  get '/LjR8XqKTIec4M1Bw/Q6gF8HkrlDYvDp5p/test', to: 'testing/formats#test', as: :test_testing_format unless Rails.env.production?

  # handle all other requests
  match  '/404',                                           to: 'exceptions#not_found',                       via: :all
  match  '/500',                                           to: 'exceptions#internal_server_error',           via: :all
  match  '*path',                                          to: 'exceptions#something_else',                  via: :all
end
