class CreatePackages < ActiveRecord::Migration[5.2]
  def up
    create_table :packages do |t|
      t.string  :name, null: false, default: "", index: true
      t.string  :package_key, null: false, default: "", index: true
      t.jsonb   :package_data, null: false, default: {}

			t.timestamps
    end

    create_table :package_pages do |t|
      t.string  :name, null: false, default: "", index: true
      t.string  :page_key, null: false, default: "", index: true
      t.integer :sys_default, null: false, default: 0
      t.integer :package_01_id, null: false, default: 0
      t.integer :package_02_id, null: false, default: 0
      t.integer :package_03_id, null: false, default: 0
      t.integer :primary_package, null: false, default: 0

      t.timestamps
    end

    add_index  :packages, :package_data, using: :gin
    remove_foreign_key :twnumbers, :clients
    add_foreign_key :twnumbers, :clients, on_delete: :cascade

    sm_package = Package.new(name: "Starter")
    sm_package.package_data = {
      max_phone_numbers: 1,
      phone_calls_allowed: 0,
      rvm_allowed: 0,
      share_funnels_allowed: 0,
      text_message_credits: 2,
      text_image_credits: 1,
      phone_call_credits: 2,
      rvm_credits: 4,
      mo_credits: 200,
      credit_charge: 0.04,
      mo_charge: 49.00
    }
    sm_package.save

    md_package = Package.new(name: "Growth")
    md_package.package_data = {
      max_phone_numbers: 2,
      phone_calls_allowed: 1,
      rvm_allowed: 0,
      share_funnels_allowed: 1,
      text_message_credits: 1,
      text_image_credits: 1,
      phone_call_credits: 2,
      rvm_credits: 4,
      mo_credits: 2000,
      credit_charge: 0.02,
      mo_charge: 99.00
    }
    md_package.save

    lg_package = Package.new(name: "Pro")
    lg_package.package_data = {
      max_phone_numbers: 5,
      phone_calls_allowed: 1,
      rvm_allowed: 1,
      share_funnels_allowed: 1,
      text_message_credits: 1,
      text_image_credits: 1,
      phone_call_credits: 2,
      rvm_credits: 4,
      mo_credits: 3500,
      credit_charge: 0.02,
      mo_charge: 149.00
    }
    lg_package.save

    Client.all.each do |c|
      c.settings[:pkg_current] = sm_package.id if c.settings[:pkg_current] == "s1100"
      c.settings[:pkg_current] = md_package.id if c.settings[:pkg_current] == "s2100"
      c.settings[:pkg_current] = lg_package.id if c.settings[:pkg_current] == "s3100"
      c.save
    end
  end

  def down
    Client.all.each do |c|
      c.settings[:pkg_current] = "s1100" if c.settings[:pkg_current] == 1
      c.settings[:pkg_current] = "s2100" if c.settings[:pkg_current] == 2
      c.settings[:pkg_current] = "s3100" if c.settings[:pkg_current] == 3
      c.save
    end

  	drop_table :packages
    drop_table :package_pages

    remove_foreign_key :twnumbers, :clients
    add_foreign_key :twnumbers, :clients
  end
end
