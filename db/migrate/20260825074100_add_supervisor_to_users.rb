class AddSupervisorToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :supervisor, :boolean, default: false
  end
end
