# frozen_string_literal: true

# app/lib/integrations/service_titan/pricebook.rb
module Integrations
  module ServiceTitan
    module Pricebook
      # call ServiceTitan API for Pricebook Categories
      # st_client.pb_categories
      #   active: (Boolean/String / Default: true)
      def pb_categories(args = {})
        reset_attributes
        page     = 0
        @result  = []
        response = @result

        params = {
          pageSize: @max_page_size,
          active:   args.dig(:active).nil? ? 'True' : args[:active].to_s.titleize
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Pricebook.pb_categories',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_pricebook}/#{api_version}/tenant/#{self.tenant_id}/categories"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for Pricebook Equipment
      # st_client.pb_equipment
      #   active: (Boolean/String / Default: true)
      def pb_equipment(args = {})
        reset_attributes
        page     = 0
        @result  = []
        response = @result

        params = {
          active:   args.dig(:active).nil? ? 'True' : args[:active].to_s.titleize,
          pageSize: @max_page_size,
          sort:     '+DisplayName'
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Pricebook.pb_equipment',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_pricebook}/#{api_version}/tenant/#{self.tenant_id}/equipment"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end
      # example ServiceTitan equipment response:
      # [
      #   {
      #     id:                                139_127_163,
      #     code:                              'IGPD',
      #     displayName:                       nil,
      #     description:                       '1/2" Galvanized Plug',
      #     cost:                              2.723175,
      #     active:                            true,
      #     price:                             0.0,
      #     memberPrice:                       0.0,
      #     addOnPrice:                        0.0,
      #     addOnMemberPrice:                  0.0,
      #     hours:                             0.0,
      #     bonus:                             0.0,
      #     commissionBonus:                   0.0,
      #     paysCommission:                    false,
      #     deductAsJobCost:                   false,
      #     unitOfMeasure:                     nil,
      #     isInventory:                       false,
      #     account:                           'Revenue',
      #     costOfSaleAccount:                 'MATERIALS & EQUIPMENT TAXED',
      #     assetAccount:                      nil,
      #     taxable:                           false,
      #     primaryVendor:                     { id: 139_127_165, vendorName: 'Goodman VMI', vendorId: 137_778_560, memo: nil, vendorPart: nil, cost: 2.723175, active: true, primarySubAccount: nil, otherSubAccounts: [] },
      #     otherVendors:                      [{ id: 178_127_543, vendorName: 'Ferguson Plumbing Supply - Laverne', vendorId: 142_353_764, memo: nil, vendorPart: nil, cost: 2.73, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_165, vendorName: 'Goodman VMI', vendorId: 137_778_560, memo: nil, vendorPart: nil, cost: 2.723175, active: true, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_166, vendorName: 'NorCal - AAA Services, Inc.', vendorId: 109_144_470, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_168, vendorName: 'NorCal - CFM Equipment Sacramento', vendorId: 109_144_473, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_169, vendorName: 'Default Replenishment Vendor', vendorId: 53_722_434, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_170, vendorName: 'NorCal - FERGUSON HVAC - Sacramento', vendorId: 100_041_559, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_171, vendorName: 'Goodman - Fresno', vendorId: 67_542_232, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_172, vendorName: 'Imported Default Replenishment Vendor', vendorId: 100_613_792, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_173, vendorName: 'JB & Associates Extended Warranties, LLC', vendorId: 109_144_485, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_174, vendorName: 'Johnstone Supply', vendorId: 26_888_881, memo: nil, vendorPart: nil, cost: 2.99, active: true, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_175, vendorName: 'Lennox - Fresno', vendorId: 20_035_816, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_176, vendorName: 'RSD', vendorId: 20_035_811, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_177, vendorName: 'Sigler', vendorId: 20_023_554, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_178, vendorName: 'Slakey Brothers', vendorId: 20_035_814, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 139_127_179, vendorName: 'NorCal - Wholesale Outlet Inc', vendorId: 109_144_455, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 201_313_433, vendorName: 'Pace Supply', vendorId: 174_878_009, memo: nil, vendorPart: nil, cost: 2.73, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 181_456_917, vendorName: 'Ferguson Plumbing Supply - Ashlan', vendorId: 142_354_148, memo: nil, vendorPart: nil, cost: 2.73, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 236_943_810, vendorName: "Lee's Warehouse - Fresno", vendorId: 156_217_022, memo: nil, vendorPart: nil, cost: 2.723175, active: false, primarySubAccount: nil, otherSubAccounts: [] }],
      #     categories:                        [51_736_211, 52_237_379, 141_645_164, 147_999_442],
      #     assets:                            [{ alias: nil, fileName: nil, type: 'Image', url: 'Images/Material/b812774e-d8fe-4ac4-a2f3-8437c0eb934b.jpg' }],
      #     modifiedOn:                        '2024-03-29T16:10:36.7383277Z',
      #     source:                            nil,
      #     externalId:                        nil,
      #     externalData:                      [],
      #     isConfigurableMaterial:            false,
      #     chargeableByDefault:               true,
      #     variationsOrConfigurableMaterials: []
      #   },
      #   { id:                                161_955_561,
      #     code:                              'DISPLAY',
      #     displayName:                       nil,
      #     description:                       'DSPLY ITEM',
      #     cost:                              0.5985,
      #     active:                            true,
      #     price:                             0.0,
      #     memberPrice:                       0.0,
      #     addOnPrice:                        0.0,
      #     addOnMemberPrice:                  0.0,
      #     hours:                             0.0,
      #     bonus:                             0.0,
      #     commissionBonus:                   0.0,
      #     paysCommission:                    false,
      #     deductAsJobCost:                   false,
      #     unitOfMeasure:                     'EA',
      #     isInventory:                       false,
      #     account:                           'Revenue',
      #     costOfSaleAccount:                 'MATERIALS & EQUIPMENT TAXED',
      #     assetAccount:                      nil,
      #     taxable:                           false,
      #     primaryVendor:                     { id: 161_955_563, vendorName: 'Ferguson Plumbing Supply - Ashlan', vendorId: 142_354_148, memo: 'DSPLY ITEM', vendorPart: 'DISPLAY', cost: 0.5985, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #     otherVendors:                      [{ id:                195_711_293, vendorName: 'NorCal - FERGUSON Plumbing Supply - Rocklin', vendorId: 183_001_031, memo: nil, vendorPart: nil, cost: 0.0, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #                                         { id:                161_955_563, vendorName: 'Ferguson Plumbing Supply - Ashlan', vendorId: 142_354_148, memo: 'DSPLY ITEM', vendorPart: 'DISPLAY', cost: 0.5985, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #                                         { id:                161_955_564, vendorName: 'Ferguson Plumbing Supply - Laverne', vendorId: 142_353_764, memo: 'DSPLY ITEM', vendorPart: 'DISPLAY', cost: 0.6, active: true, primarySubAccount: nil, otherSubAccounts:  [] }],
      #     categories:                        [161_953_684],
      #     assets:                            [],
      #     modifiedOn:                        '2024-03-29T16:10:37.6615022Z',
      #     source:                            nil,
      #     externalId:                        nil,
      #     externalData:                      [],
      #     isConfigurableMaterial:            false,
      #     chargeableByDefault:               true,
      #     variationsOrConfigurableMaterials: [] },
      #   { id:                                161_956_806,
      #     code:                              '415-49823-02',
      #     displayName:                       nil,
      #     description:                       'GAS VLV F/ URG2PV40',
      #     cost:                              247.00095,
      #     active:                            true,
      #     price:                             0.0,
      #     memberPrice:                       0.0,
      #     addOnPrice:                        0.0,
      #     addOnMemberPrice:                  0.0,
      #     hours:                             0.0,
      #     bonus:                             0.0,
      #     commissionBonus:                   0.0,
      #     paysCommission:                    false,
      #     deductAsJobCost:                   false,
      #     unitOfMeasure:                     'EA',
      #     isInventory:                       false,
      #     account:                           'Revenue',
      #     costOfSaleAccount:                 'MATERIALS & EQUIPMENT TAXED',
      #     assetAccount:                      nil,
      #     taxable:                           false,
      #     primaryVendor:                     { id:  161_956_808, vendorName: 'Ferguson Plumbing Supply - Ashlan', vendorId: 142_354_148, memo: 'GAS VLV F/ URG2PV40', vendorPart: 'B2394982302', cost: 247.00095, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #     otherVendors:                      [{ id: 161_956_808, vendorName: 'Ferguson Plumbing Supply - Ashlan', vendorId: 142_354_148, memo: 'GAS VLV F/ URG2PV40', vendorPart: 'B2394982302', cost: 247.00095, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #                                         { id: 161_956_809, vendorName: 'Ferguson Plumbing Supply - Laverne', vendorId: 142_353_764, memo: 'GAS VLV F/ URG2PV40', vendorPart: 'B2394982302', cost: 247.62, active: true, primarySubAccount: nil, otherSubAccounts:  [] },
      #                                         { id: 162_202_962, vendorName: 'NorCal - AAA Services, Inc.', vendorId: 109_144_470, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_963, vendorName: 'Ace Hardware - NE Fresno', vendorId: 156_329_870, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_965, vendorName: 'Baker Distributing Company - Angus', vendorId: 109_144_474, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_966, vendorName: 'NorCal - CFM Equipment Sacramento', vendorId: 109_144_473, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_967, vendorName: 'Default Replenishment Vendor', vendorId: 53_722_434, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_968, vendorName: 'NorCal - FERGUSON HVAC - Sacramento', vendorId: 100_041_559, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_969, vendorName: 'Ferguson HVAC', vendorId: 1_297_935, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_970, vendorName: 'Goodman - Fresno', vendorId: 67_542_232, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_971, vendorName: 'Goodman VMI', vendorId: 137_778_560, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_972, vendorName: 'Home Depot - Kings Canyon', vendorId: 1_297_934, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_973, vendorName: 'Imported Default Replenishment Vendor', vendorId: 100_613_792, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_974, vendorName: 'JB & Associates Extended Warranties, LLC', vendorId: 109_144_485, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_975, vendorName: 'Johnstone Supply', vendorId: 26_888_881, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_976, vendorName: 'Lennox - Fresno', vendorId: 20_035_816, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_977, vendorName: 'RSD', vendorId: 20_035_811, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_978, vendorName: 'Sigler', vendorId: 20_023_554, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_979, vendorName: 'Slakey Brothers', vendorId: 20_035_814, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_980, vendorName: 'Westlake Ace Hardware', vendorId: 148_000_592, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 162_202_981, vendorName: 'NorCal - Wholesale Outlet Inc', vendorId: 109_144_455, memo: nil, vendorPart: nil, cost: 0.0, active: false, primarySubAccount: nil, otherSubAccounts: [] },
      #                                         { id: 195_717_920, vendorName: 'NorCal - FERGUSON Plumbing Supply - Rocklin', vendorId: 183_001_031, memo: nil, vendorPart: nil, cost: 0.0, active: true, primarySubAccount: nil, otherSubAccounts:  [] }],
      #     categories:                        [161_953_684],
      #     assets:                            [],
      #     modifiedOn:                        '2024-03-29T16:10:38.589078Z',
      #     source:                            nil,
      #     externalId:                        nil,
      #     externalData:                      [],
      #     isConfigurableMaterial:            false,
      #     chargeableByDefault:               true,
      #     variationsOrConfigurableMaterials: [] }
      # ]

      # call ServiceTitan API for Pricebook Materials
      # st_client.pb_materials
      #   active: (Boolean/String)
      def pb_materials(args = {})
        reset_attributes
        page     = 0
        @result  = []
        response = @result

        params = {
          active:   args.dig(:active).nil? ? 'True' : args[:active].to_s.titleize,
          pageSize: @max_page_size,
          sort:     '+DisplayName'
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Pricebook.pb_materials',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_pricebook}/#{api_version}/tenant/#{self.tenant_id}/materials"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for Pricebook Services
      # st_client.pb_services
      #   active: (Boolean/String)
      def pb_services(args = {})
        reset_attributes
        page     = 0
        @result  = []
        response = @result

        params = {
          active:   args.dig(:active).nil? ? 'True' : args[:active].to_s.titleize,
          pageSize: @max_page_size,
          sort:     '+DisplayName'
        }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Pricebook.pb_services',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_pricebook}/#{api_version}/tenant/#{self.tenant_id}/services"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore)&.to_bool
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end
        end

        @result = response
      end
    end
  end
end
