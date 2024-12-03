# frozen_string_literal: true

# app/presenters/base_presenter.rb
class BasePresenter
  attr_reader :client, :client_api_integration, :contact, :user, :user_api_integration

  def initialize(args = {})
    self.contact                = args.key?(:contact) ? args[:contact] : self.contact_derived
    self.user                   = args.key?(:user) ? args[:user] : self.user_derived
    self.user_api_integration   = args.key?(:user_api_integration) ? args[:user_api_integration] : self.user_api_integration_derived
    self.client_api_integration = args.key?(:client_api_integration) ? args[:client_api_integration] : self.client_api_integration_derived
    self.client                 = args.key?(:client) ? args[:client] : self.client_derived
  end

  def client=(client)
    @client = case client
              when Client
                client
              when Integer
                Client.find_by(id: client)
              else
                client_derived
              end
  end

  def client_api_integration=(client_api_integration)
    @client_api_integration = case client_api_integration
                              when ClientApiIntegration
                                client_api_integration
                              when Integer
                                ClientApiIntegration.find_by(id: client_api_integration)
                              else
                                client_api_integration_derived
                              end

    # @client = client_derived
  end

  def contact=(contact)
    @contact = case contact
               when Contact
                 contact
               when Integer
                 Contact.find_by(id: contact)
               else
                 contact_derived
               end

    # @client = client_derived
    # @user   = user_derived
  end

  def user=(user)
    @user = case user
            when User
              user
            when Integer
              User.find_by(id: user)
            else
              user_derived
            end

    # @client = client_derived
  end

  def user_api_integration=(user_api_integration)
    @user_api_integration = case user_api_integration
                            when UserApiIntegration
                              user_api_integration
                            when Integer
                              UserApiIntegration.find_by(id: user_api_integration)
                            else
                              user_api_integration_derived
                            end

    # @client = client_derived
  end

  private

  def client_api_integration_derived
    if @client_api_integration.is_a?(ClientApiIntegration) && @client_api_integration.client_id.to_i.positive?
      @client_api_integration
    elsif @client.is_a?(Client) && !@client.new_record?
      @client.client_api_integrations.new
    elsif @user.is_a?(User) && @user.client_id.to_i.positive?
      @user.client.client_api_integrations.new
    elsif @contact.is_a?(Contact) && @contact.client_id.to_i.positive?
      @contact.client.client_api_integrations.new
    else
      ClientApiIntegration.new
    end
  end

  def client_derived
    if @client.is_a?(Client) && !@client.new_record?
      @client
    elsif @client_api_integration.is_a?(ClientApiIntegration) && @client_api_integration.client_id.to_i.positive?
      @client_api_integration.client
    elsif @user.is_a?(User) && @user.client_id.to_i.positive?
      @user.client
    elsif @contact.is_a?(Contact) && @contact.client_id.to_i.positive?
      @contact.client
    else
      Client.new
    end
  end

  def contact_derived
    if @contact.is_a?(Contact) && @contact.client_id.to_i.positive?
      @contact
    elsif @user.is_a?(User) && !@user.new_record?
      @user.contacts.new
    elsif @client.is_a?(Client) && !@client.new_record?
      @client.contacts.new
    else
      Contact.new
    end
  end

  def user_derived
    if @user.is_a?(User) && @user.client_id.to_i.positive?
      @user
    elsif @client.is_a?(Client) && !@client.new_record?
      @client.users.new
    elsif @contact.is_a?(Contact) && @contact.user_id.to_i.positive?
      @contact.user
    else
      User.new
    end
  end

  def user_api_integration_derived
    if @user_api_integration.is_a?(UserApiIntegration) && @user_api_integration.user_id.to_i.positive?
      @user_api_integration
    elsif @user.is_a?(Client) && !@user.new_record?
      @user.user_api_integrations.new
    elsif @contact.is_a?(Contact) && @contact.user_id.to_i.positive?
      @contact.user.user_api_integrations.new
    else
      UserApiIntegration.new
    end
  end
end
