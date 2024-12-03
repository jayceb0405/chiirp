# frozen_string_literal: true

# app/lib/custom_token_response.rb
module CustomTokenResponse
  def body
    user = User.find_by_id(@token.resource_owner_id)

    additional_data = {
      'username' => user.fullname,
      'userid'   => @token.resource_owner_id,
      'email'    => user.email
    }

    # call original `#body` method and merge its result with the additional data hash
    super.merge(additional_data)
  end
end
