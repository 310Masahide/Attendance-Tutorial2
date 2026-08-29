class AddApplicantConfirmedToOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :overtime_requests, :applicant_confirmed, :boolean, default: false, null: false
  end
end
