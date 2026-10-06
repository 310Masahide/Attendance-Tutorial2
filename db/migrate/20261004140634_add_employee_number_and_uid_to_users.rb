class AddEmployeeNumberAndUidToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :employee_number, :string
    add_index :users, :employee_number, unique: true
    add_column :users, :uid, :string
    add_index :users, :uid, unique: true
  end
end
