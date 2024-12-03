# frozen_string_literal: true

# app/lib/first_promoter.rb
class FirstPromoter
  require 'net/http'
  require 'uri'

  # register a refund with FirstPromoter
  # FirstPromoter.new.register_cancellation( client_id: Integer )
  def register_cancellation(params)
    client_id    = params.include?(:client_id) ? params[:client_id].to_i : 0
    client_email = params.include?(:client_email) ? params[:client_email].to_s : nil

    return unless client_id.positive?

    conn = Faraday.new(url: 'https://firstpromoter.com/api/v1/track/cancellation')
    conn.headers['x-api-key'] = Rails.application.credentials[:firstpromoter][:api_key]
    conn.post '', {
      wid:   Rails.application.credentials[:firstpromoter][:api_wid],
      email: client_email,
      uid:   client_id
    }

    # Rails.logger.info "response: #{response.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.code: #{response.code.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.body: #{response.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
  end
  # sample response
  # {
  #   "id": 1710,
  #   "type": "cancellation",
  #   "amount_cents": null,
  #   "lead": {
  #     "id": 943,
  #     "state": "cancelled",
  #     "email": "shelley@example.com",
  #     "uid": "cbdemo_shelley",
  #     "customer_since": "2018-04-11T14:54:32.014Z",
  #     "plan_name": "monthly-starter",
  #     "suspicion": "no_suspicion"
  #   },
  #   "promoter": {
  #     "id": 1983,
  #     "cust_id": null,
  #     "email": "test@test.com",
  #     "temp_password": "u1PptB",
  #     "default_promotion_id": 1986,
  #     "default_ref_id": "test_ref_id",
  #     "earnings_balance": null,
  #     "current_balance": null,
  #     "paid_balance": null
  #   }
  # }

  # register a refund with FirstPromoter
  # FirstPromoter.new.register_refund( client_id: Integer, transaction_id: Integer, refund_amount: Integer )
  def register_refund(params)
    client_id                 = params.include?(:client_id) ? params[:client_id].to_i : 0
    transaction_id            = params.include?(:transaction_id) ? params[:transaction_id].to_i : 0
    refund_amount             = params.include?(:refund_amount) ? params[:refund_amount].to_i : 0
    client_email              = params.include?(:client_email) ? params[:client_email].to_s : nil
    quantity                  = params.include?(:quantity) ? params[:quantity].to_i : nil
    original_transaction_id   = params.include?(:original_transaction_id) ? params[:original_transaction_id].to_i : nil

    return unless client_id.positive? && transaction_id.positive? && refund_amount.positive?

    conn = Faraday.new(url: 'https://firstpromoter.com/api/v1/track/refund')
    conn.headers['x-api-key'] = Rails.application.credentials[:firstpromoter][:api_key]
    conn.post '', {
      wid:           Rails.application.credentials[:firstpromoter][:api_wid],
      email:         client_email,
      uid:           client_id,
      event_id:      transaction_id.to_s,
      amount:        refund_amount,
      quantity:,
      sale_event_id: original_transaction_id
    }

    # Rails.logger.info "response: #{response.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.code: #{response.code.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.body: #{response.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
  end
  # sample response
  # {
  #   "id": 1709,
  #   "type": "refund",
  #   "amount_cents": -6000,
  #   "lead": {
  #     "id": 943,
  #     "state": "active",
  #     "email": "shelley@example.com",
  #     "uid": "cbdemo_shelley",
  #     "customer_since": "2018-04-11T14:54:32.014Z",
  #     "plan_name": "monthly-starter",
  #     "suspicion": "no_suspicion"
  #   },
  #   "promoter": {
  #     "id": 1983,
  #     "cust_id": null,
  #     "email": "test@test.com",
  #     "temp_password": "u1PptB",
  #     "default_promotion_id": 1986,
  #     "default_ref_id": "test_ref_id",
  #     "earnings_balance": null,
  #     "current_balance": null,
  #     "paid_balance": null
  #   }
  # }

  # register a sale with FirstPromoter
  # FirstPromoter.new.register_sale( client_id: Integer, transaction_id: Integer, package_key: String, amount: Integer )
  def register_sale(params)
    client_id        = params.include?(:client_id) ? params[:client_id].to_i : 0
    transaction_id   = params.include?(:transaction_id) ? params[:transaction_id].to_i : 0
    package_key      = params.include?(:package_key) ? params[:package_key].to_s : ''
    amount           = params.include?(:amount) ? params[:amount].to_i : 0
    client_email     = params.include?(:client_email) ? params[:client_email].to_s : nil
    client_name      = params.include?(:client_name) ? params[:client_name].to_s : ''
    quantity         = params.include?(:quantity) ? params[:quantity].to_i : nil
    monthly_charge   = params.include?(:monthly_charge) ? params[:monthly_charge].to_i : nil
    promo_code       = params.include?(:promo_code) ? params[:promo_code].to_s : nil
    affiliate_id     = params.include?(:affiliate_id) ? params[:affiliate_id].to_s : nil
    referral_id      = params.include?(:referral_id) ? params[:referral_id].to_s : nil

    return unless client_id.positive? && transaction_id.positive? && package_key.present? && amount.positive?

    conn = Faraday.new(url: 'https://firstpromoter.com/api/v1/track/sale')
    conn.headers['x-api-key'] = Rails.application.credentials[:firstpromoter][:api_key]
    conn.post '', {
      wid:        Rails.application.credentials[:firstpromoter][:api_wid],
      email:      client_email,
      username:   client_name,
      uid:        client_id,
      event_id:   transaction_id.to_s,
      amount:,
      quantity:,
      plan:       package_key,
      mrr:        monthly_charge,
      promo_code:,
      tid:        affiliate_id,
      ref_id:     referral_id
    }

    # Rails.logger.info "response: #{response.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.code: #{response.code.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_sale:response.body: #{response.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
  end
  # sample response
  # {
  #   "id": 1708,
  #   "type": "sale",
  #   "amount_cents": 6000,
  #   "lead": {
  #     "id": 943,
  #     "state": "active",
  #     "email": "shelley@example.com",
  #     "uid": "cbdemo_shelley",
  #     "customer_since": "2018-04-11T14:54:32.014Z",
  #     "plan_name": "monthly-starter",
  #     "suspicion": "no_suspicion"
  #   },
  #   "promoter": {
  #     "id": 1983,
  #     "cust_id": null,
  #     "email": "test@test.com",
  #     "temp_password": "u1PptB",
  #     "default_promotion_id": 1986,
  #     "default_ref_id": "test_ref_id",
  #     "earnings_balance": {
  #       "cash": 1200
  #     },
  #     "current_balance": {
  #       "cash": 1200
  #     },
  #     "paid_balance": null
  #   }
  # }

  # register a signup with FirstPromoter
  # FirstPromoter.new.register_signup( client_id: Integer, affiliate_id: String )
  def register_signup(params)
    client_id    = params.include?(:client_id) ? params[:client_id].to_i : 0
    affiliate_id = params.include?(:affiliate_id) ? params[:affiliate_id].to_s : ''
    client_email = params.include?(:client_email) ? params[:client_email].to_s : nil
    client_name  = params.include?(:client_name) ? params[:client_name].to_s : ''
    referral_id  = params.include?(:referral_id) ? params[:referral_id].to_s : nil
    ip_address   = params.include?(:ip_address) ? params[:ip_address].to_s : nil

    return unless client_id.positive? && affiliate_id.present?

    conn = Faraday.new(url: 'https://firstpromoter.com/api/v1/track/signup')
    conn.headers['x-api-key'] = Rails.application.credentials[:firstpromoter][:api_key]
    conn.post '', {
      wid:      Rails.application.credentials[:firstpromoter][:api_wid],
      email:    client_email,
      username: client_name,
      uid:      client_id,
      tid:      affiliate_id,
      ref_id:   referral_id,
      ip:       ip_address
    }

    # Rails.logger.info "response: #{response.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_signup:response.code: #{response.code.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "register_signup:response.body: #{response.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
  end
  # example response
  # {
  #   "id": 1707,
  #   "type": "signup",
  #   "amount_cents": null,
  #   "lead": {
  #     "id": 943,
  #     "state": "signup",
  #     "email": "shelley@example.com",
  #     "uid": "cbdemo_shelley",
  #     "customer_since": null,
  #     "plan_name": null
  #     "suspicion": "no_suspicion"
  #   },
  #   "promoter": {
  #     "id": 1983,
  #     "cust_id": null,
  #     "email": "test@test.com",
  #     "temp_password": "u1PptB",
  #     "default_promotion_id": 1986,
  #     "default_ref_id": "test_ref_id",
  #     "earnings_balance": null,
  #     "current_balance": null,
  #     "paid_balance": null
  #   }
  # }
end
