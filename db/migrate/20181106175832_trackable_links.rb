class TrackableLinks < ActiveRecord::Migration[5.2]
  def up
    create_table :trackable_links do |t|
      t.references :client, foreign_key: true
      t.references :tag, foreign_key: true
      t.references :campaign, foreign_key: true
      t.string  :name
      t.string  :original_url
      t.integer :dashboard, default: 0, null: false

      t.timestamps
    end

    create_table :trackable_short_links do |t|
    	t.references :trackable_link, foreign_key: true
    	t.string :short_code

    	t.timestamps
    end

    create_table :trackable_links_hits do |t|
    	t.references :trackable_short_link, foreign_key: true
    	t.string :referer
    	t.string :remote_ip

    	t.timestamps
    end
  end

  def down
    drop_table :trackable_links_hits
    drop_table :trackable_short_links
    drop_table :trackable_links
  end
end
