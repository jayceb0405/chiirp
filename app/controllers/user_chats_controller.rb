# frozen_string_literal: true

# app/controllers/user_chats_controller.rb
class UserChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!

  # (POST) save a new UserChat
  # /user_chats
  # user_chats_path
  # user_chats_url
  #   (req) id:                  (Integer)
  #   (req) user_chat[:content]: (String)
  def create
    @user = current_user.client.users.find_by(id: params[:id])

    user_chat = UserChat.new(from_user_id: current_user.id, to_user_id: @user.id, content: user_chat_params[:content])
    user_chat.save

    @user_chats = UserChat.where(from_user_id: @user.id, to_user_id: current_user.id).or(UserChat.where(from_user_id: current_user.id, to_user_id: @user.id)).order(:created_at)

    respond_to do |format|
      format.js { render partial: 'user_chats/js/show', locals: { cards: [3, 5] } }
      format.html { redirect_to user_chats_path }
    end
  end

  # (GET) list UserChats
  # /user_chats
  # user_chats_path
  # user_chats_url
  def index
    @user = current_user.client.users.find_by(id: params[:id].to_i) if params.include?(:id)

    respond_to do |format|
      format.js { render js: "window.location = '#{user_chats_path}'" }
      format.html { render 'user_chats/index' }
    end
  end

  # (GET) list existing UserChats
  # /user_chats/chat_index/:id
  # index_user_chats_chats_path(:id)
  # index_user_chats_chats_url(:id)
  def index_chats
    @user = current_user.client.users.find_by(id: params[:id])
    @user_chats = UserChat.where(from_user_id: @user.id, to_user_id: current_user.id).or(UserChat.where(from_user_id: current_user.id, to_user_id: @user.id)).order(:created_at)

    respond_to do |format|
      format.js { render partial: 'user_chats/js/show', locals: { cards: [3] } }
      format.html { redirect_to user_chats_path }
    end
  end

  # (GET) list Users
  # /user_chats/user_index
  # index_user_chats_users_path
  # index_user_chats_users_url
  def index_users
    @users = current_user.by_last_chat

    respond_to do |format|
      format.js { render partial: 'user_chats/js/show', locals: { cards: [1] } }
      format.html { redirect_to user_chats_path }
    end
  end

  # (GET) show a UserChat
  # /user_chats/:id
  # user_chat_path(:id)
  # user_chat_url(:id)
  #   (req) id: (integer)
  def show
    @user = current_user.client.users.find_by(id: params[:id])

    # update read_at for all UserChats for this User
    # rubocop:disable Rails/SkipsModelValidations
    UserChat.where(from_user_id: @user.id, to_user_id: current_user.id).update_all(read_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
    UserCable.new.broadcast current_user.client, current_user, { turnoff: 'true', id: "user_chats_user_indicator_#{@user.id}" }

    @user_chats = UserChat.where(from_user_id: @user.id, to_user_id: current_user.id).or(UserChat.where(from_user_id: current_user.id, to_user_id: @user.id)).order(:created_at)

    respond_to do |format|
      format.js { render partial: 'user_chats/js/show', locals: { cards: [2, 4] } }
      format.html { redirect_to user_chats_path }
    end
  end

  private

  def authorize_user!
    return if defined?(current_user) && current_user.user?

    raise ExceptionHandlers::UserNotAuthorized.new('Chat', login_path)
  end

  def user_chat_params
    params.require(:user_chat).permit(:content)
  end
end
