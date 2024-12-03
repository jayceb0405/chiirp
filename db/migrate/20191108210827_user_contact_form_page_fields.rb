class UserContactFormPageFields < ActiveRecord::Migration[5.2]
  def up
    add_column     :user_contact_forms,          :page_domain,       :string,            null: false,        default: ""
    add_column     :user_contact_forms,          :page_name,         :string,            null: false,        default: ""

    add_index      :user_contact_forms,          :page_domain
    add_index      :user_contact_forms,          :page_name
  end

  def down
    remove_column  :user_contact_forms,          :page_domain
    remove_column  :user_contact_forms,          :page_name
  end
end
