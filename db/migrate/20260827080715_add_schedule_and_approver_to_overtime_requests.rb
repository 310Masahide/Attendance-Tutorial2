class AddScheduleAndApproverToOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :overtime_requests, :finished_hour, :integer
    add_column :overtime_requests, :finished_minute, :integer
    add_column :overtime_requests, :next_day, :boolean
    add_column :overtime_requests, :content, :string
    add_column :overtime_requests, :approver, :integer
  end
end
