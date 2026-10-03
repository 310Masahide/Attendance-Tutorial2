class AddOriginalTimesToAttendanceCorrectionRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :attendance_correction_requests, :original_started_at, :datetime
    add_column :attendance_correction_requests, :original_finished_at, :datetime
  end
end
