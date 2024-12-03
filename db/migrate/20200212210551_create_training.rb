class CreateTraining < ActiveRecord::Migration[5.2]
  def up
    create_table :trainings do |t|
      t.string     :menu_label,        null: false,        default: ""
      t.string     :title,             null: false,        default: ""
      t.string     :description,       null: false,        default: ""

      t.timestamps
    end

    create_table :training_pages do |t|
      t.references :training,          null: false,        default: 0,         index: true
      t.string     :menu_label,        null: false,        default: ""
      t.string     :title,             null: false,        default: ""
      t.boolean    :parent,            null: false,        default: false
    	t.integer    :position,          null: false,        default: 0,         index: true
    	t.text       :header,            null: false,        default: ""
    	t.text       :footer,            null: false,        default: ""
    	t.string     :video_link,        null: false,        default: ""

			t.timestamps
    end
  end

  def down
    drop_table :trainings
  	drop_table :training_pages
  end
end
