class AddTrialToPackage < ActiveRecord::Migration[5.2]
  def up
    Package.all.each do |p|
      p.update(trial_days: 0, trial_credits: 0.0)
    end

    Client.all.each do |c|
      c.update(pkg_trial_days: 0, pkg_trial_credits: 0.0)
    end

    remove_column :clients, :settings
  end

  def down
    Package.all.each do |p|
    	p.package_data.delete("trial_days")
    	p.package_data.delete("trial_credits")
      p.save
    end

    Client.all.each do |c|
      c.data.delete("pkg_trial_days")
      c.data.delete("pkg_trial_credits")
      c.save
    end
  end
end
