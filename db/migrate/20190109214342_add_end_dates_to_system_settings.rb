class AddEndDatesToSystemSettings < ActiveRecord::Migration[5.2]
  def up
  	SystemSetting.where(setting_key: [201,211,212,231,232,237]).where(end_date: nil).update_all(end_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc)

    SystemSetting.all.each do |ss|
      unless ss.setting_key[0] == "s"
        ss.setting_key = "s#{ss.setting_key.to_s}"
        ss.save
      end
    end

  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1100", setting_value: "Starter").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1110", setting_value: "49.00").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1120", setting_value: "0.04").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1130", setting_value: "200").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1140", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1150", setting_value: "0").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1160", setting_value: "0").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1170", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1180", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1190", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s1200", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2100", setting_value: "Growth").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2110", setting_value: "99.00").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2120", setting_value: "0.02").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2130", setting_value: "2000").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2140", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2150", setting_value: "0").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2160", setting_value: "0").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2170", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2180", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2190", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s2200", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3100", setting_value: "Pro").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3110", setting_value: "149.00").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3120", setting_value: "0.02").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3130", setting_value: "3500").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3140", setting_value: "5").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3150", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3160", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3170", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3180", setting_value: "1").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3190", setting_value: "2").save
  	SystemSetting.new(start_date: Time.current.in_time_zone("Mountain Time (US & Canada)").utc, setting_key: "s3200", setting_value: "2").save

    Client.all.each do |c|
      unless c.settings.nil?
        c.settings[:pkg_text_message_credits] = c.settings[:s211] if c.settings.include?(:s211)
        c.settings.delete(:s211) if c.settings.include?(:s211)
        c.settings[:pkg_text_image_credits] = c.settings[:s212] if c.settings.include?(:s212)
        c.settings.delete(:s212) if c.settings.include?(:s212)
        c.settings[:pkg_phone_call_credits] = c.settings[:s231] if c.settings.include?(:s231)
        c.settings.delete(:s231) if c.settings.include?(:s231)
        c.settings[:pkg_rvm_credits] = c.settings[:s232] if c.settings.include?(:s232)
        c.settings.delete(:s232) if c.settings.include?(:s232)
        c.settings[:pkg_credit_charge] = c.settings[:s237] if c.settings.include?(:s237)
        c.settings.delete(:s237) if c.settings.include?(:s237)
        c.settings[:pkg_mo_charge] = c.settings[:s241] if c.settings.include?(:s241)
        c.settings.delete(:s241) if c.settings.include?(:s241)
        c.settings[:pkg_mo_credits] = c.settings[:s242] if c.settings.include?(:s242)
        c.settings.delete(:s242) if c.settings.include?(:s242)
        c.settings[:pkg_current] = "s1100"
        c.settings[:pkg_phone_numbers_qty] = "1"
        c.settings[:pkg_phone_calls_allowed] = "1"
        c.settings[:pkg_rvm_allowed] = "1"
        c.save
      end
    end

    ClientTransaction.where(setting_key: 601).update_all(setting_key: "s601")
    ClientTransaction.where(setting_key: 701).update_all(setting_key: "s701")
    ClientTransaction.where(setting_key: 702).update_all(setting_key: "s702")
    ClientTransaction.where(setting_key: 211).update_all(setting_key: "pkg_text_message_credits")
    ClientTransaction.where(setting_key: 212).update_all(setting_key: "pkg_text_image_credits")
    ClientTransaction.where(setting_key: 231).update_all(setting_key: "pkg_phone_call_credits")
    ClientTransaction.where(setting_key: 232).update_all(setting_key: "pkg_rvm_credits")
    ClientTransaction.where(setting_key: 237).update_all(setting_key: "pkg_credit_charge")
    ClientTransaction.where(setting_key: 241).update_all(setting_key: "pkg_mo_charge")
    ClientTransaction.where(setting_key: 242).update_all(setting_key: "pkg_mo_credits")
  end

  def down
  end
end
