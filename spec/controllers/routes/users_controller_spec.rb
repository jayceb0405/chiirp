# /Users/Kevin/Rails Projects/funyl/spec/controllers/users_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/users_controller_spec.rb
require 'rails_helper'
#              api_v1_users GET      /api/v1/users(.:format)                              api/v1/users#index
#                           POST     /api/v1/users(.:format)                              api/v1/users#create
#           new_api_v1_user GET      /api/v1/users/new(.:format)                          api/v1/users#new
#          edit_api_v1_user GET      /api/v1/users/:id/edit(.:format)                     api/v1/users#edit
#               api_v1_user GET      /api/v1/users/:id(.:format)                          api/v1/users#show
#                           PATCH    /api/v1/users/:id(.:format)                          api/v1/users#update
#                           PUT      /api/v1/users/:id(.:format)                          api/v1/users#update
#                           DELETE   /api/v1/users/:id(.:format)                          api/v1/users#destroy
#                     users POST     /users(.:format)                                     users#create
#             user_validate POST     /users/validate(.:format)                            users#validate
#          edit_users_admin GET      /users/admin/:id/edit(.:format)                      users/admin#edit
#               users_admin PATCH    /users/admin/:id(.:format)                           users/admin#update
#                           PUT      /users/admin/:id(.:format)                           users/admin#update
#              users_avatar PATCH    /users/avatar/:id(.:format)                          users/avatar#update
#                           PUT      /users/avatar/:id(.:format)                          users/avatar#update
#   edit_users_notification GET      /users/notifications/:id/edit(.:format)              users/notifications#edit
#        users_notification PATCH    /users/notifications/:id(.:format)                   users/notifications#update
#                           PUT      /users/notifications/:id(.:format)                   users/notifications#update
#       edit_users_overview GET      /users/overview/:id/edit(.:format)                   users/overview#edit
#     edit_users_permission GET      /users/permissions/:id/edit(.:format)                users/permissions#edit
#          users_permission PATCH    /users/permissions/:id(.:format)                     users/permissions#update
#                           PUT      /users/permissions/:id(.:format)                     users/permissions#update
#          edit_users_phone GET      /users/phone/:id/edit(.:format)                      users/phone#edit
#               users_phone PATCH    /users/phone/:id(.:format)                           users/phone#update
#                           PUT      /users/phone/:id(.:format)                           users/phone#update
#       users_profile_index POST     /users/profile(.:format)                             users/profile#create
#         new_users_profile GET      /users/profile/new(.:format)                         users/profile#new
#        edit_users_profile GET      /users/profile/:id/edit(.:format)                    users/profile#edit
#             users_profile PATCH    /users/profile/:id(.:format)                         users/profile#update
#                           PUT      /users/profile/:id(.:format)                         users/profile#update
#               users_tasks GET      /users/tasks(.:format)                               users/tasks#index
#               user_become GET      /users/:user_id/become(.:format)                     users#become
#       user_return_to_self GET      /users/:user_id/return(.:format)                     users#return_to_self
#          user_edit_mobile GET      /users/:user_id/editmobile(.:format)                 users#edit_mobile
# user_show_active_contacts GET      /users/:user_id/show_active_contacts(.:format)       users#show_active_contacts
#                           GET      /users/:user_id/show_active_contacts/:page(.:format) users#show_active_contacts
#          user_file_upload POST     /users/:user_id/file_upload(.:format)                users#file_upload
#               user_logout GET      /users/:user_id/logout(.:format)                     users#logout
#         user_rcvpushtoken POST     /users/:user_id/rcvpushtoken(.:format)               users#rcvpushtoken
# user_push_destroy_desktop DELETE   /users/:user_id/destroy_desktop_push(.:format)       users#destroy_desktop_push
#  user_push_destroy_mobile DELETE   /users/:user_id/destroy_mobile_push(.:format)        users#destroy_mobile_push
#            user_push_test POST     /users/:user_id/send_test_push(.:format)             users#send_test_push
#                      user PATCH    /users/:id(.:format)                                 users#update
#                           PUT      /users/:id(.:format)                                 users#update

