# frozen_string_literal: true

# app/lib/ctypt.rb
module Crypt
  def self.encrypt(unencrypted_data)
    # generate encrypted data
    #
    # Example:
    # 	Crypt.encrypt data
    #
    # Required Arguments:
    # 	unencrypted_data: (Any Class)
    #
    # Optional Arguments:
    #   none
    #
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.credentials[:secure_key])
    crypt.encrypt_and_sign unencrypted_data
  end

  def self.decrypt(encrypted_data)
    # decrypt client_id
    #
    # Example:
    # 	Crypt.decrypt data
    #
    # Required Arguments:
    # 	encrypted_data: (Ant Class)
    #
    # Optional Arguments:
    #   none
    #
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.credentials[:secure_key])
    crypt.decrypt_and_verify encrypted_data
  end
end
