class AddApprovedAtToAttendanceCorrectionRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :attendance_correction_requests, :approved_at, :datetime
  end
end
