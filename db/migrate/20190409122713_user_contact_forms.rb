class UserContactForms < ActiveRecord::Migration[5.2]
  def up
    create_table :user_contact_forms do |t|
      t.references :user, foreign_key: true
      t.string     :title,             default: "",   null: false
      t.text       :header_notes,      default: "",   null: false
      t.text       :footer_notes,      default: "",   null: false
      t.string     :logo_image
      t.string     :background_image
      t.string     :redirect_url,      default: "",   null: false
      t.string     :page_key,          default: "",   null: false, index: true
      t.integer    :campaign_id,       default: 0,    null: false
      t.integer    :tag_id,            default: 0,    null: false
      t.text       :data,              default: "",   null: false
    end
  end

  def down
  	drop_table :user_contact_forms
  end
end
