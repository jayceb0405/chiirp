class AddClientWidgetFormatting < ActiveRecord::Migration[5.2]
  def up
    create_table :client_widgets do |t|
      t.references :client, foreign_key: true
      t.string     :widget_name,     default: "",   null: false
      t.integer    :campaign_id,     default: 0,    null: false
      t.integer    :tag_id,          default: 0,    null: false
      t.string     :widget_key,      default: "",   null: false, index: true
      t.string     :share_code,      default: "",   null: false
      t.jsonb      :formatting,      default: {},   null: false
    end

    add_index  :client_widgets, :formatting, using: :gin
  end

  def down
  	drop_table :client_widgets
  end
end
