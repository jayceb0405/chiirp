class AddFromPhoneToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column     :tasks,             :from_phone,        :string,            null: false,        default: ''
  end
end
