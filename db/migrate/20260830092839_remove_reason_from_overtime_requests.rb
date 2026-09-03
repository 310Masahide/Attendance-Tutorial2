class RemoveReasonFromOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    remove_column :overtime_requests, :next_day, :finishes_next_day
    change_column_default :overtime_requests, :finishes_next_day, from: nil, to: false
    change_column_null :overtime_requests, :finishes_next_day, false, false
  end
end
