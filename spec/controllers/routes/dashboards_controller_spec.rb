# /Users/Kevin/Rails Projects/funyl/spec/controllers/dashboards_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/dashboards_controller_spec.rb
require 'rails_helper'
#              dashboards GET    /dashboards(.:format)                                   dashboards#show
# buttons_index_dashboard GET    /dashboards/buttons/:user_id(.:format)                  dashboards#index_buttons
#       buttons_dashboard PATCH  /dashboards/buttons/:id(.:format)                       dashboards#update_buttons
#        period_dashboard PATCH  /dashboards/period/:id(.:format)                        dashboards#update_period
#   cal_actions_dashboard GET    /dashboards/cal_actions(.:format)                       dashboards#cal_actions
#      cal_msgs_dashboard GET    /dashboards/cal_msgs(.:format)                          dashboards#cal_msgs
#     cal_tasks_dashboard PATCH  /dashboards/cal_tasks(.:format)                         dashboards#update_cal_tasks
#                         GET    /dashboards/cal_tasks(.:format)                         dashboards#cal_tasks
#   index_tasks_dashboard GET    /dashboards/tasks(.:format)                             dashboards#index_tasks
#           task_complete PATCH  /dashboards/task_complete(.:format)                     dashboards#update_task_complete
#                    root GET    /                                                       dashboards#show
#                         POST   /dashboards(.:format)                                   dashboards#create
#           new_dashboard GET    /dashboards/new(.:format)                               dashboards#new
#          edit_dashboard GET    /dashboards/:id/edit(.:format)                          dashboards#edit
#               dashboard GET    /dashboards/:id(.:format)                               dashboards#show
#                         PATCH  /dashboards/:id(.:format)                               dashboards#update
#                         PUT    /dashboards/:id(.:format)                               dashboards#update
#                         DELETE /dashboards/:id(.:format)                               dashboards#destroy

describe 'routing to Dashboards Controller' do
  it 'routes /dashboards/:id to dashboards#show' do
    expect(get: '/dashboards/1').to route_to(
      controller: 'dashboards',
      action:     'show',
      id:         '1'
    )
  end

  it 'routes /dashboards/buttons/:user_id to dashboards#index_buttons' do
    expect(get: '/dashboards/button/asdf').to route_to(
      controller: 'dashboards',
      action:     'show_button',
      type:       'asdf'
    )
  end

  it 'routes /dashboards/buttons/:id to dashboards#update_buttons' do
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    expect(patch: '/dashboards/buttons/1').to route_to(
      controller: 'dashboards',
      action:     'update_buttons',
      id:         '1'
    )
  end

  it 'routes /dashboards/period/:id to dashboards#update_period' do
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    expect(patch: '/dashboards/period/1').to route_to(
      controller: 'dashboards',
      action:     'update_period',
      id:         '1'
    )
  end

  it 'routes /dashboards/cal_actions to dashboards#cal_actions' do
    expect(get: '/dashboards/cal_actions').to route_to(
      controller: 'dashboards',
      action:     'cal_actions'
    )
  end

  it 'routes /dashboards/cal_msgs to dashboards#cal_msgs' do
    expect(get: '/dashboards/cal_msgs').to route_to(
      controller: 'dashboards',
      action:     'cal_msgs'
    )
  end

  it 'routes /dashboards/cal_tasks to dashboards#update_cal_tasks' do
    expect(patch: '/dashboards/cal_tasks').to route_to(
      controller: 'dashboards',
      action:     'update_cal_tasks'
    )
  end

  it 'routes /dashboards/cal_tasks to dashboards#cal_tasks' do
    expect(get: '/dashboards/cal_tasks').to route_to(
      controller: 'dashboards',
      action:     'cal_tasks'
    )
  end

  it 'routes /dashboards/tasks to dashboards#index_tasks' do
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    expect(get: '/dashboards/tasks').to route_to(
      controller: 'dashboards',
      action:     'index_tasks'
    )
  end

  it 'routes /dashboards/task_complete to dashboards#update_task_complete' do
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    expect(patch: '/dashboards/task_complete').to route_to(
      controller: 'dashboards',
      action:     'update_task_complete'
    )
  end

  it 'routes /dashboards to dashboards#show' do
    expect(get: '/dashboards').to route_to(
      controller: 'dashboards',
      action:     'show'
    )
  end

  it 'routes /dashboards to dashboards#create' do
    expect(post: '/dashboards').to route_to(
      controller: 'dashboards',
      action:     'create'
    )
  end

  it 'routes /dashboards/new to dashboards#new' do
    expect(get: '/dashboards/new').to route_to(
      controller: 'dashboards',
      action:     'new'
    )
  end

  it 'routes /dashboards/:id/edit to dashboards#edit' do
    expect(get: '/dashboards/1/edit').to route_to(
      controller: 'dashboards',
      action:     'edit',
      id:         '1'
    )
  end

  it 'routes / to dashboards#show' do
    expect(get: '/').to route_to(
      controller: 'dashboards',
      action:     'show'
    )
  end

  it 'routes /dashboards/:id to dashboards#update' do
    expect(patch: '/dashboards/1').to route_to(
      controller: 'dashboards',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /dashboards/:id to dashboards#update' do
    expect(put: '/dashboards/1').to route_to(
      controller: 'dashboards',
      action:     'update',
      id:         '1'
    )
  end

  it 'routes /dashboards/:id to dashboards#destroy' do
    expect(delete: '/dashboards/1').to route_to(
      controller: 'dashboards',
      action:     'destroy',
      id:         '1'
    )
  end
end