describe 'routing to users' do
  it 'routes /api/v1/users to api/v1/users#index' do
    expect(get: 'api/v1/users').to route_to(
      controller: 'api/v1/users',
      action:     'index'
    )
  end

  it 'routes /api/v1/users to api/v1/users#create' do
    expect(post: 'api/v1/users').to route_to(
      controller: 'api/v1/users',
      action:     'create'
    )
  end

  it 'routes /api/v1/users/new to api/v1/users#new' do
    expect(get: 'api/v1/users/new').to route_to(
      controller: 'api/v1/users',
      action:     'new'
    )
  end

  it 'routes /api/v1/users/:id/edit to api/v1/users#edit' do
    expect(get: 'api/v1/users/1/edit').to route_to(
      controller: 'api/v1/users',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /api/v1/users/:id to api/v1/users#show' do
    expect(get: 'api/v1/users/1').to route_to(
      controller: 'api/v1/users',
      action:     'show',
      id:         '1'
    )
  end

  it 'routes /api/v1/users/:id to api/v1/users#update' do
    expect(patch: 'api/v1/users/1').to route_to(
      controller: 'api/v1/users',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /api/v1/users/:id to api/v1/users#update' do
    expect(put: 'api/v1/users/1').to route_to(
      controller: 'api/v1/users',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /api/v1/users/:id to api/v1/users#destroy' do
    expect(delete: 'api/v1/users/1').to route_to(
      controller: 'api/v1/users',
      action:     'destroy',
      id:         '1'
    )
  end

  it 'routes /users to users#create' do
    expect(post: 'users').to route_to(
      controller: 'users',
      action:     'create'
    )
  end

  it 'routes /users/validate to users#validate' do
    expect(post: 'users/validate').to route_to(
      controller: 'users',
      action:     'validate'
    )
  end

  it 'routes /users/admin/:id/edit to users/admin#edit' do
    expect(get: 'users/admin/1/edit').to route_to(
      controller: 'users/admin',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /users/admin/:id to users/admin#update' do
    expect(patch: 'users/admin/1').to route_to(
      controller: 'users/admin',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/admin/:id to users/admin#update' do
    expect(put: 'users/admin/1').to route_to(
      controller: 'users/admin',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/avatar/:id to users/avatar#update' do
    expect(patch: 'users/avatar/1').to route_to(
      controller: 'users/avatar',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/avatar/:id to users/avatar#update' do
    expect(put: 'users/avatar/1').to route_to(
      controller: 'users/avatar',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/notifications/:id/edit to users/notifications#edit' do
    expect(get: 'users/notifications/1/edit').to route_to(
      controller: 'users/notifications',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /users/notifications/:id to users/notifications#update' do
    expect(patch: 'users/notifications/1').to route_to(
      controller: 'users/notifications',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/notifications/:id to users/notifications#update' do
    expect(put: 'users/notifications/1').to route_to(
      controller: 'users/notifications',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/overview/:id/edit to users/overview#edit' do
    expect(get: 'users/overview/1/edit').to route_to(
      controller: 'users/overview',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /users/permissions/:id/edit to users/permissions#edit' do
    expect(get: 'users/permissions/1/edit').to route_to(
      controller: 'users/permissions',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /users/permissions/:id to users/permissions#update' do
    expect(patch: 'users/permissions/1').to route_to(
      controller: 'users/permissions',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/permissions/:id to users/permissions#update' do
    expect(put: 'users/permissions/1').to route_to(
      controller: 'users/permissions',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/phone/:id/edit to users/phone#edit' do
    expect(get: 'users/phone/1/edit').to route_to(
      controller: 'users/phone',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes /users/phone/:id to users/phone#update' do
    expect(patch: 'users/phone/1').to route_to(
      controller: 'users/phone',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/phone/:id to users/phone#update' do
    expect(put: 'users/phone/1').to route_to(
      controller: 'users/phone',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/tasks to users/tasks#index' do
    expect(get: 'users/tasks').to route_to(
      controller: 'users/tasks',
      action:     'index'
    )
  end

  it 'routes /users/:user_id/become to users#become' do
    expect(get: 'users/1/become').to route_to(
      controller: 'users',
      action:     'become',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/return to users#return_to_self' do
    expect(get: 'users/1/return').to route_to(
      controller: 'users',
      action:     'return_to_self',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/editmobile to users#edit_mobile' do
    expect(get: 'users/1/editmobile').to route_to(
      controller: 'users',
      action:     'edit_mobile',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/show_active_contacts to users#show_active_contacts' do
    expect(get: 'users/1/show_active_contacts').to route_to(
      controller: 'users',
      action:     'show_active_contacts',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/show_active_contacts/:page to users#show_active_contacts' do
    expect(get: 'users/1/show_active_contacts/2').to route_to(
      controller: 'users',
      action:     'show_active_contacts',
      user_id:    '1',
      page:       '2'
    )
  end

  it 'routes /users/:user_id/file_upload to users#file_upload' do
    expect(post: 'users/1/file_upload').to route_to(
      controller: 'users',
      action:     'file_upload',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/logout to users#logout' do
    expect(get: 'users/1/logout').to route_to(
      controller: 'users',
      action:     'logout',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/rcvpushtoken to users#rcvpushtoken' do
    expect(post: 'users/1/rcvpushtoken').to route_to(
      controller: 'users',
      action:     'rcvpushtoken',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/destroy_desktop_push to users#destroy_desktop_push' do
    expect(delete: 'users/1/destroy_desktop_push').to route_to(
      controller: 'users',
      action:     'destroy_desktop_push',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/destroy_mobile_push to users#destroy_mobile_push' do
    expect(delete: 'users/1/destroy_mobile_push').to route_to(
      controller: 'users',
      action:     'destroy_mobile_push',
      user_id:    '1'
    )
  end

  it 'routes /users/:user_id/send_test_push to users#send_test_push' do
    expect(post: 'users/1/send_test_push').to route_to(
      controller: 'users',
      action:     'send_test_push',
      user_id:    '1'
    )
  end

  it 'routes /users/:id to users#update' do
    expect(patch: 'users/1').to route_to(
      controller: 'users',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /users/:id to users#update' do
    expect(put: 'users/1').to route_to(
      controller: 'users',
      action:     'update',
      id:         '1'
    )
  end
end
