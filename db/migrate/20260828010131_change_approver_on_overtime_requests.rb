class ChangeApproverOnOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    remove_column :overtime_requests, :approver, :integer
    add_reference :overtime_requests, :approver, foreign_key: { to_table: :users }
    add_column :overtime_requests, :status, :integer, default: 0, null: false
  end
end
