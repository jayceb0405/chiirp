class ChangeServiceTitanInvoicesToKpiStatsInvoices < ActiveRecord::Migration[6.0]
  def up
  	rename_table   :service_titan_invoices,      :fcp_invoices

  	ClientApiIntegration.where( target: "servicetitan-stats" ).update_all( target: "fieldcontrolpro-stats" )
  end

  def down
  	rename_table   :fcp_invoices,          :service_titan_invoices

  	ClientApiIntegration.where( target: "fieldcontrolpro-stats" ).update_all( target: "servicetitan-stats" )
  end
end
