# frozen_string_literal: true

# app/lib/integrations/card_x/transactions.rb
# https://developer.cardx.com/
module Integrations
  module CardX
    # process various API calls to CardX
    module Transactions
      def transaction(id)
        callrail_request(
          url: "/api/merchant/:#{@account}/order/transaction/:#{id}"
        )
      end
    end
  end
end
