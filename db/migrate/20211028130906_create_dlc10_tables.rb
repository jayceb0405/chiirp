class CreateDlc10Tables < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating ClientDlc10Brands table...' do

      create_table :clients_dlc10_brands do |t|
        t.references    :client, foreign_key: true, index: true
        t.string        :tcr_brand_id,                          default: '',        null: false
        t.string        :firstname,                             default: '',        null: false
        t.string        :lastname,                              default: '',        null: false
        t.string        :company_name,                          default: '',        null: false
        t.string        :display_name,                          default: '',        null: false
        t.string        :street,                                default: '',        null: false
        t.string        :city,                                  default: '',        null: false
        t.string        :state,                                 default: '',        null: false
        t.string        :zipcode,                               default: '',        null: false
        t.string        :country,                               default: '',        null: false
        t.string        :phone,                                 default: '',        null: false
        t.string        :email,                                 default: '',        null: false
        t.string        :entity_type,                           default: '',        null: false
        t.string        :ein,                                   default: '',        null: false
        t.string        :ein_country,                           default: '',        null: false
        t.string        :stock_symbol,                          default: '',        null: false
        t.string        :stock_exchange,                        default: '',        null: false
        t.string        :ip_address,                            default: '',        null: false
        t.string        :website,                               default: '',        null: false
        t.string        :brand_relationship,                    default: '',        null: false
        t.string        :vertical,                              default: '',        null: false
        t.string        :alt_business_id,                       default: '',        null: false
        t.string        :alt_business_id_type,                  default: '',        null: false

        t.timestamps
      end
    end

    say_with_time 'Creating ClientDlc10Campaigns table...' do

      create_table :clients_dlc10_campaigns do |t|
        t.references    :dlc10_brand, foreign_key: {to_table: 'clients_dlc10_brands'}, index: true
        t.string        :tcr_campaign_id,                       default: '',             null: false
        t.string        :name,                                  default: '',             null: false
        t.string        :vertical,                              default: '',             null: false
        t.string        :use_case,                              default: '',             null: false
        t.text          :sub_use_cases,     array: true,        default: []
        t.string        :reseller_id,                           default: '',             null: false
        t.string        :description,                           default: '',             null: false
        t.boolean       :embedded_link,                         default: true,           null: false
        t.boolean       :embedded_phone,                        default: false,          null: false
        t.boolean       :number_pool,                           default: false,          null: false
        t.boolean       :age_gated,                             default: false,          null: false
        t.boolean       :direct_lending,                        default: false,          null: false
        t.boolean       :subscriber_optin,                      default: true,           null: false
        t.boolean       :subscriber_optout,                     default: true,           null: false
        t.boolean       :subscriber_help,                       default: true,           null: false
        t.text          :sample1,                               default: '',             null: false
        t.text          :sample2,                               default: '',             null: false
        t.text          :sample3,                               default: '',             null: false
        t.text          :sample4,                               default: '',             null: false
        t.text          :sample5,                               default: '',             null: false
        t.string        :reference_id,                          default: '',             null: false
        t.boolean       :auto_renewal,                          default: true,           null: false
        t.boolean       :affiliate_marketing,                   default: false,          null: false
        t.decimal       :mo_charge,                             default: 0,              null: false
        t.date          :next_mo_date,                          default: -> { "NOW()" }, null: false
        t.decimal       :qtr_charge,                            default: 0,              null: false
        t.date          :next_qtr_date,                         default: -> { "NOW()" }, null: false
        t.datetime      :shared_at

        t.timestamps
      end
    end

    say_with_time 'Adding ClientDlc10Campaign reference to Twnumbers table...' do
      # add_reference     :twnumbers,         :dlc10_campaign,    foreign_key: {to_table: 'clients_dlc10_campaigns'}, index: true
      add_reference     :twnumbers,         :dlc10_campaign,    default: 0,         null: false,        to_table: 'clients_dlc10_campaigns',    index: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
