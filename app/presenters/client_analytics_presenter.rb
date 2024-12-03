# frozen_string_literal: true

# app/presenters/client_analytics_presenter.rb
class ClientAnalyticsPresenter
  attr_reader :month, :year

  def initialize(user, month, year)
    @user = if user.is_a?(User)
              user
            elsif user.is_a?(Integer)
              User.find_by(id: user)
            else
              User.new
            end

    @month                          = month.to_i
    @year                           = year.to_i
    @ad_costs                       = nil
    @ad_costs_by_month              = nil
    @added_charges                  = nil
    @avg_ad_costs                   = nil
    @avg_commission_costs           = nil
    @avg_monthly_charges            = nil
    @avg_startup_revenue            = nil
    @commissions_by_month           = nil
    @credits_charges                = nil
    @end_commission_costs           = nil
    @first_month_costs_by_month     = nil
    @gross_profit                   = nil
    @gross_revenue_by_month         = nil
    @mid_commission_costs           = nil
    @monthly_charges                = nil
    @new_clients                    = nil
    @new_clients_active             = nil
    @new_clients_active_count       = nil
    @new_clients_by_month           = nil
    @new_clients_count              = nil
    @new_clients_last_month         = nil
    @new_clients_last_month_count   = nil
    @new_leads                      = nil
    @new_leads_by_month             = nil
    @new_leads_count                = nil
    @new_leads_last_month           = nil
    @new_leads_last_month_count     = nil
    @startup_revenue                = nil
    @startup_revenue_by_month       = nil
    @total_clients                  = nil
    @total_clients_count            = nil
    @total_costs_by_month           = nil

    # @ad_costs_by_month          ||= { 7=>0.855e3, 8=>0.4124e4, 9=>0.5652e4, 10=>0.5164e4 }
    # @commissions_by_month       ||= { 7=>0.0, 8=>0.10718e5, 9=>0.14913e5, 10=>0.7128e4 }
    # @first_month_costs_by_month ||= { 12=>0, 1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0, 7=>0.855e3, 8=>0.9483e4, 9=>0.131085e5, 10=>0.8728e4, 11=>0 }
    # @gross_revenue_by_month     ||= { 1.0=>0.1042298e5, 2.0=>0.2839793e5, 3.0=>0.2119772e5, 4.0=>0.5951e5, 5.0=>0.39423e5, 6.0=>0.31994e5, 7.0=>0.251785e5, 8.0=>0.43459e5, 9.0=>0.3192e5, 10.0=>0.281877e5, 11.0=>0.19713e5, 12.0=>0.9144e4 }
    # @new_clients_by_month       ||= { 1.0=>31, 2.0=>26, 3.0=>21, 4.0=>19, 5.0=>16, 6.0=>9, 7.0=>18, 8.0=>50, 9.0=>50, 10.0=>34, 11.0=>13, 12.0=>12 }
    # @new_leads_by_month         ||= { 3.0=>52, 4.0=>19, 5.0=>59, 6.0=>130, 7.0=>171, 8.0=>529, 9.0=>482, 10.0=>426, 11.0=>203 }
    # @startup_revenue_by_month   ||= { 2.0=>147.0, 3.0=>178.0, 4.0=>3433.0, 5.0=>4039.0, 6.0=>2529.0, 7.0=>5190.0, 8.0=>10189.0, 9.0=>9516.0, 10.0=>7726.0, 11.0=>1698.0, 12.0=>129.0 }
    # @total_costs_by_month       ||= { 7=>0.855e3, 8=>0.14842e5, 9=>0.20565e5, 10=>0.12292e5 }
  end

  def ad_costs
    @ad_costs ||= TenantCost.find_by(tenant: I18n.t('tenant.id'), month: @month, year: @year, cost_key: 'ads')&.cost_value || 0
  end

  def ad_costs_by_month
    @ad_costs_by_month ||= self.ad_costs_by_month_calc
  end

  def ad_costs_by_month_calc
    last_year_months = self.month_year_sequence.select { |_key, value| value == @year - 1 }
    this_year_months = self.month_year_sequence.select { |_key, value| value == @year }
    tenant_costs = TenantCost.where(tenant: I18n.t('tenant.id')).where(cost_key: 'ads')
    tenant_costs.where(month: last_year_months.keys, year: last_year_months.values)
                .or(tenant_costs.where(month: this_year_months.keys, year: this_year_months.values))
                .map { |tenant_cost| { tenant_cost.month => tenant_cost.cost_value } }.reduce({}, :merge)
  end

  def ad_costs_graph_data
    { dataset: { yAxisID: 'ad_costs' }, name: 'Ad Costs', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => self.ad_costs_by_month[month].to_d } }.reduce({}, :merge) }
  end

  def added_charges
    @added_charges ||= ClientTransaction.where(created_at: period_range)
                                        .where(client_id: Client.where(tenant: I18n.t('tenant.id')))
                                        .where(setting_key: 'added_charge')
                                        .sum('setting_value::numeric')
  end

  def avg_ad_costs
    @avg_ad_costs ||= (self.new_clients_count.zero? ? self.ad_costs : self.ad_costs / self.new_clients_count)
  end

  def avg_commission_costs
    @avg_commission_costs ||= ((self.new_clients_count + self.new_clients_last_month_count).zero? ? self.total_commission_costs : self.total_commission_costs / (self.new_clients_count + self.new_clients_last_month_count))
  end

  def avg_costs
    self.avg_ad_costs + self.avg_commission_costs
  end

  def avg_monthly_charges
    @avg_monthly_charges ||= ((self.total_clients_count - self.new_clients_count).zero? ? self.monthly_charges : self.monthly_charges / (self.total_clients_count - self.new_clients_count))
  end

  def avg_startup_revenue
    @avg_startup_revenue ||= (self.new_clients_count.zero? ? self.startup_revenue : self.startup_revenue / self.new_clients_count)
  end

  def credits_charges
    @credits_charges ||= ClientTransaction.where(created_at: period_range)
                                          .where(client_id: Client.where(tenant: I18n.t('tenant.id')))
                                          .where(setting_key: 'credit_charge')
                                          .sum('setting_value::numeric')
  end

  def client_value_first_month
    self.avg_startup_revenue - self.avg_ad_costs - (self.avg_commission_costs / 2)
  end

  def client_value_second_month
    self.avg_monthly_charges - (self.avg_commission_costs / 2)
  end

  def client_value_third_month
    self.avg_monthly_charges + [self.client_value_first_month, 0].min + [self.client_value_second_month, 0].min
  end

  def commissions_by_month
    @commissions_by_month ||= self.commissions_by_month_calc
  end

  def commissions_by_month_calc
    last_year_months = self.month_year_sequence.select { |_key, value| value == @year - 1 }
    this_year_months = self.month_year_sequence.select { |_key, value| value == @year }
    tenant_commissions = TenantCost.where(tenant: I18n.t('tenant.id')).where(cost_key: %w[mid_comm end_comm])
    tenant_commissions.where(month: last_year_months.keys, year: last_year_months.values)
                      .or(tenant_commissions.where(month: this_year_months.keys, year: this_year_months.values))
                      .group(:month)
                      .sum(:cost_value)
  end

  def commissions_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => (((self.commissions_by_month[month] || 0) / 2) / (self.new_clients_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def commissions_graph_data
    { dataset: { yAxisID: 'commissions' }, name: '50% Commissions', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => (((self.commissions_by_month[month] || 0) / 2) / (self.new_clients_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge) }
  end

  def end_commission_costs
    @end_commission_costs ||= TenantCost.find_by(tenant: I18n.t('tenant.id'), month: @month, year: @year, cost_key: 'end_comm')&.cost_value || 0
  end

  def first_month_costs_by_month
    @first_month_costs_by_month ||= self.month_sequence.map { |month| { month => (((self.commissions_by_month[month] || 0) / 2) + (self.ad_costs_by_month[month] || 0)) } }.reduce({}, :merge)
  end

  def first_month_costs_graph_data
    { prefix: '$', dataset: { yAxisID: 'first_month_costs' }, name: 'First Month Costs', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => self.first_month_costs_by_month[month].to_d } }.reduce({}, :merge) }
  end

  def gross_profit
    @gross_profit ||= (self.startup_revenue + self.monthly_charges - self.total_costs)
  end

  def gross_revenue_by_month
    @gross_revenue_by_month ||= ClientTransaction.joins(:client)
                                                 .where(client_transactions: { created_at: period_range_by_month })
                                                 .where(client_transactions: { setting_key: %w[startup_costs added_charge credit_charge mo_charge] })
                                                 .where(clients: { tenant: I18n.t('tenant.id') })
                                                 .where("(clients.data ->> 'mo_charge')::numeric > ?", 0)
                                                 .group('EXTRACT(MONTH FROM clients.created_at)')
                                                 .sum('client_transactions.setting_value::numeric')
  end

  def gross_revenue_graph_data
    { prefix: '$', dataset: { yAxisID: 'gross_revenue' }, name: 'Gross Revenue', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => (self.gross_revenue_by_month[month.to_f] || 0) } }.reduce({}, :merge) }
  end

  def lost_clients_count
    self.new_clients_count - self.new_clients_active_count
  end

  def lost_clients_by_month
    self.months_between.zero? ? self.lost_clients_count : self.lost_clients_count / self.months_between
  end

  def lost_clients_as_percentage_of_new
    self.new_clients_count.zero? ? 0 : self.lost_clients_count / self.new_clients_count
  end

  def lost_clients_as_percentage_of_new_by_month
    if self.new_clients_count.zero?
      0
    else
      self.months_between.zero? ? self.lost_clients_as_percentage_of_new : (self.lost_clients_count / self.new_clients_count) / self.months_between
    end
  end

  def mid_commission_costs
    @mid_commission_costs ||= TenantCost.find_by(tenant: I18n.t('tenant.id'), month: @month, year: @year, cost_key: 'mid_comm')&.cost_value || 0
  end

  def month_name
    Date::MONTHNAMES[@month]
  end

  def monthly_charges
    @monthly_charges ||= ClientTransaction.where(created_at: period_range)
                                          .where(client_id: Client.where(tenant: I18n.t('tenant.id')))
                                          .where(setting_key: 'mo_charge')
                                          .sum('setting_value::numeric')
  end

  def net_revenue_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.gross_revenue_by_month[month.to_f] || 0) - (self.total_costs_by_month[month] || 0)) } }.reduce({}, :merge)
  end

  def new_clients
    @new_clients ||= Client.where(tenant: I18n.t('tenant.id')).where(created_at: period_range).where("(clients.data ->> 'mo_charge')::numeric > ?", 0)
  end

  def new_clients_active
    @new_clients_active ||= self.new_clients.where('clients.data @> ?', { active: true }.to_json).where("(clients.data ->> 'mo_charge')::numeric > ?", 0)
  end

  def new_clients_active_count
    @new_clients_active_count ||= self.new_clients_active.count
  end

  def new_clients_ad_costs_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.ad_costs_by_month[month] || 0) / (self.new_clients_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def new_clients_per_leads
    self.new_clients_count.zero? ? 0 : self.new_leads_count / self.new_clients_count
  end

  def new_clients_by_month
    @new_clients_by_month ||= Client.where(tenant: I18n.t('tenant.id')).where(created_at: period_range_by_month).where("(clients.data ->> 'mo_charge')::numeric > ?", 0).group('EXTRACT(MONTH FROM created_at)').count
  end

  def new_clients_count
    @new_clients_count ||= self.new_clients.count
  end

  def new_clients_graph_data
    { dataset: { yAxisID: 'new_clients' }, name: 'New Clients', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => new_clients_by_month[month.to_f] } }.reduce({}, :merge) }
  end

  def new_clients_last_month
    @new_clients_last_month ||= Client.where(tenant: I18n.t('tenant.id')).where(created_at: previous_period_range)
  end

  def new_clients_last_month_count
    @new_clients_last_month_count ||= self.new_clients_last_month.count
  end

  def new_clients_leads_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.new_leads_by_month[month.to_f] || 0) / (self.new_clients_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def new_clients_startup_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.startup_revenue_by_month[month.to_f] || 0) / (self.new_clients_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def new_leads
    @new_leads ||= Contact.where(client_id: I18n.t("tenant.#{Rails.env}.client_id_leads")).where(created_at: period_range)
  end

  def new_leads_ad_costs_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.ad_costs_by_month[month] || 0) / (self.new_leads_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def new_leads_by_month
    @new_leads_by_month ||= Contact.where(client_id: I18n.t("tenant.#{Rails.env}.client_id_leads")).where(created_at: period_range_by_month).group('EXTRACT(MONTH FROM created_at)').count
  end

  def new_leads_count
    @new_leads_count ||= self.new_leads.count
  end

  def new_leads_graph_data
    { dataset: { yAxisID: 'new_leads' }, name: 'New Leads', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => new_leads_by_month[month.to_f] } }.reduce({}, :merge) }
  end

  def new_leads_last_month
    @new_leads_last_month ||= Contact.where(client_id: I18n.t("tenant.#{Rails.env}.client_id_leads")).where(created_at: previous_period_range)
  end

  def new_leads_last_month_count
    @new_leads_last_month_count ||= self.new_leads_last_month.count
  end

  def new_leads_startup_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.startup_revenue_by_month[month.to_f] || 0) / (self.new_leads_by_month[month.to_f] || 1)).round(2) } }.reduce({}, :merge)
  end

  def startup_revenue
    @startup_revenue ||= self.new_clients.joins(:client_transactions)
                             .where(client_transactions: { created_at: period_range })
                             .where(client_transactions: { setting_key: 'startup_costs' })
                             .sum('client_transactions.setting_value::numeric')
  end

  def startup_revenue_by_month
    @startup_revenue_by_month ||= ClientTransaction.joins(:client)
                                                   .where(client_transactions: { created_at: period_range_by_month })
                                                   .where(client_transactions: { setting_key: 'startup_costs' })
                                                   .where(clients: { tenant: I18n.t('tenant.id') })
                                                   .where("(clients.data ->> 'mo_charge')::numeric > ?", 0)
                                                   .group('EXTRACT(MONTH FROM clients.created_at)')
                                                   .sum('client_transactions.setting_value::numeric')
  end

  def startup_revenue_vs_first_month_costs_by_month_ratio_graph_data
    self.month_sequence.map { |month| { Date::MONTHNAMES[month] => ((self.startup_revenue_by_month[month.to_f] || 0) - (self.first_month_costs_by_month[month] || 0)) } }.reduce({}, :merge)
  end

  def startup_revenue_graph_data
    { prefix: '$', dataset: { yAxisID: 'startup_revenue' }, name: 'Startup Revenue', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => startup_revenue_by_month[month.to_f] } }.reduce({}, :merge) }
  end

  def total_clients
    @total_clients ||= Client.where(tenant: I18n.t('tenant.id')).where('clients.data @> ?', { active: true }.to_json).where("(clients.data ->> 'mo_charge')::numeric > ?", 0)
  end

  def total_clients_count
    @total_clients_count ||= self.total_clients.count
  end

  def total_commission_costs
    self.mid_commission_costs + self.end_commission_costs
  end

  def total_costs
    self.ad_costs + self.total_commission_costs
  end

  def total_costs_by_month
    @total_costs_by_month ||= self.total_costs_by_month_calc
  end

  def total_costs_by_month_calc
    last_year_months = self.month_year_sequence.select { |_key, value| value == @year - 1 }
    this_year_months = self.month_year_sequence.select { |_key, value| value == @year }
    tenant_costs = TenantCost.where(tenant: I18n.t('tenant.id')).where(cost_key: %w[ads mid_comm end_comm])
    tenant_costs.where(month: last_year_months.keys, year: last_year_months.values)
                .or(tenant_costs.where(month: this_year_months.keys, year: this_year_months.values))
                .group(:month)
                .sum(:cost_value)
  end

  def total_costs_graph_data
    { prefix: '$', dataset: { yAxisID: 'total_costs' }, name: 'Total Costs', data: self.month_sequence.map { |month| { Date::MONTHNAMES[month] => self.total_costs_by_month[month].to_d } }.reduce({}, :merge) }
  end

  private

  def month_sequence
    ((@month + 1)..12).to_a + (1..@month).to_a
  end

  def month_year_sequence
    self.month_sequence.map { |month| { month => (month > "#{@year}-#{@month}-01".to_time.month ? @year - 1 : @year) } }.reduce({}, :merge)
  end

  def months_between
    ((Time.current.month + (Time.current.year * 12)) - (@month + (@year * 12)))
  end

  def period_range
    ["#{@year}-#{@month}-01".to_time.."#{@year}-#{@month}-01".to_time.at_end_of_month]
  end

  def period_range_by_month
    [("#{@year}-#{@month}-01".to_time - 11.months).."#{@year}-#{@month}-01".to_time.at_end_of_month]
  end

  def previous_period_range
    month = @month == 1 ? 12 : @month - 1
    year  = @month == 1 ? @year - 1 : @year
    ["#{year}-#{month}-01".to_time.."#{year}-#{month}-01".to_time.at_end_of_month]
  end
end
