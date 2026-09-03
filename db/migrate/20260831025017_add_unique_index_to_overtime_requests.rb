class AddUniqueIndexToOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    add_index :overtime_requests, [:user_id, :worked_on], unique: true
  end
end
