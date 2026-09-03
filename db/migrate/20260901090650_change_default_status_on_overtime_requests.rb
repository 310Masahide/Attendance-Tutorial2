class ChangeDefaultStatusOnOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    # enum status: { unset: 0, pending: 1, approved: 2, rejected: 3 } の pending=1
    change_column_default :overtime_requests, :status, from: 0, to: 1
  end
end
